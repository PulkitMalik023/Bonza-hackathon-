import '../board_cell_position.dart';
import '../board_line_word_detector.dart';
import 'puzzle_layout_metadata.dart';
import 'puzzle_runtime_state.dart';
import 'word_assignment.dart';
import 'word_resolution_logger.dart';
import 'word_resolution_models.dart';

Map<BoardCellPosition, String> letterMapFromRuntimeState(
  PuzzleRuntimeState state,
) {
  final board = <BoardCellPosition, String>{};
  for (final entry in state.boardCellMap.entries) {
    board[entry.key] = entry.value.letter;
  }
  for (final placed in state.placedCellsByFinalId.values) {
    board[BoardCellPosition(row: placed.boardRow, col: placed.boardCol)] =
        placed.letter;
  }
  return board;
}

CandidateWordInstance? getHorizontalWordAtCell({
  required int row,
  required int col,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final board = letterMapFromRuntimeState(state);
  final line = getHorizontalLineFromCell(row, col, board);
  if (line == null) {
    return null;
  }
  return _candidateFromLine(
    line: line,
    orientation: 'H',
    state: state,
    metadata: metadata,
  );
}

CandidateWordInstance? getVerticalWordAtCell({
  required int row,
  required int col,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final board = letterMapFromRuntimeState(state);
  final line = getVerticalLineFromCell(row, col, board);
  if (line == null) {
    return null;
  }
  return _candidateFromLine(
    line: line,
    orientation: 'V',
    state: state,
    metadata: metadata,
  );
}

CandidateWordInstance? _candidateFromLine({
  required FormedBoardLine line,
  required String orientation,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final orderedBoardCells = <OrderedBoardCell>[];
  final finalCellIds = <String>[];
  final chunkIds = <String>{};
  final componentIds = <String>{};

  for (final position in line.cellsInReadOrder) {
    final boardEntry = state.boardCellMap[position];
    final placed = state.placedCellsByFinalId.values.firstWhere(
      (cell) => cell.boardRow == position.row && cell.boardCol == position.col,
      orElse: () => const PlacedRuntimeCell(
        finalCellId: '',
        letter: '',
        boardRow: -1,
        boardCol: -1,
        chunkId: '',
        componentId: '',
      ),
    );

    if (placed.finalCellId.isEmpty && boardEntry == null) {
      return null;
    }

    var resolvedFinalCellId = placed.finalCellId.isNotEmpty
        ? placed.finalCellId
        : boardEntry!.finalCellId;
    var resolvedLetter = placed.finalCellId.isNotEmpty
        ? placed.letter
        : boardEntry!.letter;
    var resolvedChunkId =
        placed.finalCellId.isNotEmpty ? placed.chunkId : boardEntry!.chunkId;
    var resolvedComponentId = placed.finalCellId.isNotEmpty
        ? placed.componentId
        : boardEntry!.componentId;

    if (resolvedFinalCellId.startsWith('completed_')) {
      final sharedCell = _resolveSharedIntersectionAtCompletedCell(
        position: position,
        letter: resolvedLetter,
        state: state,
        metadata: metadata,
      );
      if (sharedCell == null) {
        return null;
      }
      resolvedFinalCellId = sharedCell.finalCellId;
      resolvedLetter = sharedCell.letter;
      resolvedChunkId = sharedCell.chunkId;
      resolvedComponentId = sharedCell.componentId;
    }

    orderedBoardCells.add(
      OrderedBoardCell(
        finalCellId: resolvedFinalCellId,
        boardRow: position.row,
        boardCol: position.col,
        chunkId: resolvedChunkId,
        componentId: resolvedComponentId,
        letter: resolvedLetter,
      ),
    );
    finalCellIds.add(resolvedFinalCellId);
    chunkIds.add(resolvedChunkId);
    componentIds.add(resolvedComponentId);
  }

  if (orderedBoardCells.isEmpty) {
    return null;
  }

  return CandidateWordInstance(
    text: line.text,
    orientation: orientation,
    orderedBoardCells: orderedBoardCells,
    finalCellIds: finalCellIds,
    chunkIds: chunkIds.toList(),
    componentIds: componentIds.toList(),
  );
}

List<CandidateWordInstance> scanCandidateWordsForWholeBoard({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final seeds = <BoardCellPosition>{
    ...state.boardCellMap.keys,
    ...state.placedCellsByFinalId.values.map(
      (cell) => BoardCellPosition(row: cell.boardRow, col: cell.boardCol),
    ),
  };
  return _scanCandidatesFromSeeds(
    seeds: seeds,
    state: state,
    metadata: metadata,
  );
}

List<CandidateWordInstance> scanCandidateWordsForAffectedComponents({
  required Set<String> affectedComponentIds,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final seeds = <BoardCellPosition>{};

  for (final placed in state.placedCellsByFinalId.values) {
    if (affectedComponentIds.contains(placed.componentId)) {
      seeds.add(BoardCellPosition(row: placed.boardRow, col: placed.boardCol));
    }
  }

  for (final entry in state.boardCellMap.entries) {
    if (affectedComponentIds.contains(entry.value.componentId)) {
      seeds.add(entry.key);
    }
  }

  return _scanCandidatesFromSeeds(
    seeds: seeds,
    state: state,
    metadata: metadata,
  );
}

List<CandidateWordInstance> _scanCandidatesFromSeeds({
  required Set<BoardCellPosition> seeds,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final deduped = <String, CandidateWordInstance>{};

  for (final seed in seeds) {
    final horizontal = getHorizontalWordAtCell(
      row: seed.row,
      col: seed.col,
      state: state,
      metadata: metadata,
    );
    if (horizontal != null) {
      deduped[horizontal.dedupeKey] = horizontal;
    }

    final vertical = getVerticalWordAtCell(
      row: seed.row,
      col: seed.col,
      state: state,
      metadata: metadata,
    );
    if (vertical != null) {
      deduped[vertical.dedupeKey] = vertical;
    }
  }

  final candidates = deduped.values.toList()
    ..sort((a, b) => b.text.length.compareTo(a.text.length));

  for (final candidate in candidates) {
    logCandidate(candidate);
  }
  logCandidateScanTotal(candidates.length);

  return candidates;
}

BoardCellEntry? _resolveSharedIntersectionAtCompletedCell({
  required BoardCellPosition position,
  required String letter,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final boardEntry = state.boardCellMap[position];
  if (boardEntry != null && !boardEntry.finalCellId.startsWith('completed_')) {
    if (isCrosswordIntersectionCell(boardEntry.finalCellId, metadata) &&
        isCellNeededByUnsolvedWord(
          cellId: boardEntry.finalCellId,
          solvedWordIds: state.solvedWordIds,
          metadata: metadata,
        )) {
      return boardEntry;
    }
  }

  final matches = <String>[];
  for (final cellId in state.reservedCellIds) {
    if (!isCrosswordIntersectionCell(cellId, metadata)) {
      continue;
    }

    final layoutCell = metadata.finalCellById[cellId];
    if (layoutCell == null ||
        layoutCell.letter.toUpperCase() != letter.toUpperCase()) {
      continue;
    }

    if (!isCellNeededByUnsolvedWord(
      cellId: cellId,
      solvedWordIds: state.solvedWordIds,
      metadata: metadata,
    )) {
      continue;
    }

    final ownedBySolved = state.solvedAssignments.values.any(
      (assignment) => assignment.assignedCellIds.contains(cellId),
    );
    if (!ownedBySolved) {
      continue;
    }

    matches.add(cellId);
  }

  if (matches.length == 1) {
    final cellId = matches.single;
    final indexed = state.placedCellsByFinalId[cellId];
    if (indexed != null) {
      return BoardCellEntry(
        finalCellId: cellId,
        letter: indexed.letter,
        chunkId: indexed.chunkId,
        componentId: indexed.componentId,
      );
    }

    return BoardCellEntry(
      finalCellId: cellId,
      letter: letter,
      chunkId: boardEntry?.chunkId ?? '',
      componentId: boardEntry?.componentId ?? '',
    );
  }

  final unsolvedSlot = resolveUnsolvedWordSlotAtBoardPosition(
    position: position,
    letter: letter,
    state: state,
    metadata: metadata,
  );
  if (unsolvedSlot != null) {
    return BoardCellEntry(
      finalCellId: unsolvedSlot,
      letter: letter,
      chunkId: boardEntry?.chunkId ?? '',
      componentId: boardEntry?.componentId ?? '',
    );
  }

  if (boardEntry != null) {
    return boardEntry;
  }

  return null;
}
