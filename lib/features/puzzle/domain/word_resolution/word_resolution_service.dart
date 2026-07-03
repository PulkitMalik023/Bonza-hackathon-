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

WordResolutionResult runInitialPuzzleResolution({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
}) {
  logFlowStart(
    mode: 'INIT_RESOLUTION',
    movedChunks: const [],
    solvedWords: solvedWordIds,
    reserved: reservedCellIds,
  );

  final state = rebuildRuntimeBoardState(
    pieces: pieces,
    metadata: metadata,
    solvedWordIds: solvedWordIds,
    reservedCellIds: reservedCellIds,
    solvedAssignments: solvedAssignments,
  );

  final candidates = scanCandidateWordsForWholeBoard(
    state: state,
    metadata: metadata,
  );

  return _resolveAndApply(
    pieces: pieces,
    metadata: metadata,
    state: state,
    candidates: candidates,
    affectedComponentIds: state.componentsById.keys.toSet(),
    solvedWordIds: solvedWordIds,
    reservedCellIds: reservedCellIds,
    solvedAssignments: solvedAssignments,
  );
}

WordResolutionResult handlePuzzleStateAfterReconnect({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Iterable<String> movedChunkIds,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
}) {
  logFlowStart(
    mode: 'POST_RECONNECT',
    movedChunks: movedChunkIds.toList(),
    solvedWords: solvedWordIds,
    reserved: reservedCellIds,
  );

  final state = rebuildRuntimeBoardState(
    pieces: pieces,
    metadata: metadata,
    solvedWordIds: solvedWordIds,
    reservedCellIds: reservedCellIds,
    solvedAssignments: solvedAssignments,
  );

  final affectedComponentIds = getAffectedComponentsAfterReconnect(
    movedChunkIds: movedChunkIds,
    state: state,
  );

  final candidates = scanCandidateWordsForAffectedComponents(
    affectedComponentIds: affectedComponentIds,
    state: state,
    metadata: metadata,
  );

  return _resolveAndApply(
    pieces: pieces,
    metadata: metadata,
    state: state,
    candidates: candidates,
    affectedComponentIds: affectedComponentIds,
    solvedWordIds: solvedWordIds,
    reservedCellIds: reservedCellIds,
    solvedAssignments: solvedAssignments,
  );
}

WordResolutionResult _resolveAndApply({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required PuzzleRuntimeState state,
  required List<CandidateWordInstance> candidates,
  required Set<String> affectedComponentIds,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
}) {
  final accepted = resolveCompletedWordsAfterReconnect(
    candidateWordInstances: candidates,
    affectedComponentIds: affectedComponentIds,
    state: state,
    metadata: metadata,
  );

  if (accepted.isEmpty) {
    final puzzleComplete = checkAndHandlePuzzleCompleted(
      solvedWordIds: solvedWordIds,
      metadata: metadata,
    );
    logSolveState(solvedWordIds, reservedCellIds);
    return WordResolutionResult(
      pieces: pieces,
      solvedWordIds: solvedWordIds,
      reservedCellIds: reservedCellIds,
      solvedAssignments: solvedAssignments,
      newlySolvedWordIds: const {},
      puzzleComplete: puzzleComplete,
      completedAnswers: completedAnswersFromSolvedWordIds(
        solvedWordIds,
        metadata,
      ),
    );
  }

  final moveClusters = groupAcceptedAssignmentsIntoMoveClusters(
    acceptedAssignments: accepted,
    state: state,
  );

  var updatedPieces = pieces;
  var updatedSolvedWordIds = {...solvedWordIds};
  var updatedReservedCellIds = {...reservedCellIds};
  var updatedAssignments = Map<String, SolvedAssignment>.from(solvedAssignments);
  final newlySolved = <String>{};

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

        if (canRemainingPuzzleBeSolved(
          state: trial,
          metadata: metadata,
          options: options,
        )) {
          chosen = assignment;
          break;
        }

        logCandidateRejected(
          candidateText: candidate.text,
          wordId: wordId,
          reason: 'remaining_puzzle_unsolvable',
        );
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

      accepted.add(chosen);
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

  for (var index = 0; index < acceptedAssignments.length; index++) {
    final current = acceptedAssignments[index];
    final currentComponents = current.contributingComponentIds.toSet();
    for (var other = index + 1; other < acceptedAssignments.length; other++) {
      final otherComponents =
          acceptedAssignments[other].contributingComponentIds.toSet();
      if (currentComponents.intersection(otherComponents).isNotEmpty) {
        union(
          currentComponents.first,
          otherComponents.first,
        );
      }
    }
  }

  final grouped = <String, MoveCluster>{};

  for (final assignment in acceptedAssignments) {
    final componentId = assignment.contributingComponentIds.isNotEmpty
        ? find(assignment.contributingComponentIds.first)
        : 'cmp_isolated';

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
    final reservedBoardCells = _boardCellsForReservedIds(
      reservedCellIds: cluster.reservedCellIds,
      pieces: updated,
      metadata: metadata,
    );

    final visualCells = expandToContributingComponentCells(
      matchedCells: reservedBoardCells.keys,
      pieces: updated,
      playAreaBoard: buildPlayAreaLetterMap(updated),
    );

    final answers = cluster.assignmentWordIds
        .map((wordId) => metadata.textForWordId(wordId))
        .whereType<String>()
        .toSet();

    final completedCluster = CompletedCluster(
      answers: answers,
      cells: visualCells,
    );

    updated = applyCompletedClusterGrouping(
      pieces: updated,
      cluster: completedCluster,
    );
  }

  return updated;
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
