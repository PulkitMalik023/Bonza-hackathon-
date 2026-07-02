import 'grid_cell.dart';
import 'placed_word.dart';
import 'puzzle_content.dart';
import 'puzzle_layout.dart';

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
  final List<PlacedWord> placements;
  final List<GridCell> occupiedCells;
  final int minRow;
  final int maxRow;
  final int minCol;
  final int maxCol;

  factory GeneratedPuzzleLayout.fromPuzzleContent(
    PuzzleContent content,
    PuzzleLayout layout,
  ) {
    final sortedWords = content.words.map((word) => word.toUpperCase()).toList()
      ..sort((a, b) {
        final lengthCompare = b.length.compareTo(a.length);
        if (lengthCompare != 0) {
          return lengthCompare;
        }
        return a.compareTo(b);
      });

    return GeneratedPuzzleLayout(
      puzzleId: content.id.toString(),
      category: content.category,
      words: sortedWords,
      placements: layout.placedWords,
      occupiedCells: PuzzleLayout.buildOccupiedCells(layout.placedWords),
      minRow: layout.minRow,
      maxRow: layout.maxRow,
      minCol: layout.minCol,
      maxCol: layout.maxCol,
    );
  }
}
