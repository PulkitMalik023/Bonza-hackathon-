import 'dart:math';
import 'dart:ui';

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
import 'puzzle_node_tile.dart';

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
  });

  final int boardRows;
  final int boardCols;
  final int canvasRows;
  final int canvasCols;
  final List<PuzzlePiece> pieces;
  final ValueChanged<PiecesChangeEvent> onPiecesChanged;
  final double tileSize;
  final bool interactionEnabled;

  @override
  State<PuzzleChunksLayer> createState() => _PuzzleChunksLayerState();
}

class _PuzzleChunksLayerState extends State<PuzzleChunksLayer> {
  final GlobalKey _stackKey = GlobalKey();
  final BoardOccupancy _occupancy = BoardOccupancy();
  final Set<String> _animatedCompletedGroupIds = {};

  late List<PuzzlePiece> _pieces;
  String? _draggedPieceId;
  Offset? _liveDragTopLeft;
  Offset _grabOffset = Offset.zero;
  int? _dragStartAnchorRow;
  int? _dragStartAnchorCol;

  bool get _isDragLocked => _draggedPieceId != null;

  @override
  void initState() {
    super.initState();
    _pieces = _clonePieces(widget.pieces);
    _rebuildOccupancy();
  }

  @override
  void didUpdateWidget(covariant PuzzleChunksLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pieces != widget.pieces) {
      _trackNewCompletedGroups(oldWidget.pieces, widget.pieces);
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

  void _trackNewCompletedGroups(
    List<PuzzlePiece> previousPieces,
    List<PuzzlePiece> nextPieces,
  ) {
    final previousGroupIds = previousPieces
        .where((piece) => piece.isCompletedWordGroup)
        .map((piece) => piece.id)
        .toSet();

    for (final piece in nextPieces) {
      if (piece.isCompletedWordGroup &&
          !previousGroupIds.contains(piece.id)) {
        _animatedCompletedGroupIds.add(piece.id);
      }
    }
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
    final maxX = (widget.canvasCols - size.width) * tileSize;
    final maxY = (widget.canvasRows - size.height) * tileSize;

    return Offset(
      topLeft.dx.clamp(0.0, maxX),
      topLeft.dy.clamp(0.0, maxY),
    );
  }

  void _notifyPiecesChanged({required Set<BoardCellPosition> affectedCells}) {
    widget.onPiecesChanged(
      PiecesChangeEvent(
        pieces: _clonePieces(_pieces),
        affectedCells: affectedCells,
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

    final droppedTopLeft = _liveDragTopLeft!;
    final result = evaluateChunkDrop(
      droppedTopLeft: droppedTopLeft,
      piece: piece,
      occupancy: _occupancy,
      boardRows: widget.boardRows,
      boardCols: widget.boardCols,
      tileSize: widget.tileSize,
      canvasRows: widget.canvasRows,
      canvasCols: widget.canvasCols,
    );

    _logDropResult(piece, result);
    logPiecePlacementResult(piece: piece, result: result);

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

    final affectedCells = getAffectedCellsForPiece(
      piece: piece,
      previousAnchorRow: startRow,
      previousAnchorCol: startCol,
    );

    _notifyPiecesChanged(affectedCells: affectedCells);
  }

  ({double width, double height}) _pieceSize(PuzzlePiece piece) {
    final tileSize = widget.tileSize;
    final size = pieceGridSize(piece);
    return (width: size.width * tileSize, height: size.height * tileSize);
  }

  Widget _buildPiece(PuzzlePiece piece) {
    final isActive = piece.id == _draggedPieceId;
    final tileSize = widget.tileSize;
    final left = isActive
        ? (_liveDragTopLeft?.dx ?? cellTopLeft(piece.anchorRow, piece.anchorCol, tileSize).dx)
        : cellTopLeft(piece.anchorRow, piece.anchorCol, tileSize).dx;
    final top = isActive
        ? (_liveDragTopLeft?.dy ?? cellTopLeft(piece.anchorRow, piece.anchorCol, tileSize).dy)
        : cellTopLeft(piece.anchorRow, piece.anchorCol, tileSize).dy;
    final pieceSize = _pieceSize(piece);
    final shouldPulseCompletedGroup =
        piece.isCompletedWordGroup && _animatedCompletedGroupIds.contains(piece.id);

    final pieceContent = SizedBox(
      width: pieceSize.width,
      height: pieceSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in piece.cells)
            Positioned(
              left: cell.colOffset * tileSize,
              top: cell.rowOffset * tileSize,
              child: PuzzleNodeTile(
                character: cell.letter,
                tileSize: tileSize,
                isDragging: isActive,
                showBorder: isActive || !piece.isCompletedWordGroup,
              ),
            ),
        ],
      ),
    );

    final animatedContent = shouldPulseCompletedGroup
        ? TweenAnimationBuilder<double>(
            key: ValueKey('completed_pulse_${piece.id}'),
            tween: Tween<double>(begin: 1, end: 1.05),
            duration: const Duration(milliseconds: 125),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            onEnd: () {
              if (!mounted) {
                return;
              }
              setState(() {
                _animatedCompletedGroupIds.remove(piece.id);
              });
            },
            child: pieceContent,
          )
        : pieceContent;

    return Positioned(
      key: ValueKey(piece.id),
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: !widget.interactionEnabled || (_isDragLocked && !isActive),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onPanStart(piece, details),
          onPanUpdate: (details) => _onPanUpdate(piece, details),
          onPanEnd: (_) => _onPanEnd(piece),
          onPanCancel: () => _onPanEnd(piece),
          child: animatedContent,
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
        width: widget.canvasCols * widget.tileSize,
        height: widget.canvasRows * widget.tileSize,
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
