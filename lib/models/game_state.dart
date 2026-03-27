// ============================================================
// game_state.dart
// Top-level snapshot of the entire game at any point in time.
//
// Map generation:
//   The initial() factory seeds the 20×20 grid with natural
//   terrain clusters using a simple flood-fill algorithm so
//   mountains and water form contiguous, organic-looking blobs
//   rather than random scattered dots.
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'tile.dart';
import 'resources.dart';
import 'building_type.dart';
import 'terrain_type.dart';

const int gridSize = 20;

/// Approximate fraction of tiles that become non-buildable terrain.
/// ~12 % mountain + ~10 % water = ~22 % of the map is impassable.
const int _mountainClusters = 4;
const int _waterClusters = 3;
const int _clusterRadius = 2; // tiles of spread per cluster seed

class GameState {
  final List<Tile> tiles;
  final Resources resources;

  GameState({required this.tiles, required this.resources});

  // ── Factory constructors ───────────────────────────────────

  /// Creates a brand-new game with a procedurally generated map.
  factory GameState.initial({int? seed}) {
    final rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

    // Start with all-grass grid.
    final tiles = List<Tile>.generate(
      gridSize * gridSize,
      (i) => Tile(row: i ~/ gridSize, col: i % gridSize),
    );

    // Helper: set terrain for a tile index if in bounds.
    void setTerrain(int r, int c, TerrainType t) {
      if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) return;
      final idx = r * gridSize + c;
      // Don't overwrite an already-assigned non-grass tile.
      if (tiles[idx].terrain != TerrainType.grass) return;
      tiles[idx] = Tile(row: r, col: c, terrain: t);
    }

    // Grow clusters of a given terrain type from random seed points.
    void growClusters(int count, TerrainType type) {
      for (int i = 0; i < count; i++) {
        // Avoid placing cluster seeds in the very centre (starter area).
        int seedR, seedC;
        do {
          seedR = rng.nextInt(gridSize);
          seedC = rng.nextInt(gridSize);
        } while ((seedR - gridSize ~/ 2).abs() < 3 &&
            (seedC - gridSize ~/ 2).abs() < 3);

        // Flood-fill a blob of radius _clusterRadius with some noise.
        for (int dr = -_clusterRadius; dr <= _clusterRadius; dr++) {
          for (int dc = -_clusterRadius; dc <= _clusterRadius; dc++) {
            // Skip corners to make it feel rounder.
            if (dr.abs() + dc.abs() > _clusterRadius + 1) continue;
            // Add a little randomness so edges are jagged.
            if (rng.nextDouble() < 0.25) continue;
            setTerrain(seedR + dr, seedC + dc, type);
          }
        }
      }
    }

    growClusters(_mountainClusters, TerrainType.mountain);
    growClusters(_waterClusters, TerrainType.water);

    return GameState(tiles: tiles, resources: Resources());
  }

  // ── Grid helpers ───────────────────────────────────────────

  Tile tileAt(int row, int col) => tiles[row * gridSize + col];

  GameState withNewBuilding(int row, int col, BuildingType building) {
    final newTiles = List<Tile>.from(tiles);
    newTiles[row * gridSize + col] = Tile(
      row: row,
      col: col,
      terrain: tileAt(row, col).terrain,
      building: building,
      level: 0,
    );
    return GameState(tiles: newTiles, resources: resources);
  }

  GameState withUpgradedTile(int row, int col, int newLevel) {
    final newTiles = List<Tile>.from(tiles);
    final old = newTiles[row * gridSize + col];
    newTiles[row * gridSize + col] = Tile(
      row: row,
      col: col,
      terrain: old.terrain,
      building: old.building,
      level: newLevel,
    );
    return GameState(tiles: newTiles, resources: resources);
  }

  GameState withDemolishedTile(int row, int col) {
    final newTiles = List<Tile>.from(tiles);
    final old = newTiles[row * gridSize + col];
    newTiles[row * gridSize + col] = Tile(
      row: row,
      col: col,
      terrain: old.terrain, // Keep the terrain!
      building: BuildingType.empty,
      level: 0,
    );
    return GameState(tiles: newTiles, resources: resources);
  }

  GameState withResources(Resources newResources) =>
      GameState(tiles: tiles, resources: newResources);

  // ── Serialisation ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'tiles': tiles.map((t) => t.toJson()).toList(),
        'resources': resources.toJson(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawTiles = json['tiles'] as List<dynamic>;
    return GameState(
      tiles: rawTiles
          .map((t) => Tile.fromJson(t as Map<String, dynamic>))
          .toList(),
      resources:
          Resources.fromJson(json['resources'] as Map<String, dynamic>),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String source) =>
      GameState.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
