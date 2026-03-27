// ============================================================
// statistics_screen.dart
// Shows line charts of resource levels over time using fl_chart.
//
// Layout:
//   • Tab bar: Credits | Food | Power | Population
//   • Each tab shows a LineChart with the last N snapshots
//   • A summary card below the chart shows current value,
//     peak value, and trend (rising/falling/stable)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/game_provider.dart';
import '../models/resource_snapshot.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TabInfo('💰', 'Credits', Color(0xFFFFD700)),
    _TabInfo('🌾', 'Food', Color(0xFF8BC34A)),
    _TabInfo('⚡', 'Power', Color(0xFFFF9800)),
    _TabInfo('👥', 'Population', Color(0xFF64B5F6)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<GameProvider>().resourceHistory;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('📊 Statistics',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: _tabs
              .map((t) => Tab(text: '${t.emoji} ${t.label}'))
              .toList(),
        ),
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📈', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'No data yet.\nWait for the first resource tick.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (i) {
                return _ResourceTab(
                  history: history,
                  tabInfo: _tabs[i],
                  valueSelector: _valueSelectors[i],
                );
              }),
            ),
    );
  }

  static final List<int Function(ResourceSnapshot)> _valueSelectors = [
    (s) => s.credits,
    (s) => s.food,
    (s) => s.power,
    (s) => s.population,
  ];
}

// ── Tab info ───────────────────────────────────────────────

class _TabInfo {
  final String emoji;
  final String label;
  final Color color;
  const _TabInfo(this.emoji, this.label, this.color);
}

// ── Individual resource tab ────────────────────────────────

class _ResourceTab extends StatelessWidget {
  final List<ResourceSnapshot> history;
  final _TabInfo tabInfo;
  final int Function(ResourceSnapshot) valueSelector;

  const _ResourceTab({
    required this.history,
    required this.tabInfo,
    required this.valueSelector,
  });

  @override
  Widget build(BuildContext context) {
    final values = history.map(valueSelector).toList();
    final current = values.last;
    final peak = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    // Trend: compare last 5 ticks.
    final recentCount = values.length >= 5 ? 5 : values.length;
    final recentAvg =
        values.sublist(values.length - recentCount).reduce((a, b) => a + b) /
            recentCount;
    final prevCount = values.length >= 10 ? 5 : (values.length ~/ 2);
    final prevStart = (values.length - recentCount - prevCount).clamp(0, values.length);
    final prevEnd = (values.length - recentCount).clamp(0, values.length);
    double prevAvg = recentAvg;
    if (prevEnd > prevStart) {
      prevAvg = values.sublist(prevStart, prevEnd).reduce((a, b) => a + b) /
          (prevEnd - prevStart);
    }
    final trend = recentAvg > prevAvg + 1
        ? '📈 Rising'
        : recentAvg < prevAvg - 1
            ? '📉 Falling'
            : '➡️ Stable';

    // Build chart spots.
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i].toDouble()));
    }

    final maxY = (peak * 1.2).clamp(10.0, double.infinity);
    final minY = (min * 0.8).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Chart ──────────────────────────────────────
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white12),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, _) => Text(
                        'T${value.toInt()}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: tabInfo.color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: tabInfo.color.withOpacity(0.12),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${tabInfo.emoji} ${s.y.toInt()}',
                              TextStyle(
                                  color: tabInfo.color,
                                  fontWeight: FontWeight.bold),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Summary cards ───────────────────────────────
          Row(
            children: [
              _StatCard(label: 'Current', value: current, color: tabInfo.color),
              _StatCard(label: 'Peak', value: peak, color: Colors.amber),
              _StatCard(label: 'Min', value: min, color: Colors.redAccent),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('Trend',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(trend,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            '${history.length} data points  •  last ${history.length * 5}s of play',
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
