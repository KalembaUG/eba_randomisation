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

    test(
      'first 71 female candidates produce exactly 60 Treatment and 11 Control',
      () async {
        final assignments = <String>[];
        for (var i = 0; i < 71; i++) {
          final c = TestParishes.eligibleFemale();
          await engine.processEnrollment(c);
          assignments.add(c.groupAssignment!);
        }
        expect(assignments.where((a) => a == 'Treatment').length, 60);
        expect(assignments.where((a) => a == 'Control').length, 11);
      },
    );

    test(
      'first 71 male candidates produce exactly 60 Treatment and 11 Control',
      () async {
        final assignments = <String>[];
        for (var i = 0; i < 71; i++) {
          final c = TestParishes.eligibleMale();
          await engine.processEnrollment(c);
          assignments.add(c.groupAssignment!);
        }
        expect(assignments.where((a) => a == 'Treatment').length, 60);
        expect(assignments.where((a) => a == 'Control').length, 11);
      },
    );

    test(
      'over 71 female assignments ratio is exactly 60:11 Treatment:Control',
      () async {
        // Use a large limit so Phase 1 never completes within 71 iterations.
        // genderLimit = round(10000 × 0.6) = 6000; Phase1 Treatment target = 5070.
        final bigStore = InMemoryRandomisationStore();
        bigStore.setParishLimit('IGOMBE', 'IGOMBE', 10000);
        final bigEngine = RandomisationEngine(
          parishes: TestParishes.igombeOnly,
          store: bigStore,
          random: Random(42),
        );

        final assignments = <String>[];
        for (var i = 0; i < 71; i++) {
          final c = TestParishes.eligibleFemale();
          await bigEngine.processEnrollment(c);
          if (c.groupAssignment != null) {
            assignments.add(c.groupAssignment!);
            bigStore.addRecord(
              parish: 'IGOMBE',
              subcounty: 'IGOMBE',
              gender: 'Female',
              groupAssignment: c.groupAssignment,
              recruitmentPhase: 'Phase1',
            );
          }
        }
        final treatmentCount = assignments
            .where((a) => a == 'Treatment')
            .length;
        final controlCount = assignments.where((a) => a == 'Control').length;
        // 71 assignments = 1 complete block of 71 → exactly 60T + 11C
        expect(treatmentCount, 60,
            reason: 'Expected exactly 60 Treatment in one complete block');
        expect(controlCount, 11,
            reason: 'Expected exactly 11 Control in one complete block');
      },
    );

    test('female and male queues are independent', () async {
      // Use a large limit so Phase 1 never completes within 71 iterations.
      final bigStore = InMemoryRandomisationStore();
      bigStore.setParishLimit('IGOMBE', 'IGOMBE', 10000);
      final bigEngine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: bigStore,
        random: Random(42),
      );

      final femaleAssignments = <String>[];
      final maleAssignments = <String>[];

      for (var i = 0; i < 71; i++) {
        final f = TestParishes.eligibleFemale();
        await bigEngine.processEnrollment(f);
        if (f.groupAssignment != null) {
          femaleAssignments.add(f.groupAssignment!);
          bigStore.addRecord(
            parish: 'IGOMBE',
            subcounty: 'IGOMBE',
            gender: 'Female',
            groupAssignment: f.groupAssignment,
            recruitmentPhase: 'Phase1',
          );
        }

        final m = TestParishes.eligibleMale();
        await bigEngine.processEnrollment(m);
        if (m.groupAssignment != null) {
          maleAssignments.add(m.groupAssignment!);
          bigStore.addRecord(
            parish: 'IGOMBE',
            subcounty: 'IGOMBE',
            gender: 'Male',
            groupAssignment: m.groupAssignment,
            recruitmentPhase: 'Phase1',
          );
        }
      }

      // Each gender draws from its own independent block of 71 → 60T + 11C each
      expect(femaleAssignments.where((a) => a == 'Treatment').length, 60);
      expect(maleAssignments.where((a) => a == 'Treatment').length, 60);
    });

    test('all assignments have recruitmentPhase set to Phase1', () async {
      for (var i = 0; i < 3; i++) {
        final c = TestParishes.eligibleFemale();
        await engine.processEnrollment(c);
        expect(c.recruitmentPhase, 'Phase1');
        store.addRecord(
          parish: 'IGOMBE',
          subcounty: 'IGOMBE',
          gender: 'Female',
          groupAssignment: c.groupAssignment,
          recruitmentPhase: 'Phase1',
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

    test(
      'non-auto-randomisation parish gets no assignment even when eligible',
      () async {
        final store2 = InMemoryRandomisationStore();
        final engine2 = RandomisationEngine(
          parishes: [TestParishes.bulunguli],
          store: store2,
        );
        final c = TestParishes.eligibleFemale(
          parish: 'BULUNGULI',
          subcounty: 'BULIDHA',
          district: 'BUGIRI',
        );
        await engine2.processEnrollment(c);
        expect(c.eligibilityStatus, 'Eligible');
        expect(c.groupAssignment, isNull);
      },
    );
  });

  group('Block randomisation — Phase 2', () {
    late InMemoryRandomisationStore store;
    late RandomisationEngine engine;

    setUp(() {
      store = InMemoryRandomisationStore();
      // limit=12 → female genderLimit = round(12 × 0.6) = 7
      //   p1TTarget = floor(7 × 0.8451) = 5, p1CTarget = floor(7 × 0.1549) = 1
      store.setParishLimit('IGOMBE', 'IGOMBE', 12);

      // Seed store with 5 Treatment + 1 Control for Female → Phase 1 complete
      for (var i = 0; i < 5; i++) {
        store.addRecord(
          parish: 'IGOMBE',
          subcounty: 'IGOMBE',
          gender: 'Female',
          groupAssignment: 'Treatment',
          recruitmentPhase: 'Phase1',
        );
      }
      store.addRecord(
        parish: 'IGOMBE',
        subcounty: 'IGOMBE',
        gender: 'Female',
        groupAssignment: 'Control',
        recruitmentPhase: 'Phase1',
      );

      engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(99),
      );
    });

    tearDown(() => engine.resetQueues());

    test(
      'first Phase 2 round produces exactly 1 Waiting and 1 Control',
      () async {
        final assignments = <String>[];
        for (var i = 0; i < 2; i++) {
          final c = TestParishes.eligibleFemale();
          await engine.processEnrollment(c);
          if (c.groupAssignment != null) assignments.add(c.groupAssignment!);
          if (c.groupAssignment != null) {
            store.addRecord(
              parish: 'IGOMBE',
              subcounty: 'IGOMBE',
              gender: 'Female',
              groupAssignment: c.groupAssignment,
              recruitmentPhase: 'Phase2',
            );
          }
        }
        expect(assignments.where((a) => a == 'Waiting').length, 1);
        expect(assignments.where((a) => a == 'Control').length, 1);
      },
    );

    test('Phase 2 assignments have recruitmentPhase = Phase2', () async {
      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);
      expect(c.recruitmentPhase, 'Phase2');
    });
  });
}
