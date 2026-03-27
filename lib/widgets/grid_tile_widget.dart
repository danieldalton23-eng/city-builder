// ============================================================
// grid_tile_widget.dart
// Visual representation of a single tile on the 20×20 grid.
//
// Renders:
//   • Terrain colour (grass / mountain / water)
//   • Terrain emoji for non-grass tiles
//   • Building emoji for placed buildings
//   • Level badge (L2/L3) for upgraded buildings
//   • Blue highlight border when selected
//   • Subtle "blocked" overlay on non-buildable terrain
// ============================================================

import 'package:flutter/material.dart';
import '../models/building_type.dart';
import '../models/tile.dart';
import '../models/terrain_type.dart';

class GridTileWidget extends StatelessWidget {
  final Tile tile;
  final bool isSelected;
  final VoidCallback onTap;

  const GridTileWidget({
    super.key,
    required this.tile,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final terrainCfg = terrainConfigs[tile.terrain]!;
    final hasBuilding = tile.building != BuildingType.empty;

    // Use building colour if a building is placed; otherwise terrain colour.
    final bgColor = hasBuilding
        ? levelConfig(tile.building, tile.level).color
        : terrainCfg.color;

    // Emoji to show: building takes priority over terrain.
    final emoji = hasBuilding
        ? levelConfig(tile.building, tile.level).emoji
        : terrainCfg.emoji;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF40C4FF)
                : Colors.black.withOpacity(0.15),
            width: isSelected ? 2.0 : 0.5,
          ),
        ),
        child: Stack(
          children: [
            // ── Main emoji (terrain or building) ──────────
            if (emoji.isNotEmpty)
              Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            // ── Level badge for upgraded buildings ─────────
            if (hasBuilding && tile.level > 0)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'L${tile.level + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // ── Blocked overlay for non-buildable terrain ──
            if (!terrainCfg.buildable && !hasBuilding)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
