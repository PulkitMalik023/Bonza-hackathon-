import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/completed_cluster_builder.dart';
import 'package:jam_pro/features/puzzle/domain/completed_word_grouper.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

void main() {
  test('cluster grouping replaces source pieces with one completed group', () {
    final pieces = [
      PuzzlePiece(
        id: 'chunk_a',
        chunkId: 'chunk_a',
        anchorRow: 2,
        anchorCol: 0,
        spawnAnchorRow: 5,
        spawnAnchorCol: 0,
        cells: const [
          PieceCell(letter: 'R', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'E', rowOffset: 0, colOffset: 1),
        ],
      ),
      PuzzlePiece(
        id: 'chunk_b',
        chunkId: 'chunk_b',
        anchorRow: 2,
        anchorCol: 2,
        spawnAnchorRow: 5,
        spawnAnchorCol: 3,
        cells: const [
          PieceCell(letter: 'D', rowOffset: 0, colOffset: 0),
        ],
      ),
    ];

    final cluster = CompletedCluster(
      answers: {'RED'},
      cells: {
        const BoardCellPosition(row: 2, col: 0): 'R',
        const BoardCellPosition(row: 2, col: 1): 'E',
        const BoardCellPosition(row: 2, col: 2): 'D',
      },
    );

    final grouped = applyCompletedClusterGrouping(
      pieces: pieces,
      cluster: cluster,
    );

    final completedGroups =
        grouped.where((piece) => piece.isCompletedWordGroup).toList();
    expect(completedGroups, hasLength(1));
    expect(completedGroups.first.cells.length, 3);
    expect(completedGroups.first.completedAnswers, {'RED'});

    final board = buildBoardLetterMap(grouped);
    expect(board[const BoardCellPosition(row: 2, col: 0)], 'R');
    expect(board[const BoardCellPosition(row: 2, col: 2)], 'D');
  });
}
