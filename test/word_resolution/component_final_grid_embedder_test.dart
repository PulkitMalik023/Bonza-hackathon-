import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/candidate_word_scanner.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/component_final_grid_embedder.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_runtime_state.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

import 'word_resolution_test_helpers.dart';

void main() {
  test('findValidEmbeddings accepts translated FORK placement', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'FORK',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
    ]);

    final state = rebuildRuntimeBoardState(
      pieces: connectedPiecesAtRow(metadata: metadata, row: 5),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final componentId = state.componentsById.keys.first;
    final component = componentCellsFromRuntimeState(
      state: state,
      componentId: componentId,
    );

    final embeddings = findValidEmbeddings(
      component: component,
      metadata: metadata,
      state: state,
    );

    expect(embeddings, isNotEmpty);
  });

  test('findValidEmbeddings may match APPLEN shape as final-grid subpart', () {
    final metadata = appleNextMetadata();

    final state = rebuildRuntimeBoardState(
      pieces: applenConnectedPieces(metadata),
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final candidates = scanCandidateWordsForWholeBoard(
      state: state,
      metadata: metadata,
    );
    expect(candidates.any((candidate) => candidate.text == 'APPLEN'), isFalse);

    if (candidates.isEmpty) {
      return;
    }

    final component = connectedComponentFromCandidateSeeds(
      candidate: candidates.first,
      state: state,
    );
    final embeddings = findValidEmbeddings(
      component: component,
      metadata: metadata,
      state: state,
    );

    expect(embeddings, isNotEmpty);
  });

  test('wordMatchesEmbedding rejects letter match with wrong final cell mapping', () {
    final metadata = metadataForWords(const [
      PlacedWord(
        word: 'EAST',
        row: 0,
        col: 0,
        direction: WordDirection.horizontal,
      ),
      PlacedWord(
        word: 'LT',
        row: 0,
        col: 3,
        direction: WordDirection.horizontal,
      ),
    ]);

    final eastId = wordIdForText(metadata, 'EAST')!;
    final eastCells = metadata.wordById[eastId]!.cellIds;
    final ltId = wordIdForText(metadata, 'LT')!;
    final ltCells = metadata.wordById[ltId]!.cellIds;

    final state = rebuildRuntimeBoardState(
      pieces: [
        pieceAtFinalCell(
          metadata: metadata,
          finalCellId: eastCells[0],
          boardRow: 10,
          boardCol: 0,
        ),
        pieceAtFinalCell(
          metadata: metadata,
          finalCellId: eastCells[1],
          boardRow: 10,
          boardCol: 1,
        ),
        pieceAtFinalCell(
          metadata: metadata,
          finalCellId: eastCells[2],
          boardRow: 10,
          boardCol: 2,
        ),
        pieceAtFinalCell(
          metadata: metadata,
          finalCellId: ltCells[1],
          boardRow: 10,
          boardCol: 3,
        ),
      ],
      metadata: metadata,
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    final componentId = state.componentsById.keys.first;
    final component = componentCellsFromRuntimeState(
      state: state,
      componentId: componentId,
    );
    final embeddings = findValidEmbeddings(
      component: component,
      metadata: metadata,
      state: state,
    );

    final candidate = candidateFromHorizontalLine(
      state: state,
      row: 10,
      col: 0,
      text: 'EAST',
    );

    expect(embeddings, isEmpty);
    expect(
      wordMatchesEmbedding(
        wordId: eastId,
        candidate: candidate,
        embedding: const ComponentEmbedding(
          finalCellIdByBoardPos: {},
          rowDelta: 0,
          colDelta: 0,
        ),
        metadata: metadata,
      ),
      isFalse,
    );
  });

  test('handlePuzzleStateAfterReconnect skips APPLE on APPLEN board without exact line', () {
    final metadata = appleNextMetadata();

    final result = handlePuzzleStateAfterReconnect(
      pieces: applenConnectedPieces(metadata),
      metadata: metadata,
      movedChunkIds: metadata.chunkById.keys.toSet(),
      solvedWordIds: const {},
      reservedCellIds: const {},
      solvedAssignments: const {},
    );

    expect(result.completedAnswers, isNot(contains('APPLE')));
    expect(result.completedAnswers, isNot(contains('NEXT')));
  });
}

PuzzleLayoutMetadata appleNextMetadata() {
  return metadataForWords(const [
    PlacedWord(
      word: 'APPLE',
      row: 0,
      col: 0,
      direction: WordDirection.horizontal,
    ),
    PlacedWord(
      word: 'NEXT',
      row: 0,
      col: 5,
      direction: WordDirection.horizontal,
    ),
  ]);
}

List<PuzzlePiece> applenConnectedPieces(PuzzleLayoutMetadata metadata) {
  final appleId = wordIdForText(metadata, 'APPLE')!;
  final nextId = wordIdForText(metadata, 'NEXT')!;
  final appleChunkIds = metadata.wordToChunkCoverage[appleId]!
      .map((entry) => entry.chunkId)
      .toSet();
  final nCellId = metadata.wordById[nextId]!.cellIds.first;
  final eCellId = metadata.wordById[appleId]!.cellIds.last;
  final eLayout = metadata.finalCellById[eCellId]!;
  final nChunkId = chunkRefForFinalCell(metadata, nCellId).chunkId;

  final pieces = <PuzzlePiece>[];
  var scatterRow = 6;
  var scatterCol = 0;

  for (final ref in metadata.chunkById.values) {
    if (appleChunkIds.contains(ref.chunkId)) {
      pieces.add(
        PuzzlePiece.fromChunk(
          ref.chunk,
          anchorRow: ref.chunk.solvedMinRow,
          anchorCol: ref.chunk.solvedMinCol,
        ),
      );
      continue;
    }

    if (ref.chunkId == nChunkId) {
      pieces.add(
        pieceAtFinalCell(
          metadata: metadata,
          finalCellId: nCellId,
          boardRow: eLayout.row,
          boardCol: eLayout.col + 1,
        ),
      );
      continue;
    }

    pieces.add(
      PuzzlePiece.fromChunk(
        ref.chunk,
        anchorRow: scatterRow,
        anchorCol: scatterCol,
      ),
    );
    scatterCol = scatterCol + ref.chunk.width.toInt() + 1;
  }

  return piecesMovedOnBoard(pieces);
}

PuzzlePiece pieceAtFinalCell({
  required PuzzleLayoutMetadata metadata,
  required String finalCellId,
  required int boardRow,
  required int boardCol,
}) {
  final ref = chunkRefForFinalCell(metadata, finalCellId);
  for (final entry in ref.chunk.localCells.entries) {
    final localRow = entry.key.row;
    final localCol = entry.key.col;
    final cellId = metadata.finalCellIdForChunkLocal(
      chunkId: ref.chunkId,
      localRow: localRow,
      localCol: localCol,
    );
    if (cellId == finalCellId) {
      return pieceMovedOnBoard(
        PuzzlePiece.fromChunk(
          ref.chunk,
          anchorRow: boardRow - localRow,
          anchorCol: boardCol - localCol,
        ),
      );
    }
  }

  throw StateError('Chunk ${ref.chunkId} does not contain $finalCellId');
}

CandidateWordInstance candidateFromHorizontalLine({
  required PuzzleRuntimeState state,
  required int row,
  required int col,
  required String text,
}) {
  final cells = <OrderedBoardCell>[];
  for (var index = 0; index < text.length; index++) {
    final boardCol = col + index;
    final boardPos = BoardCellPosition(row: row, col: boardCol);
    final entry = state.boardCellMap[boardPos]!;
    cells.add(
      OrderedBoardCell(
        finalCellId: entry.finalCellId,
        boardRow: row,
        boardCol: boardCol,
        chunkId: entry.chunkId,
        componentId: entry.componentId,
        letter: entry.letter,
      ),
    );
  }

  return CandidateWordInstance(
    text: text,
    orientation: 'H',
    orderedBoardCells: cells,
    finalCellIds: cells.map((cell) => cell.finalCellId).toList(),
    chunkIds: cells.map((cell) => cell.chunkId).toSet().toList(),
    componentIds: cells.map((cell) => cell.componentId).toSet().toList(),
  );
}
