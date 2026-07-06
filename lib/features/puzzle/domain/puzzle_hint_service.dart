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
    required this.targetWordId,
    required this.targetWord,
    required this.pieceAId,
    required this.pieceBId,
    required this.pieceALabel,
    required this.pieceBLabel,
    required this.direction,
    required this.message,
  });

  final String targetWordId;
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
  String? focusWordId,
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

  if (focusWordId != null && !solvedWordIds.contains(focusWordId)) {
    final focusedHint = _hintForWord(
      wordId: focusWordId,
      metadata: metadata,
      pieceByChunkId: pieceByChunkId,
      chunkToComponent: chunkToComponent,
    );
    if (focusedHint != null) {
      return focusedHint;
    }
  }

  for (final wordId in metadata.targetWordIds) {
    if (solvedWordIds.contains(wordId)) {
      continue;
    }

    final connectHint = _connectHintForWord(
      wordId: wordId,
      metadata: metadata,
      pieceByChunkId: pieceByChunkId,
      chunkToComponent: chunkToComponent,
    );
    if (connectHint != null) {
      return connectHint;
    }
  }

  for (final wordId in metadata.targetWordIds) {
    if (solvedWordIds.contains(wordId)) {
      continue;
    }

    final word = metadata.wordById[wordId]!;
    final chunkIds = _sortedChunkIdsForWord(
      wordId: wordId,
      metadata: metadata,
    );

    final alignHint = _alignHintForWord(
      wordId: wordId,
      word: word,
      metadata: metadata,
      pieceByChunkId: pieceByChunkId,
      chunkIds: chunkIds,
    );
    if (alignHint != null) {
      return alignHint;
    }
  }

  return null;
}

PuzzleConnectHint? _hintForWord({
  required String wordId,
  required PuzzleLayoutMetadata metadata,
  required Map<String, PuzzlePiece> pieceByChunkId,
  required Map<String, String> chunkToComponent,
}) {
  final connectHint = _connectHintForWord(
    wordId: wordId,
    metadata: metadata,
    pieceByChunkId: pieceByChunkId,
    chunkToComponent: chunkToComponent,
  );
  if (connectHint != null) {
    return connectHint;
  }

  final word = metadata.wordById[wordId];
  if (word == null) {
    return null;
  }

  return _alignHintForWord(
    wordId: wordId,
    word: word,
    metadata: metadata,
    pieceByChunkId: pieceByChunkId,
    chunkIds: _sortedChunkIdsForWord(
      wordId: wordId,
      metadata: metadata,
    ),
  );
}

List<String> _sortedChunkIdsForWord({
  required String wordId,
  required PuzzleLayoutMetadata metadata,
}) {
  final coverage = metadata.wordToChunkCoverage[wordId] ?? const [];
  final cellIndexMap = metadata.wordCellIndexMap[wordId] ?? const {};

  final entries = [...coverage];
  entries.sort((a, b) {
    final aMin = _minLetterIndex(a, cellIndexMap);
    final bMin = _minLetterIndex(b, cellIndexMap);
    return aMin.compareTo(bMin);
  });

  return entries.map((entry) => entry.chunkId).toList();
}

int _minLetterIndex(
  ChunkCoverageEntry entry,
  Map<String, int> cellIndexMap,
) {
  var minIndex = 999;
  for (final cellId in entry.cellIdsForThisWord) {
    final index = cellIndexMap[cellId];
    if (index != null && index < minIndex) {
      minIndex = index;
    }
  }
  return minIndex;
}

int _connectedPrefixEnd({
  required List<String> orderedChunkIds,
  required Map<String, String> chunkToComponent,
  required PuzzleLayoutMetadata metadata,
}) {
  if (orderedChunkIds.isEmpty ||
      !chunkToComponent.containsKey(orderedChunkIds.first)) {
    return -1;
  }

  var prefixEnd = 0;
  for (var index = 0; index < orderedChunkIds.length - 1; index++) {
    final chunkAId = orderedChunkIds[index];
    final chunkBId = orderedChunkIds[index + 1];
    final componentA = chunkToComponent[chunkAId];
    final componentB = chunkToComponent[chunkBId];
    if (componentA == null || componentB == null || componentA != componentB) {
      break;
    }

    final refA = metadata.chunkById[chunkAId];
    final refB = metadata.chunkById[chunkBId];
    if (refA == null || refB == null) {
      break;
    }

    if (_chunkLayoutAdjacency(refA.chunk, refB.chunk, metadata) == null) {
      break;
    }

    prefixEnd = index + 1;
  }

  return prefixEnd;
}

