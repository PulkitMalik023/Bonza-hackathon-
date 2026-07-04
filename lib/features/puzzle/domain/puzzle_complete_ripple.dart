import 'dart:math';

import 'puzzle_board_state.dart';
import 'board_cell_position.dart';
import 'word_resolution/puzzle_layout_metadata.dart';
import 'word_resolution/word_resolution_models.dart';

const Duration kRippleStaggerPerHop = Duration(milliseconds: 45);
const Duration kRippleCellWindow = Duration(milliseconds: 200);

Duration computeRippleDuration(int maxHop) {
  return kRippleCellWindow + kRippleStaggerPerHop * maxHop;
}

int maxHopFromDistances(Map<BoardCellPosition, int> hopDistances) {
  if (hopDistances.isEmpty) {
    return 0;
  }
  return hopDistances.values.reduce(max);
}

BoardCellPosition? computeRippleOrigin({
  required PiecesChangeEvent event,
  required WordResolutionResult result,
  required PuzzleLayoutMetadata metadata,
  required Map<String, SolvedAssignment> solvedAssignments,
}) {
  final movedCells = <BoardCellPosition>[];
  for (final piece in event.pieces) {
    if (event.movedPieceIds.contains(piece.id)) {
      movedCells.addAll(piece.getOccupiedCells());
    }
  }

  if (movedCells.isNotEmpty) {
    return _cellNearestCentroid(movedCells);
  }

  final fallbackCells = <BoardCellPosition>[];
  for (final wordId in result.newlySolvedWordIds) {
    final assignment = solvedAssignments[wordId];
    if (assignment == null) {
      continue;
    }
    fallbackCells.addAll(
      boardPositionsFromFinalCellIds(
        assignment.assignedCellIds,
        metadata.finalCellById,
      ),
    );
  }

  if (fallbackCells.isNotEmpty) {
    return _cellNearestCentroid(fallbackCells);
  }

  return null;
}

Map<BoardCellPosition, int> computeConnectedRippleHopDistances({
  required BoardCellPosition origin,
  required Set<BoardCellPosition> playAreaCells,
}) {
  if (!playAreaCells.contains(origin)) {
    return const {};
  }

  final distances = <BoardCellPosition, int>{origin: 0};
  final queue = <BoardCellPosition>[origin];

  for (var index = 0; index < queue.length; index++) {
    final cell = queue[index];
    final hop = distances[cell]!;

    for (final neighbor in _orthogonalNeighbors(cell)) {
      if (!playAreaCells.contains(neighbor) ||
          distances.containsKey(neighbor)) {
        continue;
      }

      distances[neighbor] = hop + 1;
      queue.add(neighbor);
    }
  }

  return distances;
}

double rippleIntensityForCell({
  required int hop,
  required double globalProgress,
  required int maxHop,
}) {
  if (maxHop < 0 || globalProgress <= 0) {
    return 0;
  }

  final totalMs = computeRippleDuration(maxHop).inMilliseconds;
  if (totalMs <= 0) {
    return 0;
  }

  final timeMs = globalProgress * totalMs;
  final startMs = hop * kRippleStaggerPerHop.inMilliseconds;
  final localMs = timeMs - startMs;

  if (localMs < 0 || localMs > kRippleCellWindow.inMilliseconds) {
    return 0;
  }

  final localProgress = localMs / kRippleCellWindow.inMilliseconds;
  return sin(localProgress * pi);
}

BoardCellPosition _cellNearestCentroid(List<BoardCellPosition> cells) {
  final avgRow = cells.map((cell) => cell.row).reduce((a, b) => a + b) /
      cells.length;
  final avgCol = cells.map((cell) => cell.col).reduce((a, b) => a + b) /
      cells.length;

  return cells.reduce((best, cell) {
    final bestDistance = _centroidDistance(best, avgRow, avgCol);
    final cellDistance = _centroidDistance(cell, avgRow, avgCol);
    return cellDistance < bestDistance ? cell : best;
  });
}

double _centroidDistance(BoardCellPosition cell, double avgRow, double avgCol) {
  final rowDelta = cell.row - avgRow;
  final colDelta = cell.col - avgCol;
  return rowDelta * rowDelta + colDelta * colDelta;
}

List<BoardCellPosition> _orthogonalNeighbors(BoardCellPosition cell) {
  return [
    BoardCellPosition(row: cell.row - 1, col: cell.col),
    BoardCellPosition(row: cell.row + 1, col: cell.col),
    BoardCellPosition(row: cell.row, col: cell.col - 1),
    BoardCellPosition(row: cell.row, col: cell.col + 1),
  ];
}
