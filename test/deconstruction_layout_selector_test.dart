import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/deconstruction_layout_selector.dart';
import 'package:jam_pro/features/puzzle/data/deconstructors/puzzle_deconstructor.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/deconstructed_puzzle.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_solved_checker.dart';

void main() {
  final generator = PuzzleLayoutGenerator();
  final deconstructor = PuzzleDeconstructor();

  test('buildForLayoutIndex returns null for empty layouts list', () {
    expect(buildForLayoutIndex(const [], 0), isNull);
  });

  test('buildForLayoutIndex succeeds with freshly generated layouts', () {
    final layouts = generator.generateAllLayouts(['SPOON', 'FORK', 'KNIFE']);
    expect(layouts, isNotEmpty);

    final result = buildForLayoutIndex(layouts, 0);
    expect(result, isNotNull);
  });

  test('buildForLayoutIndex returns first deconstructable layout', () {
    final layouts = generator.generateAllLayouts(['SPOON', 'FORK', 'KNIFE']);
    expect(layouts, isNotEmpty);

    final result = buildForLayoutIndex(layouts, 0);
    expect(result, isNotNull);
    expect(result!.layoutIndex, 0);
    expect(result.deconstructed.sourceLayout, layouts.first);
  });

  test('buildForLayoutIndex wraps and finds a layout when start index fails', () {
    final failingDeconstructor = _FailingForFirstLayoutDeconstructor(
      realDeconstructor: deconstructor,
    );
    final layouts = generator.generateAllLayouts(['RED', 'BLUE', 'GREEN']);

    final result = buildForLayoutIndex(
      layouts,
      0,
      deconstructor: failingDeconstructor,
    );

    expect(result, isNotNull);
    expect(result!.layoutIndex, 1);
    expect(
      isPuzzleSolved(
        deconstructed: result.deconstructed,
        pieces: result.deconstructed.chunks
            .map(
              (chunk) => PuzzlePiece.fromChunk(
                chunk,
                anchorRow: chunk.solvedMinRow,
                anchorCol: chunk.solvedMinCol,
              ),
            )
            .toList(),
        boardRows: result.layout.maxRow - result.layout.minRow + 1,
        boardCols: result.layout.maxCol - result.layout.minCol + 1,
      ),
      isTrue,
    );
  });
}

class _FailingForFirstLayoutDeconstructor extends PuzzleDeconstructor {
  _FailingForFirstLayoutDeconstructor({required this.realDeconstructor});

  final PuzzleDeconstructor realDeconstructor;
  var _calls = 0;

  @override
  DeconstructedPuzzle? tryBuild(PuzzleLayout layout) {
    if (_calls == 0) {
      _calls++;
      return null;
    }
    return realDeconstructor.tryBuild(layout);
  }
}
