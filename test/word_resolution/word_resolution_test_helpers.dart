import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/placed_word.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/core/constants/board_constants.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_service.dart';

PuzzleLayoutMetadata metadataForWords(List<PlacedWord> words) {
  final layout = PuzzleLayout.fromPlacedWords(words);
  final deconstructed = PuzzleDeconstructor().build(layout);
  return PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
    layout: layout,
    deconstructed: deconstructed,
  );
}

const _testTraySpawnRow = 14;
const _testTraySpawnCol = 0;

PuzzlePiece pieceMovedOnBoard(
  PuzzlePiece piece, {
  int spawnAnchorRow = _testTraySpawnRow,
  int spawnAnchorCol = _testTraySpawnCol,
}) {
  return PuzzlePiece(
    id: piece.id,
    chunkId: piece.chunkId,
    anchorRow: piece.anchorRow,
    anchorCol: piece.anchorCol,
    spawnAnchorRow: spawnAnchorRow,
    spawnAnchorCol: spawnAnchorCol,
    cells: piece.cells,
    isCompletedWordGroup: piece.isCompletedWordGroup,
    completedWordKey: piece.completedWordKey,
    completedAnswers: piece.completedAnswers,
  );
}

List<PuzzlePiece> piecesMovedOnBoard(List<PuzzlePiece> pieces) {
  return pieces.map(pieceMovedOnBoard).toList();
}

List<PuzzlePiece> piecesAtLayoutPositions(PuzzleLayoutMetadata metadata) {
  return piecesMovedOnBoard(
    metadata.chunkById.values
        .map(
          (ref) => PuzzlePiece.fromChunk(
            ref.chunk,
            anchorRow: ref.chunk.solvedMinRow,
            anchorCol: ref.chunk.solvedMinCol,
          ),
        )
        .toList(),
  );
}

List<PuzzlePiece> connectedPiecesAtRow({
  required PuzzleLayoutMetadata metadata,
  required int row,
}) {
  final pieces = <PuzzlePiece>[];
  var col = 0;
  for (final chunkId in metadata.chunkById.keys) {
    final chunk = metadata.chunkById[chunkId]!.chunk;
    pieces.add(
      PuzzlePiece.fromChunk(
        chunk,
        anchorRow: row,
        anchorCol: col,
      ),
    );
    col += chunk.width;
  }
  return piecesMovedOnBoard(pieces);
}

List<PuzzlePiece> connectedCrosswordPieces({
  required PuzzleLayoutMetadata metadata,
  int boardRowOffset = 0,
  int boardColOffset = 0,
}) {
  final pieces = <PuzzlePiece>[];

  for (final ref in metadata.chunkById.values) {
    final chunk = ref.chunk;
    final firstCell = chunk.localCells.entries.first;
    final localRow = firstCell.key.row;
    final localCol = firstCell.key.col;
    final layoutRow = chunk.solvedMinRow + localRow;
    final layoutCol = chunk.solvedMinCol + localCol;

    pieces.add(
      PuzzlePiece.fromChunk(
        chunk,
        anchorRow: layoutRow + boardRowOffset - localRow,
        anchorCol: layoutCol + boardColOffset - localCol,
      ),
    );
  }

  return piecesMovedOnBoard(pieces);
}

List<PuzzlePiece> fruitSaladBananaLineAtRow(
  PuzzleLayoutMetadata metadata, {
  required int row,
  int startCol = 0,
}) {
  const layoutBananaRow = 2;
  const layoutBananaStartCol = 0;
  final rowOffset = row - layoutBananaRow;
  final colOffset = startCol - layoutBananaStartCol;

  return piecesMovedOnBoard([
    for (final chunkId in chunkIdsCoveringWord(metadata, 'BANANA'))
      if (metadata.chunkById[chunkId] != null)
        PuzzlePiece.fromChunk(
          metadata.chunkById[chunkId]!.chunk,
          anchorRow:
              metadata.chunkById[chunkId]!.chunk.solvedMinRow + rowOffset,
          anchorCol:
              metadata.chunkById[chunkId]!.chunk.solvedMinCol + colOffset,
        ),
  ]);
}

