/// Storage interface required by [RandomisationEngine].
///
/// The engine calls exactly three database operations. Implement this
/// interface to connect the engine to any backend:
///
/// - [InMemoryRandomisationStore]  — fast, zero-setup, for unit tests.
/// - [SqfliteRandomisationStore]  — SQLite on mobile (sqflite) and
///   desktop/CI (sqflite_common_ffi). Same SQL, same schema.
/// - Your own Firestore / REST / etc. implementation.
abstract class RandomisationStore {
  /// Returns the count of each assignment group for [parish] + [subcounty]
  /// + [gender] (case-insensitive).
  ///
  /// The map must contain the keys:
  /// - `'treatment'` — Phase 1 Treatment count
  /// - `'control'`   — total Control count (Phase 1 + Phase 2)
  /// - `'waiting'`   — Phase 2 Waiting count
  /// - `'phase2_control'` — Phase 2 Control count only
  Future<Map<String, int>> getAssignmentCountsByParishGender(
    String parish,
    String subcounty,
    String gender,
  );

  /// Appends an audit record for a newly generated randomisation round.
  ///
  /// [parishGenderKey] is the queue key (`district_subcounty_parish_gender`).
  /// [phase] is `'Phase1'` or `'Phase2'`.
  /// [roundOrder] is the comma-separated shuffled assignment list,
  /// e.g. `'Treatment,Control,Treatment'`.
  Future<void> insertRandomisationRound({
    required String parishGenderKey,
    required String phase,
    required String roundOrder,
  });

  /// Returns the server-synced parish limit for [parish] + [subcounty], or
  /// null if no synced limit exists (caller falls back to the hardcoded
  /// [ParishConfig.limit]).
  Future<int?> getParishLimit(String parish, String subcounty);
}
