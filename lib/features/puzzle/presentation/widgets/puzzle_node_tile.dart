import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';
import 'puzzle_tile_edge_mask.dart';

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
    this.edgeMask = PuzzleTileEdgeMask.all,
    this.rippleIntensity = 0,
  });

  final String character;
  final double tileSize;
  final bool isDragging;
  final bool showBorder;
  final bool isCompleted;
  final bool isHintHighlighted;
  final bool isGhost;
  final PuzzleTileEdgeMask edgeMask;
  final double rippleIntensity;

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
    final baseDepth = PuzzleTheme.tileBaseDepthFor(tileSize);

    Widget tile = SizedBox(
      width: tileSize,
      height: tileSize + baseDepth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (state == PuzzleTileVisualState.ghost)
            _buildGhostTile()
          else
            ..._buildThreeDTile(state),
          if (state == PuzzleTileVisualState.hintHighlighted)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      PuzzleTheme.tileRadiusFor(tileSize),
                    ),
                    border: Border.all(
                      color: PuzzleTheme.yellow,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PuzzleTheme.yellow.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (state != PuzzleTileVisualState.dragging) {
      if (rippleIntensity > 0) {
        tile = Transform.scale(
          scale: 1 + rippleIntensity * 0.05,
          child: tile,
        );
      }
      return tile;
    }

    return Transform.scale(
      scale: 1.04,
      child: tile,
    );
  }

  List<Widget> _buildThreeDTile(PuzzleTileVisualState state) {
    final radius = PuzzleTheme.tileRadiusFor(tileSize);
    final lip = PuzzleTheme.tileLipWidthFor(tileSize);
    final baseDepth = PuzzleTheme.tileBaseDepthFor(tileSize);
    final greenColor = state == PuzzleTileVisualState.completed
        ? PuzzleTheme.tileBaseGreenMuted
        : PuzzleTheme.tileBaseGreen;
    final faceRadius = BorderRadius.only(
      topLeft: edgeMask.top && edgeMask.left
          ? Radius.circular(radius)
          : Radius.zero,
      topRight: edgeMask.top && edgeMask.right
          ? Radius.circular(radius)
          : Radius.zero,
      bottomLeft: edgeMask.bottom && edgeMask.left
          ? Radius.circular(radius)
          : Radius.zero,
      bottomRight: edgeMask.bottom && edgeMask.right
          ? Radius.circular(radius)
          : Radius.zero,
    );
    final greenRadius = faceRadius;

    final faceLeft = edgeMask.left ? lip : 0.0;
    final faceRight = edgeMask.right ? lip : 0.0;
    final faceTop = edgeMask.top ? lip : 0.0;
    final faceBottom = edgeMask.bottom ? lip : 0.0;

    return [
      Positioned(
        left: faceLeft * 0.5,
        right: faceRight * 0.5,
        top: baseDepth * 0.5,
        height: baseDepth + lip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: _shadowForState(state),
            borderRadius: greenRadius,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      Positioned(
        left: faceLeft * 0.25,
        right: faceRight * 0.25,
        top: lip * 0.25,
        bottom: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: greenColor,
            borderRadius: greenRadius,
            boxShadow: [
              BoxShadow(
                color: greenColor.withValues(alpha: 0.45),
                blurRadius: 4,
                offset: Offset(0, baseDepth * 0.5),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: faceLeft,
        right: faceRight,
        top: faceTop,
        bottom: faceBottom + baseDepth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: PuzzleTheme.tileFaceGradient(
              muted: state == PuzzleTileVisualState.completed,
            ),
            borderRadius: faceRadius,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: faceRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: const Alignment(0.4, 0.8),
                        colors: [
                          PuzzleTheme.tileSheenColor,
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  character,
                  style: TextStyle(
                    color: PuzzleTheme.tileText,
                    fontSize: tileSize * 0.48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (rippleIntensity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: faceRadius,
                        color: PuzzleTheme.yellow.withValues(
                          alpha: 0.45 * rippleIntensity,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildGhostTile() {
    final radius = PuzzleTheme.tileRadiusFor(tileSize);
    final baseDepth = PuzzleTheme.tileBaseDepthFor(tileSize);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: baseDepth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(radius),
          border: showBorder
              ? Border.all(
                  color: const Color(0x1A000000),
                )
              : null,
        ),
        child: Center(
          child: Text(
            character,
            style: TextStyle(
              color: const Color(0xFFBDBDBD).withValues(alpha: 0.4),
              fontSize: tileSize * 0.48,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _shadowForState(PuzzleTileVisualState state) {
    switch (state) {
      case PuzzleTileVisualState.normal:
      case PuzzleTileVisualState.completed:
      case PuzzleTileVisualState.hintHighlighted:
        return PuzzleTheme.tileRestShadow;
      case PuzzleTileVisualState.dragging:
        return PuzzleTheme.tileDragShadow;
      case PuzzleTileVisualState.ghost:
        return const [];
    }
  }
}
