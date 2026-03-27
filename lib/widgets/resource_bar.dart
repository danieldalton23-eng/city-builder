// ============================================================
// resource_bar.dart  (redesigned)
// Modern resource bar with rounded cards, colored fill bars,
// emoji icons, and smooth animated number transitions.
// ============================================================

import 'package:flutter/material.dart';
import '../models/resources.dart';
import '../theme/app_theme.dart';

class ResourceBar extends StatelessWidget {
  final Resources resources;
  const ResourceBar({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          _ResourceCard(
            icon: '💰',
            label: 'CREDITS',
            value: resources.credits,
            color: AppColors.credits,
            fillFraction: (resources.credits / 500).clamp(0.0, 1.0),
            isCrisis: false,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ResourceCard(
            icon: '🌾',
            label: 'FOOD',
            value: resources.food,
            color: AppColors.food,
            fillFraction: (resources.food / kFoodCap).clamp(0.0, 1.0),
            isCrisis: resources.isFoodCrisis,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ResourceCard(
            icon: '⚡',
            label: 'POWER',
            value: resources.power,
            color: AppColors.power,
            fillFraction: (resources.power / kPowerCap).clamp(0.0, 1.0),
            isCrisis: resources.isPowerCrisis,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ResourceCard(
            icon: '👥',
            label: 'POP',
            value: resources.population,
            color: AppColors.population,
            fillFraction: (resources.population / 200).clamp(0.0, 1.0),
            isCrisis: false,
          ),
        ],
      ),
    );
  }
}

// ── Individual resource card ───────────────────────────────────

class _ResourceCard extends StatelessWidget {
  final String icon;
  final String label;
  final int value;
  final Color color;
  final double fillFraction;
  final bool isCrisis;

  const _ResourceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.fillFraction,
    required this.isCrisis,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isCrisis ? AppColors.danger : color;
    final borderColor =
        isCrisis ? AppColors.danger.withOpacity(0.6) : Colors.transparent;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + animated value
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Expanded(
                  child: _AnimatedCounter(
                    value: value,
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Label
            Text(label, style: AppText.resourceLabel),
            const SizedBox(height: 5),
            // Progress bar track + fill
            LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 3,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: 3,
                    width: constraints.maxWidth * fillFraction.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: isCrisis
                          ? AppColors.danger
                          : (fillFraction >= 0.9
                              ? AppColors.warning
                              : effectiveColor),
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Animated number counter ────────────────────────────────────

class _AnimatedCounter extends StatefulWidget {
  final int value;
  final Color color;
  const _AnimatedCounter({required this.value, required this.color});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late int _displayed;
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _target = 0;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.value;
    _target = widget.value;
    _from = widget.value;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _anim.addListener(() {
      setState(() {
        _displayed = (_from + (_target - _from) * _anim.value).round();
      });
    });
  }

  @override
  void didUpdateWidget(_AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _displayed;
      _target = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed.toString(),
      style: AppText.resourceNumber.copyWith(color: widget.color),
      overflow: TextOverflow.ellipsis,
    );
  }
}
