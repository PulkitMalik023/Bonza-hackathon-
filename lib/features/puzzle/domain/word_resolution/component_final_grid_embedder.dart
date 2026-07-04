import '../board_cell_position.dart';
import '../puzzle_board_state.dart';
import 'puzzle_layout_metadata.dart';
import 'puzzle_runtime_state.dart';
import 'word_resolution_models.dart';

Map<BoardCellPosition, String> componentCellsFromRuntimeState({
  required PuzzleRuntimeState state,
  required String componentId,
}) {
  final cells = <BoardCellPosition, String>{};
  for (final entry in state.boardCellMap.entries) {
    if (entry.value.componentId != componentId) {
      continue;
    }
    cells[entry.key] = entry.value.letter;
  }
  return cells;
}

Map<BoardCellPosition, String> boardCellsForRuntimeComponents({
  required PuzzleRuntimeState state,
  required Set<String> componentIds,
}) {
  final cells = <BoardCellPosition, String>{};
  for (final entry in state.boardCellMap.entries) {
    if (componentIds.contains(entry.value.componentId)) {
      cells[entry.key] = entry.value.letter;
    }
  }
  return cells;
}

Map<BoardCellPosition, String> embeddingComponentFromCandidateSeeds({
  required CandidateWordInstance candidate,
  required PuzzleRuntimeState state,
}) {
  final connected = connectedComponentFromCandidateSeeds(
    candidate: candidate,
    state: state,
  );

  final candidatePositions = {
    for (final cell in candidate.orderedBoardCells)
      BoardCellPosition(row: cell.boardRow, col: cell.boardCol),
  };

  return {
    for (final entry in connected.entries)
      if (!_excludeFromEmbeddingComponent(
        position: entry.key,
        candidatePositions: candidatePositions,
        state: state,
      ))
        entry.key: entry.value,
  };
}

bool _excludeFromEmbeddingComponent({
  required BoardCellPosition position,
  required Set<BoardCellPosition> candidatePositions,
  required PuzzleRuntimeState state,
}) {
  if (candidatePositions.contains(position)) {
    return false;
  }

  final entry = state.boardCellMap[position];
  if (entry == null) {
    return true;
  }

  if (state.placedCellsByFinalId.containsKey(entry.finalCellId)) {
    return false;
  }

  if (entry.finalCellId.startsWith('completed_')) {
    return true;
  }

  if (state.reservedCellIds.contains(entry.finalCellId)) {
    return true;
  }

  return false;
}

Map<BoardCellPosition, String> connectedComponentFromCandidateSeeds({
  required CandidateWordInstance candidate,
  required PuzzleRuntimeState state,
}) {
  final playAreaBoard = {
    for (final entry in state.boardCellMap.entries) entry.key: entry.value.letter,
  };
  if (playAreaBoard.isEmpty) {
    return const {};
  }

  final seeds = {
    for (final cell in candidate.orderedBoardCells)
      BoardCellPosition(row: cell.boardRow, col: cell.boardCol),
  };

  final connected = getConnectedPlayAreaCells(
    seedCells: seeds,
    playAreaBoard: playAreaBoard,
  );

  return {
    for (final position in connected)
      if (playAreaBoard[position] != null) position: playAreaBoard[position]!,
  };
}

List<BoardCellPosition> _orthogonalNeighbors(BoardCellPosition cell) {
  return [
    BoardCellPosition(row: cell.row - 1, col: cell.col),
    BoardCellPosition(row: cell.row + 1, col: cell.col),
    BoardCellPosition(row: cell.row, col: cell.col - 1),
    BoardCellPosition(row: cell.row, col: cell.col + 1),
  ];
}

