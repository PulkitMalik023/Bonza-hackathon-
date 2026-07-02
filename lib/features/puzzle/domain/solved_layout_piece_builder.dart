import '../data/models/puzzle_layout.dart';
import 'piece_cell.dart';
import 'puzzle_piece_state.dart';

const kSolvedPieceId = 'solved_piece';

/// Builds a single connected piece representing the full solved layout.
PuzzlePieceState buildSolvedPiece(PuzzleLayout layout) {
  final localCells = layout.occupiedCells
      .map(
        (cell) => PieceCell(
          letter: cell.letter,
          rowOffset: cell.row - layout.minRow,
          colOffset: cell.col - layout.minCol,
        ),
      )
      .toList();

  return PuzzlePieceState(
    id: kSolvedPieceId,
    localCells: localCells,
    anchorRow: 0,
    anchorCol: 0,
    spawnAnchorRow: 0,
    spawnAnchorCol: 0,
  );
}
