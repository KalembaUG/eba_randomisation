import 'dart:math';

import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:test/test.dart';

import 'helpers/test_parishes.dart';

void main() {
  group('Block randomisation — Phase 1', () {
    late InMemoryRandomisationStore store;
    late RandomisationEngine engine;

    setUp(() {
      store = InMemoryRandomisationStore();
      store.setParishLimit('IGOMBE', 'IGOMBE', 110);
      engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(42), // seeded for reproducibility
      );
    });

    tearDown(() => engine.resetQueues());

    test('first 3 female candidates produce exactly 2 Treatment and 1 Control', () async {
      final assignments = <String>[];
      for (var i = 0; i < 3; i++) {
        final c = TestParishes.eligibleFemale();
        await engine.processEnrollment(c);
        assignments.add(c.groupAssignment!);
      }
      expect(assignments.where((a) => a == 'Treatment').length, 2);
      expect(assignments.where((a) => a == 'Control').length, 1);
    });

    test('first 3 male candidates produce exactly 2 Treatment and 1 Control', () async {
      final assignments = <String>[];
      for (var i = 0; i < 3; i++) {
        final c = TestParishes.eligibleMale();
        await engine.processEnrollment(c);
        assignments.add(c.groupAssignment!);
      }
      expect(assignments.where((a) => a == 'Treatment').length, 2);
      expect(assignments.where((a) => a == 'Control').length, 1);
    });

    test('over 300 female assignments ratio is close to 2:1 Treatment:Control', () async {
      // Use a large limit so Phase 1 never completes within 300 iterations.
      // genderLimit = round(10000 × 0.6) = 6000; Phase1 Treatment target = 4000.
      final bigStore = InMemoryRandomisationStore();
      bigStore.setParishLimit('IGOMBE', 'IGOMBE', 10000);
      final bigEngine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: bigStore,
        random: Random(42),
      );

      final assignments = <String>[];
      for (var i = 0; i < 300; i++) {
        final c = TestParishes.eligibleFemale();
        await bigEngine.processEnrollment(c);
        if (c.groupAssignment != null) {
          assignments.add(c.groupAssignment!);
          bigStore.addRecord(
            parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Female',
            groupAssignment: c.groupAssignment, recruitmentPhase: 'Phase1',
          );
        }
      }
      final treatmentCount = assignments.where((a) => a == 'Treatment').length;
      final controlCount = assignments.where((a) => a == 'Control').length;
      // 300 assignments = 100 complete blocks of 3 → exactly 200T + 100C
      expect(treatmentCount / controlCount, closeTo(2.0, 0.1),
          reason: 'Expected ~2× Treatment vs Control over 300 assignments');
    });

    test('female and male queues are independent', () async {
      final femaleAssignments = <String>[];
      final maleAssignments = <String>[];

      for (var i = 0; i < 3; i++) {
        final f = TestParishes.eligibleFemale();
        await engine.processEnrollment(f);
        if (f.groupAssignment != null) femaleAssignments.add(f.groupAssignment!);
        if (f.groupAssignment != null) {
          store.addRecord(
            parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Female',
            groupAssignment: f.groupAssignment, recruitmentPhase: 'Phase1',
          );
        }

        final m = TestParishes.eligibleMale();
        await engine.processEnrollment(m);
        if (m.groupAssignment != null) maleAssignments.add(m.groupAssignment!);
        if (m.groupAssignment != null) {
          store.addRecord(
            parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Male',
            groupAssignment: m.groupAssignment, recruitmentPhase: 'Phase1',
          );
        }
      }

      // Each gender block of 3 should independently have 2T+1C
      expect(femaleAssignments.where((a) => a == 'Treatment').length, 2);
      expect(maleAssignments.where((a) => a == 'Treatment').length, 2);
    });

    test('all assignments have recruitmentPhase set to Phase1', () async {
      for (var i = 0; i < 3; i++) {
        final c = TestParishes.eligibleFemale();
        await engine.processEnrollment(c);
        expect(c.recruitmentPhase, 'Phase1');
        store.addRecord(
          parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Female',
          groupAssignment: c.groupAssignment, recruitmentPhase: 'Phase1',
        );
      }
    });

    test('non-eligible candidate gets null groupAssignment', () async {
      final c = EnrollmentCandidate(
        age: 35, // too old
        income: 80000,
        educationLevel: 'S2',
        trainingInterest: true,
        previousParticipation: 'No',
        ownsBusiness: 'No',
        gender: 'Female',
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        district: 'BUGWERI',
      );
      await engine.processEnrollment(c);
      expect(c.eligibilityStatus, 'Ineligible');
      expect(c.groupAssignment, isNull);
    });

    test('non-auto-randomisation parish gets no assignment even when eligible', () async {
      final store2 = InMemoryRandomisationStore();
      final engine2 = RandomisationEngine(
        parishes: [TestParishes.bulunguli],
        store: store2,
      );
      final c = TestParishes.eligibleFemale(
        parish: 'BULUNGULI', subcounty: 'BULIDHA', district: 'BUGIRI',
      );
      await engine2.processEnrollment(c);
      expect(c.eligibilityStatus, 'Eligible');
      expect(c.groupAssignment, isNull);
    });
  });

  group('Block randomisation — Phase 2', () {
    late InMemoryRandomisationStore store;
    late RandomisationEngine engine;

    setUp(() {
      store = InMemoryRandomisationStore();
      // Small limit=6 so targets are testable quickly.
      // phase1Treatment ≥ floor(6×2/3)=4, phase1Control ≥ floor(6/3)=2
      store.setParishLimit('IGOMBE', 'IGOMBE', 6);

      // Female genderLimit = round(6 * 0.6) = 4
      // p1TTarget = floor(4*2/3) = 2, p1CTarget = floor(4/3) = 1
      // Seed store with 2 Treatment + 1 Control for Female → Phase 1 complete
      for (var i = 0; i < 2; i++) {
        store.addRecord(
          parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Female',
          groupAssignment: 'Treatment', recruitmentPhase: 'Phase1',
        );
      }
      store.addRecord(
        parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Female',
        groupAssignment: 'Control', recruitmentPhase: 'Phase1',
      );

      engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(99),
      );
    });

    tearDown(() => engine.resetQueues());

    test('first Phase 2 round produces exactly 1 Waiting and 1 Control', () async {
      final assignments = <String>[];
      for (var i = 0; i < 2; i++) {
        final c = TestParishes.eligibleFemale();
        await engine.processEnrollment(c);
        if (c.groupAssignment != null) assignments.add(c.groupAssignment!);
        if (c.groupAssignment != null) {
          store.addRecord(
            parish: 'IGOMBE', subcounty: 'IGOMBE', gender: 'Female',
            groupAssignment: c.groupAssignment, recruitmentPhase: 'Phase2',
          );
        }
      }
      expect(assignments.where((a) => a == 'Waiting').length, 1);
      expect(assignments.where((a) => a == 'Control').length, 1);
    });

    test('Phase 2 assignments have recruitmentPhase = Phase2', () async {
      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);
      expect(c.recruitmentPhase, 'Phase2');
    });
  });
}
