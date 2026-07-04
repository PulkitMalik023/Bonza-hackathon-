import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/features/puzzle/presentation/widgets/word_completion_burst.dart';

void main() {
  group('WordCompletionBurst', () {
    testWidgets('renders particle circles and calls onComplete', (tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WordCompletionBurst(
                width: 120,
                height: 40,
                onComplete: () {
                  completed = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);

      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      expect(completed, isTrue);
      expect(find.byType(WordCompletionBurst), findsOneWidget);
    });

    testWidgets('particles fade out by end of animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WordCompletionBurst(
              width: 100,
              height: 50,
            ),
          ),
        ),
      );

      await tester.pump();
      final midOpacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(midOpacity.opacity, greaterThan(0));

      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      for (final opacity in tester.widgetList<Opacity>(find.byType(Opacity))) {
        expect(opacity.opacity, 0);
      }
    });
  });
}
