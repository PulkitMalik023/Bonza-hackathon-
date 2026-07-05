import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/board_cell_position.dart';
import '../../domain/board_geometry.dart';
import '../../domain/board_occupancy.dart';
import '../../domain/chunk_drop_evaluator.dart';
import '../../domain/puzzle_board_state.dart';
import '../../domain/puzzle_piece.dart';
import '../../domain/puzzle_solved_checker.dart';
import '../../domain/word_completion_debug.dart';
import '../intro/puzzle_chunk_intro_coordinator.dart';
import 'puzzle_piece_content.dart';

export '../../domain/chunk_drop_evaluator.dart' show canPlaceOnBoard;

const _kLogChunkDrops = true;

class PuzzleChunksLayer extends StatefulWidget {
  const PuzzleChunksLayer({
    super.key,
    required this.boardRows,
    required this.boardCols,
    required this.canvasRows,
    required this.canvasCols,
    required this.pieces,
    required this.onPiecesChanged,
    required this.tileSize,
    this.interactionEnabled = true,
    this.introAnimationEnabled = false,
    this.onIntroComplete,
    this.onChunkSpawnSound,
    this.onDragStart,
    this.onDragEnd,
    this.hintHighlightedPieceIds = const {},
  });

  final int boardRows;
  final int boardCols;
  final int canvasRows;
  final int canvasCols;
  final List<PuzzlePiece> pieces;
  final ValueChanged<PiecesChangeEvent> onPiecesChanged;
  final double tileSize;
  final bool interactionEnabled;
  final bool introAnimationEnabled;
  final VoidCallback? onIntroComplete;
  final VoidCallback? onChunkSpawnSound;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Set<String> hintHighlightedPieceIds;

  @override
  State<PuzzleChunksLayer> createState() => _PuzzleChunksLayerState();
}

