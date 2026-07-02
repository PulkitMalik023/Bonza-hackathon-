import '../models/deconstructed_puzzle.dart';
import '../models/puzzle_layout.dart';
import 'puzzle_deconstructor.dart';

class DeconstructionResult {
  const DeconstructionResult({
    required this.layout,
    required this.layoutIndex,
    required this.deconstructed,
  });

  final PuzzleLayout layout;
  final int layoutIndex;
  final DeconstructedPuzzle deconstructed;
}

DeconstructionResult? buildForLayoutIndex(
  List<PuzzleLayout> layouts,
  int startIndex, {
  PuzzleDeconstructor? deconstructor,
}) {
  if (layouts.isEmpty) {
    return null;
  }

  final builder = deconstructor ?? PuzzleDeconstructor();

  for (var offset = 0; offset < layouts.length; offset++) {
    final index = (startIndex + offset) % layouts.length;
    final layout = layouts[index];
    final deconstructed = builder.tryBuild(layout);
    if (deconstructed != null) {
      return DeconstructionResult(
        layout: layout,
        layoutIndex: index,
        deconstructed: deconstructed,
      );
    }
  }

  return null;
}
