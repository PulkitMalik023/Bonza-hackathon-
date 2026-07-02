import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AnimatedGridPainter extends CustomPainter {
  AnimatedGridPainter({
    required this.tileSize,
    required this.topGradientColor,
    required this.bottomGradientColor,
    required this.waveProgress,
    this.tileLightColor = AppTheme.gridTileLight,
    this.tileDarkColor = AppTheme.gridTileDark,
    this.waveHighlightColor = AppTheme.gridWaveHighlight,
    this.waveSpread = AppTheme.gridWaveSpread,
    this.waveHighlightStrength = AppTheme.gridWaveHighlightStrength,
    this.tileBorderColor = AppTheme.gridTileBorderColor,
    this.tileBorderWidth = AppTheme.gridTileBorderWidth,
  });

  final double tileSize;
  final Color topGradientColor;
  final Color bottomGradientColor;
  final double waveProgress;
  final Color tileLightColor;
  final Color tileDarkColor;
  final Color waveHighlightColor;
  final double waveSpread;
  final double waveHighlightStrength;
  final Color tileBorderColor;
  final double tileBorderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGradient(canvas, size);

    final columns = (size.width / tileSize).ceil();
    final rows = (size.height / tileSize).ceil();
    final maxDiagonal = rows + columns - 2;
    final waveFront = waveProgress * maxDiagonal;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final rect = Rect.fromLTWH(
          col * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );

        final isLightTile = (row + col).isEven;
        final tilePaint = Paint()..color = isLightTile ? tileLightColor : tileDarkColor;
        canvas.drawRect(rect, tilePaint);

        if (waveProgress > 0) {
          final diagonalIndex = row + col;
          final distance = (diagonalIndex - waveFront).abs();
          final highlight = (1 - distance / waveSpread).clamp(0.0, 1.0);

          if (highlight > 0) {
            final wavePaint = Paint()
              ..color = waveHighlightColor.withValues(
                alpha: waveHighlightColor.a * highlight * waveHighlightStrength,
              );
            canvas.drawRect(rect, wavePaint);
          }
        }

        final borderPaint = Paint()
          ..color = tileBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = tileBorderWidth;
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  void _drawGradient(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topGradientColor, bottomGradientColor],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedGridPainter oldDelegate) {
    return oldDelegate.tileSize != tileSize ||
        oldDelegate.topGradientColor != topGradientColor ||
        oldDelegate.bottomGradientColor != bottomGradientColor ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.tileLightColor != tileLightColor ||
        oldDelegate.tileDarkColor != tileDarkColor ||
        oldDelegate.waveHighlightColor != waveHighlightColor ||
        oldDelegate.waveSpread != waveSpread ||
        oldDelegate.waveHighlightStrength != waveHighlightStrength ||
        oldDelegate.tileBorderColor != tileBorderColor ||
        oldDelegate.tileBorderWidth != tileBorderWidth;
  }
}
