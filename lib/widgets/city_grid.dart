// ============================================================
// city_grid.dart
// Renders the full 20×20 city grid as a scrollable, zoomable
// interactive map. Passes selection state to each tile.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'grid_tile_widget.dart';

class CityGrid extends StatelessWidget {
  const CityGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.state;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      constrained: false,
      child: SizedBox(
        width: gridSize * 36.0,
        height: gridSize * 36.0,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            childAspectRatio: 1.0,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            final row = index ~/ gridSize;
            final col = index % gridSize;
            final tile = state.tileAt(row, col);
            final isSelected =
                provider.selectedRow == row && provider.selectedCol == col;

            return GridTileWidget(
              tile: tile,
              isSelected: isSelected,
              onTap: () => provider.onTileTap(row, col),
            );
          },
        ),
      ),
    );
  }
}
