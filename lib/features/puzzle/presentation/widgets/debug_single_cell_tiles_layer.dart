import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/board_cell_position.dart';
import '../../domain/board_occupancy.dart';
import '../../domain/debug_draggable_tile.dart';
import '../../domain/debug_tile_drop_evaluator.dart';
import 'puzzle_node_tile.dart';

const _kLogDebugDrops = true;

class DebugSingleCellTilesLayer extends StatefulWidget {
  const DebugSingleCellTilesLayer({
    super.key,
    required this.boardRows,
    required this.boardCols,
    required this.canvasRows,
    required this.canvasCols,
    required this.tiles,
    required this.onTilesChanged,
    required this.tileSize,
  });

  final int boardRows;
  final int boardCols;
  final int canvasRows;
  final int canvasCols;
  final List<DebugDraggableTile> tiles;
  final ValueChanged<List<DebugDraggableTile>> onTilesChanged;
  final double tileSize;

  @override
  State<DebugSingleCellTilesLayer> createState() =>
      _DebugSingleCellTilesLayerState();
}

class _DebugSingleCellTilesLayerState extends State<DebugSingleCellTilesLayer> {
  final GlobalKey _stackKey = GlobalKey();
  final BoardOccupancy _occupancy = BoardOccupancy();

  late List<DebugDraggableTile> _tiles;
  String? _draggedTileId;
  Offset? _liveDragTopLeft;
  Offset _grabOffset = Offset.zero;
  Offset? _dragStartPosition;

  bool get _isDragLocked => _draggedTileId != null;

  @override
  void initState() {
    super.initState();
    _tiles = _cloneTiles(widget.tiles);
    _rebuildOccupancy();
  }

  @override
  void didUpdateWidget(covariant DebugSingleCellTilesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tiles != widget.tiles) {
      _tiles = _cloneTiles(widget.tiles);
      _rebuildOccupancy();
      if (_draggedTileId == null) {
        _resetDragState();
      }
    }
  }

  List<DebugDraggableTile> _cloneTiles(List<DebugDraggableTile> tiles) {
    return tiles
        .map(
          (tile) => DebugDraggableTile(
            id: tile.id,
            position: tile.position,
            originalPosition: tile.originalPosition,
            label: tile.label,
            snappedRow: tile.snappedRow,
            snappedCol: tile.snappedCol,
          ),
        )
        .toList();
  }

  void _rebuildOccupancy() {
    _occupancy.rebuildFromTiles(
      _tiles.map(
        (tile) => (id: tile.id, row: tile.snappedRow, col: tile.snappedCol),
      ),
    );
  }

  void _resetDragState() {
    _draggedTileId = null;
    _liveDragTopLeft = null;
    _grabOffset = Offset.zero;
    _dragStartPosition = null;
  }

  Offset _clampTopLeft(Offset topLeft) {
    final tileSize = widget.tileSize;
    final maxX = (widget.canvasCols - 1) * tileSize;
    final maxY = (widget.canvasRows - 1) * tileSize;

    return Offset(
      topLeft.dx.clamp(0.0, maxX),
      topLeft.dy.clamp(0.0, maxY),
    );
  }

  void _notifyTilesChanged() {
    widget.onTilesChanged(_cloneTiles(_tiles));
  }

  void _returnTileToOrigin(DebugDraggableTile tile) {
    tile.position = tile.originalPosition;
    tile.snappedRow = null;
    tile.snappedCol = null;
  }

  void _snapTileToCell(DebugDraggableTile tile, BoardCellPosition cell) {
    tile.position = snapTopLeftForCell(cell, widget.tileSize);
    tile.snappedRow = cell.row;
    tile.snappedCol = cell.col;
  }

  void _logDropResult(
    DebugDraggableTile tile,
    Offset droppedTopLeft,
    DebugTileDropResult result,
  ) {
    if (!kDebugMode || !_kLogDebugDrops) {
      return;
    }

    final snapped = result.action == DebugTileDropAction.snap;
    debugPrint('Tile ${tile.id} release');
    debugPrint('  droppedTopLeft=$droppedTopLeft');
    debugPrint('  center=${result.center}');
    debugPrint('  targetCell=${result.targetCell}');
    debugPrint('  overlapsBoard=${result.overlapsBoard}');
    debugPrint('  insideBoard=${result.insideBoard}');
    debugPrint('  occupied=${result.occupied}');
    debugPrint('  action=${snapped ? "snap" : "return"}');
  }

  void _onPanStart(DebugDraggableTile tile, DragStartDetails details) {
    if (_isDragLocked && _draggedTileId != tile.id) {
      return;
    }

    setState(() {
      _draggedTileId = tile.id;
      _grabOffset = details.localPosition;
      _dragStartPosition = tile.position;
      _liveDragTopLeft = tile.position;
      _occupancy.clearTile(tile.id);
      tile.snappedRow = null;
      tile.snappedCol = null;
    });
  }

  void _onPanUpdate(DebugDraggableTile tile, DragUpdateDetails details) {
    if (_draggedTileId == null ||
        _draggedTileId != tile.id ||
        _liveDragTopLeft == null) {
      return;
    }

    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) {
      return;
    }

    final fingerInStack = stackBox.globalToLocal(details.globalPosition);

    setState(() {
      _liveDragTopLeft = _clampTopLeft(fingerInStack - _grabOffset);
    });
  }

  void _onPanEnd(DebugDraggableTile tile) {
    if (_draggedTileId == null ||
        _draggedTileId != tile.id ||
        _liveDragTopLeft == null ||
        _dragStartPosition == null) {
      return;
    }

    final droppedTopLeft = _liveDragTopLeft!;
    final result = evaluateDrop(
      droppedTopLeft: droppedTopLeft,
      tileId: tile.id,
      occupancy: _occupancy,
      boardRows: widget.boardRows,
      boardCols: widget.boardCols,
      tileSize: widget.tileSize,
    );

    _logDropResult(tile, droppedTopLeft, result);

    setState(() {
      if (result.action == DebugTileDropAction.snap &&
          result.targetCell != null) {
        _snapTileToCell(tile, result.targetCell!);
      } else {
        _returnTileToOrigin(tile);
      }
      _resetDragState();
      _rebuildOccupancy();
    });

    _notifyTilesChanged();
  }

  Widget _buildTile(DebugDraggableTile tile) {
    final isActive = tile.id == _draggedTileId;
    final left =
        isActive ? (_liveDragTopLeft?.dx ?? tile.position.dx) : tile.position.dx;
    final top =
        isActive ? (_liveDragTopLeft?.dy ?? tile.position.dy) : tile.position.dy;

    return Positioned(
      key: ValueKey(tile.id),
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: _isDragLocked && !isActive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onPanStart(tile, details),
          onPanUpdate: (details) => _onPanUpdate(tile, details),
          onPanEnd: (_) => _onPanEnd(tile),
          onPanCancel: () => _onPanEnd(tile),
          child: PuzzleNodeTile(
            character: tile.label,
            tileSize: widget.tileSize,
            isDragging: isActive,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draggedId = _draggedTileId;
    final tiles = [..._tiles]
      ..sort((a, b) {
        if (a.id == draggedId) {
          return 1;
        }
        if (b.id == draggedId) {
          return -1;
        }
        return 0;
      });

    return SizedBox(
      width: widget.canvasCols * widget.tileSize,
      height: widget.canvasRows * widget.tileSize,
      child: Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          for (final tile in tiles) _buildTile(tile),
        ],
      ),
    );
  }
}
