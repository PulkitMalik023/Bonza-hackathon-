import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/audio/puzzle_audio_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PuzzleAudioController.instance.configureGlobalAudio();
  runApp(const App());
}
