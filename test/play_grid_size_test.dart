import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_definition.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/play_grid_size.dart';

PuzzleDefinition _definitionById(List<PuzzleDefinition> definitions, int id) {
  return definitions.firstWhere((definition) => definition.puzzleId == id);
}

PuzzleLayout _shapesLayout() {
  return PuzzleLayout.normalize([
    const PlacedWord(
      word: 'RECTANGLE',
      row: 4,
      col: 2,
      direction: WordDirection.horizontal,
    ),
    const PlacedWord(
      word: 'PENTAGON',
      row: 3,
      col: 3,
      direction: WordDirection.vertical,
    ),
    const PlacedWord(
      word: 'SQUARE',
      row: 7,
      col: 0,
      direction: WordDirection.horizontal,
    ),
    const PlacedWord(
      word: 'TRIANGLE',
      row: 0,
      col: 7,
      direction: WordDirection.vertical,
    ),
    const PlacedWord(
      word: 'CIRCLE',
      row: 0,
      col: 9,
      direction: WordDirection.vertical,
    ),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('computeMinimumPlayGridSize', () {
    test('Fruit Salad uses 16x12 when 6-letter words exceed 10-col floor', () {
      final layout = PuzzleLayout.normalize([
        const PlacedWord(
          word: 'BANANA',
          row: 2,
          col: 0,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'ORANGE',
          row: 0,
          col: 1,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'APPLE',
          row: 2,
          col: 3,
          direction: WordDirection.vertical,
        ),
      ]);

      final size = computeMinimumPlayGridSize(layout);

      expect(size.rows, BoardConstants.kPlayGridRows);
      expect(size.cols, 12);
    });

    test('Spectrum uses 16x12 for 6-letter vertical and horizontal words', () {
      final layout = PuzzleLayout.normalize([
        const PlacedWord(
          word: 'YELLOW',
          row: 1,
          col: 2,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'BLUE',
          row: 3,
          col: 1,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'ORANGE',
          row: 5,
          col: 2,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'INDIGO',
          row: 4,
          col: 5,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'GREEN',
          row: 3,
          col: 7,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'RED',
          row: 4,
          col: 8,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'VIOLET',
          row: 9,
          col: 3,
          direction: WordDirection.horizontal,
        ),
      ]);

      final size = computeMinimumPlayGridSize(layout);

      expect(size.rows, 16);
      expect(size.cols, 12);
    });

    test('Shapes uses 16x18 for 8-letter vertical and 9-letter horizontal', () {
      final size = computeMinimumPlayGridSize(_shapesLayout());

      expect(size.rows, 16);
      expect(size.cols, 18);
    });

    test('3 Little Pigs uses 16x12 for 6-letter vertical and horizontal', () {
      final layout = PuzzleLayout.normalize([
        const PlacedWord(
          word: 'BRICKS',
          row: 3,
          col: 0,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'STRAW',
          row: 1,
          col: 1,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'STICKS',
          row: 0,
          col: 3,
          direction: WordDirection.vertical,
        ),
      ]);

      final size = computeMinimumPlayGridSize(layout);

      expect(size.rows, 16);
      expect(size.cols, 12);
    });
  });

  group('computeMinimumPlayGridSize from puzzle_definitions.json', () {
    late List<PuzzleDefinition> definitions;

    setUpAll(() async {
      final jsonString = await rootBundle.loadString(
        'assets/data/puzzle_definitions.json',
      );
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      definitions = decoded
          .map(
            (entry) =>
                PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
    });

    test('Compass (id 2) stays at 16x10 floor', () {
      final layout = _definitionById(definitions, 2).layout.toPuzzleLayout();
      final size = computeMinimumPlayGridSize(layout);

      expect(size.rows, BoardConstants.kPlayGridRows);
      expect(size.cols, BoardConstants.kPlayGridCols);
    });

    test('Shapes (id 11) expands to 16x18', () {
      final layout = _definitionById(definitions, 11).layout.toPuzzleLayout();
      final size = computeMinimumPlayGridSize(layout);

      expect(size.rows, 16);
      expect(size.cols, 18);
    });
  });

  group('computePlayGridSizeForViewport', () {
    test('returns minimum when viewport is zero', () {
      final layout = _shapesLayout();
      final minimum = computeMinimumPlayGridSize(layout);

      expect(
        computePlayGridSizeForViewport(
          layout: layout,
          playableWidth: 0,
          playableHeight: 500,
        ),
        minimum,
      );
      expect(
        computePlayGridSizeForViewport(
          layout: layout,
          playableWidth: 390,
          playableHeight: 0,
        ),
        minimum,
      );
    });

    test('Eye of the... expands rows to fill tall phone viewport', () {
      final layout = PuzzleLayout.normalize([
        const PlacedWord(
          word: 'BEHOLDER',
          row: 3,
          col: 0,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'NEEDLE',
          row: 2,
          col: 1,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'STORM',
          row: 1,
          col: 3,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'TIGER',
          row: 0,
          col: 6,
          direction: WordDirection.vertical,
        ),
      ]);

      const playableWidth = 390.0;
      const playableHeight = 500.0;

      final minimum = computeMinimumPlayGridSize(layout);
      expect(minimum.rows, 16);
      expect(minimum.cols, 16);

      final size = computePlayGridSizeForViewport(
        layout: layout,
        playableWidth: playableWidth,
        playableHeight: playableHeight,
      );
      final tileSize = computePlayTileSize(
        gridSize: size,
        playableWidth: playableWidth,
        playableHeight: playableHeight,
      );

      expect(size.rows, greaterThan(minimum.rows));
      expect(size.cols, minimum.cols);
      expect(size.cols * tileSize, closeTo(playableWidth, 2.0));
      expect(playableHeight - size.rows * tileSize, lessThan(tileSize));
    });

    test('Shapes expands rows beyond minimum on tall viewport', () {
      const playableWidth = 390.0;
      const playableHeight = 500.0;

      final size = computePlayGridSizeForViewport(
        layout: _shapesLayout(),
        playableWidth: playableWidth,
        playableHeight: playableHeight,
      );

      expect(size.rows, greaterThan(16));
      expect(size.cols, 18);

      final tileSize = computePlayTileSize(
        gridSize: size,
        playableWidth: playableWidth,
        playableHeight: playableHeight,
      );
      expect(size.rows * tileSize, closeTo(playableHeight, 2.0));
      expect(size.cols * tileSize, closeTo(playableWidth, 2.0));
      expect(playableHeight - size.rows * tileSize, lessThan(tileSize));
    });

    test('Compass expands cols when viewport is taller than minimum grid', () {
      final layout = PuzzleLayout.normalize([
        const PlacedWord(
          word: 'NORTH',
          row: 1,
          col: 2,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'SOUTH',
          row: 0,
          col: 3,
          direction: WordDirection.vertical,
        ),
        const PlacedWord(
          word: 'WEST',
          row: 3,
          col: 0,
          direction: WordDirection.horizontal,
        ),
        const PlacedWord(
          word: 'EAST',
          row: 3,
          col: 1,
          direction: WordDirection.vertical,
        ),
      ]);

      const playableWidth = 390.0;
      const playableHeight = 500.0;

      final size = computePlayGridSizeForViewport(
        layout: layout,
        playableWidth: playableWidth,
        playableHeight: playableHeight,
      );

      expect(size.rows, 16);
      expect(size.cols, greaterThan(10));

      final tileSize = computePlayTileSize(
        gridSize: size,
        playableWidth: playableWidth,
        playableHeight: playableHeight,
      );
      expect(size.rows * tileSize, closeTo(playableHeight, 2.0));
      expect(playableWidth - size.cols * tileSize, lessThan(tileSize));
    });
  });
}
