import '../data/models/puzzle_chunk.dart';
import 'puzzle_piece.dart';
import 'word_resolution/puzzle_layout_metadata.dart';
import 'word_resolution/puzzle_runtime_state.dart';
import 'word_resolution/word_resolution_models.dart';

enum ConnectDirection { horizontal, vertical }

extension ConnectDirectionLabel on ConnectDirection {
  String get adverb =>
      this == ConnectDirection.horizontal ? 'horizontally' : 'vertically';
}

class PuzzleConnectHint {
  const PuzzleConnectHint({
    required this.targetWord,
    required this.pieceAId,
    required this.pieceBId,
    required this.pieceALabel,
    required this.pieceBLabel,
    required this.direction,
    required this.message,
  });

  final String targetWord;
  final String pieceAId;
  final String pieceBId;
  final String pieceALabel;
  final String pieceBLabel;
  final ConnectDirection direction;
  final String message;

  Set<String> get highlightedPieceIds => {pieceAId, pieceBId};
}

PuzzleConnectHint? suggestNextConnectHint({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
}) {
  final unsolvedWordIds = metadata.targetWordIds
      .where((wordId) => !solvedWordIds.contains(wordId))
      .toList();

  if (unsolvedWordIds.isEmpty) {
    return null;
  }

  final activePieces = pieces.where((piece) => !piece.isCompletedWordGroup);
  final pieceByChunkId = {
    for (final piece in activePieces) piece.chunkId: piece,
  };

  final state = rebuildRuntimeBoardState(
    pieces: pieces,
    metadata: metadata,
    solvedWordIds: solvedWordIds,
    reservedCellIds: const {},
    solvedAssignments: const {},
  );

  final chunkToComponent = <String, String>{};
  for (final placed in state.placedCellsByFinalId.values) {
    chunkToComponent[placed.chunkId] = placed.componentId;
  }

  unsolvedWordIds.sort((a, b) {
    final aScore = _placedChunkCount(
      wordId: a,
      metadata: metadata,
      chunkToComponent: chunkToComponent,
    );
    final bScore = _placedChunkCount(
      wordId: b,
      metadata: metadata,
      chunkToComponent: chunkToComponent,
    );
    return bScore.compareTo(aScore);
  });

  for (final wordId in unsolvedWordIds) {
    final word = metadata.wordById[wordId]!;
    final chunkIds = metadata.wordToChunkCoverage[wordId]
            ?.map((entry) => entry.chunkId)
            .toSet()
            .toList() ??
        const [];

    final connectHint = _connectHintForWord(
      wordId: wordId,
      wordText: word.text,
      chunkIds: chunkIds,
      metadata: metadata,
      pieceByChunkId: pieceByChunkId,
      chunkToComponent: chunkToComponent,
    );
    if (connectHint != null) {
      return connectHint;
    }

    final alignHint = _alignHintForWord(
      word: word,
      pieceByChunkId: pieceByChunkId,
      chunkIds: chunkIds,
    );
    if (alignHint != null) {
      return alignHint;
    }
  }

  return null;
}

int _placedChunkCount({
  required String wordId,
  required PuzzleLayoutMetadata metadata,
  required Map<String, String> chunkToComponent,
}) {
  final chunkIds =
      metadata.wordToChunkCoverage[wordId]?.map((entry) => entry.chunkId) ??
          const [];
  return chunkIds.where(chunkToComponent.containsKey).length;
}

PuzzleConnectHint? _connectHintForWord({
  required String wordId,
  required String wordText,
  required List<String> chunkIds,
  required PuzzleLayoutMetadata metadata,
  required Map<String, PuzzlePiece> pieceByChunkId,
  required Map<String, String> chunkToComponent,
}) {
  final adjacentPairs = _layoutAdjacentChunkPairs(
    chunkIds: chunkIds,
    metadata: metadata,
  );

  for (final pair in adjacentPairs) {
    final componentA = chunkToComponent[pair.chunkAId];
    final componentB = chunkToComponent[pair.chunkBId];
    if (componentA == null || componentB == null) {
      continue;
    }
    if (componentA == componentB) {
      continue;
    }

    final pieceA = pieceByChunkId[pair.chunkAId];
    final pieceB = pieceByChunkId[pair.chunkBId];
    if (pieceA == null || pieceB == null) {
      continue;
    }

    return PuzzleConnectHint(
      targetWord: wordText,
      pieceAId: pieceA.id,
      pieceBId: pieceB.id,
      pieceALabel: _pieceLabel(pieceA),
      pieceBLabel: _pieceLabel(pieceB),
      direction: pair.direction,
      message:
          'Join ${_pieceLabel(pieceA)} and ${_pieceLabel(pieceB)} ${pair.direction.adverb} to spell $wordText',
    );
  }

  return null;
}

