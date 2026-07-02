import 'grid_cell.dart';
import 'word_placement.dart';

class GeneratedPuzzleLayout {
  const GeneratedPuzzleLayout({
    required this.puzzleId,
    required this.category,
    required this.words,
    required this.placements,
    required this.occupiedCells,
    required this.minRow,
    required this.maxRow,
    required this.minCol,
    required this.maxCol,
  });

  final String puzzleId;
  final String category;
  final List<String> words;
  final List<WordPlacement> placements;
  final List<GridCell> occupiedCells;
  final int minRow;
  final int maxRow;
  final int minCol;
  final int maxCol;
}
