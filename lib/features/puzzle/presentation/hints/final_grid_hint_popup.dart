import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../data/models/generated_puzzle_layout.dart';
import '../../domain/board_geometry.dart';
import '../widgets/solved_grid_board.dart';

class FinalGridHintPopup extends StatelessWidget {
  const FinalGridHintPopup({
    super.key,
    required this.layout,
    required this.onClose,
  });

  final GeneratedPuzzleLayout layout;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width > 400 ? 360.0 : width - 32;
    final rowCount = layout.maxRow - layout.minRow + 1;
    final colCount = layout.maxCol - layout.minCol + 1;
    final maxPreviewWidth = maxWidth - 48;
    const maxPreviewHeight = 220.0;
    final tileSize = min(
      32.0,
      min(maxPreviewWidth / colCount, maxPreviewHeight / rowCount),
    );
    final geometry = BoardGeometry.local(
      boardRows: rowCount,
      boardCols: colCount,
      boardCellSize: tileSize,
    );

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Use this as a reference while solving the puzzle.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PuzzleTheme.tooltipText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxPreviewWidth,
                              maxHeight: maxPreviewHeight,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: PuzzleTheme.tileBg.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: SolvedGridBoard(
                                  layout: layout,
                                  geometry: geometry,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: withButtonTap(onClose),
                          style: FilledButton.styleFrom(
                            backgroundColor: PuzzleTheme.darkGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                'FINAL GRID',
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

Future<void> showFinalGridHintPopup(
  BuildContext context, {
  required GeneratedPuzzleLayout layout,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) {
      return FinalGridHintPopup(
        layout: layout,
        onClose: () => Navigator.of(context).pop(),
      );
    },
  );
}
