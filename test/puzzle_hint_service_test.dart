import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_hint_service.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';

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

PuzzleLayoutMetadata flowersCrosswordMetadata() {
  return metadataForWords(const [
    PlacedWord(
      word: 'DAFFODIL',
      row: 3,
      col: 0,
      direction: WordDirection.horizontal,
    ),
    PlacedWord(
      word: 'DAISY',
      row: 2,
      col: 1,
      direction: WordDirection.vertical,
    ),
    PlacedWord(
      word: 'ROSE',
      row: 2,
      col: 4,
      direction: WordDirection.vertical,
    ),
    PlacedWord(
      word: 'TULIP',
      row: 0,
      col: 6,
      direction: WordDirection.vertical,
    ),
  ]);
}

List<String> orderedChunkIdsForWord(
  PuzzleLayoutMetadata metadata,
  String wordText,
) {
  final wordId = wordIdForText(metadata, wordText);
  expect(wordId, isNotNull);

  final coverage = metadata.wordToChunkCoverage[wordId] ?? const [];
  final cellIndexMap = metadata.wordCellIndexMap[wordId] ?? const {};

  final entries = [...coverage];
  entries.sort((a, b) {
    int minIndex(ChunkCoverageEntry entry) {
      var min = 999;
      for (final cellId in entry.cellIdsForThisWord) {
        final index = cellIndexMap[cellId];
        if (index != null && index < min) {
          min = index;
        }
      }
      return min;
    }

    return minIndex(a).compareTo(minIndex(b));
  });

  return entries.map((entry) => entry.chunkId).toList();
}

List<PuzzlePiece> scatteredWordPieces({
  required PuzzleLayoutMetadata metadata,
  required String wordText,
  int rowSpacing = 4,
}) {
  final chunkIds = orderedChunkIdsForWord(metadata, wordText);
  final pieces = <PuzzlePiece>[];
  for (var index = 0; index < chunkIds.length; index++) {
    final chunk = metadata.chunkById[chunkIds[index]]!.chunk;
    pieces.add(
      PuzzlePiece.fromChunk(
        chunk,
        anchorRow: index * rowSpacing,
        anchorCol: 0,
      ),
    );
  }
  return piecesMovedOnBoard(pieces);
}

List<PuzzlePiece> wordPiecesWithConnectedPrefix({
  required PuzzleLayoutMetadata metadata,
  required String wordText,
  required int connectedChunkCount,
  int row = 0,
}) {
  final chunkIds = orderedChunkIdsForWord(metadata, wordText);
  expect(connectedChunkCount, lessThan(chunkIds.length));

  final pieces = <PuzzlePiece>[];
  var col = 0;
  for (var index = 0; index < chunkIds.length; index++) {
    final chunk = metadata.chunkById[chunkIds[index]]!.chunk;
    final anchorRow = index < connectedChunkCount ? row : row + (index + 1) * 4;
    final anchorCol = index < connectedChunkCount ? col : 0;

    pieces.add(
      PuzzlePiece.fromChunk(
        chunk,
        anchorRow: anchorRow,
        anchorCol: anchorCol,
      ),
    );

    if (index < connectedChunkCount) {
      col += chunk.width;
    }
  }

  return piecesMovedOnBoard(pieces);
}

PuzzlePiece? pieceForChunkId(List<PuzzlePiece> pieces, String chunkId) {
  for (final piece in pieces) {
    if (piece.chunkId == chunkId) {
      return piece;
    }
  }
  return null;
}

Set<String> solvedWordIdsExcept(
  PuzzleLayoutMetadata metadata,
  String keepUnsolvedWordText,
) {
  final keepId = wordIdForText(metadata, keepUnsolvedWordText);
  return {
    for (final wordId in metadata.targetWordIds)
      if (wordId != keepId) wordId,
  };
}

String eastStChunkId(PuzzleLayoutMetadata metadata) {
  final eastId = wordIdForText(metadata, 'EAST')!;
  final indexMap = metadata.wordCellIndexMap[eastId]!;

  for (final entry in metadata.wordToChunkCoverage[eastId]!) {
    for (final cellId in entry.cellIdsForThisWord) {
      if ((indexMap[cellId] ?? -1) >= 2) {
        return entry.chunkId;
      }
    }
  }

  throw StateError('EAST ST chunk not found');
}

