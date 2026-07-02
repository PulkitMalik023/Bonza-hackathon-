/// Temporary flag to bypass deconstructed chunks and test single-cell drag/snap.
const bool kUseDebugSingleCellTiles = false;

enum PuzzlePieceSource {
  deconstructed,
  solved,
  words,
}

const PuzzlePieceSource kPuzzlePieceSource = PuzzlePieceSource.deconstructed;

/// Logs word/puzzle completion checks, grouping, and drop results.
const bool kLogPuzzleCompletion = true;
