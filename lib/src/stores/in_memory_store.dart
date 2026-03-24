import '../stores/randomisation_store.dart';

/// In-memory [RandomisationStore] implementation.
///
/// Holds all state in plain Dart collections — no database required.
/// Use this in unit tests and anywhere you need a zero-setup store:
///
/// ```dart
/// final store = InMemoryRandomisationStore();
/// final engine = RandomisationEngine(parishes: EbaParishes.all, store: store);
/// ```
///
/// This class is exported from the main library so consuming projects
/// can use it in their own test suites without re-implementing it.
class InMemoryRandomisationStore implements RandomisationStore {
  // Records stored as a list of attribute maps. Intentionally simple;
  // the store is only queried for aggregation, not full object reads.
  final List<_Record> _records = [];
  final List<_Round> _rounds = [];
  final Map<String, int> _parishLimits = {};

  // ── RandomisationStore ─────────────────────────────────────────────

  @override
  Future<Map<String, int>> getAssignmentCountsByParishGender(
    String parish,
    String subcounty,
    String gender,
  ) async {
    final matching = _records.where(
      (r) =>
          r.parish.toUpperCase() == parish.toUpperCase() &&
          r.subcounty.toUpperCase() == subcounty.toUpperCase() &&
          r.gender.toUpperCase() == gender.toUpperCase() &&
          r.eligibilityStatus == 'Eligible',
    );

    int treatment = 0;
    int control = 0;
    int waiting = 0;
    int phase2Control = 0;

    for (final r in matching) {
      switch (r.groupAssignment) {
        case 'Treatment':
          treatment++;
        case 'Control':
          control++;
          if (r.recruitmentPhase == 'Phase2') phase2Control++;
        case 'Waiting':
          waiting++;
      }
    }

    return {
      'treatment': treatment,
      'control': control,
      'waiting': waiting,
      'phase2_control': phase2Control,
    };
  }

  @override
  Future<void> insertRandomisationRound({
    required String parishGenderKey,
    required String phase,
    required String roundOrder,
  }) async {
    _rounds.add(_Round(
      parishGenderKey: parishGenderKey,
      phase: phase,
      roundOrder: roundOrder,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<int?> getParishLimit(String parish, String subcounty) async {
    final key = '${parish.toUpperCase()}_${subcounty.toUpperCase()}';
    return _parishLimits[key];
  }

  // ── Helpers for test setup ─────────────────────────────────────────

  /// Manually add an enrollment record (e.g. to pre-seed state for tests).
  void addRecord({
    required String parish,
    required String subcounty,
    required String gender,
    String eligibilityStatus = 'Eligible',
    String? groupAssignment,
    String? recruitmentPhase,
  }) {
    _records.add(_Record(
      parish: parish,
      subcounty: subcounty,
      gender: gender,
      eligibilityStatus: eligibilityStatus,
      groupAssignment: groupAssignment,
      recruitmentPhase: recruitmentPhase,
    ));
  }

  /// Override the synced parish limit (simulates a server-sent limit).
  void setParishLimit(String parish, String subcounty, int limit) {
    final key = '${parish.toUpperCase()}_${subcounty.toUpperCase()}';
    _parishLimits[key] = limit;
  }

  /// All randomisation round audit entries logged so far.
  List<_Round> get rounds => List.unmodifiable(_rounds);

  /// All records stored so far.
  List<_Record> get records => List.unmodifiable(_records);

  /// Reset all state (useful between tests).
  void reset() {
    _records.clear();
    _rounds.clear();
    _parishLimits.clear();
  }
}

class _Record {
  _Record({
    required this.parish,
    required this.subcounty,
    required this.gender,
    required this.eligibilityStatus,
    this.groupAssignment,
    this.recruitmentPhase,
  });

  final String parish;
  final String subcounty;
  final String gender;
  final String eligibilityStatus;
  final String? groupAssignment;
  final String? recruitmentPhase;
}

class _Round {
  _Round({
    required this.parishGenderKey,
    required this.phase,
    required this.roundOrder,
    required this.createdAt,
  });

  final String parishGenderKey;
  final String phase;
  final String roundOrder;
  final DateTime createdAt;
}
