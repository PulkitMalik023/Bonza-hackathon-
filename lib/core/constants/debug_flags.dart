/// Temporary flag to bypass deconstructed chunks and test single-cell drag/snap.
const bool kUseDebugSingleCellTiles = false;

enum PuzzlePieceSource {
  deconstructed,
  solved,
  words,
}

const PuzzlePieceSource kPuzzlePieceSource = PuzzlePieceSource.deconstructed;

/// Legacy flag; Pulkit word-check logs use [kLogPulkitWordCheck] only.
const bool kLogPuzzleCompletion = false;

/// Filter console with "Pulkit" after tile release: targets, formed H/V words, comparisons.
const bool kLogPulkitWordCheck = true;

/// Filter console with [impossible_logic] [MOVE_STEP] after each tile release.
const bool kLogWordResolutionSteps = true;
