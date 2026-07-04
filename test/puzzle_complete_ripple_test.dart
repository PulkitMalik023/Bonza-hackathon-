import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/board_cell_position.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_board_state.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_complete_ripple.dart';
import 'package:jam_pro/features/puzzle/domain/puzzle_piece.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/puzzle_layout_metadata.dart';
import 'package:jam_pro/features/puzzle/domain/word_resolution/word_resolution_models.dart';
import 'package:jam_pro/features/puzzle/presentation/completion/puzzle_complete_ripple_controller.dart';

void main() {
  group('computeConnectedRippleHopDistances', () {
    test('assigns increasing hops through connected cells', () {
      final playAreaCells = {
        const BoardCellPosition(row: 0, col: 0),
        const BoardCellPosition(row: 0, col: 1),
        const BoardCellPosition(row: 0, col: 2),
        const BoardCellPosition(row: 1, col: 1),
      };

      final distances = computeConnectedRippleHopDistances(
        origin: const BoardCellPosition(row: 0, col: 0),
        playAreaCells: playAreaCells,
      );

      expect(distances[const BoardCellPosition(row: 0, col: 0)], 0);
      expect(distances[const BoardCellPosition(row: 0, col: 1)], 1);
      expect(distances[const BoardCellPosition(row: 0, col: 2)], 2);
      expect(distances[const BoardCellPosition(row: 1, col: 1)], 2);
      expect(distances.length, 4);
    });

    test('does not reach disconnected cells', () {
      final playAreaCells = {
        const BoardCellPosition(row: 0, col: 0),
        const BoardCellPosition(row: 0, col: 2),
      };

      final distances = computeConnectedRippleHopDistances(
        origin: const BoardCellPosition(row: 0, col: 0),
        playAreaCells: playAreaCells,
      );

      expect(distances.length, 1);
      expect(distances.containsKey(const BoardCellPosition(row: 0, col: 2)),
          isFalse);
    });
  });

  group('computeRippleOrigin', () {
    test('prefers moved piece cells', () {
      final piece = PuzzlePiece(
        id: 'moved',
        chunkId: 'moved',
        anchorRow: 2,
        anchorCol: 3,
        spawnAnchorRow: 0,
        spawnAnchorCol: 0,
        cells: const [
          PieceCell(letter: 'A', rowOffset: 0, colOffset: 0),
          PieceCell(letter: 'B', rowOffset: 0, colOffset: 1),
        ],
      );

      final event = PiecesChangeEvent(
        pieces: [piece],
        affectedCells: const {},
        movedPieceIds: const ['moved'],
      );

      final result = WordResolutionResult(
        pieces: const [],
        solvedWordIds: const {},
        reservedCellIds: const {},
        solvedAssignments: const {},
        newlySolvedWordIds: const {'word_0_FORK'},
        puzzleComplete: true,
        completedAnswers: const {},
      );

      final origin = computeRippleOrigin(
        event: event,
        result: result,
        metadata: _emptyMetadata(),
        solvedAssignments: const {},
      );

      expect(origin, const BoardCellPosition(row: 2, col: 3));
    });
  });

  group('rippleIntensityForCell', () {
    test('peaks mid-window and is zero outside window', () {
      const maxHop = 3;

      expect(
        rippleIntensityForCell(hop: 1, globalProgress: 0, maxHop: maxHop),
        0,
      );

      final midProgress = (1 * kRippleStaggerPerHop.inMilliseconds +
              kRippleCellWindow.inMilliseconds / 2) /
          computeRippleDuration(maxHop).inMilliseconds;
      final peak = rippleIntensityForCell(
        hop: 1,
        globalProgress: midProgress,
        maxHop: maxHop,
      );

      expect(peak, closeTo(1, 0.01));

      expect(
        rippleIntensityForCell(hop: 1, globalProgress: 1, maxHop: maxHop),
        0,
      );
    });
  });

  group('PuzzleCompleteRippleController', () {
    testWidgets('calls onComplete when animation finishes', (tester) async {
      var completed = false;
      late _RippleTestHostState hostState;

      await tester.pumpWidget(
        _RippleTestHost(
          onHostReady: (state) => hostState = state,
          onComplete: () => completed = true,
        ),
      );

      hostState.startRipple();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}

PuzzleLayoutMetadata _emptyMetadata() {
  return PuzzleLayoutMetadata(
    wordById: const {},
    finalCellById: const {},
    wordCellIndexMap: const {},
    chunkById: const {},
    wordToChunkCoverage: const {},
    targetWordIds: const [],
  );
}

class _RippleTestHost extends StatefulWidget {
  const _RippleTestHost({
    required this.onHostReady,
    required this.onComplete,
  });

  final void Function(_RippleTestHostState hostState) onHostReady;
  final VoidCallback onComplete;

  @override
  State<_RippleTestHost> createState() => _RippleTestHostState();
}

class _RippleTestHostState extends State<_RippleTestHost>
    with SingleTickerProviderStateMixin {
  PuzzleCompleteRippleController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHostReady(this);
    });
  }

  void startRipple() {
    _controller?.dispose();
    _controller = PuzzleCompleteRippleController(
      vsync: this,
      hopDistances: const {
        BoardCellPosition(row: 0, col: 0): 0,
        BoardCellPosition(row: 0, col: 1): 1,
      },
      onTick: () {
        if (mounted) {
          setState(() {});
        }
      },
      onComplete: widget.onComplete,
    )..start();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