List<PuzzlePiece> fruitSaladGappedBananaLineAtRow(
  PuzzleLayoutMetadata metadata, {
  required int row,
  int startCol = 0,
}) {
  const layoutBananaRow = 2;
  const layoutBananaStartCol = 0;
  const layoutBananaSplitCol = 3;
  final rowOffset = row - layoutBananaRow;
  final colOffset = startCol - layoutBananaStartCol;

  return piecesMovedOnBoard([
    for (final chunkId in chunkIdsCoveringWord(metadata, 'BANANA'))
      if (metadata.chunkById[chunkId] != null)
        PuzzlePiece.fromChunk(
          metadata.chunkById[chunkId]!.chunk,
          anchorRow:
              metadata.chunkById[chunkId]!.chunk.solvedMinRow + rowOffset,
          anchorCol: metadata.chunkById[chunkId]!.chunk.solvedMinCol +
              colOffset +
              (metadata.chunkById[chunkId]!.chunk.solvedMinCol >=
                      layoutBananaSplitCol
                  ? 1
                  : 0),
        ),
  ]);
}

PuzzleLayoutMetadata cutleryMetadata() {
  return metadataForWords(const [
    PlacedWord(
      word: 'SPOON',
      row: 0,
      col: 1,
      direction: WordDirection.vertical,
    ),
    PlacedWord(
      word: 'FORK',
      row: 2,
      col: 0,
      direction: WordDirection.horizontal,
    ),
    PlacedWord(
      word: 'KNIFE',
      row: 4,
      col: 0,
      direction: WordDirection.horizontal,
    ),
  ]);
}

String? knifeWordId(PuzzleLayoutMetadata metadata) {
  for (final wordId in metadata.targetWordIds) {
    if (metadata.wordById[wordId]?.text == 'KNIFE') {
      return wordId;
    }
  }
  return null;
}

Set<String> knifeChunkIds(PuzzleLayoutMetadata metadata) {
  final knifeId = knifeWordId(metadata);
  if (knifeId == null) {
    return const {};
  }

  return metadata.wordToChunkCoverage[knifeId]
          ?.map((entry) => entry.chunkId)
          .toSet() ??
      const {};
}

