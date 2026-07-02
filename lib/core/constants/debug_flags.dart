/// Temporary flag to bypass deconstructed chunks and test single-cell drag/snap.
const bool kUseDebugSingleCellTiles = false;

enum PuzzlePieceSource {
  deconstructed,
  solved,
  words,
}

const PuzzlePieceSource kPuzzlePieceSource = PuzzlePieceSource.deconstructed;
