import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/landing/presentation/screens/landing_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jam Pro',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const LandingScreen(),
    );
  }
}