List<PuzzlePiece> directionsPiecesEastNeedsSt(
  PuzzleLayoutMetadata metadata,
) {
  final pieces = connectedCrosswordPieces(metadata: metadata);
  final stChunkId = eastStChunkId(metadata);

  final updated = <PuzzlePiece>[];
  for (final piece in pieces) {
    if (piece.chunkId == stChunkId) {
      updated.add(
        PuzzlePiece.fromChunk(
          metadata.chunkById[piece.chunkId]!.chunk,
          anchorRow: 10,
          anchorCol: 0,
        ),
      );
    } else {
      updated.add(piece);
    }
  }

  return piecesMovedOnBoard(updated);
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

  test('initial hint uses first unsolved word in puzzle layout order', () {
    final metadata = cutleryMetadata();
    final pieces = scatteredPieces(metadata: metadata);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'SPOON');
    expect(hint.targetWordId, metadata.targetWordIds.first);
  });

  test('two-chunk word hints first two chunks in reading order', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'APPLE',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);
    final chunkIds = orderedChunkIdsForWord(metadata, 'APPLE');
    expect(chunkIds.length, greaterThanOrEqualTo(2));

    final pieces = scatteredWordPieces(metadata: metadata, wordText: 'APPLE');
    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'APPLE');
    expect(hint.highlightedPieceIds, hasLength(2));

    final first = pieceForChunkId(pieces, chunkIds[0])!;
    final second = pieceForChunkId(pieces, chunkIds[1])!;
    expect(hint.highlightedPieceIds, {first.id, second.id});
  });

  test('multi-chunk word hints first reading-order join when scattered', () {
    final metadata = cutleryMetadata();
    final forkChunkIds = orderedChunkIdsForWord(metadata, 'FORK');
    expect(forkChunkIds.length, greaterThanOrEqualTo(2));

    final pieces = scatteredWordPieces(metadata: metadata, wordText: 'FORK');
    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: solvedWordIdsExcept(metadata, 'FORK'),
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'FORK');

    final first = pieceForChunkId(pieces, forkChunkIds[0])!;
    final second = pieceForChunkId(pieces, forkChunkIds[1])!;
    expect(hint.highlightedPieceIds, {first.id, second.id});
  });

  test('partial progress hints next join along reading order', () {
    final metadata = cutleryMetadata();
    final forkChunkIds = orderedChunkIdsForWord(metadata, 'FORK');
    expect(forkChunkIds.length, greaterThanOrEqualTo(2));

    final pieces = wordPiecesWithConnectedPrefix(
      metadata: metadata,
      wordText: 'FORK',
      connectedChunkCount: 1,
    );

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: solvedWordIdsExcept(metadata, 'FORK'),
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'FORK');

    final boundary = pieceForChunkId(pieces, forkChunkIds[0])!;
    final next = pieceForChunkId(pieces, forkChunkIds[1])!;
    expect(hint.highlightedPieceIds, {boundary.id, next.id});
  });

  test('sticks to focusWordId until that word is no longer unsolved', () {
    final metadata = cutleryMetadata();
    final forkWordId = wordIdForText(metadata, 'FORK')!;
    final pieces = scatteredPieces(metadata: metadata);
    final forkPieces = wordPiecesWithConnectedPrefix(
      metadata: metadata,
      wordText: 'FORK',
      connectedChunkCount: 1,
      row: 0,
    );
    final forkByChunkId = {
      for (final piece in forkPieces) piece.chunkId: piece,
    };

    final updatedPieces = piecesMovedOnBoard([
      for (final piece in pieces)
        if (forkByChunkId.containsKey(piece.chunkId))
          forkByChunkId[piece.chunkId]!
        else
          piece,
    ]);

    final hint = suggestNextConnectHint(
      pieces: updatedPieces,
      metadata: metadata,
      solvedWordIds: {
        for (final wordId in metadata.targetWordIds)
          if (metadata.wordById[wordId]?.text == 'KNIFE') wordId,
      },
      focusWordId: forkWordId,
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'FORK');
    expect(hint.targetWordId, forkWordId);
  });

  test('crossword hint prioritizes word with longest letter prefix', () {
    final metadata = flowersCrosswordMetadata();
    final daffodilChunkIds = orderedChunkIdsForWord(metadata, 'DAFFODIL');
    expect(daffodilChunkIds.length, greaterThanOrEqualTo(2));

    final allPieces = scatteredPieces(metadata: metadata);
    final daffodilPrefixPieces = wordPiecesWithConnectedPrefix(
      metadata: metadata,
      wordText: 'DAFFODIL',
      connectedChunkCount: 1,
    );
    final prefixByChunkId = {
      for (final piece in daffodilPrefixPieces) piece.chunkId: piece,
    };

    final pieces = piecesMovedOnBoard([
      for (final piece in allPieces)
        if (prefixByChunkId.containsKey(piece.chunkId))
          prefixByChunkId[piece.chunkId]!
        else
          piece,
    ]);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: solvedWordIdsExcept(metadata, 'DAFFODIL'),
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'DAFFODIL');
    expect(hint.targetWordId, wordIdForText(metadata, 'DAFFODIL'));

    final first = pieceForChunkId(pieces, daffodilChunkIds[0])!;
    final second = pieceForChunkId(pieces, daffodilChunkIds[1])!;
    expect(hint.highlightedPieceIds, containsAll({first.id, second.id}));
    expect(hint.message, contains('to spell DAFFODIL'));
    expect(hint.pieceALabel, isNot(contains('Y')));
    expect(hint.pieceBLabel, isNot(contains('R')));
  });

  test('crossword focus keeps hint on DAFFODIL for second join step', () {
    final metadata = flowersCrosswordMetadata();
    final daffodilWordId = wordIdForText(metadata, 'DAFFODIL')!;
    final daffodilChunkIds = orderedChunkIdsForWord(metadata, 'DAFFODIL');
    expect(daffodilChunkIds.length, greaterThanOrEqualTo(3));

    final allPieces = scatteredPieces(metadata: metadata);
    final daffodilPrefixPieces = wordPiecesWithConnectedPrefix(
      metadata: metadata,
      wordText: 'DAFFODIL',
      connectedChunkCount: 2,
    );
    final prefixByChunkId = {
      for (final piece in daffodilPrefixPieces) piece.chunkId: piece,
    };

    final pieces = piecesMovedOnBoard([
      for (final piece in allPieces)
        if (prefixByChunkId.containsKey(piece.chunkId))
          prefixByChunkId[piece.chunkId]!
        else
          piece,
    ]);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
      focusWordId: daffodilWordId,
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'DAFFODIL');
    expect(hint.targetWordId, daffodilWordId);

    final boundary = pieceForChunkId(pieces, daffodilChunkIds[1])!;
    final next = pieceForChunkId(pieces, daffodilChunkIds[2])!;
    expect(hint.highlightedPieceIds, containsAll({boundary.id, next.id}));
    expect(hint.highlightedPieceIds.length, greaterThanOrEqualTo(2));
  });

  test('compass EAST hints join prefix pieces with isolated ST chunk', () {
    final metadata = directionsMetadata();
    final pieces = directionsPiecesEastNeedsSt(metadata);
    final eastChunkIds = orderedChunkIdsForWord(metadata, 'EAST');
    final stChunkId = eastStChunkId(metadata);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'EAST');
    expect(hint.message, contains('to spell EAST'));
    expect(hint.pieceBLabel, 'T');

    final prefixPiece = pieceForChunkId(pieces, eastChunkIds.first)!;
    final stPiece = pieceForChunkId(pieces, stChunkId)!;
    expect(hint.highlightedPieceIds, containsAll({prefixPiece.id, stPiece.id}));
  });

  test('compass word priority picks EAST over fully connected directions', () {
    final metadata = directionsMetadata();
    final pieces = directionsPiecesEastNeedsSt(metadata);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'EAST');
  });

  test('compass focus advances when focused word has no remaining join', () {
    final metadata = directionsMetadata();
    final northId = wordIdForText(metadata, 'NORTH')!;
    final pieces = directionsPiecesEastNeedsSt(metadata);

    final hint = suggestNextConnectHint(
      pieces: pieces,
      metadata: metadata,
      solvedWordIds: const {},
      focusWordId: northId,
    );

    expect(hint, isNotNull);
    expect(hint!.targetWord, 'EAST');
  });
}
