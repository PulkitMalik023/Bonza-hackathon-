import 'puzzle_piece.dart';
import 'piece_cell.dart';

List<PuzzlePiece> clonePuzzlePieces(List<PuzzlePiece> pieces) {
  return pieces
      .map(
        (piece) => PuzzlePiece(
          id: piece.id,
          chunkId: piece.chunkId,
          anchorRow: piece.anchorRow,
          anchorCol: piece.anchorCol,
          spawnAnchorRow: piece.spawnAnchorRow,
          spawnAnchorCol: piece.spawnAnchorCol,
          cells: [
            for (final cell in piece.cells)
              PieceCell(
                letter: cell.letter,
                rowOffset: cell.rowOffset,
                colOffset: cell.colOffset,
              ),
          ],
          isCompletedWordGroup: piece.isCompletedWordGroup,
          completedWordKey: piece.completedWordKey,
          completedAnswers: {...piece.completedAnswers},
        ),
      )
      .toList();
}

class PuzzleMoveSnapshot {
  const PuzzleMoveSnapshot({
    required this.pieces,
    required this.completedAnswers,
  });

  final List<PuzzlePiece> pieces;
  final Set<String> completedAnswers;
}

class PuzzleMoveHistory {
  final List<PuzzleMoveSnapshot> _stack = [];

  bool get canUndo => _stack.isNotEmpty;

  void push(List<PuzzlePiece> pieces, Set<String> completedAnswers) {
    _stack.add(
      PuzzleMoveSnapshot(
        pieces: clonePuzzlePieces(pieces),
        completedAnswers: {...completedAnswers},
      ),
    );
  }

  PuzzleMoveSnapshot? pop() {
    if (_stack.isEmpty) {
      return null;
    }
    return _stack.removeLast();
  }

  void clear() {
    _stack.clear();
  }
}