PuzzlePiece _pieceWithFinalCellAt({
  required PuzzleLayoutMetadata metadata,
  required PuzzleChunkRef ref,
  required String finalCellId,
  required int boardRow,
  required int boardCol,
}) {
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

/// All cutlery letters on board; only KNIFE chunks connected horizontally.
/// SPOON/FORK letters remain scattered (inventory-satisfiable but no contiguous candidate).
List<PuzzlePiece> cutleryWithKnifeConnectedOnly(PuzzleLayoutMetadata metadata) {
  final knifeId = knifeWordId(metadata)!;
  final knifeCells = metadata.wordById[knifeId]!.cellIds;
  final knifeChunks = knifeChunkIds(metadata);
  const knifeRow = 4;
  const knifeStartCol = 0;

  final pieces = <PuzzlePiece>[];
  var scatterRow = 0;
  var scatterCol = 5;

  for (final ref in metadata.chunkById.values) {
    if (knifeChunks.contains(ref.chunkId)) {
      final knifeCellForChunk = ref.finalCellIds
          .firstWhere((cellId) => knifeCells.contains(cellId));
      final cellIndex = knifeCells.indexOf(knifeCellForChunk);
      pieces.add(
        _pieceWithFinalCellAt(
          metadata: metadata,
          ref: ref,
          finalCellId: knifeCellForChunk,
          boardRow: knifeRow,
          boardCol: knifeStartCol + cellIndex,
        ),
      );
      continue;
    }

    if (scatterCol + ref.chunk.width > BoardConstants.kPlayGridCols) {
      scatterCol = 5;
      scatterRow += ref.chunk.height + 1;
    }

    pieces.add(
      PuzzlePiece.fromChunk(
        ref.chunk,
        anchorRow: scatterRow,
        anchorCol: scatterCol,
      ),
    );
    scatterCol += ref.chunk.width + 1;
  }

  return piecesMovedOnBoard(pieces);
}

/// All cutlery letters on board in crossword shape (all words can be accepted).
List<PuzzlePiece> cutleryCrosswordConnected(PuzzleLayoutMetadata metadata) {
  return connectedCrosswordPieces(metadata: metadata);
}

PuzzleLayoutMetadata directionsMetadata() {
  final generator = PuzzleLayoutGenerator();
  final layouts = generator.generateAllLayouts(
    ['NORTH', 'SOUTH', 'EAST', 'WEST'],
  );
  final layout = layouts.first;
  final deconstructed = PuzzleDeconstructor().build(layout);
  return PuzzleLayoutMetadata.fromLayoutAndDeconstruction(
    layout: layout,
    deconstructed: deconstructed,
  );
}

String? wordIdForText(PuzzleLayoutMetadata metadata, String text) {
  final normalized = text.toUpperCase();
  for (final wordId in metadata.targetWordIds) {
    if (metadata.wordById[wordId]?.text == normalized) {
      return wordId;
    }
  }
  return null;
}

String? sharedCellBetween(
  PuzzleLayoutMetadata metadata,
  String wordTextA,
  String wordTextB,
) {
  final wordIdA = wordIdForText(metadata, wordTextA);
  final wordIdB = wordIdForText(metadata, wordTextB);
  if (wordIdA == null || wordIdB == null) {
    return null;
  }

  final cellsA = metadata.wordById[wordIdA]!.cellIds.toSet();
  final cellsB = metadata.wordById[wordIdB]!.cellIds.toSet();
  final shared = cellsA.intersection(cellsB);
  if (shared.length != 1) {
    return null;
  }
  return shared.single;
}

WordResolutionResult completeNorthOnlyInDirections({
  required PuzzleLayoutMetadata metadata,
  required List<PuzzlePiece> pieces,
}) {
  final northId = wordIdForText(metadata, 'NORTH')!;
  final northCells = metadata.wordById[northId]!.cellIds.toSet();
  final assignment = WordAssignmentOption(
    wordId: northId,
    reservedFinalCellIds: northCells.toList(),
    contributingFinalCellIds: northCells.toList(),
    contributingChunkIds: metadata.chunkById.keys.toList(),
    contributingComponentIds: const ['cmp_directions'],
    assignmentType: AssignmentType.flexibleIndependent,
    debugReason: 'test_north_only',
  );
  final cluster = MoveCluster(
    moveComponentId: 'cmp_directions',
    assignmentWordIds: [northId],
    reservedCellIds: northCells,
    contributingComponentIds: {'cmp_directions'},
    contributingChunkIds: metadata.chunkById.keys.toSet(),
  );

  final groupedPieces = animateSolvedClusters(
    moveClusters: [cluster],
    pieces: pieces,
    metadata: metadata,
    acceptedAssignments: [assignment],
  );

  return WordResolutionResult(
    pieces: groupedPieces,
    newlySolvedWordIds: {northId},
    solvedWordIds: {northId},
    reservedCellIds: northCells,
    solvedAssignments: {
      northId: SolvedAssignment(
        wordId: northId,
        assignedCellIds: northCells,
        moveComponentId: cluster.moveComponentId,
      ),
    },
    completedAnswers: {'NORTH'},
    puzzleComplete: false,
  );
}

WordResolutionResult completeSouthOnlyInDirections({
  required PuzzleLayoutMetadata metadata,
  required List<PuzzlePiece> pieces,
}) {
  final southId = wordIdForText(metadata, 'SOUTH')!;
  final southCells = metadata.wordById[southId]!.cellIds.toSet();
  final assignment = WordAssignmentOption(
    wordId: southId,
    reservedFinalCellIds: southCells.toList(),
    contributingFinalCellIds: southCells.toList(),
    contributingChunkIds: metadata.chunkById.keys.toList(),
    contributingComponentIds: const ['cmp_directions'],
    assignmentType: AssignmentType.flexibleIndependent,
    debugReason: 'test_south_only',
  );
  final cluster = MoveCluster(
    moveComponentId: 'cmp_directions',
    assignmentWordIds: [southId],
    reservedCellIds: southCells,
    contributingComponentIds: {'cmp_directions'},
    contributingChunkIds: metadata.chunkById.keys.toSet(),
  );

  final groupedPieces = animateSolvedClusters(
    moveClusters: [cluster],
    pieces: pieces,
    metadata: metadata,
    acceptedAssignments: [assignment],
  );

  return WordResolutionResult(
    pieces: groupedPieces,
    newlySolvedWordIds: {southId},
    solvedWordIds: {southId},
    reservedCellIds: southCells,
    solvedAssignments: {
      southId: SolvedAssignment(
        wordId: southId,
        assignedCellIds: southCells,
        moveComponentId: cluster.moveComponentId,
      ),
    },
    completedAnswers: {'SOUTH'},
    puzzleComplete: false,
  );
}

WordResolutionResult completeEastOnlyInDirections({
  required PuzzleLayoutMetadata metadata,
  required List<PuzzlePiece> pieces,
}) {
  final eastId = wordIdForText(metadata, 'EAST')!;
  final eastCells = metadata.wordById[eastId]!.cellIds.toSet();
  final assignment = WordAssignmentOption(
    wordId: eastId,
    reservedFinalCellIds: eastCells.toList(),
    contributingFinalCellIds: eastCells.toList(),
    contributingChunkIds: metadata.chunkById.keys.toList(),
    contributingComponentIds: const ['cmp_directions'],
    assignmentType: AssignmentType.flexibleIndependent,
    debugReason: 'test_east_only',
  );
  final cluster = MoveCluster(
    moveComponentId: 'cmp_directions',
    assignmentWordIds: [eastId],
    reservedCellIds: eastCells,
    contributingComponentIds: {'cmp_directions'},
    contributingChunkIds: metadata.chunkById.keys.toSet(),
  );

  final groupedPieces = animateSolvedClusters(
    moveClusters: [cluster],
    pieces: pieces,
    metadata: metadata,
    acceptedAssignments: [assignment],
  );

  return WordResolutionResult(
    pieces: groupedPieces,
    newlySolvedWordIds: {eastId},
    solvedWordIds: {eastId},
    reservedCellIds: eastCells,
    solvedAssignments: {
      eastId: SolvedAssignment(
        wordId: eastId,
        assignedCellIds: eastCells,
        moveComponentId: cluster.moveComponentId,
      ),
    },
    completedAnswers: {'EAST'},
    puzzleComplete: false,
  );
}

PuzzleChunkRef chunkRefForFinalCell(
  PuzzleLayoutMetadata metadata,
  String finalCellId,
) {
  for (final ref in metadata.chunkById.values) {
    if (ref.finalCellIds.contains(finalCellId)) {
      return ref;
    }
  }

  throw StateError('No chunk contains $finalCellId');
}

Set<String> chunkIdsForFinalCells(
  PuzzleLayoutMetadata metadata,
  Iterable<String> finalCellIds,
) {
  return {
    for (final cellId in finalCellIds)
      chunkRefForFinalCell(metadata, cellId).chunkId,
  };
}

/// TH + EAS/ST layout used to complete EAST before stacking WE for WEST.
List<PuzzlePiece> directionsPiecesForEastFirstWestTest(
  PuzzleLayoutMetadata metadata,
) {
  final eastId = wordIdForText(metadata, 'EAST')!;
  final eastCells = metadata.wordById[eastId]!.cellIds;
  final westId = wordIdForText(metadata, 'WEST')!;
  final westCells = metadata.wordById[westId]!.cellIds;
  final southId = wordIdForText(metadata, 'SOUTH')!;
  final southCells = metadata.wordById[southId]!.cellIds;

  final placedChunkIds = <String>{};
  final pieces = <PuzzlePiece>[
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, southCells[3]),
      finalCellId: southCells[3],
      boardRow: 2,
      boardCol: 0,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, southCells[4]),
      finalCellId: southCells[4],
      boardRow: 3,
      boardCol: 0,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, eastCells[0]),
      finalCellId: eastCells[0],
      boardRow: 3,
      boardCol: 2,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, eastCells[1]),
      finalCellId: eastCells[1],
      boardRow: 3,
      boardCol: 3,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, eastCells[2]),
      finalCellId: eastCells[2],
      boardRow: 3,
      boardCol: 4,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, westCells[2]),
      finalCellId: westCells[2],
      boardRow: 2,
      boardCol: 5,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, westCells[3]),
      finalCellId: westCells[3],
      boardRow: 3,
      boardCol: 5,
    ),
  ];

  for (final piece in pieces) {
    placedChunkIds.add(piece.chunkId);
  }

  var scatterRow = 10;
  for (final ref in metadata.chunkById.values) {
    if (placedChunkIds.contains(ref.chunkId)) {
      continue;
    }

    final anchorCell = ref.finalCellIds.first;
    pieces.add(
      _pieceWithFinalCellAt(
        metadata: metadata,
        ref: ref,
        finalCellId: anchorCell,
        boardRow: scatterRow,
        boardCol: 0,
      ),
    );
    placedChunkIds.add(ref.chunkId);
    scatterRow += ref.chunk.height + 2;
  }

  return piecesMovedOnBoard(pieces);
}