List<ComponentEmbedding> findValidEmbeddings({
  required Map<BoardCellPosition, String> component,
  required PuzzleLayoutMetadata metadata,
  required PuzzleRuntimeState state,
}) {
  if (component.isEmpty) {
    return const [];
  }

  final layoutByPosition = _layoutCellsByPosition(metadata);
  final sortedKeys = component.keys.toList()
    ..sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.col.compareTo(b.col);
    });
  final anchorBoardPos = sortedKeys.first;
  final anchorLetter = component[anchorBoardPos]!.toUpperCase();

  final embeddings = <ComponentEmbedding>[];
  final seenKeys = <String>{};

  for (final layoutCell in metadata.finalCellById.values) {
    if (layoutCell.letter.toUpperCase() != anchorLetter) {
      continue;
    }

    final rowDelta = layoutCell.row - anchorBoardPos.row;
    final colDelta = layoutCell.col - anchorBoardPos.col;
    final embedding = _tryEmbeddingAtDelta(
      component: component,
      rowDelta: rowDelta,
      colDelta: colDelta,
      layoutByPosition: layoutByPosition,
      metadata: metadata,
      state: state,
    );
    if (embedding == null) {
      continue;
    }

    final key = embedding.finalCellIdByBoardPos.values.join(',');
    if (seenKeys.add(key)) {
      embeddings.add(embedding);
    }
  }

  embeddings.sort(
    (a, b) => _embeddingScore(b, state).compareTo(_embeddingScore(a, state)),
  );

  return embeddings;
}

ComponentEmbedding? _tryEmbeddingAtDelta({
  required Map<BoardCellPosition, String> component,
  required int rowDelta,
  required int colDelta,
  required Map<BoardCellPosition, FinalLayoutCell> layoutByPosition,
  required PuzzleLayoutMetadata metadata,
  required PuzzleRuntimeState state,
}) {
  final finalCellIdByBoardPos = <BoardCellPosition, String>{};

  for (final entry in component.entries) {
    final layoutPos = BoardCellPosition(
      row: entry.key.row + rowDelta,
      col: entry.key.col + colDelta,
    );
    final layoutCell = layoutByPosition[layoutPos];
    if (layoutCell == null ||
        layoutCell.letter.toUpperCase() != entry.value.toUpperCase()) {
      return null;
    }
    finalCellIdByBoardPos[entry.key] = layoutCell.id;

    final boardEntry = state.boardCellMap[entry.key];
    if (boardEntry != null &&
        !boardEntry.finalCellId.startsWith('completed_') &&
        boardEntry.finalCellId.isNotEmpty &&
        boardEntry.finalCellId != layoutCell.id) {
      return null;
    }
  }

  if (!_passesNeighborGapRule(
    component: component,
    finalCellIdByBoardPos: finalCellIdByBoardPos,
    layoutByPosition: layoutByPosition,
    metadata: metadata,
    state: state,
  )) {
    return null;
  }

  return ComponentEmbedding(
    finalCellIdByBoardPos: finalCellIdByBoardPos,
    rowDelta: rowDelta,
    colDelta: colDelta,
  );
}

bool _passesNeighborGapRule({
  required Map<BoardCellPosition, String> component,
  required Map<BoardCellPosition, String> finalCellIdByBoardPos,
  required Map<BoardCellPosition, FinalLayoutCell> layoutByPosition,
  required PuzzleLayoutMetadata metadata,
  required PuzzleRuntimeState state,
}) {
  for (final entry in component.entries) {
    final boardPos = entry.key;
    final finalCellId = finalCellIdByBoardPos[boardPos];
    if (finalCellId == null) {
      return false;
    }

    final layoutCell = metadata.finalCellById[finalCellId];
    if (layoutCell == null) {
      return false;
    }

    for (final neighborOffset in const [
      (-1, 0),
      (1, 0),
      (0, -1),
      (0, 1),
    ]) {
      final neighborLayoutPos = BoardCellPosition(
        row: layoutCell.row + neighborOffset.$1,
        col: layoutCell.col + neighborOffset.$2,
      );
      final neighborLayoutCell = layoutByPosition[neighborLayoutPos];
      if (neighborLayoutCell == null) {
        continue;
      }

      final boardNeighbor = BoardCellPosition(
        row: boardPos.row + neighborOffset.$1,
        col: boardPos.col + neighborOffset.$2,
      );
      final boardEntry = state.boardCellMap[boardNeighbor];
      if (boardEntry == null) {
        continue;
      }

      if (!component.containsKey(boardNeighbor)) {
        if (_isAllowedExternalBoardNeighbor(
          boardEntry: boardEntry,
          state: state,
          metadata: metadata,
        )) {
          continue;
        }
        return false;
      }

      if (boardEntry.letter.toUpperCase() !=
          neighborLayoutCell.letter.toUpperCase()) {
        return false;
      }
    }
  }

  return true;
}

