// ============================================================
// resource_bar.dart
// Top status bar showing all four resource counters.
//
// New in this version:
//   • Food and Power show a fill bar indicating proximity to cap (200).
//   • Food turns red when in crisis (≤ 0).
//   • Power turns red when in crisis (≤ 0).
//   • A ⚠️ warning badge appears next to a resource in crisis.
//   • Near-cap resources turn amber to warn the player to build more.
// ============================================================

import 'package:flutter/material.dart';
import '../models/resources.dart';

class ResourceBar extends StatelessWidget {
  final Resources resources;
  const ResourceBar({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _ResourceTile(
            icon: '💰',
            label: 'Credits',
            value: resources.credits,
            isCrisis: false,
          ),
          _ResourceTile(
            icon: '🌾',
            label: 'Food',
            value: resources.food,
            cap: kFoodCap,
            isCrisis: resources.isFoodCrisis,
          ),
          _ResourceTile(
            icon: '⚡',
            label: 'Power',
            value: resources.power,
            cap: kPowerCap,
            isCrisis: resources.isPowerCrisis,
          ),
          _ResourceTile(
            icon: '👥',
            label: 'Pop',
            value: resources.population,
            isCrisis: false,
          ),
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String icon;
  final String label;
  final int value;
  final int? cap;
  final bool isCrisis;

  const _ResourceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isCrisis,
    this.cap,
  });

  @override
  Widget build(BuildContext context) {
    final fillFraction =
        cap != null ? (value / cap!).clamp(0.0, 1.0) : null;
    final isNearCap = fillFraction != null && fillFraction >= 0.9;

    // Colour logic: red in crisis, amber near cap, white otherwise.
    final textColor = isCrisis
        ? Colors.red.shade300
        : isNearCap
            ? Colors.amber
            : Colors.white;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Value row ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Text(
                cap != null ? '$value/$cap' : '$value',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (isCrisis) ...[
                const SizedBox(width: 2),
                const Text('⚠️', style: TextStyle(fontSize: 10)),
              ],
            ],
          ),

          // ── Fill bar (only for capped resources) ───────
          if (fillFraction != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fillFraction,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCrisis
                        ? Colors.red.shade400
                        : isNearCap
                            ? Colors.amber
                            : Colors.green.shade400,
                  ),
                ),
              ),
            ),
          ],

          // ── Label ──────────────────────────────────────
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
