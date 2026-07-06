import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_definition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Shapes hardcoded chunks match screenshot partition', () async {
    final jsonString = await rootBundle.loadString(
      'assets/data/puzzle_definitions.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final definition = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .firstWhere((entry) => entry.puzzleId == 11);

    expect(definition.chunks.length, 10);
    expect(definition.chunks[5].cells.length, 5);
    expect(definition.chunks[8].cells.length, 4);
    expect(
      definition.chunks[8].cells.any(
        (cell) => cell.row == 4 && cell.col == 6 && cell.letter == 'A',
      ),
      isTrue,
    );
    expect(
      definition.chunks[5].cells.any(
        (cell) => cell.row == 4 && cell.col == 6,
      ),
      isFalse,
    );
  });
}
