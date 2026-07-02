import 'package:flutter/material.dart';

import '../../../../core/audio/audio_settings_service.dart';
import '../../../../core/audio/puzzle_audio_controller.dart';
import '../../../../core/economy/coin_service.dart';
import '../../../puzzle/data/models/puzzle_content.dart';
import '../../../puzzle/data/repositories/puzzle_repository.dart';
import '../../../puzzle/presentation/puzzle_screen.dart';
import '../../../puzzle/presentation/widgets/puzzle_nature_background.dart';
import '../widgets/home_header.dart';
import '../widgets/home_level_card.dart';
import '../widgets/home_section_title.dart';
import '../widgets/home_settings_sheet.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with WidgetsBindingObserver {
  List<PuzzleContent>? _puzzles;
  String? _errorMessage;
  bool _isLoading = true;

  PuzzleAudioController get _audioController => PuzzleAudioController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CoinService.instance.load();
    _bootstrapAudio();
    _loadPuzzles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _audioController.pausePuzzleLoopSound();
      case AppLifecycleState.resumed:
        _audioController.resumePuzzleLoopSound();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _bootstrapAudio() async {
    await AudioSettingsService.instance.load();
    await _audioController.ensurePuzzleLoopPlaying();
  }

  Future<void> _loadPuzzles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _puzzles = null;
    });

    try {
      final puzzles = await PuzzleRepository().loadPuzzles();
      debugPrint('[LandingScreen] Loaded ${puzzles.length} puzzles');

      if (!mounted) {
        return;
      }

      setState(() {
        _puzzles = puzzles;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[LandingScreen] Failed to load puzzles: $error');
      debugPrint('[LandingScreen] $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _openPuzzle(int puzzleId) {
    debugPrint(
      '[LandingScreen] Tapped level $puzzleId (puzzleId: $puzzleId)',
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleScreen(puzzleId: puzzleId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PuzzleNatureBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: CoinService.instance,
                  builder: (context, _) {
                    return HomeHeader(
                      coinBalance: CoinService.instance.coinBalance,
                      onSettingsPressed: () => showHomeSettingsSheet(context),
                    );
                  },
                ),
                const HomeSectionTitle(),
                Expanded(child: _buildBody(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D50),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1F4D38),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final puzzles = _puzzles;
    if (puzzles == null || puzzles.isEmpty) {
      return const Center(
        child: Text(
          'No puzzles available',
          style: TextStyle(
            color: Color(0xFF1F4D38),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: puzzles.length,
      itemBuilder: (context, index) {
        final puzzle = puzzles[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HomeLevelCard(
            levelNumber: puzzle.id,
            category: puzzle.category,
            onTap: () => _openPuzzle(puzzle.id),
          ),
        );
      },
    );
  }
}
