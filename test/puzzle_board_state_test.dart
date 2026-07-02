import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

void main() {
  test('buildPlayAreaLetterMap excludes pieces still at spawn', () {
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

    expect(playArea.length, 2);
    expect(playArea[const BoardCellPosition(row: 1, col: 1)], 'A');
    expect(playArea.containsKey(const BoardCellPosition(row: 5, col: 0)), isFalse);
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
}
