import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';

enum PuzzleTileVisualState {
  normal,
  dragging,
  completed,
  hintHighlighted,
  ghost,
}

class PuzzleNodeTile extends StatelessWidget {
  const PuzzleNodeTile({
    super.key,
    required this.character,
    required this.tileSize,
    this.isDragging = false,
    this.showBorder = true,
    this.isCompleted = false,
    this.isHintHighlighted = false,
    this.isGhost = false,
  });

  final String character;
  final double tileSize;
  final bool isDragging;
  final bool showBorder;
  final bool isCompleted;
  final bool isHintHighlighted;
  final bool isGhost;

  PuzzleTileVisualState get visualState {
    if (isGhost) {
      return PuzzleTileVisualState.ghost;
    }
    if (isDragging) {
      return PuzzleTileVisualState.dragging;
    }
    if (isCompleted) {
      return PuzzleTileVisualState.completed;
    }
    if (isHintHighlighted) {
      return PuzzleTileVisualState.hintHighlighted;
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
              color: state == PuzzleTileVisualState.ghost
                  ? const Color(0xFFBDBDBD).withValues(alpha: 0.4)
                  : PuzzleTheme.tileText,
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
      case PuzzleTileVisualState.hintHighlighted:
        return PuzzleTheme.yellow.withValues(alpha: 0.35);
      case PuzzleTileVisualState.ghost:
        return const Color(0xFFF5F5F5);
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
      case PuzzleTileVisualState.hintHighlighted:
        return PuzzleTheme.yellow;
      case PuzzleTileVisualState.ghost:
        return const Color(0x1A000000);
    }
  }

  List<BoxShadow> _shadowForState(PuzzleTileVisualState state) {
    switch (state) {
      case PuzzleTileVisualState.normal:
      case PuzzleTileVisualState.completed:
        return PuzzleTheme.tileRestShadow;
      case PuzzleTileVisualState.dragging:
        return PuzzleTheme.tileDragShadow;
      case PuzzleTileVisualState.hintHighlighted:
        return [
          BoxShadow(
            color: PuzzleTheme.yellow.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ];
      case PuzzleTileVisualState.ghost:
        return const [];
    }
  }
}
