import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/presentation/widgets/puzzle_bottom_action_bar.dart';

void main() {
  testWidgets('shows undo, hint, and full grid buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleBottomActionBar(
            onUndo: () {},
            onHint: () {},
            onFullGrid: () {},
          ),
        ),
      ),
    );

    expect(find.text('UNDO'), findsOneWidget);
    expect(find.text('HINT'), findsOneWidget);
    expect(find.text('FULL GRID'), findsOneWidget);
  });

  testWidgets('full grid button triggers callback', (tester) async {
    var fullGridTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleBottomActionBar(
            onUndo: () {},
            onHint: () {},
            onFullGrid: () => fullGridTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('FULL GRID'));
    await tester.pump();

    expect(fullGridTapped, isTrue);
  });

  testWidgets('hint button triggers callback', (tester) async {
    var hintTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleBottomActionBar(
            onUndo: () {},
            onHint: () => hintTapped = true,
            onFullGrid: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('HINT'));
    await tester.pump();

    expect(hintTapped, isTrue);
  });

  testWidgets('disables hint and full grid when puzzle completed', (tester) async {
    var hintTapped = false;
    var fullGridTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleBottomActionBar(
            onUndo: () {},
            onHint: () => hintTapped = true,
            onFullGrid: () => fullGridTapped = true,
            hintEnabled: false,
            fullGridEnabled: false,
          ),
        ),
      ),
    );

    await tester.tap(find.text('HINT'));
    await tester.tap(find.text('FULL GRID'));
    await tester.pump();

    expect(hintTapped, isFalse);
    expect(fullGridTapped, isFalse);
  });
}
