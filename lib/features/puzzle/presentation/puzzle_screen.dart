import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/audio/puzzle_audio_controller.dart';
import '../../../core/constants/board_constants.dart';
import '../../../core/constants/debug_flags.dart';
import '../../../core/constants/puzzle_ui_flags.dart';
import '../../../core/economy/coin_service.dart';
import '../../../core/theme/puzzle_theme.dart';
import '../data/deconstructors/puzzle_deconstructor.dart';
import '../data/generators/puzzle_layout_generator.dart';
import '../data/models/deconstructed_puzzle.dart';
import '../data/models/puzzle_content.dart';
import '../data/models/puzzle_layout.dart';
import '../data/repositories/puzzle_repository.dart';
import '../domain/board_geometry.dart';
import '../domain/completion_scan_service.dart';
import '../domain/deconstructed_pieces_builder.dart';
import '../domain/puzzle_board_state.dart';
import '../domain/puzzle_move_history.dart';
import '../domain/puzzle_piece.dart';
import '../domain/solved_layout_piece_builder.dart';
import '../domain/word_pieces_builder.dart';
import '../domain/word_completion_debug.dart';
import 'widgets/puzzle_board_container.dart';
import 'widgets/puzzle_board_grid.dart';
import 'widgets/puzzle_bottom_action_bar.dart';
import 'widgets/puzzle_chunks_layer.dart';
import 'widgets/puzzle_hint_tooltip_row.dart';
import 'widgets/puzzle_nature_background.dart';
import 'widgets/puzzle_top_header.dart';

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

class _PuzzleScreenState extends State<PuzzleScreen> with WidgetsBindingObserver {
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
  DeconstructedPuzzle? _deconstructedPuzzle;
  Set<String> _completedAnswers = {};
  bool _puzzleCompletionHandled = false;
  bool _interactionEnabled = true;
  String? _lastEvaluatedPiecesSnapshot;
  bool _applyingUndo = false;

