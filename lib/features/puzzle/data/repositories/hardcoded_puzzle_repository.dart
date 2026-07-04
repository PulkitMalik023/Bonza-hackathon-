import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/deconstructed_puzzle.dart';
import '../models/puzzle_definition.dart';
import '../models/puzzle_layout.dart';

class HardcodedPuzzleBundle {
  const HardcodedPuzzleBundle({
    required this.definition,
    required this.layout,
    required this.deconstructed,
  });

  final PuzzleDefinition definition;
  final PuzzleLayout layout;
  final DeconstructedPuzzle deconstructed;
}

class HardcodedPuzzleRepository {
  static const assetPath = 'assets/data/puzzle_definitions.json';

  List<PuzzleDefinition>? _cache;

  Future<List<PuzzleDefinition>> loadAllDefinitions() async {
    if (_cache != null) {
      return _cache!;
    }

    final jsonString = await rootBundle.loadString(assetPath);
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw const FormatException(
        'Expected puzzle_definitions.json root to be an array',
      );
    }

    _cache = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.puzzleId.compareTo(b.puzzleId));

    return _cache!;
  }

  Future<PuzzleDefinition?> getDefinitionById(int puzzleId) async {
    final definitions = await loadAllDefinitions();
    for (final definition in definitions) {
      if (definition.puzzleId == puzzleId) {
        return definition;
      }
    }
    return null;
  }

  Future<HardcodedPuzzleBundle?> loadBundle(int puzzleId) async {
    final definition = await getDefinitionById(puzzleId);
    if (definition == null) {
      return null;
    }

    final layout = definition.puzzleLayout;
    final deconstructed = definition.toDeconstructedPuzzle();

    return HardcodedPuzzleBundle(
      definition: definition,
      layout: layout,
      deconstructed: deconstructed,
    );
  }
}
