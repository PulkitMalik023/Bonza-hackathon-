import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/grid_cell.dart';
import 'package:jam_pro/features/puzzle/data/repositories/puzzle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PuzzleRepository repository;
  late PuzzleLayoutGenerator generator;

  setUp(() {
    repository = PuzzleRepository();
    generator = PuzzleLayoutGenerator();
  });

  test('loads 50 puzzles from JSON', () async {
    final puzzles = await repository.loadPuzzles(enabledOnly: false);

    expect(puzzles, hasLength(50));
    expect(puzzles.first.id, 1);
    expect(puzzles.last.id, 50);
    expect(puzzles.first.category, 'Directions');
    expect(puzzles.first.words, ['NORTH', 'SOUTH', 'EAST', 'WEST']);
  });

  test('loads only enabled puzzles for home screen', () async {
    final puzzles = await repository.loadPuzzles();

    expect(puzzles, hasLength(27));
    for (final puzzle in puzzles) {
      expect(puzzle.enabled, isTrue);
    }
  });

  test('generates layout for puzzle id 1 and prints debug output', () async {
    final puzzle = await repository.getPuzzleById(1);
    expect(puzzle, isNotNull);

    final layout = generator.generate(puzzle!);

    debugPrint('--- puzzle 1 layout ---');
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

    expect(layout.puzzleId, '1');
    expect(layout.placements, hasLength(4));
    expect(_isOccupiedGridConnected(layout.occupiedCells), isTrue);
  });

  test('generates connected layout for all enabled puzzles', () async {
    final puzzles = await repository.loadPuzzles();
    final failures = <int>[];

    for (final puzzle in puzzles) {
      try {
        final layout = generator.generate(puzzle);

        expect(layout.puzzleId, puzzle.id.toString());
        expect(layout.placements, hasLength(puzzle.words.length));
        expect(
          layout.placements.map((placement) => placement.word).toSet(),
          puzzle.words.map((word) => word.toUpperCase()).toSet(),
        );
        expect(_isOccupiedGridConnected(layout.occupiedCells), isTrue,
            reason: 'Occupied cells must be connected for puzzle ${puzzle.id}');
      } catch (error) {
        failures.add(puzzle.id);
        debugPrint('[BatchValidation] Puzzle ${puzzle.id} failed: $error');
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'These enabled puzzles failed generation: $failures',
    );
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
