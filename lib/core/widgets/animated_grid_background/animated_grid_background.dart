import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'animated_grid_painter.dart';
import 'grid_wave_controller.dart';

class AnimatedGridBackground extends StatefulWidget {
  const AnimatedGridBackground({
    super.key,
    this.tileSize = AppTheme.gridTileSize,
    this.topGradientColor = AppTheme.gridTopGradient,
    this.bottomGradientColor = AppTheme.gridBottomGradient,
    this.waveDuration = const Duration(milliseconds: 1800),
    this.waveInterval = const Duration(seconds: 5),
    this.child,
  });

  final double tileSize;
  final Color topGradientColor;
  final Color bottomGradientColor;
  final Duration waveDuration;
  final Duration waveInterval;
  final Widget? child;

  @override
  State<AnimatedGridBackground> createState() => _AnimatedGridBackgroundState();
}

class _AnimatedGridBackgroundState extends State<AnimatedGridBackground>
    with SingleTickerProviderStateMixin {
  late GridWaveController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = GridWaveController(
      vsync: this,
      waveDuration: widget.waveDuration,
      waveInterval: widget.waveInterval,
      onTick: () => setState(() {}),
    );
    _waveController.start();
  }

  @override
  void didUpdateWidget(covariant AnimatedGridBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.waveDuration != widget.waveDuration ||
        oldWidget.waveInterval != widget.waveInterval) {
      _waveController.dispose();
      _waveController = GridWaveController(
        vsync: this,
        waveDuration: widget.waveDuration,
        waveInterval: widget.waveInterval,
        onTick: () => setState(() {}),
      );
      _waveController.start();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: AnimatedGridPainter(
            tileSize: widget.tileSize,
            topGradientColor: widget.topGradientColor,
            bottomGradientColor: widget.bottomGradientColor,
            waveProgress: _waveController.waveProgress,
            wavePattern: _waveController.currentPattern,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
          child: widget.child,
        );
      },
    );
  }
}
