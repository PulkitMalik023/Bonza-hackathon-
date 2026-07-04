import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/domain/piece_cell.dart';
import 'package:jam_pro/features/puzzle/presentation/widgets/puzzle_completed_group_seams.dart';

void main() {
  group('PuzzleCompletedGroupSeams', () {
    testWidgets('draws vertical seams between horizontally adjacent cells', (
      tester,
    ) async {
      const tileSize = 50.0;
      final cells = [
        const PieceCell(letter: 'F', rowOffset: 0, colOffset: 0),
        const PieceCell(letter: 'O', rowOffset: 0, colOffset: 1),
        const PieceCell(letter: 'R', rowOffset: 0, colOffset: 2),
        const PieceCell(letter: 'K', rowOffset: 0, colOffset: 3),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: tileSize * 4,
              height: tileSize,
              child: PuzzleCompletedGroupSeams(
                cells: cells,
                tileSize: tileSize,
                connectionSeamOpacity: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ColoredBox), findsNWidgets(3));
    });

    testWidgets('draws seams for cross-shaped completed groups', (tester) async {
      const tileSize = 50.0;
      final cells = [
        const PieceCell(letter: 'T', rowOffset: 0, colOffset: 0),
        const PieceCell(letter: 'U', rowOffset: 1, colOffset: 0),
        const PieceCell(letter: 'L', rowOffset: 0, colOffset: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: tileSize * 2,
              height: tileSize * 2,
              child: PuzzleCompletedGroupSeams(
                cells: cells,
                tileSize: tileSize,
                connectionSeamOpacity: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ColoredBox), findsNWidgets(2));
    });

    testWidgets('renders nothing when opacity is zero', (tester) async {
      const tileSize = 50.0;
      final cells = [
        const PieceCell(letter: 'T', rowOffset: 0, colOffset: 0),
        const PieceCell(letter: 'U', rowOffset: 1, colOffset: 0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuzzleCompletedGroupSeams(
              cells: cells,
              tileSize: tileSize,
              connectionSeamOpacity: 0,
            ),
          ),
        ),
      );

      expect(find.byType(ColoredBox), findsNothing);
    });
  });
}
