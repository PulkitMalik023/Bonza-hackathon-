import 'puzzle_chunk.dart';
import 'puzzle_layout.dart';

class DeconstructedPuzzle {
  const DeconstructedPuzzle({
    required this.sourceLayout,
    required this.chunks,
  });

  final PuzzleLayout sourceLayout;
  final List<PuzzleChunk> chunks;
}
