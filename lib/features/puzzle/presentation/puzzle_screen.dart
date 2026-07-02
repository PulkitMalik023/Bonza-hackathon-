import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/board_constants.dart';
import '../../shared/widgets/grid_background.dart';
import '../data/generators/puzzle_layout_generator.dart';
import '../data/models/generated_puzzle_layout.dart';
import '../data/models/puzzle_content.dart';
import '../data/models/puzzle_layout.dart';
import '../data/repositories/puzzle_repository.dart';
import 'widgets/solved_grid_board.dart';

/// Returns the next layout index when cycling through [layoutCount] layouts.
int nextLayoutIndex(int currentIndex, int layoutCount) {
  if (layoutCount <= 1) {
    return currentIndex;
  }
  return (currentIndex + 1) % layoutCount;
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.puzzleId,
  });

  final int puzzleId;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  PuzzleContent? _puzzle;
  List<PuzzleLayout> _layouts = const [];
  int _currentLayoutIndex = 0;
  String? _errorMessage;
  bool _isLoading = true;

  PuzzleLayout? get _currentLayout =>
      _layouts.isEmpty ? null : _layouts[_currentLayoutIndex];

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  @override
  void didUpdateWidget(covariant PuzzleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.puzzleId != widget.puzzleId) {
      _loadAndGenerate();
    }
  }

  Future<void> _loadAndGenerate() async {
    debugPrint('[PuzzleScreen] Rendering puzzleId: ${widget.puzzleId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _puzzle = null;
      _layouts = const [];
      _currentLayoutIndex = 0;
    });

    try {
      final puzzle = await PuzzleRepository().getPuzzleById(widget.puzzleId);

      if (puzzle == null) {
        throw StateError('Puzzle ${widget.puzzleId} was not found');
      }

      if (!puzzle.enabled) {
        throw StateError('Puzzle ${widget.puzzleId} is disabled');
      }

      final layouts = PuzzleLayoutGenerator().generateAllLayouts(puzzle.words);

      debugPrint('[PuzzleScreen] Loaded puzzle: ${puzzle.id}');
      debugPrint('[PuzzleScreen] Category: ${puzzle.category}');
      debugPrint('[PuzzleScreen] Words: ${puzzle.words}');
      debugPrint('[PuzzleScreen] Total layouts: ${layouts.length}');

      if (layouts.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage = 'No valid layout found for this puzzle';
          _isLoading = false;
        });
        return;
      }

      final currentLayout = layouts.first;
      debugPrint('[PuzzleScreen] Placements:');
      for (final placement in currentLayout.placedWords) {
        debugPrint('[PuzzleScreen]   $placement');
      }
      debugPrint(
        '[PuzzleScreen] Bounds: rows ${currentLayout.minRow}..${currentLayout.maxRow}, '
        'cols ${currentLayout.minCol}..${currentLayout.maxCol}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _puzzle = puzzle;
        _layouts = layouts;
        _currentLayoutIndex = 0;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[PuzzleScreen] Failed to load puzzle: $error');
      debugPrint('[PuzzleScreen] $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _userFacingError(error);
        _isLoading = false;
      });
    }
  }

  void _shuffleLayout() {
    if (_layouts.length <= 1) {
      return;
    }

    setState(() {
      _currentLayoutIndex = nextLayoutIndex(
        _currentLayoutIndex,
        _layouts.length,
      );
    });

    debugPrint(
      '[PuzzleScreen] Shuffled to layout ${_currentLayoutIndex + 1} / ${_layouts.length}',
    );
  }

  String _userFacingError(Object error) {
    if (error is StateError &&
        error.message.contains('Could not generate connected layout')) {
      return 'Unable to generate puzzle grid for this content';
    }

    if (error is StateError &&
        error.message.contains('cannot form a connected graph')) {
      return 'Unable to generate puzzle grid for this content';
    }

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_puzzle?.category ?? 'Puzzle ${widget.puzzleId}'),
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
          padding: const EdgeInsets.all(BoardConstants.kBoardOuterPadding),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final puzzle = _puzzle;
    final currentLayout = _currentLayout;
    if (puzzle == null || currentLayout == null) {
      return const SizedBox.shrink();
    }

    final displayLayout = GeneratedPuzzleLayout.fromPuzzleContent(
      puzzle,
      currentLayout,
    );

    final rowCount = displayLayout.maxRow - displayLayout.minRow + 1;
    final colCount = displayLayout.maxCol - displayLayout.minCol + 1;
    final boardWidth = colCount * BoardConstants.kBoardTileSize;
    final boardHeight = rowCount * BoardConstants.kBoardTileSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BoardConstants.kBoardOuterPadding,
            8,
            BoardConstants.kBoardOuterPadding,
            8,
          ),
          child: Column(
            children: [
              Text(
                puzzle.category,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _layouts.length > 1 ? _shuffleLayout : null,
                    icon: const Icon(Icons.shuffle),
                    tooltip: 'Shuffle layout',
                  ),
                  Text(
                    'Layout ${_currentLayoutIndex + 1} / ${_layouts.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final left = BoardConstants.snapToGrid(
                (constraints.maxWidth - boardWidth) / 2,
              );
              final top = BoardConstants.snapToGrid(
                (constraints.maxHeight - boardHeight) / 2,
              );

              return SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: max(constraints.maxHeight, boardHeight + top),
                  child: Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: top,
                        child: SolvedGridBoard(
                          key: ValueKey(_currentLayoutIndex),
                          layout: displayLayout,
                        ),
                      ),
                    ],
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
