// ============================================================
// achievement.dart
// Defines all game achievements (milestones) and their rewards.
//
// Each achievement has:
//   • A unique string id
//   • A title and description shown in the achievements screen
//   • An emoji icon
//   • A credit reward paid out on first unlock
//   • A check function that evaluates the current game state
//
// To add a new achievement:
//   1. Add an AchievementDefinition to allAchievements.
//   2. The engine will automatically evaluate and unlock it.
// ============================================================

import 'game_state.dart';
import 'building_type.dart';
import 'resources.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int creditReward;

  /// Returns true when the achievement condition is met.
  final bool Function(GameState state) check;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.creditReward,
    required this.check,
  });
}

// ── Helper: count buildings of a specific type on the map ──

int _countBuildings(GameState state, BuildingType type) =>
    state.tiles.where((t) => t.building == type).length;

int _countAllBuildings(GameState state) =>
    state.tiles.where((t) => t.building != BuildingType.empty).length;

bool _hasAnyTier2(GameState state) =>
    state.tiles.any((t) => isTier2(t.building));

int _maxBuildingLevel(GameState state) =>
    state.tiles.isEmpty
        ? 0
        : state.tiles
            .where((t) => t.building != BuildingType.empty)
            .fold(0, (max, t) => t.level > max ? t.level : max);

// ── Master achievement registry ────────────────────────────

final List<AchievementDefinition> allAchievements = [
  // ── Placement milestones ─────────────────────────────────
  AchievementDefinition(
    id: 'first_building',
    title: 'First Steps',
    description: 'Place your first building.',
    emoji: '🏗️',
    creditReward: 20,
    check: (s) => _countAllBuildings(s) >= 1,
  ),
  AchievementDefinition(
    id: 'five_buildings',
    title: 'Growing City',
    description: 'Have 5 buildings on the map.',
    emoji: '🏘️',
    creditReward: 30,
    check: (s) => _countAllBuildings(s) >= 5,
  ),
  AchievementDefinition(
    id: 'ten_buildings',
    title: 'Urban Planner',
    description: 'Have 10 buildings on the map.',
    emoji: '🗺️',
    creditReward: 50,
    check: (s) => _countAllBuildings(s) >= 10,
  ),
  AchievementDefinition(
    id: 'twenty_buildings',
    title: 'Metropolis',
    description: 'Have 20 buildings on the map.',
    emoji: '🌆',
    creditReward: 100,
    check: (s) => _countAllBuildings(s) >= 20,
  ),

  // ── Population milestones ────────────────────────────────
  AchievementDefinition(
    id: 'pop_10',
    title: 'Village',
    description: 'Reach a population of 10.',
    emoji: '👨‍👩‍👧',
    creditReward: 25,
    check: (s) => s.resources.population >= 10,
  ),
  AchievementDefinition(
    id: 'pop_50',
    title: 'Town',
    description: 'Reach a population of 50.',
    emoji: '🏙️',
    creditReward: 75,
    check: (s) => s.resources.population >= 50,
  ),
  AchievementDefinition(
    id: 'pop_100',
    title: 'City',
    description: 'Reach a population of 100.',
    emoji: '🌇',
    creditReward: 150,
    check: (s) => s.resources.population >= 100,
  ),

  // ── Resource milestones ──────────────────────────────────
  AchievementDefinition(
    id: 'food_100',
    title: 'Well Fed',
    description: 'Store 100 food.',
    emoji: '🍞',
    creditReward: 30,
    check: (s) => s.resources.food >= 100,
  ),
  AchievementDefinition(
    id: 'food_200',
    title: 'Granary Full',
    description: 'Fill the food storage to maximum (200).',
    emoji: '🌽',
    creditReward: 60,
    check: (s) => s.resources.food >= kFoodCap,
  ),
  AchievementDefinition(
    id: 'power_100',
    title: 'Fully Powered',
    description: 'Store 100 power.',
    emoji: '💡',
    creditReward: 30,
    check: (s) => s.resources.power >= 100,
  ),
  AchievementDefinition(
    id: 'credits_500',
    title: 'Investor',
    description: 'Accumulate 500 credits.',
    emoji: '💰',
    creditReward: 50,
    check: (s) => s.resources.credits >= 500,
  ),
  AchievementDefinition(
    id: 'credits_1000',
    title: 'Tycoon',
    description: 'Accumulate 1000 credits.',
    emoji: '🤑',
    creditReward: 100,
    check: (s) => s.resources.credits >= 1000,
  ),

  // ── Building-type milestones ─────────────────────────────
  AchievementDefinition(
    id: 'first_farm',
    title: 'Green Thumb',
    description: 'Place your first Farm.',
    emoji: '🌱',
    creditReward: 15,
    check: (s) => _countBuildings(s, BuildingType.farm) >= 1,
  ),
  AchievementDefinition(
    id: 'first_power',
    title: 'Lights On',
    description: 'Place your first Power Plant.',
    emoji: '🔌',
    creditReward: 15,
    check: (s) => _countBuildings(s, BuildingType.powerPlant) >= 1,
  ),
  AchievementDefinition(
    id: 'first_tier2',
    title: 'Advanced Civilisation',
    description: 'Place your first Tier-2 building.',
    emoji: '⭐',
    creditReward: 80,
    check: (s) => _hasAnyTier2(s),
  ),
  AchievementDefinition(
    id: 'first_market',
    title: 'Open for Business',
    description: 'Place a Market.',
    emoji: '🏪',
    creditReward: 40,
    check: (s) => _countBuildings(s, BuildingType.market) >= 1,
  ),
  AchievementDefinition(
    id: 'first_lab',
    title: 'Science!',
    description: 'Place a Research Lab.',
    emoji: '🔬',
    creditReward: 40,
    check: (s) => _countBuildings(s, BuildingType.researchLab) >= 1,
  ),

  // ── Upgrade milestones ───────────────────────────────────
  AchievementDefinition(
    id: 'first_upgrade',
    title: 'Level Up',
    description: 'Upgrade any building for the first time.',
    emoji: '⬆️',
    creditReward: 20,
    check: (s) => _maxBuildingLevel(s) >= 1,
  ),
  AchievementDefinition(
    id: 'max_upgrade',
    title: 'Perfection',
    description: 'Upgrade any building to its maximum level.',
    emoji: '🏆',
    creditReward: 100,
    check: (s) => _maxBuildingLevel(s) >= 2,
  ),
];
