// ============================================================
// save_service.dart
// Handles reading and writing game state to local storage.
//
// Save Slots:
//   Supports 3 independent save slots (0, 1, 2).
//   Each slot stores a full GameState JSON string plus metadata
//   (slot name, last-saved timestamp, building count, population).
//   The active slot index is also persisted so the game resumes
//   on the correct slot after a browser refresh.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/building_type.dart';

const int kNumSlots = 3;
const String _kActiveSlotKey = 'city_builder_active_slot';
String _slotKey(int slot) => 'city_builder_save_v2_slot$slot';
String _slotMetaKey(int slot) => 'city_builder_meta_v2_slot$slot';

/// Lightweight metadata displayed on the slot picker screen.
class SaveSlotMeta {
  final int slot;
  final String name;
  final DateTime? lastSaved;
  final int buildingCount;
  final int population;
  final bool isEmpty;

  const SaveSlotMeta({
    required this.slot,
    required this.name,
    required this.isEmpty,
    this.lastSaved,
    this.buildingCount = 0,
    this.population = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastSaved': lastSaved?.millisecondsSinceEpoch,
        'buildingCount': buildingCount,
        'population': population,
      };

  factory SaveSlotMeta.empty(int slot) => SaveSlotMeta(
        slot: slot,
        name: 'City ${slot + 1}',
        isEmpty: true,
      );

  factory SaveSlotMeta.fromJson(int slot, Map<String, dynamic> json) =>
      SaveSlotMeta(
        slot: slot,
        name: json['name'] as String? ?? 'City ${slot + 1}',
        lastSaved: json['lastSaved'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastSaved'] as int)
            : null,
        buildingCount: json['buildingCount'] as int? ?? 0,
        population: json['population'] as int? ?? 0,
        isEmpty: false,
      );
}

class SaveService {
  SaveService._();

  // ── Active slot ────────────────────────────────────────────

  /// Returns the currently active slot index (defaults to 0).
  static Future<int> getActiveSlot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kActiveSlotKey) ?? 0;
  }

  /// Persists the active slot index.
  static Future<void> setActiveSlot(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kActiveSlotKey, slot.clamp(0, kNumSlots - 1));
  }

  // ── Save / Load ────────────────────────────────────────────

  /// Saves [state] to [slot], also writing updated metadata.
  static Future<bool> save(GameState state, {int? slot}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetSlot = slot ?? await getActiveSlot();

      // Write game state.
      await prefs.setString(_slotKey(targetSlot), state.toJsonString());

      // Write metadata.
      final buildingCount =
          state.tiles.where((t) => t.building != BuildingType.empty).length;
      final meta = SaveSlotMeta(
        slot: targetSlot,
        name: 'City ${targetSlot + 1}',
        lastSaved: DateTime.now(),
        buildingCount: buildingCount,
        population: state.resources.population,
        isEmpty: false,
      );
      await prefs.setString(
          _slotMetaKey(targetSlot), jsonEncode(meta.toJson()));
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[SaveService] save error: $e');
      return false;
    }
  }

  /// Loads a [GameState] from [slot]. Returns null if empty or corrupt.
  static Future<GameState?> load({int? slot}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetSlot = slot ?? await getActiveSlot();
      final raw = prefs.getString(_slotKey(targetSlot));
      if (raw == null) return null;
      return GameState.fromJsonString(raw);
    } catch (e) {
      // ignore: avoid_print
      print('[SaveService] load error: $e');
      return null;
    }
  }

  /// Deletes the save data for [slot].
  static Future<void> clear({int? slot}) async {
    final prefs = await SharedPreferences.getInstance();
    final targetSlot = slot ?? await getActiveSlot();
    await prefs.remove(_slotKey(targetSlot));
    await prefs.remove(_slotMetaKey(targetSlot));
  }

  // ── Slot metadata ──────────────────────────────────────────

  /// Returns metadata for all 3 slots (empty slots return placeholder meta).
  static Future<List<SaveSlotMeta>> loadAllMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <SaveSlotMeta>[];
    for (int i = 0; i < kNumSlots; i++) {
      final raw = prefs.getString(_slotMetaKey(i));
      if (raw == null) {
        result.add(SaveSlotMeta.empty(i));
      } else {
        try {
          result.add(SaveSlotMeta.fromJson(
              i, jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {
          result.add(SaveSlotMeta.empty(i));
        }
      }
    }
    return result;
  }

  /// Renames a save slot.
  static Future<void> renameSlot(int slot, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_slotMetaKey(slot));
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map['name'] = newName;
      await prefs.setString(_slotMetaKey(slot), jsonEncode(map));
    } catch (_) {}
  }
}
