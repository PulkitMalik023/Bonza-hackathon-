import '../../../../core/constants/board_constants.dart';
import '../data/models/puzzle_chunk.dart';
import 'puzzle_piece.dart';
import 'puzzle_solved_checker.dart';
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
    required this.highlightedPieceIds,
  });

  final String targetWordId;
  final String targetWord;
  final String pieceAId;
  final String pieceBId;
  final String pieceALabel;
  final String pieceBLabel;
  final ConnectDirection direction;
  final String message;
  final Set<String> highlightedPieceIds;
}

class _HintContext {
  const _HintContext({
    required this.metadata,
    required this.state,
    required this.pieceByChunkId,
    required this.pieceById,
    required this.finalCellIdToPieceId,
    required this.chunkToComponent,
  });

  final PuzzleLayoutMetadata metadata;
  final PuzzleRuntimeState state;
  final Map<String, PuzzlePiece> pieceByChunkId;
  final Map<String, PuzzlePiece> pieceById;
  final Map<String, String> finalCellIdToPieceId;
  final Map<String, String> chunkToComponent;
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

  final context = _buildHintContext(
    pieces: pieces,
    metadata: metadata,
    solvedWordIds: solvedWordIds,
  );

  if (focusWordId != null && !solvedWordIds.contains(focusWordId)) {
    final focusedHint = _hintForWord(
      wordId: focusWordId,
      context: context,
    );
    if (focusedHint != null) {
      return focusedHint;
    }
  }

  return _bestHintForUnsolvedWords(
    metadata: metadata,
    solvedWordIds: solvedWordIds,
    context: context,
  );
}

_HintContext _buildHintContext({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
}) {
  final activePieces = pieces.where((piece) => !piece.isCompletedWordGroup);
  final pieceByChunkId = {
    for (final piece in activePieces) piece.chunkId: piece,
  };
  final pieceById = <String, PuzzlePiece>{};
  final finalCellIdToPieceId = <String, String>{};

  for (final piece in pieces) {
    if (!isPieceOnBoard(
      piece,
      BoardConstants.kPlayGridRows,
      BoardConstants.kPlayGridCols,
    )) {
      continue;
    }

    pieceById[piece.id] = piece;

    for (final cell in piece.cells) {
      final finalCellId = metadata.finalCellIdForChunkLocal(
        chunkId: piece.chunkId,
        localRow: cell.rowOffset,
        localCol: cell.colOffset,
      );
      if (finalCellId != null) {
        finalCellIdToPieceId[finalCellId] = piece.id;
      }
    }
  }

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

  return _HintContext(
    metadata: metadata,
    state: state,
    pieceByChunkId: pieceByChunkId,
    pieceById: pieceById,
    finalCellIdToPieceId: finalCellIdToPieceId,
    chunkToComponent: chunkToComponent,
  );
}

PuzzleConnectHint? _bestHintForUnsolvedWords({
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
  required _HintContext context,
}) {
  PuzzleConnectHint? bestHint;
  var bestPrefixLength = -1;
  var bestWordOrder = metadata.targetWordIds.length;
  var bestIsConnect = false;

  for (final wordId in metadata.targetWordIds) {
    if (solvedWordIds.contains(wordId)) {
      continue;
    }

    final connectHint = _connectHintForWord(
      wordId: wordId,
      context: context,
    );
    final alignHint = connectHint == null
        ? _alignHintForWord(
            wordId: wordId,
            context: context,
          )
        : null;
    final hint = connectHint ?? alignHint;
    if (hint == null) {
      continue;
    }

    final prefixLength = _letterPrefixLength(
      wordId: wordId,
      state: context.state,
      metadata: context.metadata,
    );
    final wordOrder = metadata.targetWordIds.indexOf(wordId);
    final isConnect = connectHint != null;

    if (prefixLength > bestPrefixLength ||
        (prefixLength == bestPrefixLength &&
            (isConnect && !bestIsConnect ||
                isConnect == bestIsConnect && wordOrder < bestWordOrder))) {
      bestHint = hint;
      bestPrefixLength = prefixLength;
      bestWordOrder = wordOrder;
      bestIsConnect = isConnect;
    }
  }

  return bestHint;
}

