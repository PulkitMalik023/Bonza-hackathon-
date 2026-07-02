import 'package:flutter/material.dart';

import '../../../../core/constants/home_assets.dart';
import '../../../../core/constants/puzzle_ui_flags.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../../core/widgets/asset_icon.dart';

enum HomeNavTab {
  home,
  daily,
  rewards,
  shop,
}

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    this.activeTab = HomeNavTab.home,
    this.onTabSelected,
  });

  final HomeNavTab activeTab;
  final ValueChanged<HomeNavTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PuzzleTheme.bottomNavBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: PuzzleTheme.headerShadow,
          border: Border.all(
            color: PuzzleTheme.lightGreen.withValues(alpha: 0.4),
          ),
        ),
        child: SizedBox(
          height: PuzzleTheme.bottomNavHeight,
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                assetPath: HomeAssets.home,
                fallbackIcon: Icons.home_rounded,
                isActive: activeTab == HomeNavTab.home,
                onTap: () => onTabSelected?.call(HomeNavTab.home),
              ),
              _NavItem(
                label: 'Daily',
                assetPath: HomeAssets.daily,
                fallbackIcon: Icons.calendar_month_rounded,
                isActive: activeTab == HomeNavTab.daily,
                onTap: () => onTabSelected?.call(HomeNavTab.daily),
              ),
              _NavItem(
                label: 'Rewards',
                assetPath: HomeAssets.rewards,
                fallbackIcon: Icons.card_giftcard_rounded,
                isActive: activeTab == HomeNavTab.rewards,
                showBadge: kShowRewardsNavBadge,
                onTap: () => onTabSelected?.call(HomeNavTab.rewards),
              ),
              _NavItem(
                label: 'Shop',
                assetPath: HomeAssets.shop,
                fallbackIcon: Icons.storefront_rounded,
                isActive: activeTab == HomeNavTab.shop,
                onTap: () => onTabSelected?.call(HomeNavTab.shop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.isActive,
    required this.onTap,
    this.showBadge = false,
  });

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? PuzzleTheme.bottomNavActiveBg
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isActive ? PuzzleTheme.tileRestShadow : null,
                      ),
                      child: AssetIcon(
                        assetPath: assetPath,
                        fallbackIcon: fallbackIcon,
                        size: 22,
                        color: isActive ? PuzzleTheme.yellow : PuzzleTheme.darkGreen,
                      ),
                    ),
                    if (showBadge)
                      const Positioned(
                        top: -2,
                        right: 4,
                        child: _Badge(),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? PuzzleTheme.bottomNavActiveBg
                        : PuzzleTheme.darkGreen,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: PuzzleTheme.badgeRed,
        shape: BoxShape.circle,
      ),
    );
  }
}
