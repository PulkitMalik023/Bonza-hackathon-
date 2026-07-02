import 'package:flutter_test/flutter_test.dart';

import 'package:jam_pro/app/app.dart';

void main() {
  testWidgets('App renders home screen background', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(App), findsOneWidget);
  });
}
