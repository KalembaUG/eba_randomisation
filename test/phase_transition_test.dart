import 'dart:math';

import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:test/test.dart';

import 'helpers/test_parishes.dart';

/// Helpers to quickly fill [store] with [n] records of a given assignment.
void _fillRecords(
  InMemoryRandomisationStore store, {
  required int n,
  required String assignment,
  required String phase,
  String parish = 'IGOMBE',
  String subcounty = 'IGOMBE',
  String gender = 'Female',
}) {
  for (var i = 0; i < n; i++) {
    store.addRecord(
      parish: parish,
      subcounty: subcounty,
      gender: gender,
      groupAssignment: assignment,
      recruitmentPhase: phase,
    );
  }
}

void main() {
  // limit=30 → genderLimit female = round(30 × 0.6) = 18
  //   Phase1: treatTarget=floor(18×2/3)=12, controlTarget=floor(18/3)=6
  //   Phase2: waitTarget=floor(18/3)=6,    p2ControlTarget=floor(18/3)=6
  const limit = 30;

  InMemoryRandomisationStore makeStore() {
    final s = InMemoryRandomisationStore();
    s.setParishLimit('IGOMBE', 'IGOMBE', limit);
    return s;
  }

  group('Phase transition', () {
    test('Phase 1 → Phase 2 when treatment and control targets are met', () async {
      final store = makeStore();
      // Fill Phase 1 Female: 12 Treatment + 6 Control → Phase 1 complete
      _fillRecords(store, n: 12, assignment: 'Treatment', phase: 'Phase1');
      _fillRecords(store, n: 6, assignment: 'Control', phase: 'Phase1');

      final engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(1),
      );

      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);

      expect(c.recruitmentPhase, 'Phase2',
          reason: 'Should be in Phase 2 when Phase 1 targets met');
      expect(
        c.groupAssignment,
        anyOf('Waiting', 'Control'),
        reason: 'Phase 2 only assigns Waiting or Control',
      );
    });

    test('Phase 1 continues when only treatment target met but not control', () async {
      final store = makeStore();
      _fillRecords(store, n: 12, assignment: 'Treatment', phase: 'Phase1');
      _fillRecords(store, n: 5, assignment: 'Control', phase: 'Phase1'); // 1 short

      final engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(2),
      );

      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);

      expect(c.recruitmentPhase, 'Phase1');
    });

    test('Phase 1 continues when only control target met but not treatment', () async {
      final store = makeStore();
      _fillRecords(store, n: 11, assignment: 'Treatment', phase: 'Phase1'); // 1 short
      _fillRecords(store, n: 6, assignment: 'Control', phase: 'Phase1');

      final engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(3),
      );

      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);

      expect(c.recruitmentPhase, 'Phase1');
    });

    test('no assignment when both phases complete', () async {
      final store = makeStore();
      // Phase 1 complete
      _fillRecords(store, n: 12, assignment: 'Treatment', phase: 'Phase1');
      _fillRecords(store, n: 6, assignment: 'Control', phase: 'Phase1');
      // Phase 2 complete
      _fillRecords(store, n: 6, assignment: 'Waiting', phase: 'Phase2');
      _fillRecords(store, n: 6, assignment: 'Control', phase: 'Phase2');

      final engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(4),
      );

      final c = TestParishes.eligibleFemale();
      await engine.processEnrollment(c);

      expect(c.eligibilityStatus, 'Eligible');
      expect(c.groupAssignment, isNull,
          reason: 'Parish full — no assignment should be issued');
      expect(c.recruitmentPhase, isNull);
    });

    test('male and female phases transition independently', () async {
      final store = makeStore();
      // genderLimit male = round(30 × 0.4) = 12
      // male Phase1 targets: treatTarget=floor(12×2/3)=8, controlTarget=floor(12/3)=4
      // Fill male Phase 1 complete
      _fillRecords(store, n: 8, assignment: 'Treatment', phase: 'Phase1', gender: 'Male');
      _fillRecords(store, n: 4, assignment: 'Control', phase: 'Phase1', gender: 'Male');
      // Female Phase 1 NOT complete (only 2 Treatment)
      _fillRecords(store, n: 2, assignment: 'Treatment', phase: 'Phase1', gender: 'Female');

      final engine = RandomisationEngine(
        parishes: TestParishes.igombeOnly,
        store: store,
        random: Random(5),
      );

      final male = TestParishes.eligibleMale();
      await engine.processEnrollment(male);
      expect(male.recruitmentPhase, 'Phase2', reason: 'Male should be in Phase 2');

      final female = TestParishes.eligibleFemale();
      await engine.processEnrollment(female);
      expect(female.recruitmentPhase, 'Phase1', reason: 'Female should still be in Phase 1');
    });
  });
}