bool wordMatchesEmbedding({
  required String wordId,
  required CandidateWordInstance candidate,
  required ComponentEmbedding embedding,
  required PuzzleLayoutMetadata metadata,
}) {
  return bindCandidateViaEmbedding(
        wordId: wordId,
        candidate: candidate,
        embedding: embedding,
        metadata: metadata,
      ) !=
      null;
}

List<String>? bindCandidateViaEmbedding({
  required String wordId,
  required CandidateWordInstance candidate,
  required ComponentEmbedding embedding,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null || candidate.text != word.text) {
    return null;
  }

  if (candidate.orderedBoardCells.length != word.cellIds.length) {
    return null;
  }

  final mappedIds = <String>[];
  for (final cell in candidate.orderedBoardCells) {
    final boardPos = BoardCellPosition(
      row: cell.boardRow,
      col: cell.boardCol,
    );
    final finalCellId = embedding.finalCellIdByBoardPos[boardPos];
    if (finalCellId == null) {
      return null;
    }
    mappedIds.add(finalCellId);
  }

  if (!_listsEqual(mappedIds, word.cellIds)) {
    return null;
  }

  return word.cellIds;
}

bool _otherWordIsActiveForSharedCell({
  required String otherWordId,
  required String sharedCellId,
  required BoardCellPosition sharedPosition,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  if (state.solvedWordIds.contains(otherWordId)) {
    return true;
  }

  final otherWord = metadata.wordById[otherWordId];
  if (otherWord == null) {
    return false;
  }

  for (final neighbor in _orthogonalNeighbors(sharedPosition)) {
    final neighborEntry = state.boardCellMap[neighbor];
    if (neighborEntry == null) {
      continue;
    }

    if (otherWord.cellIds.contains(neighborEntry.finalCellId) &&
        neighborEntry.finalCellId != sharedCellId) {
      return true;
    }
  }

  return false;
}

bool candidateSharedIntersectionsAreAnchored({
  required String wordId,
  required CandidateWordInstance candidate,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null) {
    return false;
  }

  for (final cell in candidate.orderedBoardCells) {
    final position = BoardCellPosition(
      row: cell.boardRow,
      col: cell.boardCol,
    );
    final entry = state.boardCellMap[position];
    if (entry == null) {
      return false;
    }

    final isSharedIntersection =
        (metadata.finalCellById[entry.finalCellId]?.wordIds.length ?? 0) > 1 &&
            word.cellIds.contains(entry.finalCellId);
    if (!isSharedIntersection) {
      continue;
    }

    final otherWordIds = metadata.finalCellById[entry.finalCellId]!.wordIds
        .where((id) => id != wordId && metadata.targetWordIds.contains(id));

    final activeOtherWordIds = otherWordIds.where(
      (otherWordId) => _otherWordIsActiveForSharedCell(
        otherWordId: otherWordId,
        sharedCellId: entry.finalCellId,
        sharedPosition: position,
        state: state,
        metadata: metadata,
      ),
    );

    if (activeOtherWordIds.isEmpty) {
      continue;
    }

    var anchored = false;
    for (final otherWordId in activeOtherWordIds) {
      if (state.solvedWordIds.contains(otherWordId)) {
        anchored = true;
        break;
      }
    }

    if (anchored) {
      continue;
    }

    for (final neighbor in _orthogonalNeighbors(position)) {
      final neighborEntry = state.boardCellMap[neighbor];
      if (neighborEntry == null) {
        continue;
      }

      for (final otherWordId in activeOtherWordIds) {
        final otherWord = metadata.wordById[otherWordId];
        if (otherWord == null) {
          continue;
        }

        if (otherWord.cellIds.contains(neighborEntry.finalCellId) &&
            neighborEntry.finalCellId != entry.finalCellId) {
          anchored = true;
          break;
        }
      }

      if (anchored) {
        break;
      }
    }

    if (!anchored) {
      return false;
    }
  }

  return true;
}

bool candidateActiveTilesAreConnected({
  required String wordId,
  required CandidateWordInstance candidate,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final word = metadata.wordById[wordId];
  if (word == null) {
    return false;
  }

  final activeBoard = {
    for (final placed in state.placedCellsByFinalId.values)
      BoardCellPosition(row: placed.boardRow, col: placed.boardCol):
          placed.letter,
  };

  final bridgeExcludedPositions = <BoardCellPosition>{};
  final nonSharedPositions = <BoardCellPosition>{};
  for (final cell in candidate.orderedBoardCells) {
    final position = BoardCellPosition(
      row: cell.boardRow,
      col: cell.boardCol,
    );
    final entry = state.boardCellMap[position];
    if (entry == null) {
      return false;
    }

    final isSharedIntersection =
        (metadata.finalCellById[entry.finalCellId]?.wordIds.length ?? 0) > 1 &&
            word.cellIds.contains(entry.finalCellId);

    if (isSharedIntersection) {
      bridgeExcludedPositions.add(position);
      continue;
    }

    if (!state.placedCellsByFinalId.containsKey(entry.finalCellId)) {
      return false;
    }

    nonSharedPositions.add(position);
  }

  if (nonSharedPositions.length <= 1) {
    return true;
  }

  final traversableBoard = {
    for (final entry in activeBoard.entries)
      if (!bridgeExcludedPositions.contains(entry.key)) entry.key: entry.value,
  };

  final connected = getConnectedPlayAreaCells(
    seedCells: nonSharedPositions,
    playAreaBoard: traversableBoard,
  );

  return nonSharedPositions.every(connected.contains);
}

Map<String, List<ComponentEmbedding>> buildEmbeddingCacheForCandidates({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  required List<CandidateWordInstance> candidates,
}) {
  final cache = <String, List<ComponentEmbedding>>{};
  for (final candidate in candidates) {
    final key = candidateComponentKey(candidate);
    if (cache.containsKey(key)) {
      continue;
    }
    final component = embeddingComponentFromCandidateSeeds(
      candidate: candidate,
      state: state,
    );
    cache[key] = findValidEmbeddings(
      component: component,
      metadata: metadata,
      state: state,
    );
  }
  return cache;
}

String candidateComponentKey(CandidateWordInstance candidate) {
  final positions = candidate.orderedBoardCells
      .map((cell) => '${cell.boardRow}_${cell.boardCol}')
      .toList()
    ..sort();
  return '${candidate.text}:${positions.join('|')}';
}

List<ComponentEmbedding>? embeddingsForCandidate({
  required CandidateWordInstance candidate,
  required Map<String, List<ComponentEmbedding>> cache,
}) {
  return cache[candidateComponentKey(candidate)];
}

Map<String, List<ComponentEmbedding>> buildEmbeddingCacheForComponents({
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
  required Set<String> componentIds,
}) {
  final cache = <String, List<ComponentEmbedding>>{};
  for (final componentId in componentIds) {
    final component = componentCellsFromRuntimeState(
      state: state,
      componentId: componentId,
    );
    cache[componentId] = findValidEmbeddings(
      component: component,
      metadata: metadata,
      state: state,
    );
  }
  return cache;
}

String? primaryComponentIdForCandidate(CandidateWordInstance candidate) {
  if (candidate.componentIds.isEmpty) {
    return null;
  }
  return candidate.componentIds.first;
}

int _embeddingScore(ComponentEmbedding embedding, PuzzleRuntimeState state) {
  var score = 0;
  for (final cellId in embedding.finalCellIdByBoardPos.values) {
    if (state.reservedCellIds.contains(cellId)) {
      score += 2;
    }
    for (final assignment in state.solvedAssignments.values) {
      if (assignment.assignedCellIds.contains(cellId)) {
        score += 1;
      }
    }
  }
  return score;
}

Map<BoardCellPosition, FinalLayoutCell> _layoutCellsByPosition(
  PuzzleLayoutMetadata metadata,
) {
  return {
    for (final cell in metadata.finalCellById.values)
      BoardCellPosition(row: cell.row, col: cell.col): cell,
  };
}

bool _isAllowedExternalBoardNeighbor({
  required BoardCellEntry boardEntry,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  if (boardEntry.finalCellId.startsWith('completed_')) {
    return true;
  }

  if (state.reservedCellIds.contains(boardEntry.finalCellId) &&
      !isCellNeededByUnsolvedWord(
        cellId: boardEntry.finalCellId,
        solvedWordIds: state.solvedWordIds,
        metadata: metadata,
      )) {
    return true;
  }

  return false;
}

bool _listsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
