// ============================================================
// upgrade_panel.dart
// Slide-up panel shown when the player taps an occupied tile.
//
// Displays:
//   • Building name, current level, and current stats
//   • Upgrade button with ALL costs (credits + food + power)
//     and population requirement badges
//   • A 3-step level progress bar
//   • Demolish button
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building_type.dart';
import '../models/tile.dart';
import '../providers/game_provider.dart';

class UpgradePanel extends StatelessWidget {
  final Tile tile;

  const UpgradePanel({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    final r = context.watch<GameProvider>().resources;

    final type = tile.building;
    final currentLevel = tile.level;
    final max = maxLevel(type);
    final currentCfg = levelConfig(type, currentLevel);
    final buildingName = buildingConfigs[type]!.name;
    final baseColor = buildingConfigs[type]!.baseColor;

    final bool canUpgrade = currentLevel < max;
    final nextCfg = canUpgrade ? levelConfig(type, currentLevel + 1) : null;

    // Check each requirement individually for granular badge colours.
    final bool meetsPopulation =
        nextCfg != null && r.population >= nextCfg.populationRequired;
    final bool meetsCredits =
        nextCfg != null && r.credits >= nextCfg.creditCost;
    final bool meetsFood =
        nextCfg != null &&
        (nextCfg.foodCost == 0 || r.food >= nextCfg.foodCost);
    final bool meetsPower =
        nextCfg != null &&
        (nextCfg.powerCost == 0 || r.power >= nextCfg.powerCost);
    final bool upgradeEnabled =
        meetsPopulation && meetsCredits && meetsFood && meetsPower;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.97),
        border: Border(
          top: BorderSide(color: baseColor.withOpacity(0.6), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────
          Row(
            children: [
              Text(currentCfg.emoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$buildingName — ${currentCfg.levelName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _statsLine(currentCfg),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      '🔧 Upkeep: ${currentCfg.upkeepPerTick} 💰/tick',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white54, size: 18),
                onPressed: () =>
                    provider.selectBuilding(provider.selectedBuilding),
                tooltip: 'Close',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Level progress bar ───────────────────────────
          _LevelProgressBar(
            currentLevel: currentLevel,
            maxLevel: max,
            baseColor: baseColor,
          ),

          const SizedBox(height: 10),

          // ── Action buttons row ───────────────────────────
          Row(
            children: [
              if (canUpgrade)
                Expanded(
                  child: _UpgradeButton(
                    nextCfg: nextCfg!,
                    enabled: upgradeEnabled,
                    meetsPopulation: meetsPopulation,
                    meetsCredits: meetsCredits,
                    meetsFood: meetsFood,
                    meetsPower: meetsPower,
                    onTap: () =>
                        provider.upgradeTile(tile.row, tile.col),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '✅ Max Level Reached',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              SizedBox(
                width: 90,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: Colors.white),
                  label: const Text('Demolish',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11)),
                  onPressed: () =>
                      provider.demolishTile(tile.row, tile.col),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statsLine(BuildingLevelConfig cfg) {
    final parts = <String>[];
    if (cfg.foodPerTick > 0) parts.add('+${cfg.foodPerTick} 🌾/tick');
    if (cfg.powerPerTick > 0) parts.add('+${cfg.powerPerTick} ⚡/tick');
    if (cfg.populationPerTick > 0)
      parts.add('+${cfg.populationPerTick} 👥/tick');
    if (cfg.creditsPerTick > 0)
      parts.add('+${cfg.creditsPerTick} 💰/tick');
    return parts.isEmpty ? 'No production' : parts.join('  ');
  }
}

// ── Level progress bar ─────────────────────────────────────

class _LevelProgressBar extends StatelessWidget {
  final int currentLevel;
  final int maxLevel;
  final Color baseColor;

  const _LevelProgressBar({
    required this.currentLevel,
    required this.maxLevel,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxLevel + 1, (i) {
        final active = i <= currentLevel;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 8,
            decoration: BoxDecoration(
              color: active ? baseColor : Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ── Upgrade button ─────────────────────────────────────────

class _UpgradeButton extends StatelessWidget {
  final BuildingLevelConfig nextCfg;
  final bool enabled;
  final bool meetsPopulation;
  final bool meetsCredits;
  final bool meetsFood;
  final bool meetsPower;
  final VoidCallback onTap;

  const _UpgradeButton({
    required this.nextCfg,
    required this.enabled,
    required this.meetsPopulation,
    required this.meetsCredits,
    required this.meetsFood,
    required this.meetsPower,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF1565C0)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(0xFF42A5F5)
                : Colors.white24,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(nextCfg.emoji,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'Upgrade → ${nextCfg.levelName}',
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // All cost badges in a wrap row.
            Wrap(
              spacing: 5,
              runSpacing: 3,
              children: [
                _RequirementBadge(
                  label: '💰 ${nextCfg.creditCost}',
                  met: meetsCredits,
                ),
                if (nextCfg.foodCost > 0)
                  _RequirementBadge(
                    label: '🌾 ${nextCfg.foodCost}',
                    met: meetsFood,
                  ),
                if (nextCfg.powerCost > 0)
                  _RequirementBadge(
                    label: '⚡ ${nextCfg.powerCost}',
                    met: meetsPower,
                  ),
                if (nextCfg.populationRequired > 0)
                  _RequirementBadge(
                    label: '👥 ≥${nextCfg.populationRequired}',
                    met: meetsPopulation,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementBadge extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementBadge({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: met
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: met
              ? Colors.green.shade400
              : Colors.red.shade400,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: met ? Colors.greenAccent : Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
