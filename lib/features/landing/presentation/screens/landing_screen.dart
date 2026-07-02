import 'package:flutter/material.dart';

import '../../../puzzle/data/models/puzzle_content.dart';
import '../../../puzzle/data/repositories/puzzle_repository.dart';
import '../../../puzzle/presentation/puzzle_screen.dart';
import '../../../../core/constants/board_constants.dart';
import '../../../shared/widgets/grid_background.dart';
import '../widgets/level_button.dart';

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
          padding: const EdgeInsets.all(BoardConstants.kBoardOuterPadding),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BoardConstants.kBoardOuterPadding,
            16,
            BoardConstants.kBoardOuterPadding,
            8,
          ),
          child: Column(
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
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              BoardConstants.kBoardOuterPadding,
              8,
              BoardConstants.kBoardOuterPadding,
              BoardConstants.kBoardOuterPadding,
            ),
            itemCount: puzzles.length,
            itemBuilder: (context, index) {
              final puzzle = puzzles[index];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: BoardConstants.kLevelButtonSpacing,
                ),
                child: Center(
                  child: LevelButton(
                    label: 'LEVEL ${puzzle.id}',
                    subtitle: puzzle.category,
                    onTap: () => _openPuzzle(puzzle.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
