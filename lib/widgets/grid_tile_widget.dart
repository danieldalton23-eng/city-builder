// ============================================================
// grid_tile_widget.dart  (redesigned)
// A single tile in the 20×20 city grid.
//
// Visual design:
//   • Slightly rounded corners (4 px radius)
//   • Desaturated terrain palette from AppColors
//   • Building emoji centred on tile with subtle shadow
//   • Level badge (L2/L3) in top-right corner
//   • Selected tile shows sky-blue glow border + scale-up
//   • Hover highlight on web/desktop via MouseRegion
//   • Tap scale-down animation for tactile feedback
// ============================================================

import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../models/building_type.dart';
import '../models/terrain_type.dart';
import '../theme/app_theme.dart';

class GridTileWidget extends StatefulWidget {
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
  State<GridTileWidget> createState() => _GridTileWidgetState();
}

class _GridTileWidgetState extends State<GridTileWidget>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _tapCtrl.forward();
  void _onTapUp(_) => _tapCtrl.reverse();
  void _onTapCancel() => _tapCtrl.reverse();

  // ── Terrain base color ─────────────────────────────────────

  Color get _baseColor {
    switch (widget.tile.terrain) {
      case TerrainType.water:
        return AppColors.water;
      case TerrainType.mountain:
        return AppColors.mountain;
      case TerrainType.grass:
        return widget.tile.building != BuildingType.empty
            ? AppColors.grassDark
            : AppColors.grass;
    }
  }

  // ── Building overlay color ─────────────────────────────────

  Color _buildingColor(BuildingType b) {
    switch (b) {
      case BuildingType.house:       return AppColors.house;
      case BuildingType.farm:        return AppColors.farm;
      case BuildingType.powerPlant:  return AppColors.powerPlant;
      case BuildingType.market:      return AppColors.market;
      case BuildingType.barracks:    return AppColors.barracks;
      case BuildingType.researchLab: return AppColors.researchLab;
      case BuildingType.empty:       return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBuilding = widget.tile.building != BuildingType.empty;
    final isSelected = widget.isSelected;

    // Emoji from existing levelConfig helper
    final terrainCfg = terrainConfigs[widget.tile.terrain]!;
    final emoji = hasBuilding
        ? levelConfig(widget.tile.building, widget.tile.level).emoji
        : terrainCfg.emoji;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _tapScale,
          builder: (context, child) => Transform.scale(
            scale: _tapScale.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            margin: const EdgeInsets.all(0.8),
            decoration: BoxDecoration(
              color: _baseColor,
              borderRadius: AppRadius.tileRadius,
              border: isSelected
                  ? Border.all(color: AppColors.selected, width: 2)
                  : _hovered
                      ? Border.all(
                          color: AppColors.selected.withOpacity(0.55),
                          width: 1.5)
                      : Border.all(
                          color: Colors.black.withOpacity(0.18),
                          width: 0.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.selected.withOpacity(0.35),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Subtle top-left highlight gradient for depth
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.tileRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.07),
                          Colors.black.withOpacity(0.12),
                        ],
                      ),
                    ),
                  ),
                ),

                // Building color overlay (tinted wash)
                if (hasBuilding)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _buildingColor(widget.tile.building)
                            .withOpacity(0.30),
                        borderRadius: AppRadius.tileRadius,
                      ),
                    ),
                  ),

                // Hover highlight overlay
                if (_hovered && !isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.selected.withOpacity(0.10),
                        borderRadius: AppRadius.tileRadius,
                      ),
                    ),
                  ),

                // Emoji (building or terrain icon)
                if (emoji.isNotEmpty)
                  Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Level badge (L2 / L3) — top-right corner
                if (hasBuilding && widget.tile.level > 0)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'L${widget.tile.level + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Blocked overlay for non-buildable terrain
                if (!terrainCfg.buildable && !hasBuilding)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.10),
                        borderRadius: AppRadius.tileRadius,
                      ),
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
