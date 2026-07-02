import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jam_pro/core/audio/audio_settings_service.dart';
import 'package:jam_pro/features/landing/presentation/widgets/home_settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AudioSettingsService.instance.resetForTest();
  });

  group('HomeSettingsSheet', () {
    testWidgets('shows sound, music, and how to play options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showHomeSettingsSheet(context),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
    });

    testWidgets('toggles sound label between On and Off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showHomeSettingsSheet(context),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('On'), findsNWidgets(2));

      await tester.tap(find.text('Sound'));
      await tester.pumpAndSettle();

      expect(find.text('Off'), findsOneWidget);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });

    testWidgets('how to play opens tutorial popup', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showHomeSettingsSheet(context),
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

      await tester.tap(find.text('How to Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('HOW TO PLAY'), findsOneWidget);
    });
  });
}
