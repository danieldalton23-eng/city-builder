// ============================================================
// slot_picker_screen.dart  (redesigned)
// Shown at app launch and from the in-game menu.
// Uses the AppColors / AppText / AppRadius design system.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/save_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class SlotPickerScreen extends StatefulWidget {
  const SlotPickerScreen({super.key});

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  List<SaveSlotMeta>? _slots;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final slots = await SaveService.loadAllMeta();
    if (mounted) setState(() { _slots = slots; _loading = false; });
  }

  Future<void> _selectSlot(int slot, bool isEmpty) async {
    final provider = context.read<GameProvider>();
    if (isEmpty) {
      await provider.newGameInSlot(slot);
    } else {
      await provider.loadSlot(slot);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  Future<void> _deleteSlot(int slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text('Delete Save?',
            style: AppText.heading.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'This will permanently erase City ${slot + 1}. Are you sure?',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppText.body.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: AppText.labelBold.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SaveService.clear(slot: slot);
      _loadMeta();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Hero icon ───────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.selected.withOpacity(0.12),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                    color: AppColors.selected.withOpacity(0.3), width: 1.5),
              ),
              child: const Center(
                child: Text('🏙️', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ───────────────────────────────────────
            Text(
              'CityBuilder',
              style: AppText.displayLarge.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a save slot to continue',
              style: AppText.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 40),

            // ── Slot cards ──────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.selected),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  itemCount: kNumSlots,
                  itemBuilder: (_, i) {
                    final meta = _slots![i];
                    return _SlotCard(
                      meta: meta,
                      onTap: () => _selectSlot(i, meta.isEmpty),
                      onDelete: meta.isEmpty ? null : () => _deleteSlot(i),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Slot card ──────────────────────────────────────────────────

class _SlotCard extends StatefulWidget {
  final SaveSlotMeta meta;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SlotCard({
    required this.meta,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    final meta = widget.meta;
    final lastSavedStr =
        meta.lastSaved != null ? _formatDate(meta.lastSaved!) : null;
    final accentColor =
        meta.isEmpty ? AppColors.border : AppColors.selected;

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
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: meta.isEmpty
                  ? AppColors.border
                  : AppColors.selected.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                        color: accentColor.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      meta.isEmpty ? '➕' : '🏙️',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.isEmpty
                            ? 'Empty Slot ${meta.slot + 1}'
                            : meta.name,
                        style: AppText.headingSmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      if (meta.isEmpty)
                        Text(
                          'Tap to start a new city',
                          style: AppText.caption,
                        )
                      else ...[
                        Text(
                          '🏗️ ${meta.buildingCount} buildings  ·  👥 ${meta.population} pop',
                          style: AppText.caption.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        if (lastSavedStr != null)
                          Text(
                            'Saved $lastSavedStr',
                            style: AppText.caption,
                          ),
                      ],
                    ],
                  ),
                ),

                // Delete button
                if (widget.onDelete != null)
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.10),
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.3),
                            width: 1),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
