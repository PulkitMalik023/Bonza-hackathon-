import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';

enum PuzzleTileVisualState {
  normal,
  dragging,
  completed,
}

class PuzzleNodeTile extends StatelessWidget {
  const PuzzleNodeTile({
    super.key,
    required this.character,
    required this.tileSize,
    this.isDragging = false,
    this.showBorder = true,
    this.isCompleted = false,
  });

  final String character;
  final double tileSize;
  final bool isDragging;
  final bool showBorder;
  final bool isCompleted;

  PuzzleTileVisualState get visualState {
    if (isDragging) {
      return PuzzleTileVisualState.dragging;
    }
    if (isCompleted) {
      return PuzzleTileVisualState.completed;
    }
    return PuzzleTileVisualState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final state = visualState;
    final tile = SizedBox(
      width: tileSize,
      height: tileSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _backgroundForState(state),
          borderRadius: BorderRadius.circular(PuzzleTheme.tileRadius),
          border: showBorder
              ? Border.all(
                  color: _borderForState(state),
                  width: 1,
                )
              : null,
          boxShadow: _shadowForState(state),
        ),
        child: Center(
          child: Text(
            character,
            style: TextStyle(
              color: PuzzleTheme.tileText,
              fontSize: tileSize * 0.48,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );

    if (state != PuzzleTileVisualState.dragging) {
      return tile;
    }

    return Transform.scale(
      scale: 1.04,
      child: tile,
    );
  }

  Color _backgroundForState(PuzzleTileVisualState state) {
    switch (state) {
      case PuzzleTileVisualState.normal:
      case PuzzleTileVisualState.dragging:
        return PuzzleTheme.tileBg;
      case PuzzleTileVisualState.completed:
        return PuzzleTheme.tileBg.withValues(alpha: 0.92);
    }
  }

  Color _borderForState(PuzzleTileVisualState state) {
    switch (state) {
      case PuzzleTileVisualState.normal:
        return const Color(0x33FFFFFF);
      case PuzzleTileVisualState.dragging:
        return const Color(0x66FFFFFF);
      case PuzzleTileVisualState.completed:
        return PuzzleTheme.lightGreen.withValues(alpha: 0.6);
    }
  }

  List<BoxShadow> _shadowForState(PuzzleTileVisualState state) {
    switch (state) {
      case PuzzleTileVisualState.normal:
      case PuzzleTileVisualState.completed:
        return PuzzleTheme.tileRestShadow;
      case PuzzleTileVisualState.dragging:
        return PuzzleTheme.tileDragShadow;
    }
  }
}
