import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_definition.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PuzzleLayoutMetadata planetsMetadata;

  setUpAll(() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/puzzle_definitions.json',
    );
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    final definition = decoded
        .map(
          (entry) => PuzzleDefinition.fromJson(entry as Map<String, dynamic>),
        )
        .firstWhere((entry) => entry.puzzleId == 4);
    final deconstructed = definition.toDeconstructedPuzzle();

    planetsMetadata = PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
      layout: definition.puzzleLayout,
      deconstructed: deconstructed,
    );
  });

  PuzzlePiece chunkAtLayout(String chunkId) {
    final ref = planetsMetadata.chunkById[chunkId]!;
    final chunk = ref.chunk;
    return pieceMovedOnBoard(
      PuzzlePiece.fromChunk(
        chunk,
        anchorRow: chunk.solvedMinRow,
        anchorCol: chunk.solvedMinCol,
      ),
    );
  }

  test('rejects premature MARS when MA chunk is not on board', () {
    final pieces = [
      chunkAtLayout('chunk_1'),
      chunkAtLayout('chunk_3'),
      chunkAtLayout('chunk_4'),
    ];

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: planetsMetadata,
      movedChunkIds: ['chunk_4'],
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, isNot(contains('MARS')));
  });

  test('completes all planets words when full layout is on board', () {
    final pieces = [
      for (final chunkId in planetsMetadata.chunkById.keys)
        chunkAtLayout(chunkId),
    ];

    final result = handlePuzzleStateAfterReconnect(
      pieces: pieces,
      metadata: planetsMetadata,
      movedChunkIds: planetsMetadata.chunkById.keys.take(1),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(
      result.completedAnswers,
      containsAll(['VENUS', 'JUPITER', 'NEPTUNE', 'SATURN', 'MARS']),
    );
    expect(result.puzzleComplete, isTrue);
  });
}
