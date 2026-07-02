import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/puzzle_definition.dart';

class PuzzleContentLoader {
  static const assetPath = 'assets/content/puzzles.json';

  Future<List<PuzzleDefinition>> loadPuzzles() async {
    final jsonString = await rootBundle.loadString(assetPath);

    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected puzzles.json root to be an object');
    }

    final puzzlesJson = decoded['puzzles'];
    if (puzzlesJson is! List) {
      throw const FormatException('Expected "puzzles" to be a list');
    }

    return puzzlesJson
        .map((entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}
