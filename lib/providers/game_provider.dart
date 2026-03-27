// ============================================================
// game_provider.dart
// Central state manager for the city-builder game.
//
// New in this version:
//   1. Tier-2 building dependency checks before placement
//   2. Resource history tracking (one snapshot per tick)
//   3. Achievement evaluation and unlock notifications
//   4. Multi-slot save/load (3 independent cities)
//   5. Credits-per-tick from Market / Barracks / Research Lab
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/building_type.dart';
import '../models/resources.dart';
import '../models/tile.dart';
import '../models/terrain_type.dart';
import '../models/resource_snapshot.dart';
import '../models/achievement.dart';
import '../services/save_service.dart';

const Duration _tickInterval = Duration(seconds: 5);
const int _baseCreditsPerTick = 5;
const int _foodCrisisPopLoss = 1;
const int _powerCrisisPopLoss = 1;

class GameProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────

  GameState _state = GameState.initial();
  BuildingType _selectedBuilding = BuildingType.house;
  Timer? _tickTimer;
  bool _isLoading = true;
  String? _lastMessage;
  int? _selectedRow;
  int? _selectedCol;
  int _activeSlot = 0;

  // Resource history for the statistics screen.
  final List<ResourceSnapshot> _resourceHistory = [];

  // Set of unlocked achievement IDs.
  final Set<String> _unlockedAchievements = {};

  // Queue of newly unlocked achievements to show as toasts.
  final List<AchievementDefinition> _pendingAchievements = [];

  // ── Getters ────────────────────────────────────────────────

  GameState get state => _state;
  BuildingType get selectedBuilding => _selectedBuilding;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  Resources get resources => _state.resources;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int get activeSlot => _activeSlot;
  List<ResourceSnapshot> get resourceHistory =>
      List.unmodifiable(_resourceHistory);
  Set<String> get unlockedAchievements =>
      Set.unmodifiable(_unlockedAchievements);
  List<AchievementDefinition> get pendingAchievements =>
      List.unmodifiable(_pendingAchievements);

  Tile? get selectedTile =>
      (_selectedRow != null && _selectedCol != null)
          ? _state.tileAt(_selectedRow!, _selectedCol!)
          : null;

  // ── Initialisation ─────────────────────────────────────────

  Future<void> init() async {
    _activeSlot = await SaveService.getActiveSlot();
    final saved = await SaveService.load(slot: _activeSlot);
    if (saved != null) _state = saved;
    _isLoading = false;
    _startTick();
    notifyListeners();
  }

  // ── Slot management ────────────────────────────────────────

  Future<void> loadSlot(int slot) async {
    _tickTimer?.cancel();
    _activeSlot = slot;
    await SaveService.setActiveSlot(slot);
    final saved = await SaveService.load(slot: slot);
    _state = saved ?? GameState.initial();
    _selectedBuilding = BuildingType.house;
    _selectedRow = null;
    _selectedCol = null;
    _resourceHistory.clear();
    _startTick();
    notifyListeners();
  }

  Future<void> newGameInSlot(int slot) async {
    _tickTimer?.cancel();
    await SaveService.clear(slot: slot);
    _activeSlot = slot;
    await SaveService.setActiveSlot(slot);
    _state = GameState.initial();
    _selectedBuilding = BuildingType.house;
    _selectedRow = null;
    _selectedCol = null;
    _resourceHistory.clear();
    _startTick();
    _setMessage('New city started in Slot ${slot + 1}!');
    notifyListeners();
  }

  Future<void> newGame() async => newGameInSlot(_activeSlot);

  // ── Building selection ─────────────────────────────────────

  void selectBuilding(BuildingType type) {
    _selectedBuilding = type;
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  // ── Tier-2 dependency check ────────────────────────────────

  /// Returns true if the player has met the tier requirement for [type].
  bool isTierUnlocked(BuildingType type) {
    final req = tierRequirement(type);
    if (req == null) return true; // Tier-1 or no requirement.
    return _state.tiles.any((t) => t.building == req);
  }

  // ── Tile interaction ───────────────────────────────────────

  void onTileTap(int row, int col) {
    final tile = _state.tileAt(row, col);

    if (tile.terrain != TerrainType.grass) {
      final name =
          tile.terrain == TerrainType.mountain ? 'Mountain' : 'Water';
      _setMessage('$name tiles cannot be built on.');
      notifyListeners();
      return;
    }

    if (tile.building == BuildingType.empty) {
      if (_selectedBuilding == BuildingType.empty) return;
      _placeBuilding(row, col, _selectedBuilding);
    } else {
      if (_selectedRow == row && _selectedCol == col) {
        _selectedRow = null;
        _selectedCol = null;
      } else {
        _selectedRow = row;
        _selectedCol = col;
      }
      notifyListeners();
    }
  }

  void _placeBuilding(int row, int col, BuildingType building) {
    final cfg = levelConfig(building, 0);
    final r = _state.resources;

    // ── Tier-2 dependency check ──────────────────────────
    if (!isTierUnlocked(building)) {
      final req = tierRequirement(building)!;
      final reqName = buildingConfigs[req]!.name;
      _setMessage(
          'Requires at least one $reqName on the map first.');
      notifyListeners();
      return;
    }

    // ── Affordability checks ───────────────────────────────
    if (r.credits < cfg.creditCost) {
      _setMessage(
          'Need ${cfg.creditCost} 💰 credits. (Have ${r.credits})');
      notifyListeners();
      return;
    }
    if (cfg.foodCost > 0 && r.food < cfg.foodCost) {
      _setMessage('Need ${cfg.foodCost} 🌾 food. (Have ${r.food})');
      notifyListeners();
      return;
    }
    if (cfg.powerCost > 0 && r.power < cfg.powerCost) {
      _setMessage(
          'Need ${cfg.powerCost} ⚡ power. (Have ${r.power})');
      notifyListeners();
      return;
    }

    final newResources = r.copyWith(
      credits: r.credits - cfg.creditCost,
      food: r.food - cfg.foodCost,
      power: r.power - cfg.powerCost,
    );

    _state = _state
        .withNewBuilding(row, col, building)
        .withResources(newResources);

    _setMessage('${buildingConfigs[building]!.name} placed!');
    _checkAchievements();
    _autoSave();
    notifyListeners();
  }

  // ── Upgrade logic ──────────────────────────────────────────

  void upgradeTile(int row, int col) {
    final tile = _state.tileAt(row, col);
    if (tile.building == BuildingType.empty) {
      _setMessage('No building to upgrade here.');
      notifyListeners();
      return;
    }

    final currentLevel = tile.level;
    final max = maxLevel(tile.building);

    if (currentLevel >= max) {
      _setMessage('Already at maximum level!');
      notifyListeners();
      return;
    }

    final nextLevel = currentLevel + 1;
    final nextCfg = levelConfig(tile.building, nextLevel);
    final r = _state.resources;

    if (r.population < nextCfg.populationRequired) {
      _setMessage(
          'Need ${nextCfg.populationRequired} 👥 pop to unlock ${nextCfg.levelName}. (Have ${r.population})');
      notifyListeners();
      return;
    }
    if (r.credits < nextCfg.creditCost) {
      _setMessage(
          'Need ${nextCfg.creditCost} 💰 credits. (Have ${r.credits})');
      notifyListeners();
      return;
    }
    if (nextCfg.foodCost > 0 && r.food < nextCfg.foodCost) {
      _setMessage(
          'Need ${nextCfg.foodCost} 🌾 food. (Have ${r.food})');
      notifyListeners();
      return;
    }
    if (nextCfg.powerCost > 0 && r.power < nextCfg.powerCost) {
      _setMessage(
          'Need ${nextCfg.powerCost} ⚡ power. (Have ${r.power})');
      notifyListeners();
      return;
    }

    final newResources = r.copyWith(
      credits: r.credits - nextCfg.creditCost,
      food: r.food - nextCfg.foodCost,
      power: r.power - nextCfg.powerCost,
    );

    _state = _state
        .withUpgradedTile(row, col, nextLevel)
        .withResources(newResources);

    _setMessage('Upgraded to ${nextCfg.levelName}! 🎉');
    _checkAchievements();
    _autoSave();
    notifyListeners();
  }

  void demolishTile(int row, int col) {
    _state = _state.withDemolishedTile(row, col);
    _selectedRow = null;
    _selectedCol = null;
    _setMessage('Building demolished.');
    _autoSave();
    notifyListeners();
  }

  // ── Resource tick ──────────────────────────────────────────

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(_tickInterval, (_) => _processTick());
  }

  void _processTick() {
    int foodDelta = 0;
    int powerDelta = 0;
    int populationDelta = 0;
    int extraCredits = 0;
    int totalUpkeep = 0;

    final r = _state.resources;

    for (final tile in _state.tiles) {
      if (tile.building == BuildingType.empty) continue;
      final cfg = levelConfig(tile.building, tile.level);

      foodDelta += cfg.foodPerTick;
      powerDelta += cfg.powerPerTick;
      extraCredits += cfg.creditsPerTick; // Market / Barracks / Lab

      // Houses grow population only when power is available.
      if (cfg.populationPerTick > 0 && r.power > 0) {
        populationDelta += cfg.populationPerTick;
      }

      totalUpkeep += cfg.upkeepPerTick;
    }

    // ── Negative consequences ──────────────────────────────
    if (r.isFoodCrisis && r.population > 0) {
      populationDelta -= _foodCrisisPopLoss;
    }
    if (r.isPowerCrisis && r.population > 0) {
      populationDelta -= _powerCrisisPopLoss;
    }

    // ── Apply deltas ───────────────────────────────────────
    final newCredits =
        r.credits + _baseCreditsPerTick + extraCredits - totalUpkeep;

    final updated = Resources(
      credits: newCredits,
      food: r.food + foodDelta,
      power: r.power + powerDelta,
      population: r.population + populationDelta,
    ).clamped();

    _state = _state.withResources(updated);

    // ── Record history snapshot ────────────────────────────
    _resourceHistory.add(ResourceSnapshot(
      timestamp: DateTime.now(),
      credits: updated.credits,
      food: updated.food,
      power: updated.power,
      population: updated.population,
    ));
    // Trim to max history length.
    if (_resourceHistory.length > ResourceSnapshot.maxHistory) {
      _resourceHistory.removeAt(0);
    }

    _checkAchievements();
    _autoSave();
    notifyListeners();
  }

  // ── Achievement engine ─────────────────────────────────────

  void _checkAchievements() {
    for (final achievement in allAchievements) {
      if (_unlockedAchievements.contains(achievement.id)) continue;
      if (achievement.check(_state)) {
        _unlockedAchievements.add(achievement.id);
        _pendingAchievements.add(achievement);

        // Award credit bonus.
        final r = _state.resources;
        _state = _state.withResources(
          r.copyWith(credits: r.credits + achievement.creditReward),
        );

        // Show toast message.
        _setMessage(
            '🏆 Achievement: "${achievement.title}" +${achievement.creditReward}💰');
      }
    }
  }

  /// Called by the UI after displaying a pending achievement toast.
  void consumePendingAchievement() {
    if (_pendingAchievements.isNotEmpty) {
      _pendingAchievements.removeAt(0);
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  void _autoSave() => SaveService.save(_state, slot: _activeSlot);

  void _setMessage(String msg) {
    _lastMessage = msg;
    Future.delayed(const Duration(seconds: 3), () {
      _lastMessage = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
