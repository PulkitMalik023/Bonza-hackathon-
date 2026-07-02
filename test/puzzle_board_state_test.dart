import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

void main() {
  test('buildPlayAreaLetterMap includes all pieces on grid including at home', () {
    final pieces = [
      PuzzlePiece(
        id: 'play',
        chunkId: 'play',
        anchorRow: 1,
        anchorCol: 1,
        spawnAnchorRow: 5,
        spawnAnchorCol: 0,
        cells: const [
          PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'P', rowOffset: 0, colOffset: 1),
        ],
      ),
      PuzzlePiece(
        id: 'spawn',
        chunkId: 'spawn',
        anchorRow: 5,
        anchorCol: 0,
        spawnAnchorRow: 5,
        spawnAnchorCol: 0,
        cells: const [
          PieceCell(letter: 'L', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'E', rowOffset: 0, colOffset: 1),
        ],
      ),
    ];

    final playArea = buildPlayAreaLetterMap(pieces);

    expect(playArea.length, 4);
    expect(playArea[const BoardCellPosition(row: 1, col: 1)], 'A');
    expect(playArea[const BoardCellPosition(row: 5, col: 0)], 'L');
    expect(playArea[const BoardCellPosition(row: 5, col: 1)], 'E');
  });

  test('buildBoardChangeScanScope includes tray piece cells on full grid map', () {
    final board = {
      const BoardCellPosition(row: 12, col: 3): 'N',
      const BoardCellPosition(row: 12, col: 4): 'G',
      const BoardCellPosition(row: 12, col: 5): 'O',
    };

    final scope = buildBoardChangeScanScope(
      affectedCells: {const BoardCellPosition(row: 12, col: 3)},
      playAreaBoard: board,
    );

    expect(scope, isNotEmpty);
    expect(scope.contains(const BoardCellPosition(row: 12, col: 3)), isTrue);
  });

  test('buildPlayAreaLetterMap includes completed group at formation anchor', () {
    final knifeGroup = PuzzlePiece.completedClusterGroup(
      clusterKey: 'cluster_6_0',
      anchorRow: 6,
      anchorCol: 0,
      cells: const [
        PieceCell(letter: 'K', rowOffset: 0, colOffset: 0),
        PieceCell(letter: 'N', rowOffset: 0, colOffset: 1),
        PieceCell(letter: 'I', rowOffset: 0, colOffset: 2),
        PieceCell(letter: 'F', rowOffset: 0, colOffset: 3),
        PieceCell(letter: 'E', rowOffset: 0, colOffset: 4),
      ],
      completedAnswers: {'KNIFE'},
    );

    final playArea = buildPlayAreaLetterMap([knifeGroup]);

    expect(playArea.length, 5);
    expect(playArea[const BoardCellPosition(row: 6, col: 0)], 'K');
    expect(playArea[const BoardCellPosition(row: 6, col: 4)], 'E');
    expect(isPieceAtSpawn(knifeGroup), isFalse);
  });

  test('buildBoardChangeScanScope includes completed group dropped at formation anchor', () {
    final board = {
      const BoardCellPosition(row: 6, col: 0): 'K',
      const BoardCellPosition(row: 6, col: 1): 'N',
      const BoardCellPosition(row: 6, col: 2): 'I',
      const BoardCellPosition(row: 6, col: 3): 'F',
      const BoardCellPosition(row: 6, col: 4): 'E',
    };

    final scope = buildBoardChangeScanScope(
      affectedCells: {
        const BoardCellPosition(row: 6, col: 0),
        const BoardCellPosition(row: 6, col: 4),
      },
      playAreaBoard: board,
    );

    expect(scope, isNotEmpty);
    expect(scope.contains(const BoardCellPosition(row: 6, col: 0)), isTrue);
  });

  test('getAffectedCellsForPiece unions before and after anchors', () {
    final piece = PuzzlePiece(
      id: 'chunk',
      chunkId: 'chunk',
      anchorRow: 2,
      anchorCol: 1,
      spawnAnchorRow: 5,
      spawnAnchorCol: 0,
      cells: const [
        PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
      ],
    );

    final affected = getAffectedCellsForPiece(
      piece: piece,
      previousAnchorRow: 5,
      previousAnchorCol: 0,
    );

    expect(affected, {
      const BoardCellPosition(row: 5, col: 0),
      const BoardCellPosition(row: 2, col: 1),
    });
  });

  test('getAllPlayAreaCells returns every occupied play-area key', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'A',
      const BoardCellPosition(row: 1, col: 2): 'B',
    };

    expect(getAllPlayAreaCells(board), board.keys.toSet());
  });

  test('getConnectedPlayAreaCells flood-fills from seeds', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'R',
      const BoardCellPosition(row: 0, col: 1): 'E',
      const BoardCellPosition(row: 0, col: 2): 'D',
      const BoardCellPosition(row: 1, col: 2): 'X',
      const BoardCellPosition(row: 2, col: 2): 'Y',
      const BoardCellPosition(row: 5, col: 5): 'Z',
    };

    final connected = getConnectedPlayAreaCells(
      seedCells: {const BoardCellPosition(row: 2, col: 2)},
      playAreaBoard: board,
    );

    expect(connected, {
      const BoardCellPosition(row: 0, col: 0),
      const BoardCellPosition(row: 0, col: 1),
      const BoardCellPosition(row: 0, col: 2),
      const BoardCellPosition(row: 1, col: 2),
      const BoardCellPosition(row: 2, col: 2),
    });
    expect(connected.contains(const BoardCellPosition(row: 5, col: 5)), isFalse);
  });

  test('buildBoardChangeScanScope includes full horizontal line segment', () {
    final board = {
      const BoardCellPosition(row: 0, col: 0): 'F',
      const BoardCellPosition(row: 0, col: 1): 'O',
      const BoardCellPosition(row: 0, col: 2): 'R',
      const BoardCellPosition(row: 0, col: 3): 'K',
    };

    final scope = buildBoardChangeScanScope(
      affectedCells: {const BoardCellPosition(row: 0, col: 3)},
      playAreaBoard: board,
    );

    expect(scope, board.keys.toSet());
  });
}
