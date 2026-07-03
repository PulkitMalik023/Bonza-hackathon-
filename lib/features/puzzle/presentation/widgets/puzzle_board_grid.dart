import 'package:flutter/material.dart';

import '../../../../core/constants/board_constants.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/animated_grid_background/animated_grid_painter.dart';
import '../../../../core/widgets/animated_grid_background/grid_wave_controller.dart';

class PuzzleBoardGrid extends StatefulWidget {
  const PuzzleBoardGrid({
    super.key,
    this.spacing = BoardConstants.kBoardTileSize,
    this.gridRows = BoardConstants.kPlayGridRows,
    this.gridCols = BoardConstants.kPlayGridCols,
    this.child,
  });

  final double spacing;
  final int gridRows;
  final int gridCols;
  final Widget? child;

  @override
  State<PuzzleBoardGrid> createState() => _PuzzleBoardGridState();
}

class _PuzzleBoardGridState extends State<PuzzleBoardGrid>
    with SingleTickerProviderStateMixin {
  late GridWaveController _waveController;

  static const _tileLightColor = PuzzleTheme.boardBg;
  static const _tileDarkColor = Color(0xFFE8F2E7);
  static const _waveHighlightColor = PuzzleTheme.lightGreen;
  static const _tileBorderColor = Color(0xFFDCE8DC);

  @override
  void initState() {
    super.initState();
    _waveController = GridWaveController(
      vsync: this,
      waveDuration: const Duration(milliseconds: 1800),
      waveInterval: const Duration(seconds: 5),
      onTick: () => setState(() {}),
    );
    _waveController.start();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridWidth = widget.gridCols * widget.spacing;
    final gridHeight = widget.gridRows * widget.spacing;

    return SizedBox(
      width: gridWidth,
      height: gridHeight,
      child: CustomPaint(
        painter: AnimatedGridPainter(
          tileSize: widget.spacing,
          topGradientColor: PuzzleTheme.boardBg,
          bottomGradientColor: PuzzleTheme.boardBg,
          waveProgress: _waveController.waveProgress,
          wavePattern: _waveController.currentPattern,
          tileLightColor: _tileLightColor,
          tileDarkColor: _tileDarkColor,
          waveHighlightColor: _waveHighlightColor,
          waveSpread: 3,
          waveHighlightStrength: 0.35,
          tileBorderColor: _tileBorderColor,
          tileBorderWidth: BoardConstants.kBoardGridLineWidth,
        ),
        child: widget.child,
      ),
    );
  }
}
