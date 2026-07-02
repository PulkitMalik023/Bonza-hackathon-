import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/theme/puzzle_theme.dart';
import 'how_to_play_pager.dart';

class HowToPlayPopup extends StatelessWidget {
  const HowToPlayPopup({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width > 400 ? 360.0 : width - 32;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PuzzleTheme.boardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: PuzzleTheme.boardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(onClose: onClose),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: HowToPlayPager(onClose: onClose),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: PuzzleTheme.headerGradient,
        boxShadow: PuzzleTheme.headerShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const Icon(Icons.eco, color: PuzzleTheme.lightGreen, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'HOW TO PLAY',
                style: PuzzleTheme.headerTitleStyle(
                  MediaQuery.sizeOf(context).width,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.eco, color: PuzzleTheme.lightGreen, size: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: withButtonTap(onClose),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: PuzzleTheme.yellow,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showHowToPlayPopup(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) {
      return HowToPlayPopup(
        onClose: () => Navigator.of(context).pop(),
      );
    },
  );
}
