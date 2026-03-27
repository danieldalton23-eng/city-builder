// ============================================================
// game_screen.dart  (redesigned)
// Primary game screen. Assembles resource bar, city grid,
// building selector / upgrade panel, and crisis banners.
//
// Uses the AppColors / AppText / AppRadius design system.
// Crisis banners slide in with AnimatedSize + AnimatedOpacity.
// Achievement toasts use the modern SnackBar style.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/building_type.dart';
import '../widgets/resource_bar.dart';
import '../widgets/city_grid.dart';
import '../widgets/building_selector.dart';
import '../widgets/upgrade_panel.dart';
import '../theme/app_theme.dart';
import 'statistics_screen.dart';
import 'achievements_screen.dart';
import 'slot_picker_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _lastPendingCount = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    // Fire achievement toasts on every rebuild that has new ones.
    if (provider.pendingAchievements.length > _lastPendingCount) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAchievementToast(provider));
      _lastPendingCount = provider.pendingAchievements.length;
    }

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.selected),
        ),
      );
    }

    final r = provider.resources;
    final selectedTile = provider.selectedTile;

    // Net income calculation for status line.
    int totalUpkeep = 0;
    for (final tile in provider.state.tiles) {
      if (tile.building != BuildingType.empty) {
        totalUpkeep += levelConfig(tile.building, tile.level).upkeepPerTick;
      }
    }
    const int baseIncome = 5;
    final int netIncome = baseIncome - totalUpkeep;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, provider),
      body: Column(
        children: [
          // ── Resource bar ────────────────────────────────────
          ResourceBar(resources: r),

          // ── Net income strip ────────────────────────────────
          _IncomeStrip(netIncome: netIncome, totalUpkeep: totalUpkeep),

          // ── Crisis banners (animated slide-in) ──────────────
          _AnimatedCrisisBanner(
            visible: r.isFoodCrisis,
            icon: '🌾',
            message: 'FOOD SHORTAGE — Population is starving!',
            color: AppColors.danger,
          ),
          _AnimatedCrisisBanner(
            visible: r.isPowerCrisis,
            icon: '⚡',
            message: 'POWER OUTAGE — Houses offline!',
            color: AppColors.warning,
          ),

          // ── Feedback message ────────────────────────────────
          if (provider.lastMessage != null)
            _FeedbackBanner(message: provider.lastMessage!),

          // ── City grid ───────────────────────────────────────
          Expanded(
            child: Container(
              color: AppColors.mapBackground,
              child: const Center(child: CityGrid()),
            ),
          ),

          // ── Bottom panel: upgrade OR building selector ───────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: selectedTile != null
                ? UpgradePanel(
                    key: ValueKey('${selectedTile.row}_${selectedTile.col}'),
                    tile: selectedTile,
                  )
                : const BuildingSelector(key: ValueKey('selector')),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, GameProvider provider) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleSpacing: AppSpacing.md,
      title: Row(
        children: [
          const Text('🏙️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'CityBuilder',
            style: AppText.heading.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.selected.withOpacity(0.15),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                  color: AppColors.selected.withOpacity(0.3), width: 1),
            ),
            child: Text(
              'Slot ${provider.activeSlot + 1}',
              style: AppText.caption.copyWith(color: AppColors.selected),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          color: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
              borderRadius: AppRadius.cardRadius),
          onSelected: (v) => _handleMenu(context, v, provider),
          itemBuilder: (_) => [
            _menuItem('stats', '📊', 'Statistics', AppColors.textPrimary),
            _menuItem('achievements', '🏆', 'Achievements', AppColors.textPrimary),
            _menuItem('slots', '💾', 'Save Slots', AppColors.textPrimary),
            const PopupMenuDivider(),
            _menuItem('new_game', '🔄', 'New Game', AppColors.danger),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, String emoji, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(label,
              style: AppText.body.copyWith(color: color)),
        ],
      ),
    );
  }

  // ── Achievement toast ──────────────────────────────────────

  void _showAchievementToast(GameProvider provider) {
    if (provider.pendingAchievements.isEmpty) return;
    final a = provider.pendingAchievements.first;
    provider.consumePendingAchievement();
    _lastPendingCount = (_lastPendingCount - 1).clamp(0, 999);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(
              color: AppColors.credits.withOpacity(0.4), width: 1),
        ),
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.credits.withOpacity(0.15),
                borderRadius: AppRadius.cardRadius,
              ),
              child: Center(
                child: Text(a.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🏆 Achievement Unlocked',
                    style: AppText.caption.copyWith(
                        color: AppColors.credits,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(a.title,
                      style: AppText.labelBold
                          .copyWith(color: AppColors.textPrimary)),
                  Text(
                    '+${a.creditReward} 💰 credits awarded',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu handler ───────────────────────────────────────────

  void _handleMenu(
      BuildContext context, String value, GameProvider provider) {
    switch (value) {
      case 'stats':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()));
        break;
      case 'achievements':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AchievementsScreen()));
        break;
      case 'slots':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SlotPickerScreen()));
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text('Start New Game?',
            style: AppText.heading.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'This will erase your current city in this slot. Are you sure?',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppText.body.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.newGame();
            },
            child: Text('Start Fresh',
                style: AppText.labelBold.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Income strip ───────────────────────────────────────────────

class _IncomeStrip extends StatelessWidget {
  final int netIncome;
  final int totalUpkeep;
  const _IncomeStrip({required this.netIncome, required this.totalUpkeep});

  @override
  Widget build(BuildContext context) {
    final isNegative = netIncome < 0;
    final netColor =
        isNegative ? AppColors.danger : AppColors.food;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 4),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '💰 +5/tick   🔧 -$totalUpkeep/tick   Net: ',
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
          Text(
            '${isNegative ? "" : "+"}$netIncome/tick',
            style: AppText.caption.copyWith(
              color: netColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated crisis banner ─────────────────────────────────────

class _AnimatedCrisisBanner extends StatelessWidget {
  final bool visible;
  final String icon;
  final String message;
  final Color color;

  const _AnimatedCrisisBanner({
    required this.visible,
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1.0 : 0.0,
        child: visible
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 3),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(
                      color: color.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message,
                        style: AppText.labelBold.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ── Feedback banner ────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final String message;
  const _FeedbackBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      color: AppColors.surfaceLight,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
