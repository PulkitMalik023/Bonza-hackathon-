import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/candidate_word_scanner.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_runtime_state.dart';

import 'word_resolution_test_helpers.dart';

PuzzleLayoutMetadata _forkMetadata() {
  final layout = PuzzleLayout.fromPlacedWords(const [
    PlacedWord(
      word: 'FORK',
      row: 0,
      col: 0,
      direction: WordDirection.horizontal,
    ),
  ]);
  final deconstructed = PuzzleDeconstructor().build(layout);
  return PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
    layout: layout,
    deconstructed: deconstructed,
  );
}

PuzzlePiece _pieceFromChunk({
  required PuzzleLayoutMetadata metadata,
  required String chunkId,
  required int anchorRow,
  required int anchorCol,
}) {
  final chunk = metadata.chunkById[chunkId]!.chunk;
  return PuzzlePiece.fromChunk(
    chunk,
    anchorRow: anchorRow,
    anchorCol: anchorCol,
  );
}

void main() {
  test('FORK scan reads full horizontal segment through middle attachment', () {
    final metadata = _forkMetadata();
    final chunks = metadata.chunkById.keys.toList();

    final pieces = <PuzzlePiece>[];
    var col = 0;
    for (final chunkId in chunks) {
      pieces.add(
        _pieceFromChunk(
          metadata: metadata,
          chunkId: chunkId,
          anchorRow: 0,
          anchorCol: col,
        ),
      );
      col += metadata.chunkById[chunkId]!.chunk.width;
    }

    final state = rebuildRuntimeBoardState(
      pieces: piecesMovedOnBoard(pieces),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final candidates = scanCandidateWordsForWholeBoard(
      state: state,
      metadata: metadata,
    );

    expect(candidates.any((candidate) => candidate.text == 'FORK'), isTrue);
    expect(
      candidates.firstWhere((candidate) => candidate.text == 'FORK').finalCellIds,
      hasLength(4),
    );
  });

  test('dedupes candidate instances by orientation and final cell ids', () {
    final metadata = _forkMetadata();
    final chunkId = metadata.chunkById.keys.first;
    final piece = _pieceFromChunk(
      metadata: metadata,
      chunkId: chunkId,
      anchorRow: 0,
      anchorCol: 0,
    );

    final state = rebuildRuntimeBoardState(
      pieces: [pieceMovedOnBoard(piece)],
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final candidates = scanCandidateWordsForAffectedComponents(
      affectedComponentIds: state.componentsById.keys.toSet(),
      state: state,
      metadata: metadata,
    );

    final keys = candidates.map((candidate) => candidate.dedupeKey).toSet();
    expect(keys.length, candidates.length);
  });
}
