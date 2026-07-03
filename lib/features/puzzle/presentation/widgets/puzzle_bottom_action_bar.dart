import 'package:flutter/material.dart';

import '../../../../core/constants/puzzle_assets.dart';
import '../../../../core/constants/puzzle_ui_flags.dart';
import 'puzzle_action_button.dart';

class PuzzleBottomActionBar extends StatelessWidget {
  const PuzzleBottomActionBar({
    super.key,
    required this.onUndo,
    required this.onHint,
    required this.onFullGrid,
    this.undoEnabled = true,
    this.hintEnabled = true,
    this.fullGridEnabled = true,
  });

  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onFullGrid;
  final bool undoEnabled;
  final bool hintEnabled;
  final bool fullGridEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            label: 'FULL GRID',
            assetPath: 'assets/icons/full_grid.png',
            fallbackIcon: Icons.grid_view_rounded,
            onPressed: fullGridEnabled ? onFullGrid : null,
          ),
        ],
      ),
    );
  }
}
