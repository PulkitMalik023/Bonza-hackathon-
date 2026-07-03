import '../../data/models/deconstructed_puzzle.dart';
import '../../data/models/placed_word.dart';
import '../../data/models/puzzle_chunk.dart';
import '../../data/models/puzzle_layout.dart';
import '../board_cell_position.dart';
import '../puzzle_board_state.dart';
import 'word_resolution_models.dart';

class PuzzleLayoutMetadata {
  PuzzleLayoutMetadata({
    required this.wordById,
    required this.finalCellById,
    required this.wordCellIndexMap,
    required this.chunkById,
    required this.wordToChunkCoverage,
    required this.targetWordIds,
  });

  final Map<String, FinalLayoutWord> wordById;
  final Map<String, FinalLayoutCell> finalCellById;
  final Map<String, Map<String, int>> wordCellIndexMap;
  final Map<String, PuzzleChunkRef> chunkById;
  final Map<String, List<ChunkCoverageEntry>> wordToChunkCoverage;
  final List<String> targetWordIds;

  String? textForWordId(String wordId) => wordById[wordId]?.text;

  Set<String> get allTargetTexts =>
      wordById.values.map((word) => word.text).toSet();

  factory PuzzleLayoutMetadata.fromLayoutAndDeconstruction({
    required PuzzleLayout layout,
    required DeconstructedPuzzle deconstructed,
  }) {
    final wordById = <String, FinalLayoutWord>{};
    final finalCellById = <String, FinalLayoutCell>{};
    final wordCellIndexMap = <String, Map<String, int>>{};
    final wordToCellIds = <String, List<String>>{};

    for (var index = 0; index < layout.placedWords.length; index++) {
      final placed = layout.placedWords[index];
      final wordId = wordKey(placed, index);
      final text = placed.word.toUpperCase();
      final orientation = placed.direction == WordDirection.horizontal
          ? WordOrientation.horizontal
          : WordOrientation.vertical;
      final cellIds = <String>[];
      wordCellIndexMap[wordId] = {};

      for (var letterIndex = 0; letterIndex < text.length; letterIndex++) {
        final position = _layoutPositionForLetter(placed, letterIndex);
        final cellId = finalCellIdForLayout(position.row, position.col);
        cellIds.add(cellId);
        wordCellIndexMap[wordId]![cellId] = letterIndex;

        final existingWordIds = finalCellById[cellId]?.wordIds ?? const [];
        finalCellById[cellId] = FinalLayoutCell(
          id: cellId,
          row: position.row,
          col: position.col,
          letter: text[letterIndex],
          wordIds: [...existingWordIds, wordId],
        );
      }

      wordToCellIds[wordId] = cellIds;
      wordById[wordId] = FinalLayoutWord(
        wordId: wordId,
        text: text,
        cellIds: cellIds,
        orientation: orientation,
      );
    }

    final chunkById = <String, PuzzleChunkRef>{};
    final wordToChunkCoverage = <String, List<ChunkCoverageEntry>>{
      for (final wordId in wordById.keys) wordId: <ChunkCoverageEntry>[],
    };

    for (final chunk in deconstructed.chunks) {
      final chunkFinalCellIds = <String>[];
      for (final entry in chunk.solvedCells.entries) {
        chunkFinalCellIds.add(finalCellIdForLayout(entry.key.row, entry.key.col));
      }

      chunkById[chunk.id] = PuzzleChunkRef(
        chunkId: chunk.id,
        finalCellIds: chunkFinalCellIds,
        chunk: chunk,
      );

      for (final wordId in wordById.keys) {
        final wordCellIds = wordToCellIds[wordId]!;
        final overlap = wordCellIds
            .where((cellId) => chunkFinalCellIds.contains(cellId))
            .toList();
        if (overlap.isEmpty) {
          continue;
        }
        wordToChunkCoverage[wordId] = [
          ...wordToChunkCoverage[wordId]!,
          ChunkCoverageEntry(
            chunkId: chunk.id,
            cellIdsForThisWord: overlap,
          ),
        ];
      }
    }

    return PuzzleLayoutMetadata(
      wordById: wordById,
      finalCellById: finalCellById,
      wordCellIndexMap: wordCellIndexMap,
      chunkById: chunkById,
      wordToChunkCoverage: wordToChunkCoverage,
      targetWordIds: layout.placedWords
          .asMap()
          .entries
          .map((entry) => wordKey(entry.value, entry.key))
          .toList(),
    );
  }

  String? finalCellIdForChunkLocal({
    required String chunkId,
    required int localRow,
    required int localCol,
  }) {
    final chunkRef = chunkById[chunkId];
    if (chunkRef == null) {
      return null;
    }

    final chunk = chunkRef.chunk;
    final solvedPosition = BoardCellPosition(
      row: chunk.solvedMinRow + localRow,
      col: chunk.solvedMinCol + localCol,
    );

    if (!chunk.solvedCells.containsKey(solvedPosition)) {
      return null;
    }

    return finalCellIdForLayout(solvedPosition.row, solvedPosition.col);
  }
}

class PuzzleChunkRef {
  const PuzzleChunkRef({
    required this.chunkId,
    required this.finalCellIds,
    required this.chunk,
  });

  final String chunkId;
  final List<String> finalCellIds;
  final PuzzleChunk chunk;
}

BoardCellPosition _layoutPositionForLetter(PlacedWord placed, int letterIndex) {
  switch (placed.direction) {
    case WordDirection.horizontal:
      return BoardCellPosition(row: placed.row, col: placed.col + letterIndex);
    case WordDirection.vertical:
      return BoardCellPosition(row: placed.row + letterIndex, col: placed.col);
  }
}

List<String> getTargetWordIdsMatchingText(String text, PuzzleLayoutMetadata meta) {
  final normalized = text.toUpperCase();
  return meta.wordById.values
      .where((word) => word.text == normalized)
      .map((word) => word.wordId)
      .toList();
}
