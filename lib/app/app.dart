import 'package:flutter/material.dart';

import '../core/system_ui/app_system_ui.dart';
import '../core/theme/app_theme.dart';
import '../features/landing/presentation/screens/landing_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppSystemUi.enableImmersive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppSystemUi.enableImmersive();
    }
  }

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
