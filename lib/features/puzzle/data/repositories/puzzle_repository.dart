import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/puzzle_content.dart';

class PuzzleRepository {
  static const assetPath = 'assets/data/puzzles.json';

  Future<List<PuzzleContent>> loadPuzzles({bool enabledOnly = true}) async {
    final puzzles = await _loadAllPuzzles();
    if (!enabledOnly) {
      return puzzles;
    }
    return puzzles.where((puzzle) => puzzle.enabled).toList();
  }

  Future<PuzzleContent?> getPuzzleById(int id) async {
    final puzzles = await _loadAllPuzzles();
    for (final puzzle in puzzles) {
      if (puzzle.id == id) {
        return puzzle;
      }
    }
    return null;
  }

  Future<int?> getNextEnabledPuzzleId(int currentId) async {
    final puzzles = await loadPuzzles();
    final currentIndex = puzzles.indexWhere((puzzle) => puzzle.id == currentId);
    if (currentIndex < 0 || currentIndex >= puzzles.length - 1) {
      return null;
    }
    return puzzles[currentIndex + 1].id;
  }

  Future<List<PuzzleContent>> _loadAllPuzzles() async {
    final jsonString = await rootBundle.loadString(assetPath);
    final dynamic decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException('Expected puzzles.json root to be an array');
    }

    final puzzles = decoded
        .map((entry) => PuzzleContent.fromJson(entry as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return puzzles;
  }
}
