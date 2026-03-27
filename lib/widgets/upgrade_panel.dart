// ============================================================
// upgrade_panel.dart  (redesigned)
// Modern slide-up panel shown when the player taps an occupied
// tile. Uses the AppColors/AppText/AppRadius design system.
//
// Displays:
//   • Building name, current level name, and production stats
//   • 3-step level progress dots
//   • Upgrade button with cost badges (green = met, red = not)
//   • Demolish button
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building_type.dart';
import '../models/tile.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

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

    // Accent color per building type
    final accent = _accentFor(type);

    final bool canUpgrade = currentLevel < max;
    final nextCfg = canUpgrade ? levelConfig(type, currentLevel + 1) : null;

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accent top stripe
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.0), accent, accent.withOpacity(0.0)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────
                Row(
                  children: [
                    // Emoji in a rounded container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(
                            color: accent.withOpacity(0.4), width: 1),
                      ),
                      child: Center(
                        child: Text(currentCfg.emoji,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Name + stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$buildingName  ·  ${currentCfg.levelName}',
                            style: AppText.headingSmall
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statsLine(currentCfg),
                            style: AppText.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            '🔧 ${currentCfg.upkeepPerTick}💰/tick upkeep',
                            style: AppText.caption
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    GestureDetector(
                      onTap: () =>
                          provider.selectBuilding(provider.selectedBuilding),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.cardRadius,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Level progress dots ───────────────────────
                _LevelDots(
                    currentLevel: currentLevel,
                    maxLevel: max,
                    accent: accent),

                const SizedBox(height: AppSpacing.sm),

                // ── Action buttons ────────────────────────────
                Row(
                  children: [
                    if (canUpgrade)
                      Expanded(
                        child: _UpgradeButton(
                          nextCfg: nextCfg!,
                          accent: accent,
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.10),
                            borderRadius: AppRadius.cardRadius,
                            border: Border.all(
                                color: accent.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: accent),
                              const SizedBox(width: 6),
                              Text(
                                'Max Level',
                                style: AppText.labelBold
                                    .copyWith(color: accent),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(width: AppSpacing.sm),

                    // Demolish button
                    _DemolishButton(
                      onTap: () =>
                          provider.demolishTile(tile.row, tile.col),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFor(BuildingType type) {
    switch (type) {
      case BuildingType.house:       return AppColors.house;
      case BuildingType.farm:        return AppColors.farm;
      case BuildingType.powerPlant:  return AppColors.powerPlant;
      case BuildingType.market:      return AppColors.market;
      case BuildingType.barracks:    return AppColors.barracks;
      case BuildingType.researchLab: return AppColors.researchLab;
      default:                       return AppColors.selected;
    }
  }

  String _statsLine(BuildingLevelConfig cfg) {
    final parts = <String>[];
    if (cfg.foodPerTick > 0) parts.add('+${cfg.foodPerTick}🌾/tick');
    if (cfg.powerPerTick > 0) parts.add('+${cfg.powerPerTick}⚡/tick');
    if (cfg.populationPerTick > 0) parts.add('+${cfg.populationPerTick}👥/tick');
    if (cfg.creditsPerTick > 0) parts.add('+${cfg.creditsPerTick}💰/tick');
    return parts.isEmpty ? 'No production' : parts.join('  ');
  }
}

// ── Level progress dots ────────────────────────────────────────

class _LevelDots extends StatelessWidget {
  final int currentLevel;
  final int maxLevel;
  final Color accent;

  const _LevelDots({
    required this.currentLevel,
    required this.maxLevel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxLevel + 1, (i) {
        final active = i <= currentLevel;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 6,
            decoration: BoxDecoration(
              color: active ? accent : AppColors.border,
              borderRadius: AppRadius.pillRadius,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 0,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ── Upgrade button ─────────────────────────────────────────────

class _UpgradeButton extends StatefulWidget {
  final BuildingLevelConfig nextCfg;
  final Color accent;
  final bool enabled;
  final bool meetsPopulation;
  final bool meetsCredits;
  final bool meetsFood;
  final bool meetsPower;
  final VoidCallback onTap;

  const _UpgradeButton({
    required this.nextCfg,
    required this.accent,
    required this.enabled,
    required this.meetsPopulation,
    required this.meetsCredits,
    required this.meetsFood,
    required this.meetsPower,
    required this.onTap,
  });

  @override
  State<_UpgradeButton> createState() => _UpgradeButtonState();
}

class _UpgradeButtonState extends State<_UpgradeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final enabled = widget.enabled;

    return GestureDetector(
      onTapDown: enabled ? (_) => _ctrl.forward() : null,
      onTapUp: enabled
          ? (_) {
              _ctrl.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: enabled
                ? accent.withOpacity(0.18)
                : AppColors.surfaceLight,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: enabled ? accent : AppColors.border,
              width: enabled ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.nextCfg.emoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Upgrade → ${widget.nextCfg.levelName}',
                    style: AppText.labelBold.copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _ReqBadge(
                      label: '💰 ${widget.nextCfg.creditCost}',
                      met: widget.meetsCredits),
                  if (widget.nextCfg.foodCost > 0)
                    _ReqBadge(
                        label: '🌾 ${widget.nextCfg.foodCost}',
                        met: widget.meetsFood),
                  if (widget.nextCfg.powerCost > 0)
                    _ReqBadge(
                        label: '⚡ ${widget.nextCfg.powerCost}',
                        met: widget.meetsPower),
                  if (widget.nextCfg.populationRequired > 0)
                    _ReqBadge(
                        label: '👥 ≥${widget.nextCfg.populationRequired}',
                        met: widget.meetsPopulation),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demolish button ────────────────────────────────────────────

class _DemolishButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DemolishButton({required this.onTap});

  @override
  State<_DemolishButton> createState() => _DemolishButtonState();
}

class _DemolishButtonState extends State<_DemolishButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.12),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
                color: AppColors.danger.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline,
                  size: 14, color: AppColors.danger),
              const SizedBox(width: 4),
              Text(
                'Demolish',
                style: AppText.labelBold
                    .copyWith(color: AppColors.danger, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Requirement badge ──────────────────────────────────────────

class _ReqBadge extends StatelessWidget {
  final String label;
  final bool met;
  const _ReqBadge({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.food : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
