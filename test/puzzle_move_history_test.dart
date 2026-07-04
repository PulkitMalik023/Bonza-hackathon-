import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_move_history.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';

void main() {
  test('push and pop restores previous piece positions', () {
    final history = PuzzleMoveHistory();

    final before = [
      PuzzlePiece(
        id: 'a',
        chunkId: 'a',
        anchorRow: 0,
        anchorCol: 0,
        spawnAnchorRow: 0,
        spawnAnchorCol: 0,
        cells: const [PieceCell(letter: 'A', rowOffset: 0, colOffset: 0)],
      ),
    ];

    history.push(before, {'RED'});
    expect(history.canUndo, isTrue);

    final snapshot = history.pop();
    expect(snapshot, isNotNull);
    expect(snapshot!.pieces.first.anchorRow, 0);
    expect(snapshot.pieces.first.anchorCol, 0);
    expect(snapshot.completedAnswers, {'RED'});
    expect(history.canUndo, isFalse);
  });

  test('clear removes undo stack', () {
    final history = PuzzleMoveHistory();
    history.push(const [], {});
    history.clear();
    expect(history.canUndo, isFalse);
  });
}
