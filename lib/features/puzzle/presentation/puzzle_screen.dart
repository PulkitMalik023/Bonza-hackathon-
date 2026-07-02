import 'package:flutter/material.dart';

import '../../../shared/widgets/grid_background.dart';
import '../../../core/theme/app_theme.dart';
import '../data/generators/puzzle_layout_generator.dart';
import '../data/models/generated_puzzle_layout.dart';
import '../data/sources/puzzle_content_loader.dart';
import 'widgets/solved_grid_board.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.puzzleIndex,
  });

  final int puzzleIndex;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  GeneratedPuzzleLayout? _layout;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future<void> _loadAndGenerate() async {
    debugPrint('[PuzzleScreen] Rendering puzzleIndex: ${widget.puzzleIndex}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _layout = null;
    });

    try {
      final puzzles = await PuzzleContentLoader().loadPuzzles();

      if (widget.puzzleIndex < 0 || widget.puzzleIndex >= puzzles.length) {
        throw StateError(
          'Puzzle index ${widget.puzzleIndex} is out of range (0..${puzzles.length - 1})',
        );
      }

      final puzzle = puzzles[widget.puzzleIndex];
      final layout = PuzzleLayoutGenerator().generate(puzzle);

      debugPrint('[PuzzleScreen] Loaded puzzle: ${layout.puzzleId}');
      debugPrint('[PuzzleScreen] Category: ${layout.category}');
      debugPrint('[PuzzleScreen] Words: ${layout.words}');
      debugPrint('[PuzzleScreen] Placements:');
      for (final placement in layout.placements) {
        debugPrint('[PuzzleScreen]   $placement');
      }
      debugPrint(
        '[PuzzleScreen] Bounds: rows ${layout.minRow}..${layout.maxRow}, '
        'cols ${layout.minCol}..${layout.maxCol}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _layout = layout;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[PuzzleScreen] Failed to load puzzle: $error');
      debugPrint('[PuzzleScreen] $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(layout?.category ?? 'Puzzle ${widget.puzzleIndex + 1}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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

    final layout = _layout;
    if (layout == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            layout.category,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SolvedGridBoard(
                layout: layout,
                tileSize: AppTheme.gridTileSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
