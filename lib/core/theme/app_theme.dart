import 'package:flutter/material.dart';

import '../constants/board_constants.dart';

abstract final class AppTheme {
  static const double gridTileSize = BoardConstants.kBoardTileSize;

  static const Color gridBackgroundColor = Color(0xFFFAFAFA);
  static const Color gridBackgroundLineColor = Color(0xFFE0E0E0);

  static const Color gridTopGradient = Color(0xFFF7F7F9);
  static const Color gridBottomGradient = Color(0xFFF2C4D3);
  static const Color gridTileLight = Color(0x0AFFFFFF);
  static const Color gridTileDark = Color(0x14FFFFFF);
  static const Color gridWaveHighlight = Color(0x2EFFFFFF);
  static const Color gridTileBorderColor = Color(0x1A000000);

  static const Color nodeBackgroundColor = Colors.black;
  static const Color nodeTextColor = Colors.white;
  static const Color nodeBorderColor = Color(0x33FFFFFF);
  static const Color nodeDragShadowColor = Color(0x66000000);

  static const double nodeDragShadowBlurRadius = 12;
  static const Offset nodeDragShadowOffset = Offset(0, 4);
  static const double nodeDragScale = 1.03;

  static const double gridTileBorderWidth = 0.75;
  static const double gridWaveSpread = 2.5;
  static const double gridWaveHighlightStrength = 1.0;

  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: gridBottomGradient,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
    );
  }
}
