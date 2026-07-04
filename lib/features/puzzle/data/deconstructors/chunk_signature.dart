import '../../domain/board_cell_position.dart';
import '../models/puzzle_chunk.dart';

/// Canonical key for chunk shape + letter layout in local coordinates.
String signatureFromLocalCells(Map<BoardCellPosition, String> localCells) {
  final entries = localCells.entries.toList()
    ..sort((a, b) {
      final rowCompare = a.key.row.compareTo(b.key.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.key.col.compareTo(b.key.col);
    });

  return entries
      .map(
        (entry) =>
            '${entry.key.row},${entry.key.col}:${entry.value.toUpperCase()}',
      )
      .join('|');
}

String signatureFromChunk(PuzzleChunk chunk) {
  return signatureFromLocalCells(chunk.localCells);
}

String signatureFromCellSet({
  required Set<BoardCellPosition> chunkCells,
  required Map<BoardCellPosition, String> letterMap,
}) {
  var minRow = chunkCells.first.row;
  var minCol = chunkCells.first.col;

  for (final cell in chunkCells) {
    minRow = minRow < cell.row ? minRow : cell.row;
    minCol = minCol < cell.col ? minCol : cell.col;
  }

  final localCells = <BoardCellPosition, String>{};
  for (final cell in chunkCells) {
    localCells[BoardCellPosition(
      row: cell.row - minRow,
      col: cell.col - minCol,
    )] = letterMap[cell]!.toUpperCase();
  }

  return signatureFromLocalCells(localCells);
}