Set<String> eastFirstWestMovedChunkIds(PuzzleLayoutMetadata metadata) {
  final eastId = wordIdForText(metadata, 'EAST')!;
  final eastCells = metadata.wordById[eastId]!.cellIds;
  final southId = wordIdForText(metadata, 'SOUTH')!;
  final southCells = metadata.wordById[southId]!.cellIds;
  final westId = wordIdForText(metadata, 'WEST')!;
  final westCells = metadata.wordById[westId]!.cellIds;

  return chunkIdsForFinalCells(metadata, [
    southCells[3],
    southCells[4],
    ...eastCells,
    westCells[2],
    westCells[3],
  ]);
}

List<PuzzlePiece> directionsPiecesForEastWithAdjacentH(
  PuzzleLayoutMetadata metadata,
) {
  final northId = wordIdForText(metadata, 'NORTH')!;
  final hCellId = metadata.wordById[northId]!.cellIds.firstWhere(
    (cellId) => metadata.finalCellById[cellId]!.letter == 'H',
  );
  final hRef = chunkRefForFinalCell(metadata, hCellId);
  final eastId = wordIdForText(metadata, 'EAST')!;
  final eLayout =
      metadata.finalCellById[metadata.wordById[eastId]!.cellIds.first]!;

  final pieces = directionsPiecesForEastFirstWestTest(metadata)
      .where((piece) => piece.chunkId != hRef.chunkId)
      .toList();

  pieces.add(
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: hRef,
      finalCellId: hCellId,
      boardRow: eLayout.row - 1,
      boardCol: eLayout.col,
    ),
  );

  return piecesMovedOnBoard(pieces);
}

