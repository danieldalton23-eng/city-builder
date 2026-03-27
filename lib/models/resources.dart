// ============================================================
// resources.dart
// Holds the four core resource counters plus their caps.
// Also exposes convenience flags used by the tick engine and UI
// to detect crisis states (zero food / zero power).
// ============================================================

/// Maximum storable food and power.
/// Credits and population are uncapped.
const int kFoodCap = 200;
const int kPowerCap = 200;

class Resources {
  int credits;
  int food;
  int power;
  int population;

  Resources({
    this.credits = 100,
    this.food = 20,
    this.power = 0,
    this.population = 0,
  });

  // ── Crisis flags ───────────────────────────────────────────

  /// True when food has run out — population will shrink.
  bool get isFoodCrisis => food <= 0;

  /// True when power has run out — houses stop growing population
  /// and existing population slowly decreases.
  bool get isPowerCrisis => power <= 0;

  // ── Serialisation ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'credits': credits,
        'food': food,
        'power': power,
        'population': population,
      };

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
        credits: json['credits'] as int? ?? 100,
        food: json['food'] as int? ?? 20,
        power: json['power'] as int? ?? 0,
        population: json['population'] as int? ?? 0,
      );

  Resources copyWith({
    int? credits,
    int? food,
    int? power,
    int? population,
  }) =>
      Resources(
        credits: credits ?? this.credits,
        food: food ?? this.food,
        power: power ?? this.power,
        population: population ?? this.population,
      );

  /// Returns a copy with food and power clamped to their caps,
  /// and population / credits floored at 0.
  Resources clamped() => Resources(
        credits: credits.clamp(0, 999999),
        food: food.clamp(0, kFoodCap),
        power: power.clamp(0, kPowerCap),
        population: population.clamp(0, 999999),
      );
}
