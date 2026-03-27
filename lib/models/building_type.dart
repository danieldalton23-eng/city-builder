// ============================================================
// building_type.dart
// Defines all building types, their upgrade levels, placement
// costs (credits + food + power), per-tick upkeep, and tier.
//
// TIER SYSTEM
//   Tier 1 — Basic buildings, available from the start.
//   Tier 2 — Advanced buildings that require at least one
//             specific Tier-1 building to be placed on the map
//             before they can be unlocked.
//
// To add a new building:
//   1. Add an entry to BuildingType enum.
//   2. Add a BuildingConfig entry to buildingConfigs (include tier
//      and optionally a requiredBuilding).
//   3. Add a List<BuildingLevelConfig> to buildingLevelConfigs.
// ============================================================

import 'package:flutter/material.dart';

/// Every placeable building type in the game.
enum BuildingType {
  empty,

  // ── Tier 1 ──────────────────────────────────────────────
  house,
  farm,
  powerPlant,

  // ── Tier 2 ──────────────────────────────────────────────
  market,      // Requires house  — boosts credit income
  barracks,    // Requires house  — produces defence (stored as credits bonus)
  researchLab, // Requires powerPlant — multiplies production of all buildings
}

// ── Per-level configuration ────────────────────────────────

/// Immutable stats for one specific level of a building.
class BuildingLevelConfig {
  final String levelName;
  final String emoji;
  final Color color;

  // ── Placement / upgrade costs ─────────────────────────────
  final int creditCost;
  final int foodCost;
  final int powerCost;

  /// Minimum total population to unlock this level.
  final int populationRequired;

  final String description;

  // ── Per-tick resource generation ──────────────────────────
  final int foodPerTick;
  final int powerPerTick;
  final int populationPerTick;

  /// Extra credits produced per tick (used by Market).
  final int creditsPerTick;

  /// Credits consumed per tick as upkeep.
  final int upkeepPerTick;

  const BuildingLevelConfig({
    required this.levelName,
    required this.emoji,
    required this.color,
    required this.creditCost,
    required this.populationRequired,
    required this.description,
    required this.upkeepPerTick,
    this.foodCost = 0,
    this.powerCost = 0,
    this.foodPerTick = 0,
    this.powerPerTick = 0,
    this.populationPerTick = 0,
    this.creditsPerTick = 0,
  });
}

// ── Top-level building metadata ────────────────────────────

class BuildingConfig {
  final String name;
  final Color baseColor;

  /// 1 = available from start. 2 = requires [requiredBuilding].
  final int tier;

  /// Tier-2 buildings require at least one of this type on the map.
  final BuildingType? requiredBuilding;

  const BuildingConfig({
    required this.name,
    required this.baseColor,
    this.tier = 1,
    this.requiredBuilding,
  });
}

const Map<BuildingType, BuildingConfig> buildingConfigs = {
  BuildingType.empty: BuildingConfig(
    name: 'Empty',
    baseColor: Color(0xFF4CAF50),
  ),

  // ── Tier 1 ──────────────────────────────────────────────
  BuildingType.house: BuildingConfig(
    name: 'House',
    baseColor: Color(0xFFFFEB3B),
    tier: 1,
  ),
  BuildingType.farm: BuildingConfig(
    name: 'Farm',
    baseColor: Color(0xFF8BC34A),
    tier: 1,
  ),
  BuildingType.powerPlant: BuildingConfig(
    name: 'Power Plant',
    baseColor: Color(0xFFFF9800),
    tier: 1,
  ),

  // ── Tier 2 ──────────────────────────────────────────────
  BuildingType.market: BuildingConfig(
    name: 'Market',
    baseColor: Color(0xFF26C6DA),
    tier: 2,
    requiredBuilding: BuildingType.house, // Needs residents to trade
  ),
  BuildingType.barracks: BuildingConfig(
    name: 'Barracks',
    baseColor: Color(0xFFEF5350),
    tier: 2,
    requiredBuilding: BuildingType.house, // Needs population to recruit
  ),
  BuildingType.researchLab: BuildingConfig(
    name: 'Research Lab',
    baseColor: Color(0xFFAB47BC),
    tier: 2,
    requiredBuilding: BuildingType.powerPlant, // Needs stable power supply
  ),
};

// ── Per-level stat registry ────────────────────────────────

