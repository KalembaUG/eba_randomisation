/// Configuration for a single recruitment parish.
///
/// The [limit] is the Phase-1 recruitment limit (eligible youth count).
/// For auto-randomisation parishes the engine will also run a Phase 2
/// that adds Waiting and overflow Control slots on top of [limit].
///
/// [tamPercent] is this parish's share of the total TAM population
/// (used for proportional-sampling monitoring). Supply `null` for
/// non-auto parishes where TAM tracking is not required.
class ParishConfig {
  const ParishConfig({
    required this.parish,
    required this.subcounty,
    required this.district,
    required this.limit,
    this.isAutoRandomisation = false,
    this.tamPercent,
  });

  final String parish;
  final String subcounty;
  final String district;
  final int limit;
  final bool isAutoRandomisation;

  /// TAM % contribution for this parish (auto-randomisation parishes only).
  final double? tamPercent;

  /// Unique lookup key — handles duplicate parish names across subcounties.
  String get key => '${district}_${subcounty}_$parish';

  /// Total enrollment capacity (Phase 1 + Phase 2 for auto parishes).
  ///
  /// Phase 2 adds ~1× Waiting + ~1× Control on top of [limit], giving
  /// roughly 167 % of [limit] total.
  int get totalCapacity {
    if (!isAutoRandomisation) return limit;
    return limit + (limit ~/ 3) * 2;
  }

  @override
  String toString() => '$parish ($subcounty, $district)';
}

/// Phase target helpers.
///
/// Targets are computed from the *gender-specific effective limit*
/// (i.e. [limit] × gender fraction), not the raw parish limit, so that
/// each gender queue has an independently reachable threshold.
extension ParishConfigTargets on ParishConfig {
  /// Phase 1 Treatment target: ⌊limit × 2/3⌋.
  static int phase1TreatmentTarget(int limit) => (limit * 2 / 3).floor();

  /// Phase 1 Control target: ⌊limit / 3⌋.
  static int phase1ControlTarget(int limit) => (limit / 3).floor();

  /// Phase 2 Waiting target: ⌊limit / 3⌋ (equals Phase 1 Control target).
  static int phase2WaitingTarget(int limit) => (limit / 3).floor();

  /// Phase 2 additional Control target: ⌊limit / 3⌋.
  static int phase2ControlTarget(int limit) => (limit / 3).floor();
}

/// Registry helpers for a list of [ParishConfig] objects.
extension ParishConfigList on List<ParishConfig> {
  /// Find the config for [parish] + [subcounty] (case-insensitive).
  /// Returns null if not found.
  ParishConfig? findConfig(String parish, String subcounty) {
    try {
      return firstWhere(
        (c) =>
            c.parish.toUpperCase() == parish.toUpperCase() &&
            c.subcounty.toUpperCase() == subcounty.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Whether [parish] + [subcounty] is an auto-randomisation parish.
  bool isAutoRandomisation(String parish, String subcounty) =>
      findConfig(parish, subcounty)?.isAutoRandomisation ?? false;
}
