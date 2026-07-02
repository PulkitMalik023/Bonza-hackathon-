import '../data/models/placed_word.dart';
import 'board_cell_position.dart';
import 'puzzle_piece.dart';

class PiecesChangeEvent {
  const PiecesChangeEvent({
    required this.pieces,
    required this.affectedCells,
  });

  final List<PuzzlePiece> pieces;
  final Set<BoardCellPosition> affectedCells;
}

bool isPieceAtSpawn(PuzzlePiece piece) {
  return piece.anchorRow == piece.spawnAnchorRow &&
      piece.anchorCol == piece.spawnAnchorCol;
}

Map<BoardCellPosition, String> buildBoardLetterMap(List<PuzzlePiece> pieces) {
  final board = <BoardCellPosition, String>{};

  for (final piece in pieces) {
    for (final cell in piece.cells) {
      final position = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );
      board[position] = cell.letter;
    }
  }

  return board;
}

Map<BoardCellPosition, String> buildPlayAreaLetterMap(List<PuzzlePiece> pieces) {
  final board = <BoardCellPosition, String>{};

  for (final piece in pieces) {
    if (isPieceAtSpawn(piece)) {
      continue;
    }

    for (final cell in piece.cells) {
      final position = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );
      board[position] = cell.letter;
    }
  }

  return board;
}

Set<BoardCellPosition> getAffectedCellsForPiece({
  required PuzzlePiece piece,
  required int previousAnchorRow,
  required int previousAnchorCol,
}) {
  final affected = <BoardCellPosition>{};
  affected.addAll(
    piece.getOccupiedCellsAt(previousAnchorRow, previousAnchorCol),
  );
  affected.addAll(piece.getOccupiedCells());
  return affected;
}

String wordKey(PlacedWord word, int index) =>
    'word_${index}_${word.word.toUpperCase()}';

String clusterKeyFromCells(Map<BoardCellPosition, String> cells) {
  final sorted = cells.keys.toList()
    ..sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.col.compareTo(b.col);
    });

  return 'cluster_${sorted.map((cell) => '${cell.row}_${cell.col}').join('_')}';
}
