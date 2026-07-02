import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/grid_cell.dart';
import 'package:jam_pro/features/puzzle/data/sources/puzzle_content_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PuzzleContentLoader loader;
  late PuzzleLayoutGenerator generator;

  setUp(() {
    loader = PuzzleContentLoader();
    generator = PuzzleLayoutGenerator();
  });

  test('loads puzzles from JSON', () async {
    final puzzles = await loader.loadPuzzles();

    expect(puzzles, hasLength(5));
    expect(puzzles.first.id, 'puzzle_001');
    expect(puzzles.first.category, 'Directions');
    expect(puzzles.first.words, ['NORTH', 'SOUTH', 'EAST', 'WEST']);
  });

  test('generates layout for puzzle_001 and prints debug output', () async {
    final puzzles = await loader.loadPuzzles();
    final puzzle = puzzles.firstWhere((entry) => entry.id == 'puzzle_001');

    final layout = generator.generate(puzzle);

    debugPrint('--- puzzle_001 layout ---');
    debugPrint('Category: ${layout.category}');
    debugPrint('Words: ${layout.words}');
    debugPrint('Placements:');
    for (final placement in layout.placements) {
      debugPrint('  $placement');
    }
    debugPrint(
      'Bounds: rows ${layout.minRow}..${layout.maxRow}, '
      'cols ${layout.minCol}..${layout.maxCol}',
    );
    debugPrint('Occupied cells (${layout.occupiedCells.length}):');
    for (final cell in layout.occupiedCells) {
      debugPrint('  $cell');
    }

    expect(layout.puzzleId, 'puzzle_001');
    expect(layout.placements, hasLength(4));
    expect(layout.placements.map((placement) => placement.word).toSet(), {
      'NORTH',
      'SOUTH',
      'EAST',
      'WEST',
    });
    expect(layout.occupiedCells, isNotEmpty);
    expect(_isOccupiedGridConnected(layout.occupiedCells), isTrue);
  });

  test('generates connected layout for all 5 puzzles', () async {
    final puzzles = await loader.loadPuzzles();

    for (final puzzle in puzzles) {
      final layout = generator.generate(puzzle);

      expect(layout.puzzleId, puzzle.id);
      expect(layout.placements, hasLength(puzzle.words.length));
      expect(
        layout.placements.map((placement) => placement.word).toSet(),
        puzzle.words.map((word) => word.toUpperCase()).toSet(),
      );

      final uniqueCellCount = layout.occupiedCells.map((cell) => (cell.row, cell.col)).toSet().length;
      expect(uniqueCellCount, layout.occupiedCells.length);

      final totalLetters =
          puzzle.words.fold<int>(0, (sum, word) => sum + word.length);
      expect(layout.occupiedCells.length, lessThanOrEqualTo(totalLetters));

      expect(_isOccupiedGridConnected(layout.occupiedCells), isTrue,
          reason: 'Occupied cells must form one connected component for ${puzzle.id}');
    }
  });
}

bool _isOccupiedGridConnected(List<GridCell> cells) {
  if (cells.length <= 1) {
    return true;
  }

  final cellKeys = cells.map((cell) => '${cell.row},${cell.col}').toSet();
  final startKey = cellKeys.first;
  final visited = <String>{startKey};
  final queue = <String>[startKey];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final parts = current.split(',');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    for (final neighbor in [
      '${row - 1},$col',
      '${row + 1},$col',
      '$row,${col - 1}',
      '$row,${col + 1}',
    ]) {
      if (cellKeys.contains(neighbor) && visited.add(neighbor)) {
        queue.add(neighbor);
      }
    }
  }

  return visited.length == cellKeys.length;
}
