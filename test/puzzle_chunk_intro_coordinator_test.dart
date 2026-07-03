import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/presentation/intro/puzzle_chunk_intro_coordinator.dart';
import 'package:jam_pro/features/puzzle/presentation/intro/puzzle_intro_animation_constants.dart';

PuzzlePiece _testPiece(String id) {
  return PuzzlePiece(
    id: id,
    chunkId: id,
    anchorRow: 0,
    anchorCol: 0,
    spawnAnchorRow: 0,
    spawnAnchorCol: 0,
    cells: const [
      PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
    ],
  );
}

void main() {
  final pieces = [_testPiece('chunk-a'), _testPiece('chunk-b')];

  test('chunk 0 starts with hidden real tile and no ghost at t=0', () {
    final values = PuzzleChunkIntroCoordinator.valuesAtElapsed(
      pieces: pieces,
      elapsed: Duration.zero,
    );

    final chunk0 = values['chunk-a']!;
    expect(chunk0.realOpacity, 0);
    expect(chunk0.showGhost, isFalse);
    expect(chunk0.isIntroFinished, isFalse);
  });

  test('chunk 0 shows ghost after ghost appear phase', () {
    final values = PuzzleChunkIntroCoordinator.valuesAtElapsed(
      pieces: pieces,
      elapsed: PuzzleIntroAnimationConstants.ghostAppearDuration,
    );

    final chunk0 = values['chunk-a']!;
    expect(chunk0.ghostOpacity, closeTo(PuzzleIntroAnimationConstants.ghostMaxOpacity, 0.001));
    expect(chunk0.ghostScale, closeTo(PuzzleIntroAnimationConstants.ghostEndScale, 0.001));
    expect(chunk0.showGhost, isTrue);
    expect(chunk0.realOpacity, 0);
  });

  test('chunk 0 finishes intro after settle phase', () {
    final totalDuration = Duration(
      milliseconds: PuzzleIntroAnimationConstants.ghostAppearDuration.inMilliseconds +
          PuzzleIntroAnimationConstants.realEnterDuration.inMilliseconds +
          PuzzleIntroAnimationConstants.settleDuration.inMilliseconds,
    );

    final values = PuzzleChunkIntroCoordinator.valuesAtElapsed(
      pieces: pieces,
      elapsed: totalDuration,
    );

    final chunk0 = values['chunk-a']!;
    expect(chunk0.isIntroFinished, isTrue);
    expect(chunk0.realOpacity, 1);
    expect(chunk0.realOffsetY, 0);
    expect(chunk0.realScale, closeTo(1, 0.001));
    expect(chunk0.showGhost, isFalse);
  });

  test('chunk 1 is staggered behind chunk 0', () {
    final staggeredElapsed = Duration(
      milliseconds: PuzzleIntroAnimationConstants.pieceStaggerDelay.inMilliseconds,
    );

    final values = PuzzleChunkIntroCoordinator.valuesAtElapsed(
      pieces: pieces,
      elapsed: staggeredElapsed,
    );

    final chunk0 = values['chunk-a']!;
    final chunk1 = values['chunk-b']!;

    expect(chunk0.ghostOpacity, greaterThan(0));
    expect(chunk0.realOpacity, 0);
    expect(chunk1.realOpacity, 0);
    expect(chunk1.showGhost, isFalse);
  });

  test('chunk 0 real enter starts before chunk 1 at stagger offset', () {
    final elapsed = Duration(
      milliseconds:
          PuzzleIntroAnimationConstants.ghostAppearDuration.inMilliseconds + 1,
    );

    final values = PuzzleChunkIntroCoordinator.valuesAtElapsed(
      pieces: pieces,
      elapsed: elapsed,
    );

    final chunk0 = values['chunk-a']!;
    final chunk1 = values['chunk-b']!;

    expect(chunk0.realOpacity, greaterThan(0));
    expect(chunk1.realOpacity, 0);
  });
}
