import '../../../../core/constants/board_constants.dart';
import '../board_cell_position.dart';
import '../puzzle_board_state.dart';
import '../puzzle_piece.dart';
import '../puzzle_solved_checker.dart';
import 'puzzle_layout_metadata.dart';
import 'word_resolution_logger.dart';
import 'word_resolution_models.dart';

class PuzzleRuntimeState {
  PuzzleRuntimeState({
    required this.placedCellsByFinalId,
    required this.boardCellMap,
    required this.componentsById,
    required this.solvedWordIds,
    required this.reservedCellIds,
    required this.solvedAssignments,
    this.latentInventoryByFinalId = const {},
  });

  final Map<String, PlacedRuntimeCell> placedCellsByFinalId;
  final Map<BoardCellPosition, BoardCellEntry> boardCellMap;
  final Map<String, RuntimeComponent> componentsById;
  final Set<String> solvedWordIds;
  final Set<String> reservedCellIds;
  final Map<String, SolvedAssignment> solvedAssignments;
  final Map<String, PlacedRuntimeCell> latentInventoryByFinalId;

  PuzzleRuntimeState clone() {
    return PuzzleRuntimeState(
      placedCellsByFinalId: Map.from(placedCellsByFinalId),
      boardCellMap: Map.from(boardCellMap),
      componentsById: Map.from(componentsById),
      solvedWordIds: {...solvedWordIds},
      reservedCellIds: {...reservedCellIds},
      solvedAssignments: {
        for (final entry in solvedAssignments.entries)
          entry.key: SolvedAssignment(
            wordId: entry.value.wordId,
            assignedCellIds: {...entry.value.assignedCellIds},
            moveComponentId: entry.value.moveComponentId,
          ),
      },
      latentInventoryByFinalId: Map.from(latentInventoryByFinalId),
    );
  }
}

PuzzleRuntimeState rebuildRuntimeBoardState({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
  required Set<String> solvedWordIds,
  required Set<String> reservedCellIds,
  required Map<String, SolvedAssignment> solvedAssignments,
  int boardRows = BoardConstants.kPlayGridRows,
  int boardCols = BoardConstants.kPlayGridCols,
}) {
  final placedCellsByFinalId = <String, PlacedRuntimeCell>{};
  final boardCellMap = <BoardCellPosition, BoardCellEntry>{};
  final latentInventoryByFinalId = <String, PlacedRuntimeCell>{};
  final cellToComponentSeed = <String, String>{};
  final boardPositionDelta = _boardPositionDeltaFromActivePieces(
    pieces: activePlayAreaPieces(
      pieces,
      boardRows: boardRows,
      boardCols: boardCols,
    ),
    metadata: metadata,
  );

  for (final piece in pieces) {
    if (piece.isCompletedWordGroup) {
      continue;
    }
    if (!isPieceOnBoard(piece, boardRows, boardCols)) {
      continue;
    }

    for (final cell in piece.cells) {
      final boardRow = piece.anchorRow + cell.rowOffset;
      final boardCol = piece.anchorCol + cell.colOffset;
      final boardPos = BoardCellPosition(row: boardRow, col: boardCol);

      final finalCellId = metadata.finalCellIdForChunkLocal(
        chunkId: piece.chunkId,
        localRow: cell.rowOffset,
        localCol: cell.colOffset,
      );

      if (finalCellId == null) {
        continue;
      }

      if (reservedCellIds.contains(finalCellId) &&
          !isCellNeededByUnsolvedWord(
            cellId: finalCellId,
            solvedWordIds: solvedWordIds,
            metadata: metadata,
          )) {
        continue;
      }

      final componentSeed = 'cmp_${piece.chunkId}';
      cellToComponentSeed[finalCellId] = componentSeed;

      final placed = PlacedRuntimeCell(
        finalCellId: finalCellId,
        letter: cell.letter,
        boardRow: boardRow,
        boardCol: boardCol,
        chunkId: piece.chunkId,
        componentId: componentSeed,
      );

      placedCellsByFinalId[finalCellId] = placed;
      boardCellMap[boardPos] = BoardCellEntry(
        finalCellId: finalCellId,
        letter: cell.letter,
        chunkId: piece.chunkId,
        componentId: componentSeed,
      );
    }
  }

  for (final piece in pieces) {
    if (!piece.isCompletedWordGroup) {
      continue;
    }
    if (!isPieceOnBoard(piece, boardRows, boardCols)) {
      continue;
    }

    _indexCompletedGroupCells(
      piece: piece,
      boardCellMap: boardCellMap,
      cellToComponentSeed: cellToComponentSeed,
      placedCellsByFinalId: placedCellsByFinalId,
      componentId: 'cmp_${piece.id}',
      metadata: metadata,
      reservedCellIds: reservedCellIds,
      solvedWordIds: solvedWordIds,
      solvedAssignments: solvedAssignments,
      boardRowDelta: boardPositionDelta.rowDelta,
      boardColDelta: boardPositionDelta.colDelta,
    );
  }

  for (final piece in pieces) {
    if (piece.isCompletedWordGroup) {
      continue;
    }
    if (isPieceOnBoard(piece, boardRows, boardCols)) {
      continue;
    }

    for (final cell in piece.cells) {
      final finalCellId = metadata.finalCellIdForChunkLocal(
        chunkId: piece.chunkId,
        localRow: cell.rowOffset,
        localCol: cell.colOffset,
      );

      if (finalCellId == null || placedCellsByFinalId.containsKey(finalCellId)) {
        continue;
      }

      if (reservedCellIds.contains(finalCellId) &&
          !isCellNeededByUnsolvedWord(
            cellId: finalCellId,
            solvedWordIds: solvedWordIds,
            metadata: metadata,
          )) {
        continue;
      }

      final layoutCell = metadata.finalCellById[finalCellId];
      if (layoutCell == null) {
        continue;
      }

      latentInventoryByFinalId[finalCellId] = PlacedRuntimeCell(
        finalCellId: finalCellId,
        letter: cell.letter,
        boardRow: layoutCell.row,
        boardCol: layoutCell.col,
        chunkId: piece.chunkId,
        componentId: 'latent_${piece.chunkId}',
      );
    }
  }

  final stateWithComponents = rebuildRuntimeComponents(
    PuzzleRuntimeState(
      placedCellsByFinalId: placedCellsByFinalId,
      boardCellMap: boardCellMap,
      componentsById: const {},
      solvedWordIds: solvedWordIds,
      reservedCellIds: reservedCellIds,
      solvedAssignments: solvedAssignments,
      latentInventoryByFinalId: latentInventoryByFinalId,
    ),
  );

  logBoardStateRebuild(stateWithComponents);
  return stateWithComponents;
}

