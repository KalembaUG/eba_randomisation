import 'dart:math';

import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import 'helpers/test_parishes.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late SqfliteRandomisationStore store;

  setUp(() async {
    sqfliteFfiInit();
    store = SqfliteRandomisationStore(databaseFactoryFfi, dbName: ':memory:');
  });

  tearDown(() async {
    await store.close();
  });

  group('SqfliteRandomisationStore', () {
    test(
      'getAssignmentCountsByParishGender returns zeros for empty DB',
      () async {
        final counts = await store.getAssignmentCountsByParishGender(
          'IGOMBE',
          'IGOMBE',
          'Female',
        );
        expect(counts['treatment'], 0);
        expect(counts['control'], 0);
        expect(counts['waiting'], 0);
        expect(counts['phase2_control'], 0);
      },
    );

    test('getParishLimit returns null when not set', () async {
      final limit = await store.getParishLimit('IGOMBE', 'IGOMBE');
      expect(limit, isNull);
    });

    test('setParishLimit and getParishLimit round-trip', () async {
      await store.setParishLimit('IGOMBE', 'IGOMBE', 110);
      final limit = await store.getParishLimit('IGOMBE', 'IGOMBE');
      expect(limit, 110);
    });

    test('insertEnrollment and getAssignmentCountsByParishGender', () async {
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Treatment',
        recruitmentPhase: 'Phase1',
      );
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Treatment',
        recruitmentPhase: 'Phase1',
      );
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Control',
        recruitmentPhase: 'Phase1',
      );

      final counts = await store.getAssignmentCountsByParishGender(
        'IGOMBE',
        'IGOMBE',
        'Female',
      );
      expect(counts['treatment'], 2);
      expect(counts['control'], 1);
    });

    test('counts are gender-specific', () async {
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Treatment',
        recruitmentPhase: 'Phase1',
      );
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Male',
        groupAssignment: 'Control',
        recruitmentPhase: 'Phase1',
      );

      final female = await store.getAssignmentCountsByParishGender(
        'IGOMBE',
        'IGOMBE',
        'Female',
      );
      final male = await store.getAssignmentCountsByParishGender(
        'IGOMBE',
        'IGOMBE',
        'Male',
      );

      expect(female['treatment'], 1);
      expect(female['control'], 0);
      expect(male['treatment'], 0);
      expect(male['control'], 1);
    });

    test('phase2 control counted separately from phase1 control', () async {
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Control',
        recruitmentPhase: 'Phase1',
      );
      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Control',
        recruitmentPhase: 'Phase2',
      );

      final counts = await store.getAssignmentCountsByParishGender(
        'IGOMBE',
        'IGOMBE',
        'Female',
      );
      // 'control' counts ALL Control entries (Phase1 + Phase2), while
      // 'phase2_control' counts only Phase2 Controls.
      expect(counts['control'], 2);
      expect(counts['phase2_control'], 1);
    });

    test('insertRandomisationRound stores audit record', () async {
      await store.insertRandomisationRound(
        parishGenderKey: 'BUGWERI_IGOMBE_IGOMBE_Female',
        phase: 'Phase1',
        roundOrder: 'Treatment,Control,Treatment',
      );
      final rounds = await store.allRounds();
      expect(rounds.length, 1);
      expect(rounds.first['round_order'], 'Treatment,Control,Treatment');
    });
  });

  group('Full engine cycle with SqfliteRandomisationStore', () {
    late RandomisationEngine engine;

    setUp(() async {
      await store.setParishLimit('IGOMBE', 'IGOMBE', 110);
      engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(7),
      );
    });

    test('processEnrollment assigns group and persists to DB', () async {
      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);

      expect(c.eligibilityStatus, 'Eligible');
      expect(c.groupAssignment, anyOf('Treatment', 'Control'));
      expect(c.recruitmentPhase, 'Phase1');

      await store.insertEnrollment(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: c.groupAssignment!,
        recruitmentPhase: 'Phase1',
      );

      final counts = await store.getAssignmentCountsByParishGender(
        'IGOMBE',
        'IGOMBE',
        'Female',
      );
      final total = (counts['treatment'] ?? 0) + (counts['control'] ?? 0);
      expect(total, 1);
    });

    test(
      '71 candidates produce one round with 60T+11C after persisting',
      () async {
        // Use a large limit so Phase 1 never completes within 71 iterations.
        await store.setParishLimit('IGOMBE', 'IGOMBE', 10000);
        engine = RandomisationEngine(
          parishes: TestParishes.igombeOnly,
          store: store,
          random: Random(7),
        );
        final assignments = <String>[];
        for (var i = 0; i < 71; i++) {
          final c = TestParishes.eligibleFemale();
          await engine.processEnrollment(c);
          assignments.add(c.groupAssignment!);
          await store.insertEnrollment(
            parish: 'IGOMBE',
            subcounty: 'IGOMBE',
            gender: 'Female',
            groupAssignment: c.groupAssignment!,
            recruitmentPhase: 'Phase1',
          );
        }
        expect(assignments.where((a) => a == 'Treatment').length, 60);
        expect(assignments.where((a) => a == 'Control').length, 11);

        final rounds = await store.allRounds();
        expect(rounds.length, 1);
      },
    );
  });
}