List<PuzzlePiece> directionsPiecesWithWestWeAboveCompletedEast(
  List<PuzzlePiece> pieces,
  PuzzleLayoutMetadata metadata,
) {
  final westId = wordIdForText(metadata, 'WEST')!;
  final westCells = metadata.wordById[westId]!.cellIds;
  final westW = chunkRefForFinalCell(metadata, westCells[0]);
  final westE = chunkRefForFinalCell(metadata, westCells[1]);
  final westWLayout = metadata.finalCellById[westCells[0]]!;
  final westELayout = metadata.finalCellById[westCells[1]]!;

  final updated = <PuzzlePiece>[
    for (final piece in pieces)
      if (piece.isCompletedWordGroup)
        piece
      else if (piece.chunkId != westW.chunkId &&
          piece.chunkId != westE.chunkId)
        piece,
  ];

  updated.add(
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: westW,
      finalCellId: westCells[0],
      boardRow: westWLayout.row,
      boardCol: westWLayout.col,
    ),
  );

  if (westE.chunkId != westW.chunkId) {
    updated.add(
      _pieceWithFinalCellAt(
        metadata: metadata,
        ref: westE,
        finalCellId: westCells[1],
        boardRow: westELayout.row,
        boardCol: westELayout.col,
      ),
    );
  }

  return piecesMovedOnBoard(updated);
}

