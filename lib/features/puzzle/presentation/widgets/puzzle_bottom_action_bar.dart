import 'package:flutter/material.dart';

import '../../../../core/constants/puzzle_assets.dart';
import '../../../../core/constants/puzzle_ui_flags.dart';
import '../../../../core/theme/puzzle_theme.dart';
import 'puzzle_action_button.dart';

class PuzzleBottomActionBar extends StatelessWidget {
  const PuzzleBottomActionBar({
    super.key,
    required this.onUndo,
    required this.onHint,
    required this.onShuffle,
    this.undoEnabled = true,
    this.shuffleEnabled = true,
    this.hintEnabled = true,
  });

  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onShuffle;
  final bool undoEnabled;
  final bool shuffleEnabled;
  final bool hintEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          PuzzleActionButton(
            label: 'UNDO',
            assetPath: PuzzleAssets.undo,
            fallbackIcon: Icons.undo_rounded,
            onPressed: undoEnabled ? onUndo : null,
          ),
          PuzzleActionButton(
            label: 'HINT',
            assetPath: PuzzleAssets.hintMagic,
            fallbackIcon: Icons.auto_fix_high_rounded,
            onPressed: hintEnabled ? onHint : null,
            showBadge: kShowHintBadge,
          ),
          PuzzleActionButton(
            label: 'SHUFFLE',
            assetPath: PuzzleAssets.shuffle,
            fallbackIcon: Icons.shuffle_rounded,
            onPressed: shuffleEnabled ? onShuffle : null,
          ),
        ],
      ),
    );
  }
}
