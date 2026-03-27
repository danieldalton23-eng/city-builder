// ============================================================
// achievements_screen.dart
// Displays all achievements in a scrollable grid.
// Unlocked achievements are shown in full colour with their
// reward amount. Locked ones are greyed out with the condition.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final unlocked = provider.unlockedAchievements;
    final total = allAchievements.length;
    final unlockedCount = unlocked.length;
    final totalRewards = allAchievements
        .where((a) => unlocked.contains(a.id))
        .fold(0, (sum, a) => sum + a.creditReward);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('🏆 Achievements',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Progress header ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HeaderStat(
                        label: 'Unlocked',
                        value: '$unlockedCount / $total',
                        color: Colors.amber),
                    _HeaderStat(
                        label: 'Credits Earned',
                        value: '💰 $totalRewards',
                        color: const Color(0xFFFFD700)),
                    _HeaderStat(
                        label: 'Completion',
                        value:
                            '${(unlockedCount / total * 100).round()}%',
                        color: Colors.greenAccent),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: unlockedCount / total,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.amber),
                  ),
                ),
              ],
            ),
          ),

          // ── Achievement grid ─────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: allAchievements.length,
              itemBuilder: (_, i) {
                final achievement = allAchievements[i];
                final isUnlocked = unlocked.contains(achievement.id);
                return _AchievementCard(
                  achievement: achievement,
                  isUnlocked: isUnlocked,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header stat widget ─────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

// ── Achievement card ───────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final AchievementDefinition achievement;
  final bool isUnlocked;

  const _AchievementCard(
      {required this.achievement, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF1A237E).withOpacity(0.8)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? Colors.amber.withOpacity(0.6)
              : Colors.white12,
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 22,
                    color: isUnlocked ? null : null,
                  ),
                ),
                const Spacer(),
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      '+${achievement.creditReward}💰',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const Icon(Icons.lock_outline,
                      color: Colors.white24, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              achievement.description,
              style: TextStyle(
                color: isUnlocked ? Colors.white60 : Colors.white24,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