PuzzleConnectHint? _connectHintForWord({
  required String wordId,
  required PuzzleLayoutMetadata metadata,
  required Map<String, PuzzlePiece> pieceByChunkId,
  required Map<String, String> chunkToComponent,
}) {
  final wordText = metadata.wordById[wordId]?.text;
  if (wordText == null) {
    return null;
  }

  final orderedChunkIds = _sortedChunkIdsForWord(
    wordId: wordId,
    metadata: metadata,
  );
  if (orderedChunkIds.length < 2) {
    return null;
  }

  final prefixEnd = _connectedPrefixEnd(
    orderedChunkIds: orderedChunkIds,
    chunkToComponent: chunkToComponent,
    metadata: metadata,
  );
  if (prefixEnd >= orderedChunkIds.length - 1) {
    return null;
  }

  final leftChunkIndex = prefixEnd < 0 ? 0 : prefixEnd;
  final rightChunkIndex = prefixEnd + 1;
  final leftChunkId = orderedChunkIds[leftChunkIndex];
  final rightChunkId = orderedChunkIds[rightChunkIndex];

  final leftComponent = chunkToComponent[leftChunkId];
  final rightComponent = chunkToComponent[rightChunkId];
  if (leftComponent != null &&
      rightComponent != null &&
      leftComponent == rightComponent) {
    return null;
  }

  final pieceA = pieceByChunkId[leftChunkId];
  final pieceB = pieceByChunkId[rightChunkId];
  if (pieceA == null || pieceB == null) {
    return null;
  }

  final refA = metadata.chunkById[leftChunkId];
  final refB = metadata.chunkById[rightChunkId];
  if (refA == null || refB == null) {
    return null;
  }

  final direction = _chunkLayoutAdjacency(refA.chunk, refB.chunk, metadata);
  if (direction == null) {
    return null;
  }

  final labelA = _pieceLabelForWord(
    piece: pieceA,
    wordId: wordId,
    metadata: metadata,
  );
  final labelB = _pieceLabelForWord(
    piece: pieceB,
    wordId: wordId,
    metadata: metadata,
  );

  return PuzzleConnectHint(
    targetWordId: wordId,
    targetWord: wordText,
    pieceAId: pieceA.id,
    pieceBId: pieceB.id,
    pieceALabel: labelA,
    pieceBLabel: labelB,
    direction: direction,
    message: 'Join $labelA and $labelB ${direction.adverb} to spell $wordText',
  );
}

PuzzleConnectHint? _alignHintForWord({
  required String wordId,
  required FinalLayoutWord word,
  required PuzzleLayoutMetadata metadata,
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

  final label = _pieceLabelForWord(
    piece: piece,
    wordId: wordId,
    metadata: metadata,
  );

  return PuzzleConnectHint(
    targetWordId: wordId,
    targetWord: word.text,
    pieceAId: piece.id,
    pieceBId: piece.id,
    pieceALabel: label,
    pieceBLabel: label,
    direction: direction,
    message: 'Align $label ${direction.adverb} to spell ${word.text}',
  );
}

String _pieceLabelForWord({
  required PuzzlePiece piece,
  required String wordId,
  required PuzzleLayoutMetadata metadata,
}) {
  final coverage = metadata.wordToChunkCoverage[wordId];
  if (coverage == null) {
    return _pieceLabel(piece);
  }

  ChunkCoverageEntry? entry;
  for (final candidate in coverage) {
    if (candidate.chunkId == piece.chunkId) {
      entry = candidate;
      break;
    }
  }
  if (entry == null) {
    return _pieceLabel(piece);
  }

  final cellIndexMap = metadata.wordCellIndexMap[wordId] ?? const {};
  final indexedLetters = <int, String>{};
  for (final cellId in entry.cellIdsForThisWord) {
    final letterIndex = cellIndexMap[cellId];
    final letter = metadata.finalCellById[cellId]?.letter;
    if (letterIndex == null || letter == null) {
      continue;
    }
    indexedLetters[letterIndex] = letter;
  }

  if (indexedLetters.isEmpty) {
    return _pieceLabel(piece);
  }

  final sortedIndexes = indexedLetters.keys.toList()..sort();
  return sortedIndexes.map((index) => indexedLetters[index]!).join();
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
