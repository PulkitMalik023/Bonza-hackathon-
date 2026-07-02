import 'dart:math';

import 'board_cell_position.dart';
import 'completed_cluster_builder.dart';
import 'piece_cell.dart';
import 'puzzle_board_state.dart';
import 'puzzle_piece.dart';
import 'word_completion_debug.dart';

List<PuzzlePiece> applyCompletedClusterGrouping({
  required List<PuzzlePiece> pieces,
  required CompletedCluster cluster,
}) {
  final clusterPositions = cluster.cells.keys.toSet();
  final piecesBefore = pieces.length;
  final strippedPieceIds = <String>[];

  final stripped = _stripCellsFromPieces(
    pieces,
    clusterPositions,
    onPieceStripped: (pieceId) => strippedPieceIds.add(pieceId),
  );

  final minRow = cluster.cells.keys.map((cell) => cell.row).reduce(min);
  final minCol = cluster.cells.keys.map((cell) => cell.col).reduce(min);

  final groupCells = cluster.cells.entries
      .map(
        (entry) => PieceCell(
          letter: entry.value,
          rowOffset: entry.key.row - minRow,
          colOffset: entry.key.col - minCol,
        ),
      )
      .toList();

  final groupPiece = PuzzlePiece.completedClusterGroup(
    clusterKey: cluster.id,
    anchorRow: minRow,
    anchorCol: minCol,
    cells: groupCells,
    completedAnswers: cluster.answers,
  );

  final existingGroupIds = stripped
      .where((piece) => piece.isCompletedWordGroup)
      .map((piece) => piece.id)
      .toList();

  final merged = _mergeOverlappingCompletedGroups([
    ...stripped,
    groupPiece,
  ]);

  final mergedGroupIds = merged
      .where((piece) => piece.isCompletedWordGroup)
      .map((piece) => piece.id)
      .where((id) => !existingGroupIds.contains(id) && id != groupPiece.id)
      .toList();

  final groupPieces =
      merged.where((piece) => piece.isCompletedWordGroup).toList();
  final resultGroup = groupPieces.firstWhere(
    (piece) => piece.id == groupPiece.id || piece.completedWordKey == cluster.id,
    orElse: () => groupPieces.isNotEmpty ? groupPieces.last : groupPiece,
  );

  logClusterGrouped(
    clusterId: cluster.id,
    answers: cluster.answers,
    groupId: resultGroup.id,
    cellCount: resultGroup.cells.length,
    piecesBefore: piecesBefore,
    piecesAfter: merged.length,
    strippedPieceIds: strippedPieceIds,
    mergedGroupIds: mergedGroupIds,
  );

  return merged;
}

List<PuzzlePiece> _stripCellsFromPieces(
  List<PuzzlePiece> pieces,
  Set<BoardCellPosition> clusterPositions, {
  void Function(String pieceId)? onPieceStripped,
}) {
  final result = <PuzzlePiece>[];

  for (final piece in pieces) {
    if (piece.isCompletedWordGroup) {
      result.add(piece);
      continue;
    }

    final remainingBoardCells = <BoardCellPosition, String>{};
    var removedCellCount = 0;
    for (final cell in piece.cells) {
      final position = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );
      if (!clusterPositions.contains(position)) {
        remainingBoardCells[position] = cell.letter;
      } else {
        removedCellCount++;
      }
    }

    if (remainingBoardCells.isEmpty) {
      if (removedCellCount > 0) {
        onPieceStripped?.call(piece.id);
      }
      continue;
    }

    if (removedCellCount > 0) {
      onPieceStripped?.call(piece.id);
    }

    result.add(_pieceFromBoardCells(
      remainingBoardCells,
      id: piece.id,
      chunkId: piece.chunkId,
      spawnAnchorRow: piece.spawnAnchorRow,
      spawnAnchorCol: piece.spawnAnchorCol,
    ));
  }

  return result;
}

List<PuzzlePiece> _mergeOverlappingCompletedGroups(List<PuzzlePiece> pieces) {
  final others = pieces.where((piece) => !piece.isCompletedWordGroup).toList();
  var groups = pieces.where((piece) => piece.isCompletedWordGroup).toList();

  if (groups.length <= 1) {
    return [...others, ...groups];
  }

  var changed = true;
  while (changed) {
    changed = false;

    for (var index = 0; index < groups.length; index++) {
      for (var otherIndex = index + 1; otherIndex < groups.length; otherIndex++) {
        if (!_piecesOverlap(groups[index], groups[otherIndex])) {
          continue;
        }

        final combinedCells = {
          ..._boardCellsFromPiece(groups[index]),
          ..._boardCellsFromPiece(groups[otherIndex]),
        };

        groups[index] = _pieceFromBoardCells(
          combinedCells,
          id: clusterKeyFromCells(combinedCells),
          chunkId: clusterKeyFromCells(combinedCells),
          spawnAnchorRow: combinedCells.keys.map((cell) => cell.row).reduce(min),
          spawnAnchorCol: combinedCells.keys.map((cell) => cell.col).reduce(min),
          isCompletedWordGroup: true,
          completedWordKey: groups[index].completedWordKey,
        );
        groups.removeAt(otherIndex);
        changed = true;
        break;
      }

      if (changed) {
        break;
      }
    }
  }

  return [...others, ...groups];
}

bool _piecesOverlap(PuzzlePiece first, PuzzlePiece second) {
  final firstCells = _boardCellsFromPiece(first);
  final secondCells = _boardCellsFromPiece(second);
  return firstCells.keys.any(secondCells.containsKey);
}

Map<BoardCellPosition, String> _boardCellsFromPiece(PuzzlePiece piece) {
  final cells = <BoardCellPosition, String>{};
  for (final cell in piece.cells) {
    cells[BoardCellPosition(
      row: piece.anchorRow + cell.rowOffset,
      col: piece.anchorCol + cell.colOffset,
    )] = cell.letter;
  }
  return cells;
}

PuzzlePiece _pieceFromBoardCells(
  Map<BoardCellPosition, String> boardCells, {
  required String id,
  required String chunkId,
  required int spawnAnchorRow,
  required int spawnAnchorCol,
  bool isCompletedWordGroup = false,
  String? completedWordKey,
}) {
  if (boardCells.isEmpty) {
    throw ArgumentError('Cannot build piece from empty board cells');
  }

  final minRow = boardCells.keys.map((cell) => cell.row).reduce(min);
  final minCol = boardCells.keys.map((cell) => cell.col).reduce(min);

  final cells = boardCells.entries
      .map(
        (entry) => PieceCell(
          letter: entry.value,
          rowOffset: entry.key.row - minRow,
          colOffset: entry.key.col - minCol,
        ),
      )
      .toList();

  return PuzzlePiece(
    id: id,
    chunkId: chunkId,
    anchorRow: minRow,
    anchorCol: minCol,
    spawnAnchorRow: spawnAnchorRow,
    spawnAnchorCol: spawnAnchorCol,
    cells: cells,
    isCompletedWordGroup: isCompletedWordGroup,
    completedWordKey: completedWordKey,
  );
}
