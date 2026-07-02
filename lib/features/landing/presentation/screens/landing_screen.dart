import 'package:flutter/material.dart';

import '../../../puzzle/data/models/puzzle_definition.dart';
import '../../../puzzle/data/sources/puzzle_content_loader.dart';
import '../../../puzzle/presentation/puzzle_screen.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../widgets/level_tile_card.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<PuzzleDefinition>? _puzzles;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPuzzles();
  }

  Future<void> _loadPuzzles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _puzzles = null;
    });

    try {
      final puzzles = await PuzzleContentLoader().loadPuzzles();
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

  void _openPuzzle(int index) {
    debugPrint(
      '[LandingScreen] Tapped level ${index + 1} (puzzleIndex: $index)',
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleScreen(puzzleIndex: index),
      ),
    );
  }

  Alignment _alignmentForIndex(int index) {
    switch (index % 3) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
      default:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const GridBackground(),
          SafeArea(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final puzzles = _puzzles;
    if (puzzles == null || puzzles.isEmpty) {
      return const Center(
        child: Text('No puzzles available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jam Pro',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          for (var index = 0; index < puzzles.length; index++) ...[
            Align(
              alignment: _alignmentForIndex(index),
              child: LevelTileCard(
                label: 'LEVEL ${index + 1}',
                onTap: () => _openPuzzle(index),
              ),
            ),
            if (index < puzzles.length - 1) const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}
