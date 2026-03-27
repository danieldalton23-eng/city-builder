// ============================================================
// tile.dart
// Represents a single cell on the 20×20 game grid.
// Each tile has:
//   • terrain  — set once at map generation, never changes
//   • building — what the player has placed (empty by default)
//   • level    — current upgrade level of the building (0-indexed)
// ============================================================

import 'building_type.dart';
import 'terrain_type.dart';

class Tile {
  final int row;
  final int col;

  /// Natural terrain — determines whether a building can be placed.
  final TerrainType terrain;

  /// The building placed on this tile (empty if none).
  BuildingType building;

  /// Upgrade level of the placed building (0 = base).
  int level;

  Tile({
    required this.row,
    required this.col,
    this.terrain = TerrainType.grass,
    this.building = BuildingType.empty,
    this.level = 0,
  });

  /// Whether the player can place a building on this tile.
  bool get isBuildable =>
      terrain == TerrainType.grass && building == BuildingType.empty;

  // ── Serialisation ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'terrain': terrain.index,
        'building': building.index,
        'level': level,
      };

  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
        row: json['row'] as int,
        col: json['col'] as int,
        terrain: TerrainType.values[json['terrain'] as int? ?? 0],
        building: BuildingType.values[json['building'] as int],
        level: json['level'] as int? ?? 0,
      );

  Tile copyWith({
    TerrainType? terrain,
    BuildingType? building,
    int? level,
  }) =>
      Tile(
        row: row,
        col: col,
        terrain: terrain ?? this.terrain,
        building: building ?? this.building,
        level: level ?? this.level,
      );
}