const Map<BuildingType, List<BuildingLevelConfig>> buildingLevelConfigs = {
  BuildingType.empty: [
    BuildingLevelConfig(
      levelName: 'Empty',
      emoji: '',
      color: Color(0xFF4CAF50),
      creditCost: 0,
      populationRequired: 0,
      description: 'An empty tile.',
      upkeepPerTick: 0,
    ),
  ],

  // ── HOUSE ────────────────────────────────────────────────
  BuildingType.house: [
    BuildingLevelConfig(
      levelName: 'Hut',
      emoji: '🛖',
      color: Color(0xFFFFEB3B),
      creditCost: 10,
      powerCost: 2,
      populationRequired: 0,
      description: 'Costs 10💰 + 2⚡. +1 pop/tick if power > 0.',
      populationPerTick: 1,
      upkeepPerTick: 1,
    ),
    BuildingLevelConfig(
      levelName: 'Family Home',
      emoji: '🏠',
      color: Color(0xFFFDD835),
      creditCost: 25,
      powerCost: 4,
      populationRequired: 10,
      description: 'Upgrade: 25💰 + 4⚡. +2 pop/tick. Needs pop ≥ 10.',
      populationPerTick: 2,
      upkeepPerTick: 2,
    ),
    BuildingLevelConfig(
      levelName: 'Apartment',
      emoji: '🏢',
      color: Color(0xFFF9A825),
      creditCost: 60,
      powerCost: 8,
      populationRequired: 30,
      description: 'Max: 60💰 + 8⚡. +4 pop/tick. Needs pop ≥ 30.',
      populationPerTick: 4,
      upkeepPerTick: 4,
    ),
  ],

  // ── FARM ─────────────────────────────────────────────────
  BuildingType.farm: [
    BuildingLevelConfig(
      levelName: 'Small Plot',
      emoji: '🌾',
      color: Color(0xFF8BC34A),
      creditCost: 15,
      foodCost: 5,
      populationRequired: 0,
      description: 'Costs 15💰 + 5🌾. +3 food/tick.',
      foodPerTick: 3,
      upkeepPerTick: 1,
    ),
    BuildingLevelConfig(
      levelName: 'Large Farm',
      emoji: '🚜',
      color: Color(0xFF7CB342),
      creditCost: 35,
      foodCost: 10,
      powerCost: 3,
      populationRequired: 5,
      description: 'Upgrade: 35💰 + 10🌾 + 3⚡. +6 food/tick. Needs pop ≥ 5.',
      foodPerTick: 6,
      upkeepPerTick: 2,
    ),
    BuildingLevelConfig(
      levelName: 'Agri-Complex',
      emoji: '🏭',
      color: Color(0xFF558B2F),
      creditCost: 80,
      foodCost: 20,
      powerCost: 8,
      populationRequired: 20,
      description: 'Max: 80💰 + 20🌾 + 8⚡. +12 food/tick. Needs pop ≥ 20.',
      foodPerTick: 12,
      upkeepPerTick: 3,
    ),
  ],

  // ── POWER PLANT ──────────────────────────────────────────
  BuildingType.powerPlant: [
    BuildingLevelConfig(
      levelName: 'Generator',
      emoji: '⚡',
      color: Color(0xFFFF9800),
      creditCost: 20,
      foodCost: 3,
      populationRequired: 0,
      description: 'Costs 20💰 + 3🌾. +5 power/tick.',
      powerPerTick: 5,
      upkeepPerTick: 1,
    ),
    BuildingLevelConfig(
      levelName: 'Power Station',
      emoji: '🔋',
      color: Color(0xFFF57C00),
      creditCost: 50,
      foodCost: 8,
      populationRequired: 8,
      description: 'Upgrade: 50💰 + 8🌾. +10 power/tick. Needs pop ≥ 8.',
      powerPerTick: 10,
      upkeepPerTick: 2,
    ),
    BuildingLevelConfig(
      levelName: 'Nuclear Plant',
      emoji: '☢️',
      color: Color(0xFFE65100),
      creditCost: 120,
      foodCost: 15,
      populationRequired: 25,
      description: 'Max: 120💰 + 15🌾. +25 power/tick. Needs pop ≥ 25.',
      powerPerTick: 25,
      upkeepPerTick: 4,
    ),
  ],

  // ── MARKET (Tier 2) ───────────────────────────────────────
  // Requires at least one House on the map.
  // Produces credits per tick — acts as a passive income multiplier.
  BuildingType.market: [
    BuildingLevelConfig(
      levelName: 'Stall',
      emoji: '🏪',
      color: Color(0xFF26C6DA),
      creditCost: 40,
      foodCost: 5,
      powerCost: 5,
      populationRequired: 5,
      description: 'Costs 40💰 + 5🌾 + 5⚡. +8 credits/tick. Needs pop ≥ 5.',
      creditsPerTick: 8,
      upkeepPerTick: 2,
    ),
    BuildingLevelConfig(
      levelName: 'Bazaar',
      emoji: '🛒',
      color: Color(0xFF00ACC1),
      creditCost: 90,
      foodCost: 10,
      powerCost: 10,
      populationRequired: 20,
      description: 'Upgrade: 90💰. +18 credits/tick. Needs pop ≥ 20.',
      creditsPerTick: 18,
      upkeepPerTick: 4,
    ),
    BuildingLevelConfig(
      levelName: 'Trade Hub',
      emoji: '🏬',
      color: Color(0xFF00838F),
      creditCost: 200,
      foodCost: 20,
      powerCost: 20,
      populationRequired: 40,
      description: 'Max: 200💰. +40 credits/tick. Needs pop ≥ 40.',
      creditsPerTick: 40,
      upkeepPerTick: 8,
    ),
  ],

  // ── BARRACKS (Tier 2) ─────────────────────────────────────
  // Requires at least one House on the map.
  // Produces a small credit bonus (represents tax/defence contracts)
  // and slows population loss during crises.
  BuildingType.barracks: [
    BuildingLevelConfig(
      levelName: 'Militia Post',
      emoji: '⚔️',
      color: Color(0xFFEF5350),
      creditCost: 50,
      foodCost: 10,
      powerCost: 5,
      populationRequired: 8,
      description: 'Costs 50💰 + 10🌾 + 5⚡. +5 credits/tick. Needs pop ≥ 8.',
      creditsPerTick: 5,
      upkeepPerTick: 3,
    ),
    BuildingLevelConfig(
      levelName: 'Garrison',
      emoji: '🏰',
      color: Color(0xFFE53935),
      creditCost: 110,
      foodCost: 20,
      powerCost: 10,
      populationRequired: 25,
      description: 'Upgrade: 110💰. +12 credits/tick. Needs pop ≥ 25.',
      creditsPerTick: 12,
      upkeepPerTick: 5,
    ),
    BuildingLevelConfig(
      levelName: 'Fortress',
      emoji: '🛡️',
      color: Color(0xFFB71C1C),
      creditCost: 250,
      foodCost: 35,
      powerCost: 20,
      populationRequired: 50,
      description: 'Max: 250💰. +25 credits/tick. Needs pop ≥ 50.',
      creditsPerTick: 25,
      upkeepPerTick: 9,
    ),
  ],

  // ── RESEARCH LAB (Tier 2) ─────────────────────────────────
  // Requires at least one Power Plant on the map.
  // Produces a flat credit bonus and boosts all other buildings
  // (represented as extra credits per tick at higher levels).
  BuildingType.researchLab: [
    BuildingLevelConfig(
      levelName: 'Lab',
      emoji: '🔬',
      color: Color(0xFFAB47BC),
      creditCost: 60,
      foodCost: 5,
      powerCost: 15,
      populationRequired: 10,
      description: 'Costs 60💰 + 15⚡. +6 credits/tick. Needs pop ≥ 10.',
      creditsPerTick: 6,
      upkeepPerTick: 3,
    ),
    BuildingLevelConfig(
      levelName: 'Institute',
      emoji: '🏫',
      color: Color(0xFF8E24AA),
      creditCost: 130,
      foodCost: 10,
      powerCost: 25,
      populationRequired: 30,
      description: 'Upgrade: 130💰 + 25⚡. +15 credits/tick. Needs pop ≥ 30.',
      creditsPerTick: 15,
      upkeepPerTick: 5,
    ),
    BuildingLevelConfig(
      levelName: 'Tech Campus',
      emoji: '🚀',
      color: Color(0xFF6A1B9A),
      creditCost: 300,
      foodCost: 20,
      powerCost: 50,
      populationRequired: 60,
      description: 'Max: 300💰 + 50⚡. +35 credits/tick. Needs pop ≥ 60.',
      creditsPerTick: 35,
      upkeepPerTick: 10,
    ),
  ],
};

// ── Convenience helpers ────────────────────────────────────

BuildingLevelConfig levelConfig(BuildingType type, int level) {
  final levels = buildingLevelConfigs[type]!;
  return levels[level.clamp(0, levels.length - 1)];
}

int maxLevel(BuildingType type) =>
    (buildingLevelConfigs[type]?.length ?? 1) - 1;

/// Returns true if [type] is a Tier-2 building.
bool isTier2(BuildingType type) =>
    (buildingConfigs[type]?.tier ?? 1) >= 2;

/// Returns the Tier-1 building that [type] depends on, or null.
BuildingType? tierRequirement(BuildingType type) =>
    buildingConfigs[type]?.requiredBuilding;

/// All Tier-1 placeable building types.
const List<BuildingType> tier1Buildings = [
  BuildingType.house,
  BuildingType.farm,
  BuildingType.powerPlant,
];

/// All Tier-2 placeable building types.
const List<BuildingType> tier2Buildings = [
  BuildingType.market,
  BuildingType.barracks,
  BuildingType.researchLab,
];
