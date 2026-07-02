import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/grid_cell.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
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

  test('generateAllLayouts finds unique layouts for planets words', () {
    const words = ['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER'];
    final layouts = generator.generateAllLayouts(words);

    debugPrint('Planets layouts found: ${layouts.length}');
    for (final layout in layouts) {
      debugPrint('  signature: ${PuzzleLayout.signature(layout)}');
    }

    expect(layouts, isNotEmpty);

    final signatures = layouts.map(PuzzleLayout.signature).toSet();
    expect(signatures, hasLength(layouts.length));

    for (final layout in layouts) {
      expect(layout.minRow, 0);
      expect(layout.minCol, 0);
      expect(layout.placedWords, hasLength(words.length));
      expect(
        layout.placedWords.map((placed) => placed.word).toSet(),
        words.toSet(),
      );
      expect(
        _isOccupiedGridConnected(_occupiedCellsFromLayout(layout)),
        isTrue,
        reason: 'Layout must be connected: ${PuzzleLayout.signature(layout)}',
      );
    }
  });

  test('generateSingleLayout returns first layout from generateAllLayouts', () {
    const words = ['VENUS', 'NEPTUNE', 'MARS', 'SATURN', 'JUPITER'];
    final allLayouts = generator.generateAllLayouts(words);
    final singleLayout = generator.generateSingleLayout(words);

    expect(singleLayout, isNotNull);
    expect(
      PuzzleLayout.signature(singleLayout!),
      PuzzleLayout.signature(allLayouts.first),
    );
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

List<GridCell> _occupiedCellsFromLayout(PuzzleLayout layout) {
  final occupied = <String, String>{};

  for (final placed in layout.placedWords) {
    for (var index = 0; index < placed.word.length; index++) {
      final row = placed.direction == WordDirection.horizontal
          ? placed.row
          : placed.row + index;
      final col = placed.direction == WordDirection.horizontal
          ? placed.col + index
          : placed.col;
      occupied['$row,$col'] = placed.word[index];
    }
  }

  return occupied.entries
      .map(
        (entry) => GridCell(
          row: int.parse(entry.key.split(',')[0]),
          col: int.parse(entry.key.split(',')[1]),
          letter: entry.value,
        ),
      )
      .toList();
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