  PuzzleLayout? get _currentLayout =>
      _layouts.isEmpty ? null : _layouts[_currentLayoutIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CoinService.instance.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioController.ensurePuzzleLoopPlaying();
    });
    _loadAndGenerate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _leavePuzzle() async {
    await _audioController.leavePuzzleSession();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _audioController.pausePuzzleLoopSound();
      case AppLifecycleState.resumed:
        _audioController.resumePuzzleLoopSound();
      case AppLifecycleState.inactive:
        break;
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
    _deconstructedPuzzle = PuzzleDeconstructor().build(layout);

    switch (kPuzzlePieceSource) {
      case PuzzlePieceSource.deconstructed:
        _playPieces = buildDeconstructedPlayPieces(
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
    if (puzzle == null) {
      return;
    }

    final playAreaBoard = buildPlayAreaLetterMap(_playPieces);
    final scanScope = buildInitializationScanScope(playAreaBoard);
    if (scanScope.isEmpty) {
      return;
    }

    _lastEvaluatedPiecesSnapshot = null;

    final result = runCompletionScan(
      pieces: _playPieces,
      scanScopeCells: scanScope,
      targetWords: puzzle.words,
      completedAnswers: _completedAnswers,
      source: CompletionScanSource.initialization,
      puzzleId: puzzle.id,
      puzzleCategory: puzzle.category,
      boardRows: _playCanvasRows,
      boardCols: _playCanvasCols,
    );

    _applyCompletionScanResult(result);
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

      final layouts = PuzzleLayoutGenerator().generateAllLayouts(puzzle.words);

      debugPrint('[PuzzleScreen] Loaded puzzle: ${puzzle.id}');
      debugPrint('[PuzzleScreen] Category: ${puzzle.category}');
      debugPrint('[PuzzleScreen] Words: ${puzzle.words}');
      debugPrint('[PuzzleScreen] Total layouts: ${layouts.length}');

      if (layouts.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage = 'No valid layout found for this puzzle';
          _isLoading = false;
        });
        return;
      }

      final currentLayout = layouts.first;
      debugPrint('[PuzzleScreen] Placements:');
      for (final placement in currentLayout.placedWords) {
        debugPrint('[PuzzleScreen]   $placement');
      }
      debugPrint(
        '[PuzzleScreen] Bounds: rows ${currentLayout.minRow}..${currentLayout.maxRow}, '
        'cols ${currentLayout.minCol}..${currentLayout.maxCol}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _puzzle = puzzle;
        _layouts = layouts;
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

  void _shuffleLayout() {
    if (_layouts.length <= 1) {
      return;
    }

    setState(() {
      _currentLayoutIndex = nextLayoutIndex(
        _currentLayoutIndex,
        _layouts.length,
      );
      _resetCompletionState();
      _moveHistory.clear();
      final layout = _currentLayout;
      if (layout != null && _playCanvasRows > 0 && _playCanvasCols > 0) {
        _rebuildPlayPieces(
          layout,
          canvasRows: _playCanvasRows,
          canvasCols: _playCanvasCols,
        );
      }
    });

    _scheduleCompletionScanOnInit();

    debugPrint(
      '[PuzzleScreen] Shuffled to layout ${_currentLayoutIndex + 1} / ${_layouts.length}',
    );
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
      _puzzleCompletionHandled = false;
      _interactionEnabled = true;
    });
    _applyingUndo = false;
    _lastEvaluatedPiecesSnapshot = null;
  }

  void _useHint() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Hint: place each word at its layout position on the board.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetCompletionState() {
    _completedAnswers = {};
    _puzzleCompletionHandled = false;
    _interactionEnabled = true;
    _deconstructedPuzzle = null;
    _lastEvaluatedPiecesSnapshot = null;
    _moveHistory.clear();
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
      _moveHistory.push(_playPieces, _completedAnswers);
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
    if (puzzle == null) {
      logCompletionSkipped('puzzle is null');
      return;
    }

    if (event.affectedCells.isEmpty) {
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

    var scanScope = buildBoardChangeScanScope(
      affectedCells: event.affectedCells,
      playAreaBoard: playAreaBoard,
    );

    if (scanScope.isEmpty) {
      final affectedOnBoard = event.affectedCells
          .where((cell) => playAreaBoard.containsKey(cell))
          .toSet();
      scanScope = affectedOnBoard.isNotEmpty
          ? affectedOnBoard
          : getAllPlayAreaCells(playAreaBoard);
    }

    final result = runCompletionScan(
      pieces: event.pieces,
      scanScopeCells: scanScope,
      targetWords: puzzle.words,
      completedAnswers: _completedAnswers,
      source: CompletionScanSource.boardChange,
      puzzleId: puzzle.id,
      puzzleCategory: puzzle.category,
      boardRows: _playCanvasRows,
      boardCols: _playCanvasCols,
    );

    if (result.hasChanges) {
      _lastEvaluatedPiecesSnapshot = null;
    }

    _applyCompletionScanResult(result);
  }

  void _applyCompletionScanResult(CompletionScanResult result) {
    if (!result.hasChanges) {
      if (result.allAnswersCompleted && !_puzzleCompletionHandled) {
        _onPuzzleCompleted();
      }
      return;
    }

    setState(() {
      _playPieces = result.pieces;
      _completedAnswers = result.completedAnswers;
    });

    if (result.allAnswersCompleted) {
      _onPuzzleCompleted();
    }
  }

  Future<void> _onPuzzleCompleted() async {
    if (_puzzleCompletionHandled) {
      return;
    }

    setState(() {
      _puzzleCompletionHandled = true;
      _interactionEnabled = false;
    });

    await CoinService.instance.addCoins(kPuzzleCompletionCoinReward);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Puzzle complete! +$kPuzzleCompletionCoinReward coins',
        ),
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
      await _audioController.leavePuzzleSession();
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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _audioController.leavePuzzleSession();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PuzzleNatureBackground(),
            SafeArea(
              child: _buildBody(context),
            ),
          ],
        ),
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

    final boardCellSize = BoardConstants.kBoardTileSize;

    return ListenableBuilder(
      listenable: CoinService.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PuzzleTopHeader(
              title: puzzle.category,
              coinBalance: CoinService.instance.coinBalance,
              onBack: _leavePuzzle,
            ),
            PuzzleHintTooltipRow(onHintPressed: _useHint),
            Expanded(
              child: PuzzleBoardContainer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasCols = max(
                      1,
                      (constraints.maxWidth / boardCellSize).floor(),
                    );
                    final canvasRows = max(
                      1,
                      (constraints.maxHeight / boardCellSize).floor(),
                    );

                    _schedulePlayCanvasUpdate(canvasRows, canvasCols);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PuzzleBoardGrid(spacing: boardCellSize),
                          if (_playPieces.isNotEmpty)
                            PuzzleChunksLayer(
                              key: ValueKey(_currentLayoutIndex),
                              boardRows: canvasRows,
                              boardCols: canvasCols,
                              canvasRows: canvasRows,
                              canvasCols: canvasCols,
                              pieces: _playPieces,
                              tileSize: boardCellSize,
                              onPiecesChanged: _onPiecesChanged,
                              onDragStart: _audioController.playTilePickSound,
                              onDragEnd: _audioController.playTileDropSound,
                              interactionEnabled: _interactionEnabled,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            PuzzleBottomActionBar(
              onUndo: _undoLastMove,
              onHint: _useHint,
              onShuffle: _shuffleLayout,
              undoEnabled: _moveHistory.canUndo && !_puzzleCompletionHandled,
              shuffleEnabled: _layouts.length > 1 && !_puzzleCompletionHandled,
              hintEnabled: !_puzzleCompletionHandled,
            ),
          ],
        );
      },
    );
  }
}
