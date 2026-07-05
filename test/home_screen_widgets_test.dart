import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/category/category_icon_mapper.dart';
import 'package:jam_pro/features/landing/presentation/widgets/home_level_card.dart';

void main() {
  group('CategoryIconMapper', () {
    test('returns mapped icon for known categories', () {
      final directions = CategoryIconMapper.iconFor('Directions');
      expect(directions.fallbackIcon, Icons.explore_rounded);

      final fruits = CategoryIconMapper.iconFor('Fruits');
      expect(fruits.fallbackIcon, Icons.apple_rounded);
    });

    test('returns default icon for unknown categories', () {
      final unknown = CategoryIconMapper.iconFor('Unknown Category');
      expect(unknown.fallbackIcon, Icons.category_rounded);
    });
  });

  group('HomeLevelCard', () {
    testWidgets('shows level number badge and category title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeLevelCard(
              levelNumber: 4,
              category: 'Fruits',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('LEVEL 4'), findsNothing);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Fruits'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeLevelCard(
              levelNumber: 1,
              category: 'Directions',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Directions'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