void _indexCompletedGroupCells({
  required PuzzlePiece piece,
  required Map<BoardCellPosition, BoardCellEntry> boardCellMap,
  required Map<String, String> cellToComponentSeed,
  required Map<String, PlacedRuntimeCell> placedCellsByFinalId,
  required String componentId,
  required PuzzleLayoutMetadata metadata,
  required Set<String> reservedCellIds,
  required Set<String> solvedWordIds,
  required Map<String, SolvedAssignment> solvedAssignments,
  required int boardRowDelta,
  required int boardColDelta,
}) {
  for (final cell in piece.cells) {
    final boardPos = BoardCellPosition(
      row: piece.anchorRow + cell.rowOffset,
      col: piece.anchorCol + cell.colOffset,
    );
    final finalCellId = _finalCellIdForCompletedBoardCell(
      position: boardPos,
      letter: cell.letter,
      metadata: metadata,
      reservedCellIds: reservedCellIds,
      solvedWordIds: solvedWordIds,
      solvedAssignments: solvedAssignments,
      boardRowDelta: boardRowDelta,
      boardColDelta: boardColDelta,
    );
    boardCellMap[boardPos] = BoardCellEntry(
      finalCellId: finalCellId,
      letter: cell.letter,
      chunkId: piece.chunkId,
      componentId: componentId,
    );
    cellToComponentSeed[finalCellId] = componentId;

    if (!finalCellId.startsWith('completed_')) {
      placedCellsByFinalId[finalCellId] = PlacedRuntimeCell(
        finalCellId: finalCellId,
        letter: cell.letter,
        boardRow: boardPos.row,
        boardCol: boardPos.col,
        chunkId: piece.chunkId,
        componentId: componentId,
      );
    }
  }
}

