import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_definition.dart';
import 'package:jam_pro/features/puzzle/data/repositories/puzzle_repository.dart';
import 'package:jam_pro/features/puzzle/data/validators/puzzle_definition_validator.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<PuzzleDefinition> definitions;
  const validator = PuzzleDefinitionValidator();

  setUpAll(() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/puzzle_definitions.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    definitions = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  });

  test('loads one hardcoded definition per enabled puzzle', () async {
    final repository = PuzzleRepository();
    final enabled = await repository.loadPuzzles();

    expect(definitions, hasLength(enabled.length));
    expect(
      definitions.map((definition) => definition.puzzleId).toSet(),
      enabled.map((puzzle) => puzzle.id).toSet(),
    );
  });

  test('every hardcoded definition passes validation', () {
    final failures = <String>[];

    for (final definition in definitions) {
      final result = validator.validate(definition);
      if (!result.isValid) {
        failures.add('Puzzle ${definition.puzzleId}: ${result.reason}');
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('chunk unions match layout occupied cells', () {
    for (final definition in definitions) {
      final layout = definition.puzzleLayout;
      final deconstructed = definition.toDeconstructedPuzzle();

      final assigned = <String>{};
      for (final chunk in deconstructed.chunks) {
        for (final cell in chunk.solvedCells.keys) {
          expect(
            assigned.add('${cell.row},${cell.col}'),
            isTrue,
            reason: 'Duplicate cell in puzzle ${definition.puzzleId}',
          );
        }
      }

      expect(assigned.length, layout.occupiedCells.length);
      for (final chunk in deconstructed.chunks) {
        expect(
          PuzzleDeconstructor.isConnectedCellSet(
            chunk.solvedCells.keys.toSet(),
          ),
          isTrue,
          reason: 'Chunk ${chunk.id} disconnected in ${definition.puzzleId}',
        );
      }
    }
  });

  test('fruit salad puzzle uses expected hardcoded grid', () {
    final fruitSalad = definitions.firstWhere(
      (definition) => definition.puzzleId == 1,
    );

    expect(
      fruitSalad.layout.placements.map((placement) => placement.word).toSet(),
      {'BANANA', 'ORANGE', 'APPLE'},
    );
    expect(fruitSalad.chunks.length, 4);
  });
}
