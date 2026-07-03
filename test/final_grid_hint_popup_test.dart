import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/data/generators/puzzle_layout_generator.dart';
import 'package:jam_pro/features/puzzle/data/models/generated_puzzle_layout.dart';
import 'package:jam_pro/features/puzzle/data/models/puzzle_content.dart';
import 'package:jam_pro/features/puzzle/presentation/hints/final_grid_hint_popup.dart';

void main() {
  group('FinalGridHintPopup', () {
    late GeneratedPuzzleLayout layout;

    setUp(() {
      final content = const PuzzleContent(
        id: 2,
        category: 'Cutlery',
        words: ['SPOON', 'FORK', 'KNIFE'],
      );
      final layouts = PuzzleLayoutGenerator().generateAllLayouts(content.words);
      layout = GeneratedPuzzleLayout.fromPuzzleContent(content, layouts.first);
    });

    setUpAll(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 1200);
      binding.window.devicePixelRatioTestValue = 1;
    });

    tearDownAll(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('shows title, helper text, and final grid letters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showFinalGridHintPopup(context, layout: layout),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FINAL GRID'), findsOneWidget);
      expect(
        find.text('Use this as a reference while solving the puzzle.'),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);

      for (final letter in layout.occupiedCells.map((cell) => cell.letter)) {
        expect(find.text(letter), findsWidgets);
      }
    });

    testWidgets('Close button dismisses popup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showFinalGridHintPopup(context, layout: layout),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FINAL GRID'), findsNothing);
    });

    testWidgets('close icon dismisses popup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showFinalGridHintPopup(context, layout: layout),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FINAL GRID'), findsNothing);
    });
  });
}
