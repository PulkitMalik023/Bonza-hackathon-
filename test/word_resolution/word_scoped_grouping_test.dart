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

  const traySpawnRow = 14;

  PuzzlePiece chunkAtSpawn(String chunkId, int trayCol) {
    final ref = planetsMetadata.chunkById[chunkId]!;
    final chunk = ref.chunk;
    return PuzzlePiece.fromChunk(
      chunk,
      anchorRow: traySpawnRow,
      anchorCol: trayCol,
    );
  }

  test(
    'JUPITER groups only contributing chunks when NEPTUNE UNE chunk is adjacent',
    () {
      final jupiterChunkIds = {'chunk_3', 'chunk_4'};
      final pieces = <PuzzlePiece>[];
      var trayCol = 0;

      for (final chunkId in planetsMetadata.chunkById.keys) {
        if (jupiterChunkIds.contains(chunkId) || chunkId == 'chunk_5') {
          pieces.add(chunkAtLayout(chunkId));
        } else {
          pieces.add(chunkAtSpawn(chunkId, trayCol));
          trayCol += planetsMetadata.chunkById[chunkId]!.chunk.width + 1;
        }
      }

      final result = handlePuzzleStateAfterReconnect(
        pieces: pieces,
        metadata: planetsMetadata,
        movedChunkIds: {...jupiterChunkIds, 'chunk_5'},
        solvedWordIds: const {},
        reservedCellIds: const {},
        solvedAssignments: const {},
      );

      expect(result.completedAnswers, contains('JUPITER'));
      expect(result.completedAnswers, isNot(contains('NEPTUNE')));

      final completedGroups =
          result.pieces.where((piece) => piece.isCompletedWordGroup).toList();
      expect(completedGroups, hasLength(1));
      expect(completedGroups.first.completedAnswers, contains('JUPITER'));

      final neptuneChunk = result.pieces
          .where((piece) => !piece.isCompletedWordGroup && piece.chunkId == 'chunk_5')
          .toList();
      expect(
        neptuneChunk,
        hasLength(1),
        reason: 'Adjacent NEPTUNE UNE chunk must remain a separate active piece',
      );
      expect(
        neptuneChunk.first.cells.map((cell) => cell.letter).toSet(),
        containsAll(['U', 'N', 'E']),
      );
    },
  );
}