/// Vertical WEST column plus horizontal E-A connected to shared T.
List<PuzzlePiece> directionsPiecesForWestFirstEastTest(
  PuzzleLayoutMetadata metadata,
) {
  final eastId = wordIdForText(metadata, 'EAST')!;
  final eastCells = metadata.wordById[eastId]!.cellIds;
  final westId = wordIdForText(metadata, 'WEST')!;
  final westCells = metadata.wordById[westId]!.cellIds;

  final placedChunkIds = <String>{};
  final pieces = <PuzzlePiece>[
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, westCells[0]),
      finalCellId: westCells[0],
      boardRow: 0,
      boardCol: 5,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, westCells[1]),
      finalCellId: westCells[1],
      boardRow: 1,
      boardCol: 5,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, westCells[2]),
      finalCellId: westCells[2],
      boardRow: 2,
      boardCol: 5,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, westCells[3]),
      finalCellId: westCells[3],
      boardRow: 3,
      boardCol: 5,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, eastCells[0]),
      finalCellId: eastCells[0],
      boardRow: 3,
      boardCol: 2,
    ),
    _pieceWithFinalCellAt(
      metadata: metadata,
      ref: chunkRefForFinalCell(metadata, eastCells[1]),
      finalCellId: eastCells[1],
      boardRow: 3,
      boardCol: 3,
    ),
  ];

  for (final piece in pieces) {
    placedChunkIds.add(piece.chunkId);
  }

  var scatterRow = 10;
  for (final ref in metadata.chunkById.values) {
    if (placedChunkIds.contains(ref.chunkId)) {
      continue;
    }

    final anchorCell = ref.finalCellIds.first;
    pieces.add(
      _pieceWithFinalCellAt(
        metadata: metadata,
        ref: ref,
        finalCellId: anchorCell,
        boardRow: scatterRow,
        boardCol: 0,
      ),
    );
    placedChunkIds.add(ref.chunkId);
    scatterRow += ref.chunk.height + 2;
  }

  return piecesMovedOnBoard(pieces);
}

List<PuzzlePiece> directionsPiecesForSouthAfterEast(
  List<PuzzlePiece> piecesAfterEast,
  PuzzleLayoutMetadata metadata,
) {
  final southId = wordIdForText(metadata, 'SOUTH')!;
  final southCells = metadata.wordById[southId]!.cellIds;

  final updated = <PuzzlePiece>[];
  for (final piece in piecesAfterEast) {
    if (piece.isCompletedWordGroup) {
      updated.add(piece);
      continue;
    }

    final southCellsInChunk = metadata.chunkById[piece.chunkId]!.finalCellIds
        .where((cellId) => southCells.contains(cellId))
        .toList();
    if (southCellsInChunk.isEmpty) {
      updated.add(piece);
      continue;
    }

    final cellId = southCellsInChunk.first;
    final cellIndex = southCells.indexOf(cellId);
    if (cellIndex == 0) {
      updated.add(piece);
      continue;
    }

    updated.add(
      _pieceWithFinalCellAt(
        metadata: metadata,
        ref: metadata.chunkById[piece.chunkId]!,
        finalCellId: cellId,
        boardRow: 3 + cellIndex,
        boardCol: 4,
      ),
    );
  }

  return piecesMovedOnBoard(updated);
}

