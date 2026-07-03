import 'package:flutter/material.dart';

abstract final class PuzzleTheme {
  static const Color darkGreen = Color(0xFF1F4D38);
  static const Color mediumGreen = Color(0xFF2E7D50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color yellow = Color(0xFFFFD54F);
  static const Color boardBg = Color(0xFFF4FAF3);
  static const Color tileBg = Color(0xFF1A1A1A);
  static const Color tileFaceTop = Color(0xFF1A1A1A);
  static const Color tileFaceBottom = Color(0xFF0D0D0D);
  static const Color tileBaseGreen = Color(0xFF5AD66A);
  static const Color tileBaseGreenMuted = Color(0xFF4CB85C);
  static const Color tileSheenColor = Color(0x33FFFFFF);
  static const Color tileText = Colors.white;
  static const Color headerTitle = Color(0xFFFFD54F);
  static const Color coinText = Colors.white;
  static const Color tooltipBg = Colors.white;
  static const Color tooltipText = Color(0xFF1A1A1A);
  static const Color hintButtonText = Color(0xFF1A1A1A);
  static const Color badgeRed = Color(0xFFE53935);

  static const double headerRadius = 16;
  static const double boardRadius = 0;
  static const double tileRadius = 6;
  static const double tileBaseDepth = 4;
  static const double tileBaseInset = 1;
  static const double actionButtonSize = 56;
  static const double levelCardRadius = 16;
  static const double bottomNavHeight = 72;
  static const Color bottomNavBg = Color(0xFFE8F5E9);
  static const Color bottomNavActiveBg = Color(0xFF2E7D50);
  static const Color levelCardCategoryText = Color(0xFFFFE082);

  static const LinearGradient levelCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A5F45),
      darkGreen,
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2A5F45),
      darkGreen,
    ],
  );

  static const LinearGradient natureBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8F5E9),
      Color(0xFFC8E6C9),
      Color(0xFFA5D6A7),
    ],
  );

  static List<BoxShadow> get headerShadow => const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get boardShadow => const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get tileRestShadow => const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x265AD66A),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get tileDragShadow => const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 14,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x405AD66A),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ];

  static double tileRadiusFor(double tileSize) =>
      (tileSize * 0.12).clamp(4.0, 10.0);

  static double tileBaseDepthFor(double tileSize) =>
      (tileSize * 0.08).clamp(3.0, 5.0);

  static double tileBaseInsetFor(double tileSize) =>
      (tileSize * 0.02).clamp(0.5, 2.0);

  static double tileLipWidthFor(double tileSize) =>
      (tileSize * 0.06).clamp(2.0, 4.0);

  static LinearGradient tileFaceGradient({bool muted = false}) {
    final top = muted ? tileFaceTop.withValues(alpha: 0.92) : tileFaceTop;
    final bottom =
        muted ? tileFaceBottom.withValues(alpha: 0.92) : tileFaceBottom;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, bottom],
    );
  }

  static List<BoxShadow> get levelCardShadow => const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];

  static TextStyle displayTitleStyle(double width) {
    return TextStyle(
      color: headerTitle,
      fontWeight: FontWeight.w900,
      fontSize: width < 340 ? 20 : 24,
      letterSpacing: 2,
      shadows: const [
        Shadow(
          color: Color(0x66000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  static TextStyle get sectionTitleStyle => const TextStyle(
        color: darkGreen,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: 1.4,
      );

  static TextStyle get levelCardTitleStyle => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: 1,
      );

  static TextStyle get levelCardCategoryStyle => const TextStyle(
        color: levelCardCategoryText,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      );

  static TextStyle headerTitleStyle(double width) {
    return TextStyle(
      color: headerTitle,
      fontWeight: FontWeight.w800,
      fontSize: width < 340 ? 16 : 18,
      letterSpacing: 1.2,
    );
  }

  static TextStyle actionLabelStyle = const TextStyle(
    color: darkGreen,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 0.8,
  );
}