PuzzleConnectHint? _hintForWord({
  required String wordId,
  required _HintContext context,
}) {
  final connectHint = _connectHintForWord(
    wordId: wordId,
    context: context,
  );
  if (connectHint != null) {
    return connectHint;
  }

  return _alignHintForWord(
    wordId: wordId,
    context: context,
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

int _letterPrefixLength({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null || word.cellIds.isEmpty) {
    return 0;
  }

  if (!state.placedCellsByFinalId.containsKey(word.cellIds.first)) {
    return 0;
  }

  var prefixLength = 1;
  for (var index = 1; index < word.cellIds.length; index++) {
    final previousCellId = word.cellIds[index - 1];
    final cellId = word.cellIds[index];
    final previousPlaced = state.placedCellsByFinalId[previousCellId];
    final placed = state.placedCellsByFinalId[cellId];
    if (previousPlaced == null || placed == null) {
      break;
    }
    if (previousPlaced.componentId != placed.componentId) {
      break;
    }

    final previousLayout = metadata.finalCellById[previousCellId];
    final layout = metadata.finalCellById[cellId];
    if (previousLayout == null || layout == null) {
      break;
    }

    final rowDelta = (previousLayout.row - layout.row).abs();
    final colDelta = (previousLayout.col - layout.col).abs();
    if (rowDelta + colDelta != 1) {
      break;
    }

    prefixLength++;
  }

  return prefixLength;
}

Set<String> _pieceIdsForWordPrefix({
  required String wordId,
  required int prefixLength,
  required _HintContext context,
}) {
  final word = context.metadata.wordById[wordId];
  if (word == null || prefixLength <= 0) {
    return const {};
  }

  final pieceIds = <String>{};
  for (var index = 0; index < prefixLength && index < word.cellIds.length; index++) {
    final pieceId = context.finalCellIdToPieceId[word.cellIds[index]];
    if (pieceId != null) {
      pieceIds.add(pieceId);
    }
  }
  return pieceIds;
}

String? _chunkIdForWordLetterIndex({
  required String wordId,
  required int letterIndex,
  required PuzzleLayoutMetadata metadata,
}) {
  for (final entry in metadata.wordToChunkCoverage[wordId] ?? const []) {
    final cellIndexMap = metadata.wordCellIndexMap[wordId] ?? const {};
    for (final cellId in entry.cellIdsForThisWord) {
      if (cellIndexMap[cellId] == letterIndex) {
        return entry.chunkId;
      }
    }
  }
  return null;
}

String? _nextChunkIdAfterPrefix({
  required String wordId,
  required int prefixLength,
  required _HintContext context,
}) {
  final word = context.metadata.wordById[wordId];
  if (word == null || prefixLength >= word.text.length) {
    return null;
  }

  final orderedChunkIds = _sortedChunkIdsForWord(
    wordId: wordId,
    metadata: context.metadata,
  );
  if (orderedChunkIds.length < 2) {
    return null;
  }

  if (prefixLength <= 0) {
    return orderedChunkIds[1];
  }

  final prefixComponentId =
      context.state.placedCellsByFinalId[word.cellIds[prefixLength - 1]]
          ?.componentId;
  if (prefixComponentId == null) {
    return orderedChunkIds.firstWhere(
      (chunkId) {
        final componentId = context.chunkToComponent[chunkId];
        return componentId == null || componentId != prefixComponentId;
      },
      orElse: () => orderedChunkIds[1],
    );
  }

  final targetChunkId = _chunkIdForWordLetterIndex(
    wordId: wordId,
    letterIndex: prefixLength,
    metadata: context.metadata,
  );
  if (targetChunkId == null) {
    return null;
  }

  final targetComponentId = context.chunkToComponent[targetChunkId];
  if (targetComponentId == null || targetComponentId != prefixComponentId) {
    return targetChunkId;
  }

  final targetIndex = orderedChunkIds.indexOf(targetChunkId);
  for (var index = targetIndex + 1; index < orderedChunkIds.length; index++) {
    final chunkId = orderedChunkIds[index];
    final componentId = context.chunkToComponent[chunkId];
    if (componentId == null || componentId != prefixComponentId) {
      return chunkId;
    }
  }

  return null;
}

String? _boundaryChunkIdForPrefix({
  required String wordId,
  required int prefixLength,
  required PuzzleLayoutMetadata metadata,
}) {
  if (prefixLength <= 0) {
    final orderedChunkIds = _sortedChunkIdsForWord(
      wordId: wordId,
      metadata: metadata,
    );
    return orderedChunkIds.isEmpty ? null : orderedChunkIds.first;
  }

  return _chunkIdForWordLetterIndex(
    wordId: wordId,
    letterIndex: prefixLength - 1,
    metadata: metadata,
  );
}

PuzzleConnectHint? _connectHintForWord({
  required String wordId,
  required _HintContext context,
}) {
  final wordText = context.metadata.wordById[wordId]?.text;
  if (wordText == null) {
    return null;
  }

  final orderedChunkIds = _sortedChunkIdsForWord(
    wordId: wordId,
    metadata: context.metadata,
  );
  if (orderedChunkIds.length < 2) {
    return null;
  }

  final prefixLength = _letterPrefixLength(
    wordId: wordId,
    state: context.state,
    metadata: context.metadata,
  );
  if (prefixLength >= wordText.length) {
    return null;
  }

  final nextChunkId = _nextChunkIdAfterPrefix(
    wordId: wordId,
    prefixLength: prefixLength,
    context: context,
  );
  if (nextChunkId == null) {
    return null;
  }

  final boundaryChunkId = prefixLength <= 0
      ? orderedChunkIds.first
      : _boundaryChunkIdForPrefix(
          wordId: wordId,
          prefixLength: prefixLength,
          metadata: context.metadata,
        );
  if (boundaryChunkId == null) {
    return null;
  }

  final boundaryComponent = context.chunkToComponent[boundaryChunkId];
  final nextComponent = context.chunkToComponent[nextChunkId];
  if (boundaryComponent != null &&
      nextComponent != null &&
      boundaryComponent == nextComponent) {
    return null;
  }

  final prefixPieceIds = prefixLength <= 0
      ? {
          if (context.pieceByChunkId[boundaryChunkId]?.id case final id?) id,
        }
      : _pieceIdsForWordPrefix(
          wordId: wordId,
          prefixLength: prefixLength,
          context: context,
        );
  final nextPiece = context.pieceByChunkId[nextChunkId];
  if (prefixPieceIds.isEmpty || nextPiece == null) {
    return null;
  }

  final boundaryRef = context.metadata.chunkById[boundaryChunkId];
  final nextRef = context.metadata.chunkById[nextChunkId];
  if (boundaryRef == null || nextRef == null) {
    return null;
  }

  final direction =
      _chunkLayoutAdjacency(boundaryRef.chunk, nextRef.chunk, context.metadata);
  if (direction == null) {
    return null;
  }

  final boundaryPiece =
      context.pieceByChunkId[boundaryChunkId] ??
      context.pieceById[prefixPieceIds.first];
  if (boundaryPiece == null) {
    return null;
  }

  final labelA = prefixLength <= 0
      ? _pieceLabelForWord(
          piece: boundaryPiece,
          wordId: wordId,
          metadata: context.metadata,
        )
      : wordText.substring(0, prefixLength);
  final labelB = _pieceLabelForWord(
    piece: nextPiece,
    wordId: wordId,
    metadata: context.metadata,
  );

  final highlightedPieceIds = {...prefixPieceIds, nextPiece.id};

  return PuzzleConnectHint(
    targetWordId: wordId,
    targetWord: wordText,
    pieceAId: boundaryPiece.id,
    pieceBId: nextPiece.id,
    pieceALabel: labelA,
    pieceBLabel: labelB,
    direction: direction,
    message: 'Join $labelA and $labelB ${direction.adverb} to spell $wordText',
    highlightedPieceIds: highlightedPieceIds,
  );
}

PuzzleConnectHint? _alignHintForWord({
  required String wordId,
  required _HintContext context,
}) {
  final word = context.metadata.wordById[wordId];
  if (word == null) {
    return null;
  }

  final chunkIds = _sortedChunkIdsForWord(
    wordId: wordId,
    metadata: context.metadata,
  );
  if (chunkIds.length != 1) {
    return null;
  }

  final piece = context.pieceByChunkId[chunkIds.first];
  if (piece == null) {
    return null;
  }

  final direction = word.orientation == WordOrientation.horizontal
      ? ConnectDirection.horizontal
      : ConnectDirection.vertical;

  final label = _pieceLabelForWord(
    piece: piece,
    wordId: wordId,
    metadata: context.metadata,
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
    highlightedPieceIds: {piece.id},
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
