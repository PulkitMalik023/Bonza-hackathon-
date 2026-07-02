class BoardCellPosition {
  const BoardCellPosition({
    required this.row,
    required this.col,
  });

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCellPosition && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}