class _PuzzleChunksLayerState extends State<PuzzleChunksLayer>
    with SingleTickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final BoardOccupancy _occupancy = BoardOccupancy();

  late List<PuzzlePiece> _pieces;
  String? _draggedPieceId;
  Offset? _liveDragTopLeft;
  Offset _grabOffset = Offset.zero;
  int? _dragStartAnchorRow;
  int? _dragStartAnchorCol;

  PuzzleChunkIntroCoordinator? _introCoordinator;
  bool _introStartedForCurrentPieces = false;
  Object? _introPiecesIdentity;
  int _introStartRequestId = 0;

  bool get _isDragLocked => _draggedPieceId != null;

  bool get _isIntroActive =>
      widget.introAnimationEnabled &&
      (_introCoordinator?.isRunning ?? false);

  @override
  void initState() {
    super.initState();
    _pieces = _clonePieces(widget.pieces);
    _rebuildOccupancy();
    _initIntroCoordinator();
    _maybeStartIntro();
  }

  @override
  void dispose() {
    _introStartRequestId++;
    _introCoordinator?.dispose();
    super.dispose();
  }

  void _initIntroCoordinator() {
    _introCoordinator?.dispose();
    _introCoordinator = PuzzleChunkIntroCoordinator(
      vsync: this,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
      onAllComplete: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _introStartedForCurrentPieces = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          widget.onIntroComplete?.call();
        });
      },
    );
  }

  void _maybeStartIntro({bool force = false}) {
    if (!widget.introAnimationEnabled || _pieces.isEmpty) {
      return;
    }

    final piecesIdentity = Object.hashAll(_pieces.map((piece) => piece.id));
    if (!force &&
        _introStartedForCurrentPieces &&
        _introPiecesIdentity == piecesIdentity) {
      return;
    }

    final requestId = ++_introStartRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _introStartRequestId) {
        return;
      }
      if (!widget.introAnimationEnabled || _pieces.isEmpty) {
        return;
      }

      final currentIdentity = Object.hashAll(_pieces.map((piece) => piece.id));
      if (!force &&
          _introStartedForCurrentPieces &&
          _introPiecesIdentity == currentIdentity) {
        return;
      }

      _introStartedForCurrentPieces = true;
      _introPiecesIdentity = currentIdentity;

      _introCoordinator?.start(
        _pieces,
        onChunkSpawnSound: () => widget.onChunkSpawnSound?.call(),
      );
    });
  }

  @override
  void didUpdateWidget(covariant PuzzleChunksLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final introTurnedOn =
        !oldWidget.introAnimationEnabled && widget.introAnimationEnabled;
    final piecesChanged = oldWidget.pieces != widget.pieces;

    if (oldWidget.pieces != widget.pieces) {
      _pieces = _clonePieces(widget.pieces);
      _rebuildOccupancy();
      if (_draggedPieceId == null) {
        _resetDragState();
      }
    } else if (oldWidget.boardRows != widget.boardRows ||
        oldWidget.boardCols != widget.boardCols ||
        oldWidget.canvasRows != widget.canvasRows ||
        oldWidget.canvasCols != widget.canvasCols) {
      _rebuildOccupancy();
    }

    if (introTurnedOn || (piecesChanged && widget.introAnimationEnabled)) {
      _introStartedForCurrentPieces = false;
      _maybeStartIntro(force: true);
    } else if (!widget.introAnimationEnabled && _introCoordinator?.isRunning == true) {
      _introCoordinator?.disposeTicker();
      _introStartedForCurrentPieces = false;
    }
  }

  List<PuzzlePiece> _clonePieces(List<PuzzlePiece> pieces) {
    return pieces
        .map(
          (piece) => PuzzlePiece(
            id: piece.id,
            chunkId: piece.chunkId,
            anchorRow: piece.anchorRow,
            anchorCol: piece.anchorCol,
            spawnAnchorRow: piece.spawnAnchorRow,
            spawnAnchorCol: piece.spawnAnchorCol,
            cells: piece.cells,
            isCompletedWordGroup: piece.isCompletedWordGroup,
            completedWordKey: piece.completedWordKey,
            completedAnswers: piece.completedAnswers,
          ),
        )
        .toList();
  }

  void _rebuildOccupancy() {
    _occupancy.rebuildFromPieces(
      _pieces,
      boardRows: widget.canvasRows,
      boardCols: widget.canvasCols,
    );
  }

  void _resetDragState() {
    _draggedPieceId = null;
    _liveDragTopLeft = null;
    _grabOffset = Offset.zero;
    _dragStartAnchorRow = null;
    _dragStartAnchorCol = null;
  }

  Offset _clampPieceAnchorTopLeft(PuzzlePiece piece, Offset topLeft) {
    final tileSize = widget.tileSize;
    final size = pieceGridSize(piece);
    final maxX = (widget.boardCols - size.width) * tileSize;
    final maxY = (widget.boardRows - size.height) * tileSize;

    return Offset(
      topLeft.dx.clamp(0.0, maxX),
      topLeft.dy.clamp(0.0, maxY),
    );
  }

  void _notifyPiecesChanged({
    required Set<BoardCellPosition> affectedCells,
    List<String> movedPieceIds = const [],
  }) {
    widget.onPiecesChanged(
      PiecesChangeEvent(
        pieces: _clonePieces(_pieces),
        affectedCells: affectedCells,
        movedPieceIds: movedPieceIds,
      ),
    );
  }

  void _returnPieceToOrigin(PuzzlePiece piece) {
    piece.anchorRow = piece.spawnAnchorRow;
    piece.anchorCol = piece.spawnAnchorCol;
  }

  void _snapPieceToAnchor(PuzzlePiece piece, BoardCellPosition anchor) {
    piece.anchorRow = anchor.row;
    piece.anchorCol = anchor.col;
  }

  void _logDropResult(PuzzlePiece piece, ChunkDropResult result) {
    if (!kDebugMode || !_kLogChunkDrops) {
      return;
    }

    final snapped = result.action == ChunkDropAction.snap;
    debugPrint('Chunk ${piece.id} release');
    debugPrint('  droppedTopLeft=${result.droppedTopLeft}');
    debugPrint('  center=${result.center}');
    debugPrint('  targetAnchor=${result.targetAnchor}');
    debugPrint('  overlapsBoard=${result.overlapsBoard}');
    debugPrint('  insideBoard=${result.insideBoard}');
    debugPrint('  occupied=${result.occupied}');
    debugPrint('  action=${snapped ? "snap" : "return"}');
  }

  void _onPanStart(PuzzlePiece piece, DragStartDetails details) {
    if (_isDragLocked && _draggedPieceId != piece.id) {
      return;
    }

    setState(() {
      _draggedPieceId = piece.id;
      _dragStartAnchorRow = piece.anchorRow;
      _dragStartAnchorCol = piece.anchorCol;
      _grabOffset = details.localPosition;
      _liveDragTopLeft = cellTopLeft(
        piece.anchorRow,
        piece.anchorCol,
        widget.tileSize,
      );
      if (isPieceOnBoard(piece, widget.canvasRows, widget.canvasCols)) {
        _occupancy.clearPiece(piece.id);
      }
    });
    widget.onDragStart?.call();
  }

  void _onPanUpdate(PuzzlePiece piece, DragUpdateDetails details) {
    if (_draggedPieceId == null ||
        _draggedPieceId != piece.id ||
        _liveDragTopLeft == null) {
      return;
    }

    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) {
      return;
    }

    final fingerInStack = stackBox.globalToLocal(details.globalPosition);

    setState(() {
      _liveDragTopLeft =
          _clampPieceAnchorTopLeft(piece, fingerInStack - _grabOffset);
    });
  }

  void _onPanEnd(PuzzlePiece piece) {
    if (_draggedPieceId == null ||
        _draggedPieceId != piece.id ||
        _liveDragTopLeft == null) {
      return;
    }

    widget.onDragEnd?.call();

    final droppedTopLeft = _liveDragTopLeft!;
    final result = evaluateChunkDrop(
      droppedTopLeft: droppedTopLeft,
      piece: piece,
      occupancy: _occupancy,
      boardRows: widget.boardRows,
      boardCols: widget.boardCols,
      tileSize: widget.tileSize,
    );

    _logDropResult(piece, result);

    final startRow = _dragStartAnchorRow ?? piece.spawnAnchorRow;
    final startCol = _dragStartAnchorCol ?? piece.spawnAnchorCol;

    setState(() {
      if (result.action == ChunkDropAction.snap && result.targetAnchor != null) {
        _snapPieceToAnchor(piece, result.targetAnchor!);
      } else {
        _returnPieceToOrigin(piece);
      }
      _resetDragState();
      _rebuildOccupancy();
    });

    logPiecePlacementResult(piece: piece, result: result);

    if (result.action != ChunkDropAction.snap) {
      return;
    }

    final affectedCells = getAffectedCellsForPiece(
      piece: piece,
      previousAnchorRow: startRow,
      previousAnchorCol: startCol,
    );

    _notifyPiecesChanged(
      affectedCells: affectedCells,
      movedPieceIds: [piece.id],
    );
  }

  ({double width, double height}) _pieceSize(PuzzlePiece piece) {
    final tileSize = widget.tileSize;
    final size = pieceGridSize(piece);
    return (width: size.width * tileSize, height: size.height * tileSize);
  }

  Widget _buildPieceContent({
    required PuzzlePiece piece,
    required bool isActive,
    required bool isHintHighlighted,
    required ({double width, double height}) pieceSize,
    double connectionSeamOpacity = 0,
    PuzzlePieceVisualMode visualMode = PuzzlePieceVisualMode.real,
    bool isDragging = false,
    bool? isCompleted,
  }) {
    final tileSize = widget.tileSize;
    final completed = isCompleted ?? piece.isCompletedWordGroup;

    return PuzzlePieceContent(
      piece: piece,
      tileSize: tileSize,
      pieceWidth: pieceSize.width,
      pieceHeight: pieceSize.height,
      visualMode: visualMode,
      isDragging: isDragging,
      isCompleted: completed,
      isHintHighlighted: isHintHighlighted,
      connectionSeamOpacity: connectionSeamOpacity,
    );
  }

  Widget _buildPiece(PuzzlePiece piece) {
    final isActive = piece.id == _draggedPieceId;
    final isHintHighlighted =
        widget.hintHighlightedPieceIds.contains(piece.id);
    final tileSize = widget.tileSize;
    final anchorTopLeft = cellTopLeft(
      piece.anchorRow,
      piece.anchorCol,
      tileSize,
    );
    final left = isActive
        ? (_liveDragTopLeft?.dx ?? anchorTopLeft.dx)
        : anchorTopLeft.dx;
    final top = isActive
        ? (_liveDragTopLeft?.dy ?? anchorTopLeft.dy)
        : anchorTopLeft.dy;
    final pieceSize = _pieceSize(piece);

    final introValues = _introCoordinator?.values[piece.id];
    final isIntroPiece =
        _isIntroActive && introValues != null && !introValues.isIntroFinished;

    Widget pieceContent;
    if (isIntroPiece) {
      pieceContent = Stack(
        clipBehavior: Clip.none,
        children: [
          if (introValues.showGhost)
            Opacity(
              opacity: introValues.ghostOpacity,
              child: Transform.scale(
                scale: introValues.ghostScale,
                child: _buildPieceContent(
                  piece: piece,
                  isActive: false,
                  isHintHighlighted: false,
                  pieceSize: pieceSize,
                  visualMode: PuzzlePieceVisualMode.ghost,
                ),
              ),
            ),
          Opacity(
            opacity: introValues.realOpacity,
            child: Transform.translate(
              offset: Offset(0, introValues.realOffsetY),
              child: Transform.scale(
                scale: introValues.realScale,
                child: _buildPieceContent(
                  piece: piece,
                  isActive: false,
                  isHintHighlighted: isHintHighlighted,
                  pieceSize: pieceSize,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      pieceContent = _buildPieceContent(
        piece: piece,
        isActive: isActive,
        isHintHighlighted: isHintHighlighted,
        pieceSize: pieceSize,
        isDragging: isActive,
      );
    }

    return Positioned(
      key: ValueKey(piece.id),
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: !widget.interactionEnabled ||
            _isIntroActive ||
            (_isDragLocked && !isActive),
        child: GestureDetector(
          behavior: piece.isCompletedWordGroup
              ? HitTestBehavior.deferToChild
              : HitTestBehavior.opaque,
          onPanStart: (details) => _onPanStart(piece, details),
          onPanUpdate: (details) => _onPanUpdate(piece, details),
          onPanEnd: (_) => _onPanEnd(piece),
          onPanCancel: () => _onPanEnd(piece),
          child: pieceContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draggedId = _draggedPieceId;
    final pieces = [..._pieces]
      ..sort((a, b) {
        if (a.id == draggedId) {
          return 1;
        }
        if (b.id == draggedId) {
          return -1;
        }
        return 0;
      });

    return AbsorbPointer(
      absorbing: !widget.interactionEnabled,
      child: SizedBox(
        width: widget.boardCols * widget.tileSize,
        height: widget.boardRows * widget.tileSize,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.hardEdge,
          children: [
            for (final piece in pieces) _buildPiece(piece),
          ],
        ),
      ),
    );
  }
}
