import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/puzzle_audio_controller.dart';
import '../../../core/constants/board_constants.dart';
import '../../../core/constants/debug_flags.dart';
import '../../../core/theme/puzzle_theme.dart';
import '../data/deconstructors/puzzle_deconstructor.dart';
import '../data/models/deconstructed_puzzle.dart';
import '../data/models/generated_puzzle_layout.dart';
import '../data/models/puzzle_content.dart';
import '../data/models/puzzle_layout.dart';
import '../data/repositories/hardcoded_puzzle_repository.dart';
import '../data/repositories/puzzle_repository.dart';
import '../domain/board_geometry.dart';
import '../domain/word_resolution/puzzle_layout_metadata.dart';
import '../domain/word_resolution/puzzle_runtime_state.dart';
import '../domain/word_resolution/word_resolution_logger.dart';
import '../domain/word_resolution/word_resolution_models.dart';
import '../domain/word_resolution/word_resolution_service.dart';
import '../domain/deconstructed_pieces_builder.dart';
import '../domain/puzzle_board_state.dart';
import '../domain/puzzle_hint_service.dart';
import '../domain/puzzle_move_history.dart';
import '../domain/puzzle_piece.dart';
import '../domain/solved_layout_piece_builder.dart';
import '../domain/word_pieces_builder.dart';
import '../domain/word_completion_debug.dart';
import '../../landing/presentation/widgets/home_settings_sheet.dart';
import 'widgets/puzzle_board_container.dart';
import 'widgets/puzzle_board_grid.dart';
import 'widgets/puzzle_bottom_action_bar.dart';
import 'widgets/puzzle_chunks_layer.dart';
import 'widgets/puzzle_nature_background.dart';
import 'widgets/puzzle_top_header.dart';
import 'hints/final_grid_hint_popup.dart';
import 'how_to_play/how_to_play_popup.dart';
import 'intro/puzzle_intro_animation_logger.dart';

