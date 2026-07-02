import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/theme/puzzle_theme.dart';
import 'how_to_play_step_card.dart';
import 'how_to_play_steps.dart';

class HowToPlayPager extends StatefulWidget {
  const HowToPlayPager({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<HowToPlayPager> createState() => _HowToPlayPagerState();
}

class _HowToPlayPagerState extends State<HowToPlayPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage >= howToPlaySteps.length - 1;

  void _goNext() {
    if (_isLastPage) {
      widget.onClose();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 352,
          child: PageView.builder(
            controller: _pageController,
            itemCount: howToPlaySteps.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return HowToPlayStepCard(
                step: howToPlaySteps[index],
                isActive: index == _currentPage,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < howToPlaySteps.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 10 : 8,
                height: i == _currentPage ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentPage
                      ? PuzzleTheme.mediumGreen
                      : PuzzleTheme.mediumGreen.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (!_isLastPage)
              TextButton(
                onPressed: withButtonTap(widget.onClose),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: PuzzleTheme.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const SizedBox(width: 64),
            const Spacer(),
            FilledButton(
              onPressed: withButtonTap(_goNext),
              style: FilledButton.styleFrom(
                backgroundColor: PuzzleTheme.mediumGreen,
                foregroundColor: PuzzleTheme.yellow,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isLastPage ? 'Got it' : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
