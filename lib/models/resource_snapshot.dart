// ============================================================
// resource_snapshot.dart
// A lightweight timestamped record of all four resource values.
// One snapshot is appended to the history list every game tick.
// The StatisticsScreen reads this list to draw charts.
// ============================================================

class ResourceSnapshot {
  final DateTime timestamp;
  final int credits;
  final int food;
  final int power;
  final int population;

  const ResourceSnapshot({
    required this.timestamp,
    required this.credits,
    required this.food,
    required this.power,
    required this.population,
  });

  /// Maximum history entries to retain (prevents unbounded memory growth).
  /// At one entry per 5-second tick, 120 entries = 10 minutes of history.
  static const int maxHistory = 120;

  Map<String, dynamic> toJson() => {
        'ts': timestamp.millisecondsSinceEpoch,
        'c': credits,
        'f': food,
        'p': power,
        'pop': population,
      };

  factory ResourceSnapshot.fromJson(Map<String, dynamic> json) =>
      ResourceSnapshot(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        credits: json['c'] as int,
        food: json['f'] as int,
        power: json['p'] as int,
        population: json['pop'] as int,
      );
}
