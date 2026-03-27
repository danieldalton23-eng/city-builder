// ============================================================
// building_selector.dart  (redesigned)
// Bottom build panel — horizontal-scrolling cards for each
// building type, grouped into Tier 1 and Tier 2 tabs.
//
// Each card shows:
//   • Large emoji icon
//   • Building name
//   • Placement costs (credits + optional food/power)
//   • Lock indicator for Tier-2 buildings not yet unlocked
//   • Scale-down animation on tap
//   • Selected state with accent border + background tint
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building_type.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

// Tier-1 and Tier-2 building lists (excluding 'empty')
const _tier1 = [
  BuildingType.house,
  BuildingType.farm,
  BuildingType.powerPlant,
];

const _tier2 = [
  BuildingType.market,
  BuildingType.barracks,
  BuildingType.researchLab,
];

class BuildingSelector extends StatelessWidget {
  const BuildingSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    // Hide when a tile is selected (upgrade panel takes over)
    if (provider.selectedTile != null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Tab bar ──────────────────────────────────────
            const TabBar(
              indicatorColor: AppColors.selected,
              indicatorWeight: 2,
              labelColor: AppColors.selected,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'TIER 1'),
                Tab(text: 'TIER 2  ⭐'),
              ],
            ),

            // ── Building card rows ────────────────────────────
            SizedBox(
              height: 108,
              child: TabBarView(
                children: [
                  _BuildingRow(buildings: _tier1, provider: provider),
                  _BuildingRow(buildings: _tier2, provider: provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal scrolling row of building cards ─────────────────

class _BuildingRow extends StatelessWidget {
  final List<BuildingType> buildings;
  final GameProvider provider;

  const _BuildingRow({required this.buildings, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: buildings.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (_, i) {
        final type = buildings[i];
        final lvl0 = levelConfig(type, 0);
        final r = provider.resources;
        final canAfford = r.credits >= lvl0.creditCost &&
            r.food >= lvl0.foodCost &&
            r.power >= lvl0.powerCost;

        return _BuildCard(
          type: type,
          isSelected: provider.selectedBuilding == type,
          isLocked: !provider.isTierUnlocked(type),
          canAfford: canAfford,
          onTap: () => provider.selectBuilding(type),
        );
      },
    );
  }
}

// ── Individual build card ──────────────────────────────────────

class _BuildCard extends StatefulWidget {
  final BuildingType type;
  final bool isSelected;
  final bool isLocked;
  final bool canAfford;
  final VoidCallback onTap;

  const _BuildCard({
    required this.type,
    required this.isSelected,
    required this.isLocked,
    required this.canAfford,
    required this.onTap,
  });

  @override
  State<_BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<_BuildCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
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

  Color get _accentColor {
    switch (widget.type) {
      case BuildingType.house:       return AppColors.house;
      case BuildingType.farm:        return AppColors.farm;
      case BuildingType.powerPlant:  return AppColors.powerPlant;
      case BuildingType.market:      return AppColors.market;
      case BuildingType.barracks:    return AppColors.barracks;
      case BuildingType.researchLab: return AppColors.researchLab;
      default:                       return AppColors.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = buildingConfigs[widget.type]!;
    final lvl0 = levelConfig(widget.type, 0);
    final isSelected = widget.isSelected;
    final isLocked = widget.isLocked;
    final canAfford = widget.canAfford && !isLocked;
    final accent = _accentColor;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!isLocked) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 90,
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(0.18)
                : AppColors.surfaceLight,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isSelected
                  ? accent
                  : canAfford
                      ? AppColors.border
                      : AppColors.border.withOpacity(0.4),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected ? AppShadows.elevated : AppShadows.subtle,
          ),
          child: Opacity(
            opacity: isLocked ? 0.45 : (canAfford ? 1.0 : 0.65),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji icon
                  Text(lvl0.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),

                  // Building name
                  Text(
                    cfg.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Cost chips or lock indicator
                  if (!isLocked)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 2,
                      runSpacing: 2,
                      children: [
                        _CostChip(
                            label: '${lvl0.creditCost}💰',
                            color: AppColors.credits),
                        if (lvl0.foodCost > 0)
                          _CostChip(
                              label: '${lvl0.foodCost}🌾',
                              color: AppColors.food),
                        if (lvl0.powerCost > 0)
                          _CostChip(
                              label: '${lvl0.powerCost}⚡',
                              color: AppColors.power),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 10, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        const Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small cost chip ────────────────────────────────────────────

class _CostChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CostChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
