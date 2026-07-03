class PuzzleTileEdgeMask {
  const PuzzleTileEdgeMask({
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.left = true,
  });

  static const all = PuzzleTileEdgeMask();

  final bool top;
  final bool right;
  final bool bottom;
  final bool left;
}

typedef CellOffset = (int row, int col);

Set<CellOffset> occupiedOffsetsFromCells({
  required Iterable<({int rowOffset, int colOffset})> cells,
}) {
  return {
    for (final cell in cells) (cell.rowOffset, cell.colOffset),
  };
}

PuzzleTileEdgeMask edgeMaskForCell({
  required int rowOffset,
  required int colOffset,
  required Set<CellOffset> occupiedOffsets,
}) {
  final hasTop = occupiedOffsets.contains((rowOffset - 1, colOffset));
  final hasRight = occupiedOffsets.contains((rowOffset, colOffset + 1));
  final hasBottom = occupiedOffsets.contains((rowOffset + 1, colOffset));
  final hasLeft = occupiedOffsets.contains((rowOffset, colOffset - 1));

  return PuzzleTileEdgeMask(
    top: !hasTop,
    right: !hasRight,
    bottom: !hasBottom,
    left: !hasLeft,
  );
}
