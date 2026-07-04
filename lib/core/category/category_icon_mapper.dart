import 'package:flutter/material.dart';

import '../constants/home_assets.dart';

class CategoryIconInfo {
  const CategoryIconInfo({
    required this.assetPath,
    required this.fallbackIcon,
  });

  final String assetPath;
  final IconData fallbackIcon;
}

abstract final class CategoryIconMapper {
  static CategoryIconInfo iconFor(String category) {
    return _mapping[category] ?? _defaultIcon;
  }

  static const _defaultIcon = CategoryIconInfo(
    assetPath: HomeAssets.fruits,
    fallbackIcon: Icons.category_rounded,
  );

  static final Map<String, CategoryIconInfo> _mapping = {
    'Directions': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.explore_rounded,
    ),
    'Cutlery': const CategoryIconInfo(
      assetPath: HomeAssets.cutlery,
      fallbackIcon: Icons.restaurant_rounded,
    ),
    'Fruits': const CategoryIconInfo(
      assetPath: HomeAssets.fruits,
      fallbackIcon: Icons.apple_rounded,
    ),
    'Colors': const CategoryIconInfo(
      assetPath: HomeAssets.colors,
      fallbackIcon: Icons.palette_rounded,
    ),
    'Birds': const CategoryIconInfo(
      assetPath: HomeAssets.birds,
      fallbackIcon: Icons.flutter_dash_rounded,
    ),
    'Vegetables': const CategoryIconInfo(
      assetPath: HomeAssets.vegetables,
      fallbackIcon: Icons.grass_rounded,
    ),
    'Drinks': const CategoryIconInfo(
      assetPath: HomeAssets.drinks,
      fallbackIcon: Icons.local_cafe_rounded,
    ),
    'Clothes': const CategoryIconInfo(
      assetPath: HomeAssets.fruits,
      fallbackIcon: Icons.checkroom_rounded,
    ),
    'Shapes': const CategoryIconInfo(
      assetPath: HomeAssets.colors,
      fallbackIcon: Icons.category_rounded,
    ),
    'Jobs': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.work_rounded,
    ),
    'Planets': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.public_rounded,
    ),
    'Emotions': const CategoryIconInfo(
      assetPath: HomeAssets.colors,
      fallbackIcon: Icons.sentiment_satisfied_alt_rounded,
    ),
    'Nature': const CategoryIconInfo(
      assetPath: HomeAssets.vegetables,
      fallbackIcon: Icons.park_rounded,
    ),
    'Desserts': const CategoryIconInfo(
      assetPath: HomeAssets.fruits,
      fallbackIcon: Icons.cake_rounded,
    ),
    'Days': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.calendar_today_rounded,
    ),
    'Tools': const CategoryIconInfo(
      assetPath: HomeAssets.cutlery,
      fallbackIcon: Icons.build_rounded,
    ),
    'Computer': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.computer_rounded,
    ),
    'Festival': const CategoryIconInfo(
      assetPath: HomeAssets.colors,
      fallbackIcon: Icons.celebration_rounded,
    ),
    'Snacks': const CategoryIconInfo(
      assetPath: HomeAssets.fruits,
      fallbackIcon: Icons.fastfood_rounded,
    ),
    'Breakfast': const CategoryIconInfo(
      assetPath: HomeAssets.drinks,
      fallbackIcon: Icons.free_breakfast_rounded,
    ),
    'Jungle': const CategoryIconInfo(
      assetPath: HomeAssets.birds,
      fallbackIcon: Icons.forest_rounded,
    ),
    'Travel': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.flight_rounded,
    ),
    'Office': const CategoryIconInfo(
      assetPath: HomeAssets.cutlery,
      fallbackIcon: Icons.business_center_rounded,
    ),
    'Cleaning': const CategoryIconInfo(
      assetPath: HomeAssets.cutlery,
      fallbackIcon: Icons.cleaning_services_rounded,
    ),
    'Art': const CategoryIconInfo(
      assetPath: HomeAssets.colors,
      fallbackIcon: Icons.brush_rounded,
    ),
    'Space': const CategoryIconInfo(
      assetPath: HomeAssets.directions,
      fallbackIcon: Icons.rocket_launch_rounded,
    ),
  };
}