/// Returns the next layout index when cycling through [layoutCount] layouts.
int nextLayoutIndex(int currentIndex, int layoutCount) {
  if (layoutCount <= 1) {
    return currentIndex;
  }
  return (currentIndex + 1) % layoutCount;
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.puzzleId,
  });

  final int puzzleId;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final PuzzleRepository _puzzleRepository = PuzzleRepository();
  final PuzzleMoveHistory _moveHistory = PuzzleMoveHistory();

  PuzzleAudioController get _audioController => PuzzleAudioController.instance;

  PuzzleContent? _puzzle;
  List<PuzzleLayout> _layouts = const [];
  int _currentLayoutIndex = 0;
  String? _errorMessage;
  bool _isLoading = true;
  int _playCanvasRows = 0;
  int _playCanvasCols = 0;
  List<PuzzlePiece> _playPieces = const [];
  DeconstructedPuzzle? _hardcodedDeconstructed;
  PuzzleLayoutMetadata? _layoutMetadata;
  Set<String> _completedAnswers = {};
  Set<String> _solvedWordIds = {};
  Set<String> _reservedCellIds = {};
  Map<String, SolvedAssignment> _solvedAssignments = {};
  bool _puzzleCompletionHandled = false;
  bool _interactionEnabled = false;
  bool _introAnimationPending = true;
  String? _lastEvaluatedPiecesSnapshot;
  bool _applyingUndo = false;
  PuzzleConnectHint? _activeHint;
  Set<String> _hintHighlightedPieceIds = {};
  Timer? _hintClearTimer;
  int _resolutionStepCounter = 0;

  PuzzleLayout? get _currentLayout =>
      _layouts.isEmpty ? null : _layouts[_currentLayoutIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioController.ensurePuzzleLoopPlaying();
    });
    _loadAndGenerate();
  }

  @override
  void dispose() {
    _hintClearTimer?.cancel();
    super.dispose();
  }

  void _openSettings() {
    showSettingsSheet(
      context,
      showRestart: true,
      onRestart: _loadAndGenerate,
    );
  }

  Future<void> _leavePuzzle() async {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didUpdateWidget(covariant PuzzleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.puzzleId != widget.puzzleId) {
      _loadAndGenerate();
    }
  }

  void _schedulePlayCanvasUpdate(int canvasRows, int canvasCols) {
    if (_playCanvasRows == canvasRows && _playCanvasCols == canvasCols) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playCanvasRows = canvasRows;
        _playCanvasCols = canvasCols;
        final layout = _currentLayout;
        if (layout != null) {
          _rebuildPlayPieces(
            layout,
            canvasRows: canvasRows,
            canvasCols: canvasCols,
          );
          _scheduleCompletionScanOnInit();
        }
      });
    });
  }

  void _rebuildPlayPieces(
    PuzzleLayout layout, {
    required int canvasRows,
    required int canvasCols,
  }) {
    final deconstructed =
        _hardcodedDeconstructed ?? PuzzleDeconstructor().build(layout);
    _layoutMetadata = PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
      layout: layout,
      deconstructed: deconstructed,
    );

    switch (kPuzzlePieceSource) {
      case PuzzlePieceSource.deconstructed:
        _playPieces = _hardcodedDeconstructed != null
            ? buildDeconstructedPlayPiecesFromDeconstruction(
                deconstructed: deconstructed,
                canvasRows: canvasRows,
                canvasCols: canvasCols,
              )
            : buildDeconstructedPlayPieces(
                layout: layout,
                canvasRows: canvasRows,
                canvasCols: canvasCols,
              );
      case PuzzlePieceSource.solved:
        final pieceState = buildSolvedPiece(layout);
        var piece = PuzzlePiece.fromPieceState(pieceState);
        final anchor = centeredPieceAnchor(
          canvasRows: canvasRows,
          canvasCols: canvasCols,
          piece: piece,
        );
        _playPieces = [
          PuzzlePiece(
            id: piece.id,
            chunkId: piece.chunkId,
            anchorRow: anchor.row,
            anchorCol: anchor.col,
            spawnAnchorRow: anchor.row,
            spawnAnchorCol: anchor.col,
            cells: piece.cells,
          ),
        ];
      case PuzzlePieceSource.words:
        _playPieces = buildWordPieces(
          layout: layout,
          canvasRows: canvasRows,
          canvasCols: canvasCols,
        );
    }
  }

  void _scheduleCompletionScanOnInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scanCompletionOnInit();
    });
  }

  void _scanCompletionOnInit() {
    if (_puzzleCompletionHandled) {
      return;
    }

    final puzzle = _puzzle;
    final metadata = _layoutMetadata;
    if (puzzle == null || metadata == null) {
      return;
    }

    _lastEvaluatedPiecesSnapshot = null;

    final result = runInitialPuzzleResolution(
      pieces: _playPieces,
      metadata: metadata,
      solvedWordIds: _solvedWordIds,
      reservedCellIds: _reservedCellIds,
      solvedAssignments: _solvedAssignments,
    );

    _applyWordResolutionResult(result);
  }

  Future<void> _loadAndGenerate() async {
    debugPrint('[PuzzleScreen] Rendering puzzleId: ${widget.puzzleId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _puzzle = null;
      _layouts = const [];
      _currentLayoutIndex = 0;
      _playPieces = const [];
      _hardcodedDeconstructed = null;
      _playCanvasRows = 0;
      _playCanvasCols = 0;
      _resetCompletionState();
    });

    try {
      final puzzle = await PuzzleRepository().getPuzzleById(widget.puzzleId);

      if (puzzle == null) {
        throw StateError('Puzzle ${widget.puzzleId} was not found');
      }

      if (!puzzle.enabled) {
        throw StateError('Puzzle ${widget.puzzleId} is disabled');
      }

      final bundle =
          await HardcodedPuzzleRepository().loadBundle(widget.puzzleId);
      if (bundle == null) {
        throw StateError(
          'No hardcoded definition for puzzle ${widget.puzzleId}',
        );
      }

      final layout = bundle.layout;

      debugPrint('[PuzzleScreen] Loaded puzzle: ${puzzle.id}');
      debugPrint('[PuzzleScreen] Category: ${puzzle.category}');
      debugPrint('[PuzzleScreen] Words: ${puzzle.words}');
      debugPrint('[PuzzleScreen] Using hardcoded layout and chunks');
      debugPrint('[PuzzleScreen] Placements:');
      for (final placement in layout.placedWords) {
        debugPrint('[PuzzleScreen]   $placement');
      }
      debugPrint(
        '[PuzzleScreen] Bounds: rows ${layout.minRow}..${layout.maxRow}, '
        'cols ${layout.minCol}..${layout.maxCol}',
      );
      debugPrint(
        '[PuzzleScreen] Hardcoded chunks: ${bundle.deconstructed.chunks.length}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _puzzle = puzzle;
        _layouts = [layout];
        _hardcodedDeconstructed = bundle.deconstructed;
        _currentLayoutIndex = 0;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[PuzzleScreen] Failed to load puzzle: $error');
      debugPrint('[PuzzleScreen] $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _userFacingError(error);
        _isLoading = false;
      });
    }
  }

  void _undoLastMove() {
    if (!_moveHistory.canUndo || _puzzleCompletionHandled) {
      return;
    }

    final snapshot = _moveHistory.pop();
    if (snapshot == null) {
      return;
    }

    _applyingUndo = true;
    setState(() {
      _playPieces = snapshot.pieces;
      _completedAnswers = snapshot.completedAnswers;
      _solvedWordIds = {...snapshot.solvedWordIds};
      _reservedCellIds = {...snapshot.reservedCellIds};
      _solvedAssignments = {
        for (final entry in snapshot.solvedAssignments.entries)
          entry.key: SolvedAssignment(
            wordId: entry.value.wordId,
            assignedCellIds: {...entry.value.assignedCellIds},
            moveComponentId: entry.value.moveComponentId,
          ),
      };
      _puzzleCompletionHandled = false;
      _interactionEnabled = true;
    });
    _applyingUndo = false;
    _lastEvaluatedPiecesSnapshot = null;
  }

  void _openHowToPlay() {
    showHowToPlayPopup(context);
  }

  void _clearActiveHint() {
    _hintClearTimer?.cancel();
    _hintClearTimer = null;
    if (_activeHint == null && _hintHighlightedPieceIds.isEmpty) {
      return;
    }
    setState(() {
      _activeHint = null;
      _hintHighlightedPieceIds = {};
    });
  }

  void _useHint() {
    if (!mounted || _puzzleCompletionHandled) {
      return;
    }

    final metadata = _layoutMetadata;
    if (metadata == null) {
      return;
    }

    final hint = suggestNextConnectHint(
      pieces: _playPieces,
      metadata: metadata,
      solvedWordIds: _solvedWordIds,
    );

    if (hint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All words are complete!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _hintClearTimer?.cancel();
    setState(() {
      _activeHint = hint;
      _hintHighlightedPieceIds = hint.highlightedPieceIds;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hint.message),
        duration: const Duration(seconds: 4),
      ),
    );

    _hintClearTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }
      _clearActiveHint();
    });
  }

  void _showFullGridHint() {
    if (!mounted || _puzzleCompletionHandled) {
      return;
    }

    final puzzle = _puzzle;
    final currentLayout = _currentLayout;
    if (puzzle == null || currentLayout == null) {
      return;
    }

    final generatedLayout = GeneratedPuzzleLayout.fromPuzzleContent(
      puzzle,
      currentLayout,
    );

    showFinalGridHintPopup(context, layout: generatedLayout);
  }

  void _resetCompletionState() {
    _completedAnswers = {};
    _solvedWordIds = {};
    _reservedCellIds = {};
    _solvedAssignments = {};
    _layoutMetadata = null;
    _puzzleCompletionHandled = false;
    _introAnimationPending = true;
    _interactionEnabled = false;
    _lastEvaluatedPiecesSnapshot = null;
    _moveHistory.clear();
    _clearActiveHint();
  }

  void _onIntroComplete() {
    if (!mounted) {
      return;
    }
    setState(() {
      _introAnimationPending = false;
      if (!_puzzleCompletionHandled) {
        _interactionEnabled = true;
      }
    });
    PuzzleIntroAnimationLogger.introComplete(
      interactionEnabled: !_puzzleCompletionHandled,
    );
  }

  String _piecesSnapshot(List<PuzzlePiece> pieces) {
    return pieces
        .map(
          (piece) =>
              '${piece.id}:${piece.anchorRow},${piece.anchorCol}:${piece.cells.length}:${piece.isCompletedWordGroup}',
        )
        .join('|');
  }

  void _onPiecesChanged(PiecesChangeEvent event) {
    if (!_applyingUndo && !_puzzleCompletionHandled) {
      _moveHistory.push(
        _playPieces,
        _completedAnswers,
        solvedWordIds: _solvedWordIds,
        reservedCellIds: _reservedCellIds,
        solvedAssignments: _solvedAssignments,
      );
    }

    setState(() {
      _playPieces = event.pieces;
    });
    _evaluateCompletion(event);
  }

  void _evaluateCompletion(PiecesChangeEvent event) {
    if (_puzzleCompletionHandled) {
      logCompletionSkipped('puzzle already completed');
      return;
    }

    final puzzle = _puzzle;
    final metadata = _layoutMetadata;
    if (puzzle == null || metadata == null) {
      logCompletionSkipped('puzzle or metadata is null');
      return;
    }

    if (event.affectedCells.isEmpty && event.movedPieceIds.isEmpty) {
      logCompletionSkipped('no affected cells');
      return;
    }

    final snapshot = _piecesSnapshot(event.pieces);
    if (snapshot == _lastEvaluatedPiecesSnapshot) {
      logCompletionSkipped('pieces unchanged since last evaluation');
      return;
    }
    _lastEvaluatedPiecesSnapshot = snapshot;

    final playAreaBoard = buildPlayAreaLetterMap(event.pieces);
    if (playAreaBoard.isEmpty) {
      logCompletionSkipped('board has no letters on grid');
      return;
    }

    final movedChunkIds = event.movedPieceIds.isNotEmpty
        ? chunkIdsFromMovedPieceIds(
            movedPieceIds: event.movedPieceIds,
            pieces: event.pieces,
          )
        : <String>{};

    _resolutionStepCounter++;
    logMoveStep(
      step: _resolutionStepCounter,
      movedChunkIds: movedChunkIds,
      boardLetterCount: playAreaBoard.length,
    );

    final result = handlePuzzleStateAfterReconnect(
      pieces: event.pieces,
      metadata: metadata,
      movedChunkIds: movedChunkIds,
      solvedWordIds: _solvedWordIds,
      reservedCellIds: _reservedCellIds,
      solvedAssignments: _solvedAssignments,
    );

    if (result.hasChanges) {
      _lastEvaluatedPiecesSnapshot = null;
    }

    _applyWordResolutionResult(result);
  }

  void _applyWordResolutionResult(WordResolutionResult result) {
    if (!result.hasChanges) {
      if (result.puzzleComplete && !_puzzleCompletionHandled) {
        _onPuzzleCompleted();
      }
      return;
    }

    setState(() {
      _playPieces = result.pieces;
      _completedAnswers = result.completedAnswers;
      _solvedWordIds = result.solvedWordIds;
      _reservedCellIds = result.reservedCellIds;
      _solvedAssignments = result.solvedAssignments;
    });

    if (result.puzzleComplete) {
      _onPuzzleCompleted();
    }
  }

  Future<void> _onPuzzleCompleted() async {
    if (_puzzleCompletionHandled) {
      return;
    }

    setState(() {
      _puzzleCompletionHandled = true;
      _introAnimationPending = false;
      _interactionEnabled = false;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Puzzle complete!'),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    await _goToNextPuzzle();
  }

  Future<void> _goToNextPuzzle() async {
    final nextPuzzleId =
        await _puzzleRepository.getNextEnabledPuzzleId(widget.puzzleId);

    if (!mounted) {
      return;
    }

    if (nextPuzzleId == null) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleScreen(puzzleId: nextPuzzleId),
      ),
    );
  }

  String _userFacingError(Object error) {
    if (error is StateError &&
        error.message.contains('Could not generate connected layout')) {
      return 'Unable to generate puzzle grid for this content';
    }

    if (error is StateError &&
        error.message.contains('cannot form a connected graph')) {
      return 'Unable to generate puzzle grid for this content';
    }

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PuzzleNatureBackground(),
            SafeArea(
              bottom: false,
              child: _buildBody(context),
            ),
          ],
        ),
      );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: PuzzleTheme.darkGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BoardConstants.kBoardOuterPadding),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PuzzleTheme.darkGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    final puzzle = _puzzle;
    final currentLayout = _currentLayout;
    if (puzzle == null || currentLayout == null) {
      return const SizedBox.shrink();
    }

    const boardRows = BoardConstants.kPlayGridRows;
    const boardCols = BoardConstants.kPlayGridCols;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PuzzleTopHeader(
          title: puzzle.category,
          onBack: _leavePuzzle,
          onHowToPlay: _openHowToPlay,
          onSettingsPressed: _openSettings,
        ),
        Expanded(
          child: PuzzleBoardContainer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final playableWidth = constraints.maxWidth;
                final playableHeight = constraints.maxHeight;

                const canvasRows = boardRows;
                const canvasCols = boardCols;

                final tileSize = min(
                  playableWidth / canvasCols,
                  playableHeight / canvasRows,
                );

                _schedulePlayCanvasUpdate(canvasRows, canvasCols);

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ColoredBox(
                      color: PuzzleTheme.boardBg,
                      child: SizedBox.expand(),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: PuzzleBoardGrid(
                        spacing: tileSize,
                        gridRows: boardRows,
                        gridCols: boardCols,
                      ),
                    ),
                    if (_playPieces.isNotEmpty)
                      PuzzleChunksLayer(
                        key: ValueKey(_currentLayoutIndex),
                        boardRows: boardRows,
                        boardCols: boardCols,
                        canvasRows: canvasRows,
                        canvasCols: canvasCols,
                        pieces: _playPieces,
                        tileSize: tileSize,
                        hintHighlightedPieceIds: _hintHighlightedPieceIds,
                        onPiecesChanged: _onPiecesChanged,
                        onDragStart: () {
                          _clearActiveHint();
                          _audioController.playTilePickSound();
                        },
                        onDragEnd: _audioController.playTileDropSound,
                        interactionEnabled: _interactionEnabled,
                        introAnimationEnabled:
                            _introAnimationPending &&
                            !_puzzleCompletionHandled &&
                            _playPieces.isNotEmpty,
                        onIntroComplete: _onIntroComplete,
                        onChunkSpawnSound:
                            _audioController.playPuzzleChunkSpawnSound,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        PuzzleBottomActionBar(
          onUndo: _undoLastMove,
          onHint: _useHint,
          onFullGrid: _showFullGridHint,
          undoEnabled: _moveHistory.canUndo && !_puzzleCompletionHandled,
          hintEnabled: !_puzzleCompletionHandled,
          fullGridEnabled: !_puzzleCompletionHandled,
        ),
      ],
    );
  }
}
