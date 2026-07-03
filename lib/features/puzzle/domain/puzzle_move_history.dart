import 'puzzle_piece.dart';
import 'piece_cell.dart';
import 'word_resolution/word_resolution_models.dart';

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
    this.solvedWordIds = const {},
    this.reservedCellIds = const {},
    this.solvedAssignments = const {},
  });

  final List<PuzzlePiece> pieces;
  final Set<String> completedAnswers;
  final Set<String> solvedWordIds;
  final Set<String> reservedCellIds;
  final Map<String, SolvedAssignment> solvedAssignments;
}

class PuzzleMoveHistory {
  final List<PuzzleMoveSnapshot> _stack = [];

  bool get canUndo => _stack.isNotEmpty;

  void push(
    List<PuzzlePiece> pieces,
    Set<String> completedAnswers, {
    Set<String> solvedWordIds = const {},
    Set<String> reservedCellIds = const {},
    Map<String, SolvedAssignment> solvedAssignments = const {},
  }) {
    _stack.add(
      PuzzleMoveSnapshot(
        pieces: clonePuzzlePieces(pieces),
        completedAnswers: {...completedAnswers},
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
