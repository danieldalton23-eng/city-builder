// ============================================================
// terrain_type.dart
// Defines the natural terrain of each tile, determined once
// at map generation and never changed during gameplay.
//
// Only TerrainType.grass tiles can have buildings placed on them.
// Mountain and water tiles are purely decorative obstacles.
// ============================================================

import 'package:flutter/material.dart';

enum TerrainType {
  grass,    // Default buildable tile
  mountain, // Impassable — cannot build
  water,    // Impassable — cannot build
}

/// Visual config for each terrain type.
class TerrainConfig {
  final Color color;
  final String emoji;
  final bool buildable;
  const TerrainConfig({
    required this.color,
    required this.emoji,
    required this.buildable,
  });
}

const Map<TerrainType, TerrainConfig> terrainConfigs = {
  TerrainType.grass: TerrainConfig(
    color: Color(0xFF4CAF50),
    emoji: '',
    buildable: true,
  ),
  TerrainType.mountain: TerrainConfig(
    color: Color(0xFF78909C), // blue-grey rock
    emoji: '⛰️',
    buildable: false,
  ),
  TerrainType.water: TerrainConfig(
    color: Color(0xFF1E88E5), // blue water
    emoji: '🌊',
    buildable: false,
  ),
};