PuzzleRuntimeState rebuildRuntimeComponents(PuzzleRuntimeState state) {
  if (state.boardCellMap.isEmpty) {
    return state;
  }

  final positionToFinalId = {
    for (final entry in state.boardCellMap.entries) entry.key: entry.value,
  };

  final visited = <BoardCellPosition>{};
  final componentsById = <String, RuntimeComponent>{};
  var componentCounter = 0;

  for (final start in positionToFinalId.keys) {
    if (visited.contains(start)) {
      continue;
    }

    final queue = <BoardCellPosition>[start];
    final componentPositions = <BoardCellPosition>[];
    final componentId =
        positionToFinalId[start]!.componentId.isNotEmpty
            ? positionToFinalId[start]!.componentId
            : 'cmp_auto_$componentCounter';

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) {
        continue;
      }
      componentPositions.add(current);

      for (final neighbor in _orthogonalNeighbors(current)) {
        if (positionToFinalId.containsKey(neighbor) &&
            !visited.contains(neighbor)) {
          queue.add(neighbor);
        }
      }
    }

    final finalCellIds = <String>[];
    final chunkIds = <String>{};

    for (final position in componentPositions) {
      final entry = positionToFinalId[position]!;
      if (!entry.finalCellId.startsWith('completed_')) {
        finalCellIds.add(entry.finalCellId);
      }
      chunkIds.add(entry.chunkId);
    }

    componentsById[componentId] = RuntimeComponent(
      componentId: componentId,
      finalCellIds: finalCellIds,
      chunkIds: chunkIds.toList(),
    );
    componentCounter++;
  }

  final updatedPlaced = Map<String, PlacedRuntimeCell>.from(
    state.placedCellsByFinalId,
  );
  final updatedBoard = Map<BoardCellPosition, BoardCellEntry>.from(
    state.boardCellMap,
  );

  for (final entry in updatedBoard.entries) {
    final existing = entry.value;
    final owningComponent = componentsById.values.firstWhere(
      (component) =>
          component.finalCellIds.contains(existing.finalCellId) ||
          existing.finalCellId.startsWith('completed_'),
      orElse: () => RuntimeComponent(
        componentId: existing.componentId,
        finalCellIds: const [],
        chunkIds: const [],
      ),
    );

    updatedBoard[entry.key] = BoardCellEntry(
      finalCellId: existing.finalCellId,
      letter: existing.letter,
      chunkId: existing.chunkId,
      componentId: owningComponent.componentId,
    );
  }

  for (final entry in updatedPlaced.entries) {
    final cell = entry.value;
    updatedPlaced[entry.key] = PlacedRuntimeCell(
      finalCellId: cell.finalCellId,
      letter: cell.letter,
      boardRow: cell.boardRow,
      boardCol: cell.boardCol,
      chunkId: cell.chunkId,
      componentId: updatedBoard[BoardCellPosition(
        row: cell.boardRow,
        col: cell.boardCol,
      )]?.componentId ?? cell.componentId,
    );
  }

  final rebuilt = PuzzleRuntimeState(
    placedCellsByFinalId: updatedPlaced,
    boardCellMap: updatedBoard,
    componentsById: componentsById,
    solvedWordIds: state.solvedWordIds,
    reservedCellIds: state.reservedCellIds,
    solvedAssignments: state.solvedAssignments,
    latentInventoryByFinalId: state.latentInventoryByFinalId,
  );

  for (final component in rebuilt.componentsById.values) {
    logComponent(component);
  }

  return rebuilt;
}

Set<String> getAffectedComponentsAfterReconnect({
  required Iterable<String> movedChunkIds,
  required PuzzleRuntimeState state,
}) {
  final affected = <String>{};

  for (final chunkId in movedChunkIds) {
    for (final component in state.componentsById.values) {
      if (component.chunkIds.contains(chunkId)) {
        affected.add(component.componentId);
      }
    }
  }

  if (affected.isEmpty) {
    return state.componentsById.keys.toSet();
  }

  return affected;
}

List<BoardCellPosition> _orthogonalNeighbors(BoardCellPosition cell) {
  return [
    BoardCellPosition(row: cell.row - 1, col: cell.col),
    BoardCellPosition(row: cell.row + 1, col: cell.col),
    BoardCellPosition(row: cell.row, col: cell.col - 1),
    BoardCellPosition(row: cell.row, col: cell.col + 1),
  ];
}

Set<String> chunkIdsFromMovedPieceIds({
  required Iterable<String> movedPieceIds,
  required List<PuzzlePiece> pieces,
}) {
  final pieceById = {for (final piece in pieces) piece.id: piece};
  return {
    for (final pieceId in movedPieceIds)
      if (pieceById[pieceId] != null) pieceById[pieceId]!.chunkId,
  };
}

Set<String> completedAnswersFromSolvedWordIds(
  Set<String> solvedWordIds,
  PuzzleLayoutMetadata metadata,
) {
  return {
    for (final wordId in solvedWordIds)
      if (metadata.textForWordId(wordId) != null) metadata.textForWordId(wordId)!,
  };
}

Set<String> solvedWordIdsFromCompletedAnswers(
  Set<String> completedAnswers,
  PuzzleLayoutMetadata metadata,
) {
  final normalized = completedAnswers.map((answer) => answer.toUpperCase()).toSet();
  return {
    for (final entry in metadata.wordById.entries)
      if (normalized.contains(entry.value.text)) entry.key,
  };
}

bool isCellNeededByUnsolvedWord({
  required String cellId,
  required Set<String> solvedWordIds,
  required PuzzleLayoutMetadata metadata,
}) {
  for (final wordId in metadata.targetWordIds) {
    if (solvedWordIds.contains(wordId)) {
      continue;
    }

    if (metadata.wordById[wordId]?.cellIds.contains(cellId) ?? false) {
      return true;
    }
  }

  return false;
}

