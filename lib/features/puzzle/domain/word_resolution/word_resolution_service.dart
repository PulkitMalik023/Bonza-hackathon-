import '../../../../core/constants/board_constants.dart';
import '../board_cell_position.dart';
import '../completed_cluster_builder.dart';
import '../completed_word_grouper.dart';
import '../puzzle_board_state.dart';
import '../puzzle_piece.dart';
import 'candidate_word_scanner.dart';
import 'puzzle_layout_metadata.dart';
import 'puzzle_runtime_state.dart';
import 'puzzle_solvability_solver.dart';
import 'word_assignment.dart';
import 'word_resolution_logger.dart';
import 'word_resolution_models.dart';

const _maxConnectedLineResolutionIterations = 4;

WordResolutionResult runInitialPuzzleResolution({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
  int boardRows = BoardConstants.kPlayGridRows,
  int boardCols = BoardConstants.kPlayGridCols,
}) {
  logFlowStart(
    mode: 'INIT_RESOLUTION',
    movedChunks: const [],
    solvedWords: solvedWordIds,
    reserved: reservedCellIds,
  );

  return _resolveAndApplyConnectedLines(
    pieces: pieces,
    metadata: metadata,
    solvedWordIds: solvedWordIds,
    reservedCellIds: reservedCellIds,
    solvedAssignments: solvedAssignments,
    boardRows: boardRows,
    boardCols: boardCols,
  );
}

WordResolutionResult handlePuzzleStateAfterReconnect({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Iterable<String> movedChunkIds,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
  int boardRows = BoardConstants.kPlayGridRows,
  int boardCols = BoardConstants.kPlayGridCols,
}) {
  logFlowStart(
    mode: 'POST_RECONNECT',
    movedChunks: movedChunkIds.toList(),
    solvedWords: solvedWordIds,
    reserved: reservedCellIds,
  );

  return _resolveAndApplyConnectedLines(
    pieces: pieces,
    metadata: metadata,
    solvedWordIds: solvedWordIds,
    reservedCellIds: reservedCellIds,
    solvedAssignments: solvedAssignments,
    boardRows: boardRows,
    boardCols: boardCols,
  );
}

WordResolutionResult _resolveAndApplyConnectedLines({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
  int boardRows = BoardConstants.kPlayGridRows,
  int boardCols = BoardConstants.kPlayGridCols,
}) {
  var updatedPieces = pieces;
  var updatedSolvedWordIds = {...solvedWordIds};
  var updatedReservedCellIds = {...reservedCellIds};
  var updatedAssignments = Map<String, SolvedAssignment>.from(solvedAssignments);
  final newlySolved = <String>{};

  for (var iteration = 0;
      iteration < _maxConnectedLineResolutionIterations;
      iteration++) {
    final state = rebuildRuntimeBoardState(
      pieces: updatedPieces,
      metadata: metadata,
      solvedWordIds: updatedSolvedWordIds,
      reservedCellIds: updatedReservedCellIds,
      solvedAssignments: updatedAssignments,
      boardRows: boardRows,
      boardCols: boardCols,
    );

    final candidates = scanCandidateWordsForWholeBoard(
      state: state,
      metadata: metadata,
    );

    final accepted = resolveAcceptedConnectedLineWords(
      candidates: candidates,
      state: state,
      metadata: metadata,
    );

    if (accepted.isEmpty) {
      break;
    }

    final moveClusters = groupAcceptedAssignmentsIntoMoveClusters(
      acceptedAssignments: accepted,
      state: state,
    );

    for (final cluster in moveClusters) {
      updatedPieces = animateSolvedClusters(
        moveClusters: [cluster],
        pieces: updatedPieces,
        metadata: metadata,
        acceptedAssignments: accepted,
      );

      for (final wordId in cluster.assignmentWordIds) {
        updatedSolvedWordIds.add(wordId);
        newlySolved.add(wordId);
        updatedReservedCellIds.addAll(cluster.reservedCellIds);
        final assignment = accepted.firstWhere(
          (option) => option.wordId == wordId,
        );
        updatedAssignments[wordId] = SolvedAssignment(
          wordId: wordId,
          assignedCellIds: assignment.reservedFinalCellIds.toSet(),
          moveComponentId: cluster.moveComponentId,
        );
      }
    }
  }

  final puzzleComplete = checkAndHandlePuzzleCompleted(
    solvedWordIds: updatedSolvedWordIds,
    metadata: metadata,
  );

  logSolveState(updatedSolvedWordIds, updatedReservedCellIds);

  return WordResolutionResult(
    pieces: updatedPieces,
    solvedWordIds: updatedSolvedWordIds,
    reservedCellIds: updatedReservedCellIds,
    solvedAssignments: updatedAssignments,
    newlySolvedWordIds: newlySolved,
    puzzleComplete: puzzleComplete,
    completedAnswers: completedAnswersFromSolvedWordIds(
      updatedSolvedWordIds,
      metadata,
    ),
  );
}

