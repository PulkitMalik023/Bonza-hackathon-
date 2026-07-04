import '../../../../core/constants/puzzle_ui_flags.dart';
import '../board_cell_position.dart';
import 'puzzle_layout_metadata.dart';
import 'puzzle_runtime_state.dart';
import 'word_resolution_logger.dart';
import 'word_resolution_models.dart';

bool isCrosswordIntersectionCell(
  String cellId,
  PuzzleLayoutMetadata metadata,
) {
  return (metadata.finalCellById[cellId]?.wordIds.length ?? 0) > 1;
}

bool isSharedIntersectionCell({
  required String cellId,
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  if (!state.reservedCellIds.contains(cellId)) {
    return false;
  }

  final word = metadata.wordById[wordId];
  if (word == null || !word.cellIds.contains(cellId)) {
    return false;
  }

  if (!isCrosswordIntersectionCell(cellId, metadata)) {
    return false;
  }

  final layoutCell = metadata.finalCellById[cellId];
  if (layoutCell == null) {
    return false;
  }

  if (!layoutCell.wordIds.contains(wordId)) {
    return false;
  }

  for (final solvedWordId in state.solvedWordIds) {
    final solvedAssignment = state.solvedAssignments[solvedWordId];
    if (solvedAssignment == null ||
        !solvedAssignment.assignedCellIds.contains(cellId)) {
      continue;
    }

    final solvedWord = metadata.wordById[solvedWordId];
    if (solvedWord == null || !solvedWord.cellIds.contains(cellId)) {
      return false;
    }
  }

  return true;
}

bool isCellBlockedByReservation({
  required String cellId,
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  if (!state.reservedCellIds.contains(cellId)) {
    return false;
  }

  return !isSharedIntersectionCell(
    cellId: cellId,
    wordId: wordId,
    state: state,
    metadata: metadata,
  );
}

bool wordHasPlayAreaCellsOnBoard({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null) {
    return false;
  }

  for (final cellId in word.cellIds) {
    final layoutCell = metadata.finalCellById[cellId];
    if (layoutCell == null) {
      continue;
    }

    final layoutPosition = BoardCellPosition(
      row: layoutCell.row,
      col: layoutCell.col,
    );
    final boardEntry = state.boardCellMap[layoutPosition];
    if (boardEntry != null &&
        boardEntry.letter.toUpperCase() == layoutCell.letter.toUpperCase()) {
      return true;
    }

    final placed = state.placedCellsByFinalId[cellId];
    if (placed != null &&
        placed.boardRow == layoutCell.row &&
        placed.boardCol == layoutCell.col &&
        placed.letter.toUpperCase() == layoutCell.letter.toUpperCase()) {
      return true;
    }
  }

  return false;
}

bool shouldApplySolvabilityGate({
  required String wordId,
  required WordAssignmentOption assignment,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final completingWord = metadata.wordById[wordId];
  if (completingWord == null) {
    return false;
  }

  for (final otherWordId in metadata.targetWordIds) {
    if (otherWordId == wordId || state.solvedWordIds.contains(otherWordId)) {
      continue;
    }

    if (!wordHasPlayAreaCellsOnBoard(
      wordId: otherWordId,
      state: state,
      metadata: metadata,
    )) {
      continue;
    }

    final otherWord = metadata.wordById[otherWordId];
    if (otherWord == null) {
      continue;
    }

    final sharedIntersectionIds = completingWord.cellIds.toSet()
        .intersection(otherWord.cellIds.toSet())
        .where((cellId) => isCrosswordIntersectionCell(cellId, metadata))
        .where((cellId) => assignment.reservedFinalCellIds.contains(cellId));

    if (sharedIntersectionIds.isEmpty) {
      continue;
    }

    final simulatedState = PuzzleRuntimeState(
      placedCellsByFinalId: state.placedCellsByFinalId,
      boardCellMap: state.boardCellMap,
      componentsById: state.componentsById,
      solvedWordIds: {...state.solvedWordIds, wordId},
      reservedCellIds: {
        ...state.reservedCellIds,
        ...assignment.reservedFinalCellIds,
      },
      solvedAssignments: {
        ...state.solvedAssignments,
        wordId: SolvedAssignment(
          wordId: wordId,
          assignedCellIds: assignment.reservedFinalCellIds.toSet(),
          moveComponentId: assignment.contributingComponentIds.isNotEmpty
              ? assignment.contributingComponentIds.first
              : null,
        ),
      },
      latentInventoryByFinalId: state.latentInventoryByFinalId,
    );

    if (!canWordBeSatisfiedFromBoardInventory(
          wordId: otherWordId,
          state: simulatedState,
          metadata: metadata,
        ) &&
        getPossibleAssignmentsForWord(
          wordId: otherWordId,
          state: simulatedState,
          metadata: metadata,
        ).isEmpty) {
      return true;
    }
  }

  return false;
}

PlacedRuntimeCell? resolveCellForWord({
  required String cellId,
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  bool requireLayoutPosition = true,
}) {
  if (isCellBlockedByReservation(
    cellId: cellId,
    wordId: wordId,
    state: state,
    metadata: metadata,
  )) {
    return null;
  }

  final layoutCell = metadata.finalCellById[cellId];
  if (layoutCell == null) {
    return null;
  }

  final layoutPosition = BoardCellPosition(
    row: layoutCell.row,
    col: layoutCell.col,
  );

  if (requireLayoutPosition) {
    final boardEntry = state.boardCellMap[layoutPosition];
    if (boardEntry != null &&
        boardEntry.letter.toUpperCase() == layoutCell.letter.toUpperCase()) {
      return PlacedRuntimeCell(
        finalCellId: cellId,
        letter: boardEntry.letter,
        boardRow: layoutPosition.row,
        boardCol: layoutPosition.col,
        chunkId: boardEntry.chunkId,
        componentId: boardEntry.componentId,
      );
    }
  }

  final active = state.placedCellsByFinalId[cellId];
  if (active != null) {
    if (active.letter.toUpperCase() != layoutCell.letter.toUpperCase()) {
      return null;
    }
    if (requireLayoutPosition &&
        (active.boardRow != layoutCell.row ||
            active.boardCol != layoutCell.col)) {
      return null;
    }
    return active;
  }

  for (final entry in state.boardCellMap.entries) {
    if (entry.value.finalCellId != cellId) {
      continue;
    }

    if (entry.value.letter.toUpperCase() != layoutCell.letter.toUpperCase()) {
      continue;
    }

    if (requireLayoutPosition &&
        (entry.key.row != layoutCell.row || entry.key.col != layoutCell.col)) {
      continue;
    }

    return PlacedRuntimeCell(
      finalCellId: cellId,
      letter: entry.value.letter,
      boardRow: entry.key.row,
      boardCol: entry.key.col,
      chunkId: entry.value.chunkId,
      componentId: entry.value.componentId,
    );
  }

  if (!requireLayoutPosition) {
    final latent = state.latentInventoryByFinalId[cellId];
    if (latent != null &&
        latent.letter.toUpperCase() == layoutCell.letter.toUpperCase()) {
      return latent;
    }
    return null;
  }

  for (final entry in state.boardCellMap.entries) {
    if (entry.key.row != layoutCell.row || entry.key.col != layoutCell.col) {
      continue;
    }

    if (entry.value.letter.toUpperCase() != layoutCell.letter.toUpperCase()) {
      continue;
    }

    return PlacedRuntimeCell(
      finalCellId: cellId,
      letter: entry.value.letter,
      boardRow: entry.key.row,
      boardCol: entry.key.col,
      chunkId: entry.value.chunkId,
      componentId: entry.value.componentId,
    );
  }

  return null;
}

List<WordAssignmentOption> getPossibleAssignmentsForWord({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  WordResolutionOptions options = const WordResolutionOptions(),
}) {
  if (options.flexibleEnabled && kEnableFlexibleWordAssignment) {
    return getPossibleAssignmentsForWord_Flexible(
      wordId: wordId,
      state: state,
      metadata: metadata,
      options: options,
    );
  }

  return getPossibleAssignmentsForWord_Strict(
    wordId: wordId,
    state: state,
    metadata: metadata,
  );
}

List<WordAssignmentOption> getPossibleAssignmentsForWord_Strict({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null) {
    logStrictAssignmentFail(wordId, 'unknown_word');
    return const [];
  }

  if (state.solvedWordIds.contains(wordId)) {
    logStrictAssignmentFail(wordId, 'already_solved');
    return const [];
  }

  final reserved = <String>[];
  final chunks = <String>{};
  final components = <String>{};

  for (final cellId in word.cellIds) {
    if (isCellBlockedByReservation(
      cellId: cellId,
      wordId: wordId,
      state: state,
      metadata: metadata,
    )) {
      logStrictAssignmentFail(wordId, 'cell_reserved_or_missing cellId=$cellId');
      return const [];
    }

    final layoutCell = metadata.finalCellById[cellId];
    final placed = resolveCellForWord(
      cellId: cellId,
      wordId: wordId,
      state: state,
      metadata: metadata,
    );
    if (layoutCell == null || placed == null) {
      logStrictAssignmentFail(wordId, 'cell_reserved_or_missing cellId=$cellId');
      return const [];
    }

    if (placed.letter.toUpperCase() != layoutCell.letter.toUpperCase()) {
      logStrictAssignmentFail(wordId, 'letter_mismatch cellId=$cellId');
      return const [];
    }

    if (placed.boardRow != layoutCell.row || placed.boardCol != layoutCell.col) {
      logStrictAssignmentFail(wordId, 'layout_position_mismatch cellId=$cellId');
      return const [];
    }

    reserved.add(cellId);
    chunks.add(placed.chunkId);
    components.add(placed.componentId);
  }

  logStrictAssignmentOk(wordId, reserved);

  return [
    WordAssignmentOption(
      wordId: wordId,
      reservedFinalCellIds: reserved,
      contributingFinalCellIds: reserved,
      contributingChunkIds: chunks.toList(),
      contributingComponentIds: components.toList(),
      assignmentType: AssignmentType.strictFinal,
      debugReason: 'strict_layout_match',
    ),
  ];
}

List<String>? bindCandidateToWordSlots({
  required String wordId,
  required CandidateWordInstance candidate,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null || candidate.text != word.text) {
    return null;
  }

  if (candidate.orderedBoardCells.length != word.cellIds.length) {
    return null;
  }

  for (var index = 0; index < word.cellIds.length; index++) {
    final slotId = word.cellIds[index];
    final layoutCell = metadata.finalCellById[slotId];
    final candidateCell = candidate.orderedBoardCells[index];
    if (layoutCell == null ||
        layoutCell.letter.toUpperCase() != candidateCell.letter.toUpperCase()) {
      return null;
    }
  }

  return word.cellIds;
}

List<WordAssignmentOption> getPossibleAssignmentsForWord_Flexible({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  required WordResolutionOptions options,
}) {
  final strict = getPossibleAssignmentsForWord_Strict(
    wordId: wordId,
    state: state,
    metadata: metadata,
  );

  final results = <WordAssignmentOption>[...strict];
  final seen = strict
      .map((option) => option.reservedFinalCellIds.join(','))
      .toSet();

  for (final candidate in options.candidateWordInstances) {
    if (candidate.text != metadata.wordById[wordId]?.text) {
      continue;
    }

    final boundSlots = bindCandidateToWordSlots(
      wordId: wordId,
      candidate: candidate,
      metadata: metadata,
    );
    if (boundSlots == null) {
      logFlexAssignmentReject(wordId, 'candidate_cells_do_not_match_word_slots');
      continue;
    }

    final boundKey = boundSlots.join(',');
    if (seen.contains(boundKey)) {
      continue;
    }

    if (boundSlots.any(
      (cellId) => isCellBlockedByReservation(
        cellId: cellId,
        wordId: wordId,
        state: state,
        metadata: metadata,
      ),
    )) {
      logFlexAssignmentReject(wordId, 'candidate_cells_reserved');
      continue;
    }

    logFlexAssignmentCandidate(wordId, boundSlots);

    results.add(
      WordAssignmentOption(
        wordId: wordId,
        reservedFinalCellIds: boundSlots,
        contributingFinalCellIds: boundSlots,
        contributingChunkIds: candidate.chunkIds,
        contributingComponentIds: candidate.componentIds,
        assignmentType: AssignmentType.flexibleIndependent,
        debugReason: 'flexible_runtime_candidate',
      ),
    );
    seen.add(boundKey);
  }

  return results;
}

bool canWordBeSatisfiedFromBoardInventory({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null) {
    logInventoryFail(wordId, 'unknown_word');
    return false;
  }

  if (state.solvedWordIds.contains(wordId)) {
    logInventoryFail(wordId, 'already_solved');
    return false;
  }

  for (final cellId in word.cellIds) {
    if (isCellBlockedByReservation(
      cellId: cellId,
      wordId: wordId,
      state: state,
      metadata: metadata,
    )) {
      logInventoryFail(wordId, 'cell_reserved cellId=$cellId');
      return false;
    }

    final layoutCell = metadata.finalCellById[cellId];
    final placed = resolveCellForWord(
      cellId: cellId,
      wordId: wordId,
      state: state,
      metadata: metadata,
      requireLayoutPosition: false,
    );
    if (layoutCell == null || placed == null) {
      logInventoryFail(wordId, 'cell_missing cellId=$cellId');
      return false;
    }

    if (placed.letter.toUpperCase() != layoutCell.letter.toUpperCase()) {
      logInventoryFail(wordId, 'letter_mismatch cellId=$cellId');
      return false;
    }
  }

  logInventoryOk(wordId, word.cellIds);
  return true;
}

WordAssignmentOption? buildInventoryAssignmentForWord({
  required String wordId,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  if (!canWordBeSatisfiedFromBoardInventory(
    wordId: wordId,
    state: state,
    metadata: metadata,
  )) {
    return null;
  }

  final word = metadata.wordById[wordId]!;
  final chunks = <String>{};
  final components = <String>{};

  for (final cellId in word.cellIds) {
    final placed = resolveCellForWord(
      cellId: cellId,
      wordId: wordId,
      state: state,
      metadata: metadata,
    ) ??
        state.placedCellsByFinalId[cellId] ??
        state.latentInventoryByFinalId[cellId];
    if (placed == null) {
      continue;
    }
    chunks.add(placed.chunkId);
    components.add(placed.componentId);
  }

  return WordAssignmentOption(
    wordId: wordId,
    reservedFinalCellIds: word.cellIds,
    contributingFinalCellIds: word.cellIds,
    contributingChunkIds: chunks.toList(),
    contributingComponentIds: components.toList(),
    assignmentType: AssignmentType.latentInventory,
    debugReason: 'board_inventory_coverage',
  );
}

bool assignmentMatchesCandidate({
  required WordAssignmentOption assignment,
  required CandidateWordInstance candidate,
  required PuzzleLayoutMetadata metadata,
}) {
  if (assignment.reservedFinalCellIds.length != candidate.orderedBoardCells.length) {
    return false;
  }

  if (assignment.reservedFinalCellIds.join(',') ==
      candidate.finalCellIds.join(',')) {
    return true;
  }

  for (var index = 0; index < candidate.orderedBoardCells.length; index++) {
    final slotId = assignment.reservedFinalCellIds[index];
    final layoutLetter = metadata.finalCellById[slotId]?.letter;
    if (layoutLetter == null) {
      return false;
    }

    if (candidate.orderedBoardCells[index].letter.toUpperCase() !=
        layoutLetter.toUpperCase()) {
      return false;
    }
  }

  return true;
}

List<WordAssignmentOption> assignmentsForCandidate({
  required String wordId,
  required CandidateWordInstance candidate,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  WordResolutionOptions options = const WordResolutionOptions(),
}) {
  final all = getPossibleAssignmentsForWord(
    wordId: wordId,
    state: state,
    metadata: metadata,
    options: options.copyWith(
      candidateWordInstances: [candidate],
    ),
  );

  return all
      .where(
        (assignment) => assignmentMatchesCandidate(
          assignment: assignment,
          candidate: candidate,
          metadata: metadata,
        ),
      )
      .toList()
    ..sort(_compareAssignmentsStrictFirst);
}

int _compareAssignmentsStrictFirst(
  WordAssignmentOption a,
  WordAssignmentOption b,
) {
  final aPriority = _assignmentTypePriority(a.assignmentType);
  final bPriority = _assignmentTypePriority(b.assignmentType);
  return aPriority.compareTo(bPriority);
}

int _assignmentTypePriority(AssignmentType type) {
  switch (type) {
    case AssignmentType.strictFinal:
      return 0;
    case AssignmentType.flexibleIndependent:
      return 1;
    case AssignmentType.latentInventory:
      return 2;
  }
}

extension WordResolutionOptionsCopy on WordResolutionOptions {
  WordResolutionOptions copyWith({
    List<CandidateWordInstance>? candidateWordInstances,
    Set<String>? affectedComponentIds,
    bool? flexibleEnabled,
  }) {
    return WordResolutionOptions(
      candidateWordInstances:
          candidateWordInstances ?? this.candidateWordInstances,
      affectedComponentIds:
          affectedComponentIds ?? this.affectedComponentIds,
      flexibleEnabled: flexibleEnabled ?? this.flexibleEnabled,
    );
  }
}
