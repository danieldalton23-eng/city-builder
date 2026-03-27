// ============================================================
// building_selector.dart
// Bottom panel showing all placeable buildings split into
// Tier 1 (always available) and Tier 2 (requires a Tier-1
// building on the map first).
//
// Tier-2 buildings show a lock icon and the requirement label
// when their dependency is not yet met.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/building_type.dart';
import '../providers/game_provider.dart';

class BuildingSelector extends StatefulWidget {
  const BuildingSelector({super.key});

  @override
  State<BuildingSelector> createState() => _BuildingSelectorState();
}

class _BuildingSelectorState extends State<BuildingSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    if (provider.selectedTile != null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tab bar ────────────────────────────────────
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF64B5F6),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: '🏗️ Tier 1'),
              Tab(text: '⭐ Tier 2'),
            ],
          ),

          // ── Tab content ────────────────────────────────
          SizedBox(
            height: 130,
            child: TabBarView(
              controller: _tabController,
              children: [
                _BuildingRow(
                    buildings: tier1Buildings, provider: provider),
                _BuildingRow(
                    buildings: tier2Buildings, provider: provider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row of building buttons ────────────────────────────────

class _BuildingRow extends StatelessWidget {
  final List<BuildingType> buildings;
  final GameProvider provider;

  const _BuildingRow(
      {required this.buildings, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buildings.map((type) {
          final baseCfg = levelConfig(type, 0);
          final meta = buildingConfigs[type]!;
          final isSelected = provider.selectedBuilding == type;
          final isUnlocked = provider.isTierUnlocked(type);
          final r = provider.resources;

          final canAfford = r.credits >= baseCfg.creditCost &&
              (baseCfg.foodCost == 0 || r.food >= baseCfg.foodCost) &&
              (baseCfg.powerCost == 0 || r.power >= baseCfg.powerCost);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _BuildingButton(
                baseCfg: baseCfg,
                meta: meta,
                type: type,
                isSelected: isSelected,
                isUnlocked: isUnlocked,
                canAfford: canAfford,
                onTap: () => provider.selectBuilding(type),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Individual building button ─────────────────────────────

class _BuildingButton extends StatelessWidget {
  final BuildingLevelConfig baseCfg;
  final BuildingConfig meta;
  final BuildingType type;
  final bool isSelected;
  final bool isUnlocked;
  final bool canAfford;
  final VoidCallback onTap;

  const _BuildingButton({
    required this.baseCfg,
    required this.meta,
    required this.type,
    required this.isSelected,
    required this.isUnlocked,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = meta.baseColor;
    final reqType = tierRequirement(type);
    final reqName =
        reqType != null ? buildingConfigs[reqType]!.name : null;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: !isUnlocked
              ? Colors.white.withOpacity(0.04)
              : isSelected
                  ? color.withOpacity(0.9)
                  : color.withOpacity(0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: !isUnlocked
                ? Colors.white12
                : isSelected
                    ? color
                    : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  baseCfg.emoji,
                  style: TextStyle(
                    fontSize: 20,
                    color: isUnlocked ? null : null,
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.lock,
                          size: 10, color: Colors.white54),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              meta.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked
                    ? (isSelected ? Colors.white : Colors.white70)
                    : Colors.white24,
                fontSize: 10,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            if (!isUnlocked && reqName != null)
              Text(
                'Needs $reqName',
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 8),
                textAlign: TextAlign.center,
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                children: [
                  _CostBadge('💰${baseCfg.creditCost}'),
                  if (baseCfg.foodCost > 0)
                    _CostBadge('🌾${baseCfg.foodCost}'),
                  if (baseCfg.powerCost > 0)
                    _CostBadge('⚡${baseCfg.powerCost}'),
                ],
              ),
            if (isUnlocked && !canAfford)
              const Text(
                'Can\'t afford',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  final String label;
  const _CostBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
