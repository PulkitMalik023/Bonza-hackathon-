import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/presentation/widgets/puzzle_hint_tooltip_row.dart';

void main() {
  testWidgets('hint tooltip row shows Use a hint text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleHintTooltipRow(onHintPressed: () {}),
        ),
      ),
    );

    expect(find.text('Use a hint'), findsOneWidget);
    expect(find.text('HINT'), findsOneWidget);
  });

  testWidgets('hint button triggers callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuzzleHintTooltipRow(onHintPressed: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('HINT'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
