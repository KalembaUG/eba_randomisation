import 'package:sqflite_common/sqflite.dart';

import '../stores/randomisation_store.dart';

/// SQLite-backed [RandomisationStore] using [sqflite_common].
///
/// Accepts any [DatabaseFactory] so it works on every platform:
///
/// **Mobile (Flutter app)**
/// ```dart
/// import 'package:sqflite/sqflite.dart' show databaseFactory;
///
/// final store = SqfliteRandomisationStore(databaseFactory);
/// ```
///
/// **Desktop / CI (pure Dart tests)**
/// ```dart
/// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
///
/// sqfliteFfiInit();
/// final store = SqfliteRandomisationStore(databaseFactoryFfi);
/// ```
///
/// The schema matches the host app's `EnrollmentDatabase` exactly, so a
/// store backed by the app's DB can simply implement [RandomisationStore]
/// with three delegate calls — or you can run this store against a
/// separate lightweight DB to isolate randomisation state.
class SqfliteRandomisationStore implements RandomisationStore {
  SqfliteRandomisationStore(
    this._factory, {
    this.dbName = 'eba_randomisation.db',
  });

  final DatabaseFactory _factory;
  final String dbName;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _factory.openDatabase(
      dbName,
      options: OpenDatabaseOptions(version: 1, onCreate: _createSchema),
    );
    return _db!;
  }

  Future<void> _createSchema(Database db, int version) async {
    // Minimal enrollment table — only the columns queried by the
    // randomisation engine. Matches the app's full schema so the app's
    // EnrollmentDatabase can implement RandomisationStore by delegating
    // to its existing queries.
    await db.execute('''
      CREATE TABLE enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parish TEXT,
        subcounty TEXT,
        gender TEXT,
        eligibility_status TEXT,
        group_assignment TEXT,
        recruitment_phase TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE randomisation_rounds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parish_gender_key TEXT NOT NULL,
        phase TEXT NOT NULL,
        round_order TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parish_limits (
        parish_key TEXT PRIMARY KEY,
        parish TEXT NOT NULL,
        subcounty TEXT NOT NULL,
        limit_value INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Indexes for the queries used in getAssignmentCountsByParishGender.
    await db.execute(
      'CREATE INDEX idx_enrollments_parish '
      'ON enrollments(parish, subcounty, gender, eligibility_status)',
    );
  }

  // ── RandomisationStore ─────────────────────────────────────────────

  @override
  Future<Map<String, int>> getAssignmentCountsByParishGender(
    String parish,
    String subcounty,
    String gender,
  ) async {
    final db = await _database;
    final result = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN group_assignment = 'Treatment' THEN 1 ELSE 0 END) AS treatment,
        SUM(CASE WHEN group_assignment = 'Control'   THEN 1 ELSE 0 END) AS control,
        SUM(CASE WHEN group_assignment = 'Waiting'   THEN 1 ELSE 0 END) AS waiting,
        SUM(CASE WHEN group_assignment = 'Control'
                 AND recruitment_phase = 'Phase2'   THEN 1 ELSE 0 END) AS phase2_control
      FROM enrollments
      WHERE UPPER(parish)    = ?
        AND UPPER(subcounty) = ?
        AND UPPER(gender)    = ?
        AND eligibility_status = 'Eligible'
      ''',
      [parish.toUpperCase(), subcounty.toUpperCase(), gender.toUpperCase()],
    );

    if (result.isEmpty) {
      return {'treatment': 0, 'control': 0, 'waiting': 0, 'phase2_control': 0};
    }
    final row = result.first;
    return {
      'treatment': (row['treatment'] as int?) ?? 0,
      'control': (row['control'] as int?) ?? 0,
      'waiting': (row['waiting'] as int?) ?? 0,
      'phase2_control': (row['phase2_control'] as int?) ?? 0,
    };
  }

  @override
  Future<void> insertRandomisationRound({
    required String parishGenderKey,
    required String phase,
    required String roundOrder,
  }) async {
    final db = await _database;
    await db.insert('randomisation_rounds', {
      'parish_gender_key': parishGenderKey,
      'phase': phase,
      'round_order': roundOrder,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<int?> getParishLimit(String parish, String subcounty) async {
    final db = await _database;
    final key = '${parish.toUpperCase()}_${subcounty.toUpperCase()}';
    final result = await db.query(
      'parish_limits',
      columns: ['limit_value'],
      where: 'parish_key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['limit_value'] as int?;
  }

  // ── Helpers for tests ──────────────────────────────────────────────

  /// Explicitly initialise the database (optional — the first operation
  /// will also initialise it, but calling this in setUp makes test intent
  /// clearer).
  Future<void> init() async => _database;

  /// All randomisation round audit entries (useful in tests).
  Future<List<Map<String, Object?>>> allRounds() async {
    final db = await _database;
    return db.query('randomisation_rounds', orderBy: 'id ASC');
  }

  /// Persist an enrollment record directly (use in tests to pre-seed state).
  Future<void> insertEnrollment({
    required String parish,
    required String subcounty,
    required String gender,
    String eligibilityStatus = 'Eligible',
    String? groupAssignment,
    String? recruitmentPhase,
  }) async {
    final db = await _database;
    await db.insert('enrollments', {
      'parish': parish,
      'subcounty': subcounty,
      'gender': gender,
      'eligibility_status': eligibilityStatus,
      'group_assignment': groupAssignment,
      'recruitment_phase': recruitmentPhase,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Upsert a parish limit (simulates a server-synced limit).
  Future<void> setParishLimit(
    String parish,
    String subcounty,
    int limit,
  ) async {
    final db = await _database;
    final key = '${parish.toUpperCase()}_${subcounty.toUpperCase()}';
    await db.insert('parish_limits', {
      'parish_key': key,
      'parish': parish.toUpperCase(),
      'subcounty': subcounty.toUpperCase(),
      'limit_value': limit,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Close the underlying database (call in tearDown).
  Future<void> close() async => _db?.close();

  /// Delete and recreate the database (useful for test isolation).
  Future<void> deleteAndReinit() async {
    await close();
    await _factory.deleteDatabase(dbName);
    _db = null;
  }
}
