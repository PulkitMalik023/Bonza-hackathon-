import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_grid_background/animated_grid_background.dart';
import '../../puzzle/presentation/widgets/grid_nodes_layer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedGridBackground(tileSize: AppTheme.gridTileSize),
              GridNodesLayer(
                tileSize: AppTheme.gridTileSize,
                boardSize: boardSize,
                nodeCount: 10,
              ),
            ],
          );
        },
      ),
    );
  }
}
