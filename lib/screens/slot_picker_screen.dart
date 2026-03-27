// ============================================================
// slot_picker_screen.dart
// Shown at app launch (and from the in-game menu).
// Displays all 3 save slots with their metadata and lets the
// player load an existing city or start a new game in any slot.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/save_service.dart';
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
      // Start a fresh game in this slot.
      await provider.newGameInSlot(slot);
    } else {
      // Load existing save.
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
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete Save?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently erase City ${slot + 1}. Are you sure?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // ── Title ──────────────────────────────────────
            const Text(
              '🏙️',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            const Text(
              'CityBuilder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a save slot',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // ── Slot cards ─────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: kNumSlots,
                  itemBuilder: (_, i) {
                    final meta = _slots![i];
                    return _SlotCard(
                      meta: meta,
                      onTap: () => _selectSlot(i, meta.isEmpty),
                      onDelete: meta.isEmpty
                          ? null
                          : () => _deleteSlot(i),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Slot card widget ───────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final SaveSlotMeta meta;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SlotCard({
    required this.meta,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lastSavedStr = meta.lastSaved != null
        ? _formatDate(meta.lastSaved!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: meta.isEmpty
              ? Colors.white12
              : const Color(0xFF64B5F6).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Slot icon ──────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: meta.isEmpty
                      ? Colors.white10
                      : const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    meta.isEmpty ? '➕' : '🏙️',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Slot info ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.isEmpty
                          ? 'Empty Slot ${meta.slot + 1}'
                          : meta.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (meta.isEmpty)
                      const Text(
                        'Tap to start a new city',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12),
                      )
                    else ...[
                      Text(
                        '🏗️ ${meta.buildingCount} buildings  •  👥 ${meta.population} pop',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      if (lastSavedStr != null)
                        Text(
                          'Last saved: $lastSavedStr',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                    ],
                  ],
                ),
              ),

              // ── Delete button ──────────────────────────
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete save',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