PuzzleConnectHint? _alignHintForWord({
  required FinalLayoutWord word,
  required Map<String, PuzzlePiece> pieceByChunkId,
  required List<String> chunkIds,
}) {
  if (chunkIds.length != 1) {
    return null;
  }

  final piece = pieceByChunkId[chunkIds.first];
  if (piece == null) {
    return null;
  }

  final direction = word.orientation == WordOrientation.horizontal
      ? ConnectDirection.horizontal
      : ConnectDirection.vertical;

  return PuzzleConnectHint(
    targetWord: word.text,
    pieceAId: piece.id,
    pieceBId: piece.id,
    pieceALabel: _pieceLabel(piece),
    pieceBLabel: _pieceLabel(piece),
    direction: direction,
    message: 'Align ${_pieceLabel(piece)} ${direction.adverb} to spell ${word.text}',
  );
}

class _AdjacentChunkPair {
  const _AdjacentChunkPair({
    required this.chunkAId,
    required this.chunkBId,
    required this.direction,
  });

  final String chunkAId;
  final String chunkBId;
  final ConnectDirection direction;
}

List<_AdjacentChunkPair> _layoutAdjacentChunkPairs({
  required List<String> chunkIds,
  required PuzzleLayoutMetadata metadata,
}) {
  final pairs = <_AdjacentChunkPair>[];

  for (var indexA = 0; indexA < chunkIds.length; indexA++) {
    for (var indexB = indexA + 1; indexB < chunkIds.length; indexB++) {
      final chunkAId = chunkIds[indexA];
      final chunkBId = chunkIds[indexB];
      final refA = metadata.chunkById[chunkAId];
      final refB = metadata.chunkById[chunkBId];
      if (refA == null || refB == null) {
        continue;
      }

      final adjacency = _chunkLayoutAdjacency(refA.chunk, refB.chunk, metadata);
      if (adjacency == null) {
        continue;
      }

      pairs.add(
        _AdjacentChunkPair(
          chunkAId: chunkAId,
          chunkBId: chunkBId,
          direction: adjacency,
        ),
      );
    }
  }

  return pairs;
}

ConnectDirection? _chunkLayoutAdjacency(
  PuzzleChunk chunkA,
  PuzzleChunk chunkB,
  PuzzleLayoutMetadata metadata,
) {
  for (final cellA in chunkA.solvedCells.entries) {
    final cellIdA = finalCellIdForLayout(
      cellA.key.row,
      cellA.key.col,
    );
    final layoutA = metadata.finalCellById[cellIdA];
    if (layoutA == null) {
      continue;
    }

    for (final cellB in chunkB.solvedCells.entries) {
      final cellIdB = finalCellIdForLayout(
        cellB.key.row,
        cellB.key.col,
      );
      final layoutB = metadata.finalCellById[cellIdB];
      if (layoutB == null) {
        continue;
      }

      final rowDelta = (layoutA.row - layoutB.row).abs();
      final colDelta = (layoutA.col - layoutB.col).abs();
      if (rowDelta + colDelta != 1) {
        continue;
      }

      return rowDelta == 1
          ? ConnectDirection.vertical
          : ConnectDirection.horizontal;
    }
  }

  return null;
}

String _pieceLabel(PuzzlePiece piece) {
  final cells = [...piece.cells]
    ..sort((a, b) {
      final rowCompare = a.rowOffset.compareTo(b.rowOffset);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.colOffset.compareTo(b.colOffset);
    });

  return cells.map((cell) => cell.letter).join();
}
