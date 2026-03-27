// ============================================================
// game_screen.dart
// Primary game screen. Assembles resource bar, city grid,
// tick indicator, building selector, and upgrade panel.
//
// New in this version:
//   • AppBar overflow menu: Statistics, Achievements, Save Slots
//   • Achievement toast overlay (pops up on unlock)
//   • Upkeep summary status line
//   • Crisis warning banners
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/building_type.dart';
import '../widgets/resource_bar.dart';
import '../widgets/city_grid.dart';
import '../widgets/building_selector.dart';
import '../widgets/upgrade_panel.dart';
import 'statistics_screen.dart';
import 'achievements_screen.dart';
import 'slot_picker_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Track the last pending achievement count to trigger toasts.
  int _lastPendingCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForAchievementToast();
  }

  void _checkForAchievementToast() {
    final provider = context.read<GameProvider>();
    if (provider.pendingAchievements.length > _lastPendingCount) {
      _lastPendingCount = provider.pendingAchievements.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAchievementToast(provider);
      });
    }
  }

  void _showAchievementToast(GameProvider provider) {
    if (provider.pendingAchievements.isEmpty) return;
    final achievement = provider.pendingAchievements.first;
    provider.consumePendingAchievement();
    _lastPendingCount =
        (_lastPendingCount - 1).clamp(0, 999);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1A237E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Text(achievement.emoji,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🏆 Achievement Unlocked!',
                    style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    achievement.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+${achievement.creditReward} 💰 credits',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    // Check for new achievements on every rebuild.
    if (provider.pendingAchievements.length > _lastPendingCount) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showAchievementToast(provider));
      _lastPendingCount = provider.pendingAchievements.length;
    }

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final r = provider.resources;
    final selectedTile = provider.selectedTile;

    // Calculate upkeep for status line.
    int totalUpkeep = 0;
    for (final tile in provider.state.tiles) {
      if (tile.building != BuildingType.empty) {
        totalUpkeep += levelConfig(tile.building, tile.level).upkeepPerTick;
      }
    }
    const int baseIncome = 5;
    final int netIncome = baseIncome - totalUpkeep;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Text(
          '🏙️ CityBuilder  •  Slot ${provider.activeSlot + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white70),
            color: const Color(0xFF1E1E2E),
            onSelected: (value) => _handleMenu(context, value, provider),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'stats',
                child: Row(children: [
                  Text('📊 ', style: TextStyle(fontSize: 16)),
                  Text('Statistics',
                      style: TextStyle(color: Colors.white)),
                ]),
              ),
              const PopupMenuItem(
                value: 'achievements',
                child: Row(children: [
                  Text('🏆 ', style: TextStyle(fontSize: 16)),
                  Text('Achievements',
                      style: TextStyle(color: Colors.white)),
                ]),
              ),
              const PopupMenuItem(
                value: 'slots',
                child: Row(children: [
                  Text('💾 ', style: TextStyle(fontSize: 16)),
                  Text('Save Slots',
                      style: TextStyle(color: Colors.white)),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'new_game',
                child: Row(children: [
                  Text('🔄 ', style: TextStyle(fontSize: 16)),
                  Text('New Game',
                      style: TextStyle(color: Colors.redAccent)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          ResourceBar(resources: r),
          _UpkeepStatusLine(
              netIncome: netIncome, totalUpkeep: totalUpkeep),

          // Crisis banners.
          if (r.isFoodCrisis)
            _CrisisBanner(
              message:
                  '🌾 FOOD SHORTAGE — Population is starving and shrinking!',
              color: Colors.red.shade900,
            ),
          if (r.isPowerCrisis)
            _CrisisBanner(
              message:
                  '⚡ POWER OUTAGE — Houses offline, population decreasing!',
              color: Colors.orange.shade900,
            ),

          // Feedback message.
          if (provider.lastMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              color: const Color(0xFF37474F),
              child: Text(
                provider.lastMessage!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),

          // City grid.
          Expanded(
            child: Container(
              color: const Color(0xFF263238),
              child: const Center(child: CityGrid()),
            ),
          ),

          // Bottom panel: upgrade panel OR building selector.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectedTile != null
                ? UpgradePanel(
                    key: ValueKey(
                        '${selectedTile.row}_${selectedTile.col}'),
                    tile: selectedTile,
                  )
                : const BuildingSelector(key: ValueKey('selector')),
          ),
        ],
      ),
    );
  }

  void _handleMenu(
      BuildContext context, String value, GameProvider provider) {
    switch (value) {
      case 'stats':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()));
        break;
      case 'achievements':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AchievementsScreen()));
        break;
      case 'slots':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const SlotPickerScreen()));
        break;
      case 'new_game':
        _confirmNewGame(context, provider);
        break;
    }
  }

  void _confirmNewGame(BuildContext context, GameProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('New Game?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will erase your current city in this slot. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.newGame();
            },
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }
}

// ── Crisis banner ──────────────────────────────────────────

class _CrisisBanner extends StatelessWidget {
  final String message;
  final Color color;
  const _CrisisBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: color,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Upkeep status line ─────────────────────────────────────

class _UpkeepStatusLine extends StatelessWidget {
  final int netIncome;
  final int totalUpkeep;
  const _UpkeepStatusLine(
      {required this.netIncome, required this.totalUpkeep});

  @override
  Widget build(BuildContext context) {
    final isNegative = netIncome < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: const Color(0xFF0A0A18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '💰 Income: +5/tick   🔧 Upkeep: -$totalUpkeep/tick   Net: ',
            style:
                const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          Text(
            '${isNegative ? "" : "+"}$netIncome/tick',
            style: TextStyle(
              color: isNegative
                  ? Colors.red.shade300
                  : Colors.green.shade300,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
