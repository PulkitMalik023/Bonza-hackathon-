import 'package:flutter/material.dart';

import '../../../../core/theme/puzzle_theme.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    this.title = 'CHOOSE A LEVEL',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, color: PuzzleTheme.mediumGreen, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: PuzzleTheme.sectionTitleStyle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.eco, color: PuzzleTheme.mediumGreen, size: 20),
        ],
      ),
    );
  }
}
