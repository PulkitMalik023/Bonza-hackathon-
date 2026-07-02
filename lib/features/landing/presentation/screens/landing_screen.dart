import 'package:flutter/material.dart';

import '../../../../core/economy/coin_service.dart';
import '../../../puzzle/data/models/puzzle_content.dart';
import '../../../puzzle/data/repositories/puzzle_repository.dart';
import '../../../puzzle/presentation/puzzle_screen.dart';
import '../../../puzzle/presentation/widgets/puzzle_nature_background.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/home_level_card.dart';
import '../widgets/home_section_title.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<PuzzleContent>? _puzzles;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    CoinService.instance.load();
    _loadPuzzles();
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

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onNavTabSelected(HomeNavTab tab) {
    switch (tab) {
      case HomeNavTab.home:
        break;
      case HomeNavTab.daily:
        _showPlaceholder('Daily challenges coming soon');
      case HomeNavTab.rewards:
        _showPlaceholder('Rewards coming soon');
      case HomeNavTab.shop:
        _showPlaceholder('Shop coming soon');
    }
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
                      onSettingsPressed: () {
                        _showPlaceholder('Settings coming soon');
                      },
                      onAddCoins: () {
                        _showPlaceholder('Coin shop coming soon');
                      },
                    );
                  },
                ),
                const HomeSectionTitle(),
                Expanded(child: _buildBody(context)),
                HomeBottomNavBar(onTabSelected: _onNavTabSelected),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