List<WordAssignmentOption> resolveAcceptedConnectedLineWords({
  required List<CandidateWordInstance> candidates,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  if (candidates.isEmpty) {
    return const [];
  }

  final sortedCandidates = [...candidates]
    ..sort((a, b) => b.text.length.compareTo(a.text.length));

  final options = WordResolutionOptions(
    candidateWordInstances: sortedCandidates,
  );

  final accepted = <WordAssignmentOption>[];
  var workingState = state.clone();

  for (final candidate in sortedCandidates) {
    if (candidate.text.length < 2) {
      continue;
    }

    if (!metadata.allTargetTexts.contains(candidate.text.toUpperCase())) {
      continue;
    }

    final matchedWordIds = getTargetWordIdsMatchingText(candidate.text, metadata);

    for (final wordId in matchedWordIds) {
      if (workingState.solvedWordIds.contains(wordId)) {
        continue;
      }

      final matchingAssignments = assignmentsForCandidate(
        wordId: wordId,
        candidate: candidate,
        state: workingState,
        metadata: metadata,
        options: options,
      );

      if (matchingAssignments.isEmpty) {
        continue;
      }

      WordAssignmentOption? chosen;
      for (final assignment in matchingAssignments) {
        final trial = applyWordAssignmentToSolverState(
          state: workingState,
          assignment: assignment,
          metadata: metadata,
        );

        final needsGate = shouldApplySolvabilityGate(
          wordId: wordId,
          assignment: assignment,
          state: workingState,
          metadata: metadata,
        );

        if (!needsGate ||
            canRemainingPuzzleBeSolved(
              state: trial,
              metadata: metadata,
              options: options,
            )) {
          chosen = assignment;
          break;
        }

        logSolvabilityReject(
          wordId: wordId,
          candidateText: candidate.text,
        );
        for (final blockedId in getBlockedUnsolvedWordIds(
          state: trial,
          metadata: metadata,
          options: options,
        )) {
          logBlockedWord(blockedId);
        }
      }

      if (chosen == null) {
        continue;
      }

      final moveComponent = chosen.contributingComponentIds.isNotEmpty
          ? chosen.contributingComponentIds.first
          : 'cmp_unknown';

      logCandidateAccepted(
        candidateText: candidate.text,
        wordId: wordId,
        assignmentType: chosen.assignmentType,
        moveComponent: moveComponent,
      );

      final acceptedAssignment = WordAssignmentOption(
        wordId: chosen.wordId,
        reservedFinalCellIds: chosen.reservedFinalCellIds,
        contributingFinalCellIds: chosen.contributingFinalCellIds,
        contributingChunkIds: chosen.contributingChunkIds,
        contributingComponentIds: chosen.contributingComponentIds,
        assignmentType: chosen.assignmentType,
        debugReason: chosen.debugReason,
        groupedBoardCells: candidate.orderedBoardCells,
      );

      accepted.add(acceptedAssignment);
      workingState = applyWordAssignmentToSolverState(
        state: workingState,
        assignment: chosen,
        metadata: metadata,
      );
    }
  }

  return accepted;
}

List<WordAssignmentOption> resolveCompletedWordsAfterReconnect({
  required List<CandidateWordInstance> candidateWordInstances,
  required Set<String> affectedComponentIds,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final options = WordResolutionOptions(
    candidateWordInstances: candidateWordInstances,
    affectedComponentIds: affectedComponentIds,
  );

  final accepted = <WordAssignmentOption>[];
  var workingState = state.clone();

  for (final candidate in candidateWordInstances) {
    if (candidate.text.length < 2) {
      continue;
    }

    if (!metadata.allTargetTexts.contains(candidate.text.toUpperCase())) {
      logExactLineRejected(
        candidateText: candidate.text,
        reason: 'no_exact_target_match',
      );
      continue;
    }

    final matchedWordIds = getTargetWordIdsMatchingText(candidate.text, metadata);
    logTargetMatch(candidate.text, matchedWordIds);

    for (final wordId in matchedWordIds) {
      if (workingState.solvedWordIds.contains(wordId)) {
        continue;
      }

      final matchingAssignments = assignmentsForCandidate(
        wordId: wordId,
        candidate: candidate,
        state: workingState,
        metadata: metadata,
        options: options,
      );

      WordAssignmentOption? chosen;
      for (final assignment in matchingAssignments) {
        final trial = applyWordAssignmentToSolverState(
          state: workingState,
          assignment: assignment,
          metadata: metadata,
        );

        final needsGate = shouldApplySolvabilityGate(
          wordId: wordId,
          assignment: assignment,
          state: workingState,
          metadata: metadata,
        );

        if (!needsGate ||
            canRemainingPuzzleBeSolved(
              state: trial,
              metadata: metadata,
              options: options,
            )) {
          chosen = assignment;
          break;
        }

        logSolvabilityReject(
          wordId: wordId,
          candidateText: candidate.text,
        );
        for (final blockedId in getBlockedUnsolvedWordIds(
          state: trial,
          metadata: metadata,
          options: options,
        )) {
          logBlockedWord(blockedId);
        }
      }

      if (chosen == null) {
        continue;
      }

      final moveComponent = chosen.contributingComponentIds.isNotEmpty
          ? chosen.contributingComponentIds.first
          : 'cmp_unknown';

      logCandidateAccepted(
        candidateText: candidate.text,
        wordId: wordId,
        assignmentType: chosen.assignmentType,
        moveComponent: moveComponent,
      );

      accepted.add(
        WordAssignmentOption(
          wordId: chosen.wordId,
          reservedFinalCellIds: chosen.reservedFinalCellIds,
          contributingFinalCellIds: chosen.contributingFinalCellIds,
          contributingChunkIds: chosen.contributingChunkIds,
          contributingComponentIds: chosen.contributingComponentIds,
          assignmentType: chosen.assignmentType,
          debugReason: chosen.debugReason,
          groupedBoardCells: candidate.orderedBoardCells,
        ),
      );
      workingState = applyWordAssignmentToSolverState(
        state: workingState,
        assignment: chosen,
        metadata: metadata,
      );
    }
  }

  return accepted;
}

List<MoveCluster> groupAcceptedAssignmentsIntoMoveClusters({
  required List<WordAssignmentOption> acceptedAssignments,
  required PuzzleRuntimeState state,
}) {
  if (acceptedAssignments.isEmpty) {
    return const [];
  }

  final parent = <String, String>{};

  String find(String id) {
    parent[id] ??= id;
    if (parent[id] != id) {
      parent[id] = find(parent[id]!);
    }
    return parent[id]!;
  }

  void union(String a, String b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA != rootB) {
      parent[rootB] = rootA;
    }
  }

  String clusterKeyFor(WordAssignmentOption assignment) {
    if (assignment.contributingComponentIds.isNotEmpty) {
      return assignment.contributingComponentIds.first;
    }
    return 'word_${assignment.wordId}';
  }

  for (var index = 0; index < acceptedAssignments.length; index++) {
    final current = acceptedAssignments[index];
    final currentKey = clusterKeyFor(current);
    final currentComponents = current.contributingComponentIds.toSet();
    final currentCells = current.reservedFinalCellIds.toSet();

    for (var other = index + 1; other < acceptedAssignments.length; other++) {
      final otherAssignment = acceptedAssignments[other];
      final otherKey = clusterKeyFor(otherAssignment);
      final otherComponents =
          otherAssignment.contributingComponentIds.toSet();
      final otherCells = otherAssignment.reservedFinalCellIds.toSet();

      if (currentComponents.intersection(otherComponents).isNotEmpty ||
          currentCells.intersection(otherCells).isNotEmpty) {
        union(currentKey, otherKey);
      }
    }
  }

  final grouped = <String, MoveCluster>{};

  for (final assignment in acceptedAssignments) {
    final componentId = find(clusterKeyFor(assignment));

    final existing = grouped[componentId];
    grouped[componentId] = MoveCluster(
      moveComponentId: componentId,
      assignmentWordIds: [
        ...?existing?.assignmentWordIds,
        assignment.wordId,
      ],
      reservedCellIds: {
        ...?existing?.reservedCellIds,
        ...assignment.reservedFinalCellIds,
      },
      contributingComponentIds: {
        ...?existing?.contributingComponentIds,
        ...assignment.contributingComponentIds,
      },
      contributingChunkIds: {
        ...?existing?.contributingChunkIds,
        ...assignment.contributingChunkIds,
      },
    );
  }

  final clusters = grouped.values.toList();
  for (final cluster in clusters) {
    logMoveCluster(cluster);
  }
  return clusters;
}

List<PuzzlePiece> animateSolvedClusters({
  required List<MoveCluster> moveClusters,
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required List<WordAssignmentOption> acceptedAssignments,
}) {
  var updated = pieces;

  for (final cluster in moveClusters) {
    final reservedBoardCells = _boardCellsForCluster(
      cluster: cluster,
      acceptedAssignments: acceptedAssignments,
      pieces: updated,
      metadata: metadata,
    );

    logGrouping(
      wordIds: cluster.assignmentWordIds,
      reservedCellCount: reservedBoardCells.length,
    );

    final answers = cluster.assignmentWordIds
        .map((wordId) => metadata.textForWordId(wordId))
        .whereType<String>()
        .toSet();

    final completedCluster = CompletedCluster(
      answers: answers,
      cells: reservedBoardCells,
    );

    updated = applyCompletedClusterGrouping(
      pieces: updated,
      cluster: completedCluster,
    );
  }

  return updated;
}

Map<BoardCellPosition, String> _boardCellsForCluster({
  required MoveCluster cluster,
  required List<WordAssignmentOption> acceptedAssignments,
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
}) {
  final cells = <BoardCellPosition, String>{};
  final claimedPositions = <BoardCellPosition>{};

  for (final wordId in cluster.assignmentWordIds) {
    final assignment = acceptedAssignments.firstWhere(
      (option) => option.wordId == wordId,
    );

    final grouped = assignment.groupedBoardCells;
    if (grouped != null &&
        grouped.length == assignment.reservedFinalCellIds.length) {
      for (final boardCell in grouped) {
        final position = BoardCellPosition(
          row: boardCell.boardRow,
          col: boardCell.boardCol,
        );
        if (claimedPositions.contains(position)) {
          continue;
        }
        cells[position] = boardCell.letter;
        claimedPositions.add(position);
      }
      continue;
    }

    final fallback = _boardCellsForReservedIds(
      reservedCellIds: assignment.reservedFinalCellIds.toSet(),
      pieces: pieces,
      metadata: metadata,
    );
    for (final entry in fallback.entries) {
      if (claimedPositions.contains(entry.key)) {
        continue;
      }
      cells[entry.key] = entry.value;
      claimedPositions.add(entry.key);
    }
  }

  if (cells.isEmpty) {
    return cells;
  }

  final contributingChunkIds = {
    ...cluster.contributingChunkIds,
    for (final wordId in cluster.assignmentWordIds)
      ...acceptedAssignments
          .firstWhere((option) => option.wordId == wordId)
          .contributingChunkIds,
  };

  return expandToContributingChunkCells(
    seedCells: cells,
    contributingChunkIds: contributingChunkIds,
    pieces: pieces,
  );
}

Map<BoardCellPosition, String> _boardCellsForReservedIds({
  required Set<String> reservedCellIds,
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
}) {
  final cells = <BoardCellPosition, String>{};
  final claimedCellIds = <String>{};

  for (final piece in pieces) {
    if (piece.isCompletedWordGroup) {
      continue;
    }

    for (final cell in piece.cells) {
      final finalCellId = metadata.finalCellIdForChunkLocal(
        chunkId: piece.chunkId,
        localRow: cell.rowOffset,
        localCol: cell.colOffset,
      );
      if (finalCellId == null || !reservedCellIds.contains(finalCellId)) {
        continue;
      }

      final position = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );
      cells[position] = cell.letter;
      claimedCellIds.add(finalCellId);
    }
  }

  final remainingCellIds = reservedCellIds.difference(claimedCellIds);
  if (remainingCellIds.isEmpty) {
    return cells;
  }

  final claimedPositions = cells.keys.toSet();
  for (final piece in pieces) {
    if (!piece.isCompletedWordGroup) {
      continue;
    }

    for (final cellId in remainingCellIds.toList()) {
      final layoutCell = metadata.finalCellById[cellId];
      if (layoutCell == null) {
        continue;
      }

      for (final cell in piece.cells) {
        final position = BoardCellPosition(
          row: piece.anchorRow + cell.rowOffset,
          col: piece.anchorCol + cell.colOffset,
        );
        if (claimedPositions.contains(position)) {
          continue;
        }
        if (cell.letter.toUpperCase() != layoutCell.letter.toUpperCase()) {
          continue;
        }

        cells[position] = cell.letter;
        claimedPositions.add(position);
        remainingCellIds.remove(cellId);
        break;
      }
    }
  }

  return cells;
}

bool checkAndHandlePuzzleCompleted({
  required Set<String> solvedWordIds,
  required PuzzleLayoutMetadata metadata,
}) {
  final complete = metadata.targetWordIds.every(solvedWordIds.contains);
  if (complete) {
    logPuzzleComplete(solvedWordIds.length, metadata.targetWordIds.length);
  }
  return complete;
}
