import '../../domain/board_cell_position.dart';

class PuzzleChunk {
  const PuzzleChunk({
    required this.id,
    required this.solvedCells,
    required this.localCells,
    required this.solvedMinRow,
    required this.solvedMinCol,
    required this.solvedMaxRow,
    required this.solvedMaxCol,
    required this.width,
    required this.height,
  });

  final String id;
  final Map<BoardCellPosition, String> solvedCells;
  final Map<BoardCellPosition, String> localCells;
  final int solvedMinRow;
  final int solvedMinCol;
  final int solvedMaxRow;
  final int solvedMaxCol;
  final int width;
  final int height;
}
