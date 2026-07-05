import '../../../core/constants/board_constants.dart';
import '../data/models/placed_word.dart';
import 'board_cell_position.dart';
import 'board_line_word_detector.dart';
import 'puzzle_piece.dart';
import 'puzzle_solved_checker.dart';

class PiecesChangeEvent {
  const PiecesChangeEvent({
    required this.pieces,
    required this.affectedCells,
    this.movedPieceIds = const [],
  });

  final List<PuzzlePiece> pieces;
  final Set<BoardCellPosition> affectedCells;
  final List<String> movedPieceIds;
}

bool isPieceAtSpawn(PuzzlePiece piece) {
  // Completed groups stay on the play area even when anchor matches their
  // formation position (spawnAnchor is set there at grouping time).
  if (piece.isCompletedWordGroup) {
    return false;
  }

  return piece.anchorRow == piece.spawnAnchorRow &&
      piece.anchorCol == piece.spawnAnchorCol;
}

List<PuzzlePiece> activePlayAreaPieces(
  List<PuzzlePiece> pieces, {
  int boardRows = BoardConstants.kPlayGridRows,
  int boardCols = BoardConstants.kPlayGridCols,
}) {
  return [
    for (final piece in pieces)
      if (isPieceOnBoard(piece, boardRows, boardCols))
        piece,
  ];
}

Map<BoardCellPosition, String> buildBoardLetterMap(List<PuzzlePiece> pieces) {
  final board = <BoardCellPosition, String>{};

  for (final piece in pieces) {
    for (final cell in piece.cells) {
      final position = BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      );
      board[position] = cell.letter;
    }
  }

  return board;
}

Map<BoardCellPosition, String> buildPlayAreaLetterMap(
  List<PuzzlePiece> pieces, {
  int boardRows = BoardConstants.kPlayGridRows,
  int boardCols = BoardConstants.kPlayGridCols,
}) {
  return buildBoardLetterMap(
    activePlayAreaPieces(
      pieces,
      boardRows: boardRows,
      boardCols: boardCols,
    ),
  );
}

Set<BoardCellPosition> getAffectedCellsForPiece({
  required PuzzlePiece piece,
  required int previousAnchorRow,
  required int previousAnchorCol,
}) {
  final affected = <BoardCellPosition>{};
  affected.addAll(
    piece.getOccupiedCellsAt(previousAnchorRow, previousAnchorCol),
  );
  affected.addAll(piece.getOccupiedCells());
  return affected;
}

String wordKey(PlacedWord word, int index) =>
    'word_${index}_${word.word.toUpperCase()}';

String clusterKeyFromCells(Map<BoardCellPosition, String> cells) {
  final sorted = cells.keys.toList()
    ..sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return a.col.compareTo(b.col);
    });

  return 'cluster_${sorted.map((cell) => '${cell.row}_${cell.col}').join('_')}';
}

List<BoardCellPosition> _orthogonalNeighbors(BoardCellPosition cell) {
  return [
    BoardCellPosition(row: cell.row - 1, col: cell.col),
    BoardCellPosition(row: cell.row + 1, col: cell.col),
    BoardCellPosition(row: cell.row, col: cell.col - 1),
    BoardCellPosition(row: cell.row, col: cell.col + 1),
  ];
}

Set<BoardCellPosition> getAllPlayAreaCells(
  Map<BoardCellPosition, String> playAreaBoard,
) {
  return playAreaBoard.keys.toSet();
}

Set<BoardCellPosition> getConnectedPlayAreaCells({
  required Set<BoardCellPosition> seedCells,
  required Map<BoardCellPosition, String> playAreaBoard,
}) {
  final connected = <BoardCellPosition>{};
  final queue = <BoardCellPosition>[
    for (final cell in seedCells)
      if (playAreaBoard.containsKey(cell)) cell,
  ];

  while (queue.isNotEmpty) {
    final cell = queue.removeLast();
    if (!connected.add(cell)) {
      continue;
    }

    for (final neighbor in _orthogonalNeighbors(cell)) {
      if (playAreaBoard.containsKey(neighbor) && !connected.contains(neighbor)) {
        queue.add(neighbor);
      }
    }
  }

  return connected;
}

Set<BoardCellPosition> expandPlayAreaSeedsWithOrthogonalNeighbors({
  required Set<BoardCellPosition> seedCells,
  required Map<BoardCellPosition, String> playAreaBoard,
}) {
  final expanded = <BoardCellPosition>{...seedCells};

  for (final cell in seedCells) {
    for (final neighbor in _orthogonalNeighbors(cell)) {
      if (playAreaBoard.containsKey(neighbor)) {
        expanded.add(neighbor);
      }
    }
  }

  return expanded;
}

Map<BoardCellPosition, PuzzlePiece> buildBoardCellOwnershipMap(
  List<PuzzlePiece> pieces,
) {
  final ownership = <BoardCellPosition, PuzzlePiece>{};

  for (final piece in pieces) {
    for (final cell in piece.cells) {
      ownership[BoardCellPosition(
        row: piece.anchorRow + cell.rowOffset,
        col: piece.anchorCol + cell.colOffset,
      )] = piece;
    }
  }

  return ownership;
}

Map<BoardCellPosition, String> expandToContributingComponentCells({
  required Iterable<BoardCellPosition> matchedCells,
  required List<PuzzlePiece> pieces,
  required Map<BoardCellPosition, String> playAreaBoard,
}) {
  final ownership = buildBoardCellOwnershipMap(pieces);
  final expanded = <BoardCellPosition, String>{};

  for (final cell in matchedCells) {
    final owner = ownership[cell];
    if (owner == null) {
      final letter = playAreaBoard[cell];
      if (letter != null) {
        expanded[cell] = letter;
      }
      continue;
    }

    for (final pieceCell in owner.cells) {
      final position = BoardCellPosition(
        row: owner.anchorRow + pieceCell.rowOffset,
        col: owner.anchorCol + pieceCell.colOffset,
      );
      expanded[position] = pieceCell.letter;
    }
  }

  return expanded;
}

Set<BoardCellPosition> buildBoardChangeScanScope({
  required Set<BoardCellPosition> affectedCells,
  required Map<BoardCellPosition, String> playAreaBoard,
}) {
  final playAreaSeeds = affectedCells
      .where((cell) => playAreaBoard.containsKey(cell))
      .toSet();

  if (playAreaSeeds.isEmpty) {
    return const {};
  }

  final widenedSeeds = expandPlayAreaSeedsWithOrthogonalNeighbors(
    seedCells: playAreaSeeds,
    playAreaBoard: playAreaBoard,
  );

  final connected = getConnectedPlayAreaCells(
    seedCells: widenedSeeds,
    playAreaBoard: playAreaBoard,
  );

  return expandScanScopeWithLineSegments(
    baseScope: connected,
    board: playAreaBoard,
  );
}

Set<BoardCellPosition> buildInitializationScanScope(
  Map<BoardCellPosition, String> playAreaBoard,
) {
  final allCells = getAllPlayAreaCells(playAreaBoard);
  if (allCells.isEmpty) {
    return const {};
  }

  return expandScanScopeWithLineSegments(
    baseScope: allCells,
    board: playAreaBoard,
  );
}
