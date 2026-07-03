import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_hint_service.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';

import 'word_resolution/word_resolution_test_helpers.dart';

List<PuzzlePiece> scatteredPieces({
  required PuzzleLayoutMetadata metadata,
  int rowSpacing = 4,
}) {
  final pieces = <PuzzlePiece>[];
  var index = 0;
  for (final ref in metadata.chunkById.values) {
    pieces.add(
      PuzzlePiece.fromChunk(
        ref.chunk,
        anchorRow: index * rowSpacing,
        anchorCol: 0,
      ),
    );
    index++;
  }
  return pieces;
}

void main() {
  test('returns null when all words are solved', () {
    final metadata = cutleryMetadata();

    final hint = suggestNextConnectHint(
      pieces: scatteredPieces(metadata: metadata),
      metadata: metadata,
      solvedWordIds: metadata.targetWordIds.toSet(),
    );

    expect(hint, isNull);
  });

  test('suggests joining two separated chunks for cutlery puzzle', () {
    final metadata = cutleryMetadata();
    final pieces = scatteredPieces(metadata: metadata);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
    );

    expect(hint, isNotNull);
    expect(hint!.message, contains('Join'));
    expect(hint.message, contains('to spell'));
    expect(hint.highlightedPieceIds, hasLength(2));
    expect(
      hint.message,
      anyOf(contains('horizontally'), contains('vertically')),
    );
  });

  test('highlights the two pieces referenced in the hint', () {
    final metadata = cutleryMetadata();
    final pieces = scatteredPieces(metadata: metadata);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
    );

    expect(hint, isNotNull);
    expect(hint!.highlightedPieceIds, contains(hint.pieceAId));
    expect(hint.highlightedPieceIds, contains(hint.pieceBId));
  });
}
