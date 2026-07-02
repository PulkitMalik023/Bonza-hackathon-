import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/grid_layout.dart';
import '../../domain/grid_node.dart';
import 'puzzle_node_tile.dart';

class GridNodesLayer extends StatefulWidget {
  const GridNodesLayer({
    super.key,
    required this.tileSize,
    required this.boardSize,
    this.nodeCount = 10,
  });

  final double tileSize;
  final Size boardSize;
  final int nodeCount;

  @override
  State<GridNodesLayer> createState() => _GridNodesLayerState();
}

class _GridNodesLayerState extends State<GridNodesLayer> {
  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final GlobalKey _stackKey = GlobalKey();

  late GridLayout _gridLayout;
  late List<GridNode> _nodes;
  String? _draggedNodeId;
  Offset? _liveDragTopLeft;
  Offset _grabOffset = Offset.zero;
  int? _dragStartRow;
  int? _dragStartCol;

  bool get _isDragLocked => _draggedNodeId != null;

  @override
  void initState() {
    super.initState();
    _gridLayout = _buildGridLayout();
    _nodes = _generateNodes();
  }

  @override
  void didUpdateWidget(covariant GridNodesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.boardSize != widget.boardSize ||
        oldWidget.nodeCount != widget.nodeCount ||
        oldWidget.tileSize != widget.tileSize) {
      _gridLayout = _buildGridLayout();
      _nodes = _generateNodes();
      _resetDragState();
    }
  }

  GridLayout _buildGridLayout() {
    return GridLayout.fromBoardSize(
      boardSize: widget.boardSize,
      tileSize: widget.tileSize,
    );
  }

  List<GridNode> _generateNodes() {
    final random = Random();
    final occupiedCells = <String>{};
    final nodes = <GridNode>[];

    final letters = List<String>.from(_letters.split(''))..shuffle(random);

    while (nodes.length < widget.nodeCount) {
      final row = random.nextInt(_gridLayout.rows);
      final col = random.nextInt(_gridLayout.columns);
      final key = '$row,$col';

      if (occupiedCells.contains(key)) {
        continue;
      }

      occupiedCells.add(key);
      nodes.add(
        GridNode(
          id: 'node-${nodes.length}',
          character: letters[nodes.length],
          row: row,
          col: col,
        ),
      );
    }

    return nodes;
  }

  bool _isCellOccupied(int row, int col, {required String ignoreTileId}) {
    for (final other in _nodes) {
      if (other.id == ignoreTileId) {
        continue;
      }
      if (other.row == row && other.col == col) {
        return true;
      }
    }
    return false;
  }

  void _resetDragState() {
    _draggedNodeId = null;
    _liveDragTopLeft = null;
    _grabOffset = Offset.zero;
    _dragStartRow = null;
    _dragStartCol = null;
  }

  Offset _clampTopLeft(Offset topLeft) {
    final tileSize = widget.tileSize;
    final maxX = (_gridLayout.columns - 1) * tileSize;
    final maxY = (_gridLayout.rows - 1) * tileSize;

    return Offset(
      topLeft.dx.clamp(0.0, maxX),
      topLeft.dy.clamp(0.0, maxY),
    );
  }

  void _onPanStart(GridNode node, DragStartDetails details) {
    if (_isDragLocked && _draggedNodeId != node.id) {
      return;
    }

    final tileSize = widget.tileSize;
    setState(() {
      _draggedNodeId = node.id;
      _grabOffset = details.localPosition;
      _dragStartRow = node.row;
      _dragStartCol = node.col;
      _liveDragTopLeft = Offset(
        node.col * tileSize,
        node.row * tileSize,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNodeId == null || _liveDragTopLeft == null) {
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

  void _onPanEnd(GridNode node) {
    if (_draggedNodeId == null ||
        _draggedNodeId != node.id ||
        _liveDragTopLeft == null) {
      return;
    }

    final snapped = _gridLayout.snapCellFromTopLeft(_liveDragTopLeft!);
    final isBlocked = _isCellOccupied(
      snapped.row,
      snapped.col,
      ignoreTileId: node.id,
    );

    setState(() {
      if (!isBlocked) {
        node.row = snapped.row;
        node.col = snapped.col;
      } else {
        node.row = _dragStartRow!;
        node.col = _dragStartCol!;
      }
      _resetDragState();
    });
  }

  Widget _buildNode(GridNode node) {
    final isActive = node.id == _draggedNodeId;
    final tileSize = widget.tileSize;
    final left = isActive ? _liveDragTopLeft!.dx : node.col * tileSize;
    final top = isActive ? _liveDragTopLeft!.dy : node.row * tileSize;

    return Positioned(
      key: ValueKey(node.id),
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: _isDragLocked && !isActive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onPanStart(node, details),
          onPanUpdate: _onPanUpdate,
          onPanEnd: (_) => _onPanEnd(node),
          onPanCancel: () => _onPanEnd(node),
          child: PuzzleNodeTile(
            character: node.character,
            tileSize: tileSize,
            isDragging: isActive,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draggedId = _draggedNodeId;
    final nodes = [..._nodes]
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
          for (final node in nodes) _buildNode(node),
        ],
      ),
    );
  }
}
