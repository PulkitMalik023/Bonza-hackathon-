import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/grid_layout.dart';
import '../../domain/piece_cell.dart';
import '../../domain/puzzle_piece.dart';
import 'puzzle_node_tile.dart';

class GridNodesLayer extends StatefulWidget {
  const GridNodesLayer({
    super.key,
    required this.tileSize,
    required this.boardSize,
  });

  final double tileSize;
  final Size boardSize;

  @override
  State<GridNodesLayer> createState() => _GridNodesLayerState();
}

class _GridNodesLayerState extends State<GridNodesLayer> {
  final GlobalKey _stackKey = GlobalKey();

  late GridLayout _gridLayout;
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
    _gridLayout = _buildGridLayout();
    _pieces = _initialPieces();
  }

  @override
  void didUpdateWidget(covariant GridNodesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.boardSize != widget.boardSize ||
        oldWidget.tileSize != widget.tileSize) {
      _gridLayout = _buildGridLayout();
      _pieces = _initialPieces();
      _resetDragState();
    }
  }

  GridLayout _buildGridLayout() {
    return GridLayout.fromBoardSize(
      boardSize: widget.boardSize,
      tileSize: widget.tileSize,
    );
  }

  List<PuzzlePiece> _initialPieces() {
    return [
      PuzzlePiece(
        id: 'piece1',
        anchorRow: 10,
        anchorCol: 2,
        cells: const [
          PieceCell(letter: 'R', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'K', rowOffset: 0, colOffset: 1),
        ],
      ),
      PuzzlePiece(
        id: 'piece2',
        anchorRow: 6,
        anchorCol: 0,
        cells: const [
          PieceCell(letter: 'B', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'F', rowOffset: 1, colOffset: 0),
        ],
      ),
      PuzzlePiece(
        id: 'piece3',
        anchorRow: 1,
        anchorCol: 2,
        cells: const [
          PieceCell(letter: 'I', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'N', rowOffset: 0, colOffset: 1),
        ],
      ),
      PuzzlePiece(
        id: 'piece4',
        anchorRow: 13,
        anchorCol: 4,
        cells: const [
          PieceCell(letter: 'V', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'C', rowOffset: 1, colOffset: 0),
        ],
      ),
      PuzzlePiece(
        id: 'piece5',
        anchorRow: 8,
        anchorCol: 7,
        cells: const [
          PieceCell(letter: 'L', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'M', rowOffset: 0, colOffset: 1),
        ],
      ),
    ];
  }

  bool canPlacePiece(
    PuzzlePiece movingPiece,
    int targetAnchorRow,
    int targetAnchorCol,
  ) {
    final targetCells =
        movingPiece.getOccupiedCellsAt(targetAnchorRow, targetAnchorCol);

    for (final cell in targetCells) {
      if (cell.row < 0 ||
          cell.row >= _gridLayout.rows ||
          cell.col < 0 ||
          cell.col >= _gridLayout.columns) {
        return false;
      }
    }

    for (final other in _pieces) {
      if (other.id == movingPiece.id) {
        continue;
      }
      for (final occupied in other.getOccupiedCells()) {
        for (final target in targetCells) {
          if (occupied == target) {
            return false;
          }
        }
      }
    }

    return true;
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
    final maxRowOffset =
        piece.cells.map((cell) => cell.rowOffset).reduce(max);
    final maxColOffset =
        piece.cells.map((cell) => cell.colOffset).reduce(max);
    final maxX = (_gridLayout.columns - 1 - maxColOffset) * tileSize;
    final maxY = (_gridLayout.rows - 1 - maxRowOffset) * tileSize;

    return Offset(
      topLeft.dx.clamp(0.0, maxX),
      topLeft.dy.clamp(0.0, maxY),
    );
  }

  void _onPanStart(PuzzlePiece piece, DragStartDetails details) {
    if (_isDragLocked && _draggedPieceId != piece.id) {
      return;
    }

    final tileSize = widget.tileSize;
    setState(() {
      _draggedPieceId = piece.id;
      _grabOffset = details.localPosition;
      _dragStartAnchorRow = piece.anchorRow;
      _dragStartAnchorCol = piece.anchorCol;
      _liveDragTopLeft = Offset(
        piece.anchorCol * tileSize,
        piece.anchorRow * tileSize,
      );
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

    final snapped = _gridLayout.snapCellFromTopLeft(_liveDragTopLeft!);
    final canPlace = canPlacePiece(piece, snapped.row, snapped.col);

    setState(() {
      if (canPlace) {
        piece.anchorRow = snapped.row;
        piece.anchorCol = snapped.col;
      } else {
        piece.anchorRow = _dragStartAnchorRow!;
        piece.anchorCol = _dragStartAnchorCol!;
      }
      _resetDragState();
    });
  }

  ({double width, double height}) _pieceSize(PuzzlePiece piece) {
    final tileSize = widget.tileSize;
    final maxRowOffset =
        piece.cells.map((cell) => cell.rowOffset).reduce(max);
    final maxColOffset =
        piece.cells.map((cell) => cell.colOffset).reduce(max);

    return (
      width: (maxColOffset + 1) * tileSize,
      height: (maxRowOffset + 1) * tileSize,
    );
  }

  Widget _buildPiece(PuzzlePiece piece) {
    final isActive = piece.id == _draggedPieceId;
    final tileSize = widget.tileSize;
    final left =
        isActive ? _liveDragTopLeft!.dx : piece.anchorCol * tileSize;
    final top = isActive ? _liveDragTopLeft!.dy : piece.anchorRow * tileSize;
    final pieceSize = _pieceSize(piece);

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
              ),
            ),
        ],
      ),
    );

    return Positioned(
      key: ValueKey(piece.id),
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: _isDragLocked && !isActive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
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

    return SizedBox.expand(
      child: Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          for (final piece in pieces) _buildPiece(piece),
        ],
      ),
    );
  }
}
