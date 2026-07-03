import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/audio/puzzle_audio_controller.dart';
import 'core/system_ui/app_system_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSystemUi.enableImmersive();
  await PuzzleAudioController.instance.configureGlobalAudio();
  runApp(const App());
}
