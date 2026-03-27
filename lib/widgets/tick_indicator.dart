// ============================================================
// tick_indicator.dart
// A small animated progress bar that counts down to the next
// resource-generation tick, giving the player visual feedback.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';

/// Duration that matches the tick interval in [GameProvider].
const Duration _tickDuration = Duration(seconds: 5);

class TickIndicator extends StatefulWidget {
  const TickIndicator({super.key});

  @override
  State<TickIndicator> createState() => _TickIndicatorState();
}

class _TickIndicatorState extends State<TickIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animate from 1.0 → 0.0 over the tick duration, then repeat.
    _controller = AnimationController(
      vsync: this,
      duration: _tickDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Text(
            'Next tick: ',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => LinearProgressIndicator(
                // Progress counts down from full to empty.
                value: 1.0 - _controller.value,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF64B5F6),
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