String? forkWordId(PuzzleLayoutMetadata metadata) {
  for (final wordId in metadata.targetWordIds) {
    if (metadata.wordById[wordId]?.text == 'FORK') {
      return wordId;
    }
  }
  return null;
}

Set<String> forkChunkIds(PuzzleLayoutMetadata metadata) {
  final forkId = forkWordId(metadata);
  if (forkId == null) {
    return const {};
  }

  return metadata.wordToChunkCoverage[forkId]
          ?.map((entry) => entry.chunkId)
          .toSet() ??
      const {};
}

List<PuzzlePiece> cutleryWithForkConnectedOnly(PuzzleLayoutMetadata metadata) {
  final forkId = forkWordId(metadata)!;
  final forkCells = metadata.wordById[forkId]!.cellIds;
  final forkChunks = forkChunkIds(metadata);
  const forkRow = 2;
  const forkStartCol = 0;

  final pieces = <PuzzlePiece>[];
  var scatterRow = 6;
  var scatterCol = 0;

  for (final ref in metadata.chunkById.values) {
    if (forkChunks.contains(ref.chunkId)) {
      final forkCellForChunk = ref.finalCellIds
          .firstWhere((cellId) => forkCells.contains(cellId));
      final cellIndex = forkCells.indexOf(forkCellForChunk);
      pieces.add(
        _pieceWithFinalCellAt(
          metadata: metadata,
          ref: ref,
          finalCellId: forkCellForChunk,
          boardRow: forkRow,
          boardCol: forkStartCol + cellIndex,
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
    scatterRow += ref.chunk.height + 3;
    scatterCol += ref.chunk.width + 1;
  }

  return piecesMovedOnBoard(pieces);
}

WordResolutionResult completeForkOnlyInCutlery({
  required PuzzleLayoutMetadata metadata,
  required List<PuzzlePiece> pieces,
}) {
  final forkId = forkWordId(metadata)!;
  final forkCells = metadata.wordById[forkId]!.cellIds.toSet();
  final withoutFork = pieces
      .where((piece) => !forkChunkIds(metadata).contains(piece.chunkId))
      .toList();

  var groupMinRow = forkCells
      .map((cellId) => metadata.finalCellById[cellId]!.row)
      .reduce((a, b) => a < b ? a : b);
  var groupMinCol = forkCells
      .map((cellId) => metadata.finalCellById[cellId]!.col)
      .reduce((a, b) => a < b ? a : b);

  final groupCells = <PieceCell>[];
  for (final cellId in forkCells) {
    final cell = metadata.finalCellById[cellId]!;
    groupCells.add(
      PieceCell(
        letter: cell.letter,
        rowOffset: cell.row - groupMinRow,
        colOffset: cell.col - groupMinCol,
      ),
    );
  }

  final groupedPieces = [
    ...withoutFork,
    PuzzlePiece.completedClusterGroup(
      clusterKey: 'fork_test',
      anchorRow: groupMinRow,
      anchorCol: groupMinCol,
      cells: groupCells,
      completedAnswers: {'FORK'},
    ),
  ];

  return WordResolutionResult(
    pieces: groupedPieces,
    newlySolvedWordIds: {forkId},
    solvedWordIds: {forkId},
    reservedCellIds: forkCells,
    solvedAssignments: {
      forkId: SolvedAssignment(
        wordId: forkId,
        assignedCellIds: forkCells,
        moveComponentId: 'cmp_fork_test',
      ),
    },
    completedAnswers: {'FORK'},
    puzzleComplete: false,
  );
}

List<PuzzlePiece> cutleryKnifePiecesAfterForkCompleted(
  List<PuzzlePiece> forkPieces,
  PuzzleLayoutMetadata metadata,
) {
  final knifeId = knifeWordId(metadata)!;
  final knifeCells = metadata.wordById[knifeId]!.cellIds;
  const knifeRow = 4;
  const knifeStartCol = 0;

  final updated = <PuzzlePiece>[];
  for (final piece in forkPieces) {
    if (piece.isCompletedWordGroup) {
      updated.add(piece);
      continue;
    }

    if (!knifeChunkIds(metadata).contains(piece.chunkId)) {
      updated.add(piece);
      continue;
    }

    final knifeCellForChunk = metadata.chunkById[piece.chunkId]!
        .finalCellIds
        .firstWhere((cellId) => knifeCells.contains(cellId));
    final cellIndex = knifeCells.indexOf(knifeCellForChunk);

    updated.add(
      _pieceWithFinalCellAt(
        metadata: metadata,
        ref: metadata.chunkById[piece.chunkId]!,
        finalCellId: knifeCellForChunk,
        boardRow: knifeRow,
        boardCol: knifeStartCol + cellIndex,
      ),
    );
  }

  return piecesMovedOnBoard(updated);
}

bool completedGroupContainsFinalCell({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required String finalCellId,
}) {
  for (final piece in pieces) {
    if (!piece.isCompletedWordGroup) {
      continue;
    }

    for (final cell in piece.cells) {
      final cellId = metadata.finalCellIdForChunkLocal(
        chunkId: piece.chunkId,
        localRow: cell.rowOffset,
        localCol: cell.colOffset,
      );
      if (cellId == finalCellId) {
        return true;
      }
    }
  }

  return false;
}

int totalCompletedGroupCellCount(List<PuzzlePiece> pieces) {
  return pieces
      .where((piece) => piece.isCompletedWordGroup)
      .fold<int>(0, (sum, piece) => sum + piece.cells.length);
}

bool activePiecesContainFinalCell({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required String finalCellId,
}) {
  for (final piece in pieces) {
    if (piece.isCompletedWordGroup) {
      continue;
    }

    for (final cell in piece.cells) {
      final cellId = metadata.finalCellIdForChunkLocal(
        chunkId: piece.chunkId,
        localRow: cell.rowOffset,
        localCol: cell.colOffset,
      );
      if (cellId == finalCellId) {
        return true;
      }
    }
  }

  return false;
}

PuzzleLayoutMetadata fruitSaladMetadata() {
  return metadataForWords(const [
    PlacedWord(
      word: 'BANANA',
      row: 2,
      col: 0,
      direction: WordDirection.horizontal,
    ),
    PlacedWord(
      word: 'ORANGE',
      row: 0,
      col: 1,
      direction: WordDirection.vertical,
    ),
    PlacedWord(
      word: 'APPLE',
      row: 2,
      col: 3,
      direction: WordDirection.vertical,
    ),
  ]);
}

List<String> chunkIdsCoveringWord(
  PuzzleLayoutMetadata metadata,
  String wordText,
) {
  final wordId = wordIdForText(metadata, wordText);
  if (wordId == null) {
    return const [];
  }

  return metadata.wordToChunkCoverage[wordId]
          ?.map((entry) => entry.chunkId)
          .toSet()
          .toList() ??
      const [];
}

List<PuzzlePiece> piecesForChunkIds(
  PuzzleLayoutMetadata metadata,
  Iterable<String> chunkIds,
) {
  return piecesMovedOnBoard([
    for (final chunkId in chunkIds)
      if (metadata.chunkById[chunkId] != null)
        PuzzlePiece.fromChunk(
          metadata.chunkById[chunkId]!.chunk,
          anchorRow: metadata.chunkById[chunkId]!.chunk.solvedMinRow,
          anchorCol: metadata.chunkById[chunkId]!.chunk.solvedMinCol,
        ),
  ]);
}

List<PuzzlePiece> fruitSaladBananaOnlyPieces(PuzzleLayoutMetadata metadata) {
  return piecesForChunkIds(
    metadata,
    chunkIdsCoveringWord(metadata, 'BANANA'),
  );
}

List<PuzzlePiece> fruitSaladAllPiecesAtLayout(PuzzleLayoutMetadata metadata) {
  return piecesAtLayoutPositions(metadata);
}