({int rowDelta, int colDelta}) boardPositionDeltaFromState(
  PuzzleRuntimeState state,
  PuzzleLayoutMetadata metadata,
) {
  for (final placed in state.placedCellsByFinalId.values) {
    final layoutCell = metadata.finalCellById[placed.finalCellId];
    if (layoutCell == null) {
      continue;
    }

    return (
      rowDelta: placed.boardRow - layoutCell.row,
      colDelta: placed.boardCol - layoutCell.col,
    );
  }

  return (rowDelta: 0, colDelta: 0);
}

String? resolveUnsolvedWordSlotAtBoardPosition({
  required BoardCellPosition position,
  required String letter,
  required PuzzleRuntimeState state,
  required PuzzleLayoutMetadata metadata,
}) {
  final delta = boardPositionDeltaFromState(state, metadata);
  final matches = <String>[];

  for (final entry in metadata.finalCellById.entries) {
    final cellId = entry.key;
    final layoutCell = entry.value;
    if (layoutCell.row + delta.rowDelta != position.row ||
        layoutCell.col + delta.colDelta != position.col) {
      continue;
    }
    if (layoutCell.letter.toUpperCase() != letter.toUpperCase()) {
      continue;
    }
    if (!isCellNeededByUnsolvedWord(
      cellId: cellId,
      solvedWordIds: state.solvedWordIds,
      metadata: metadata,
    )) {
      continue;
    }
    matches.add(cellId);
  }

  if (matches.length == 1) {
    return matches.single;
  }

  return null;
}

bool _isCrosswordIntersectionCell(
  String cellId,
  PuzzleLayoutMetadata metadata,
) {
  return (metadata.finalCellById[cellId]?.wordIds.length ?? 0) > 1;
}

String _finalCellIdForCompletedBoardCell({
  required BoardCellPosition position,
  required String letter,
  required PuzzleLayoutMetadata metadata,
  required Set<String> reservedCellIds,
  required Set<String> solvedWordIds,
  required Map<String, SolvedAssignment> solvedAssignments,
  required int boardRowDelta,
  required int boardColDelta,
}) {
  final intersectionMatches = <String>[];

  for (final cellId in reservedCellIds) {
    if (!_isCrosswordIntersectionCell(cellId, metadata)) {
      continue;
    }

    final layoutCell = metadata.finalCellById[cellId];
    if (layoutCell == null) {
      continue;
    }

    if (layoutCell.letter.toUpperCase() != letter.toUpperCase()) {
      continue;
    }

    final ownedBySolved = solvedAssignments.values.any(
      (assignment) => assignment.assignedCellIds.contains(cellId),
    );
    if (!ownedBySolved) {
      continue;
    }

    intersectionMatches.add(cellId);
  }

  if (intersectionMatches.length == 1) {
    return intersectionMatches.single;
  }

  final unsolvedWordMatches = <String>[];
  for (final entry in metadata.finalCellById.entries) {
    final cellId = entry.key;
    final layoutCell = entry.value;
    if (!_layoutCellMatchesBoardPosition(
      layoutCell: layoutCell,
      boardPosition: position,
      boardRowDelta: boardRowDelta,
      boardColDelta: boardColDelta,
    )) {
      continue;
    }
    if (layoutCell.letter.toUpperCase() != letter.toUpperCase()) {
      continue;
    }
    if (!isCellNeededByUnsolvedWord(
      cellId: cellId,
      solvedWordIds: solvedWordIds,
      metadata: metadata,
    )) {
      continue;
    }
    unsolvedWordMatches.add(cellId);
  }

  if (unsolvedWordMatches.length == 1) {
    return unsolvedWordMatches.single;
  }

  return 'completed_${position.row}_${position.col}';
}

({int rowDelta, int colDelta}) _boardPositionDeltaFromActivePieces({
  required List<PuzzlePiece> pieces,
  required PuzzleLayoutMetadata metadata,
}) {
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
      if (finalCellId == null) {
        continue;
      }

      final layoutCell = metadata.finalCellById[finalCellId];
      if (layoutCell == null) {
        continue;
      }

      return (
        rowDelta: piece.anchorRow + cell.rowOffset - layoutCell.row,
        colDelta: piece.anchorCol + cell.colOffset - layoutCell.col,
      );
    }
  }

  return (rowDelta: 0, colDelta: 0);
}

bool _layoutCellMatchesBoardPosition({
  required FinalLayoutCell layoutCell,
  required BoardCellPosition boardPosition,
  required int boardRowDelta,
  required int boardColDelta,
}) {
  return layoutCell.row + boardRowDelta == boardPosition.row &&
      layoutCell.col + boardColDelta == boardPosition.col;
}
