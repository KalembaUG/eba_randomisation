import 'dart:math';

import '../models/enrollment_candidate.dart';
import '../models/parish_config.dart';
import '../stores/randomisation_store.dart';
import 'eligibility_service.dart';

/// Block-randomisation engine for EBA youth recruitment.
///
/// ## Usage
///
/// ```dart
/// final engine = RandomisationEngine(
///   parishes: EbaParishes.all,   // or your own list
///   store: SqfliteRandomisationStore(databaseFactory),
/// );
///
/// final candidate = EnrollmentCandidate(age: 22, income: 10000, ...);
/// await engine.processEnrollment(candidate);
/// print(candidate.groupAssignment); // 'Treatment' | 'Control' | 'Waiting'
/// ```
///
/// ## Phase model
///
/// Each auto-randomisation parish tracks two phases **per gender** independently:
///
/// | Phase   | Round | Assignments             | End condition                               |
/// |---------|-------|-------------------------|---------------------------------------------|
/// | Phase 1 | 3     | 2× Treatment + 1× Control | Treatment ≥ 67 % AND Control ≥ 33 %        |
/// | Phase 2 | 2     | 1× Waiting + 1× Control  | Waiting ≥ 33 % AND Phase-2 Control ≥ 33 %  |
///
/// Phase determination reads live DB counts so the engine survives
/// process restarts correctly.
///
/// ## Deterministic tests
///
/// Pass a seeded [Random] to get reproducible results:
///
/// ```dart
/// RandomisationEngine(parishes: ..., store: ..., random: Random(42))
/// ```
class RandomisationEngine {
  RandomisationEngine({
    required List<ParishConfig> parishes,
    required RandomisationStore store,
    Random? random,
  })  : _parishes = parishes,
        _store = store,
        _random = random ?? Random();

  final List<ParishConfig> _parishes;
  final RandomisationStore _store;
  final Random _random;

  // In-memory queues survive within a single engine instance.
  // Key: "district_subcounty_parish_gender"
  final Map<String, List<String>> _phase1Queues = {};
  final Map<String, List<String>> _phase2Queues = {};

  // ── Public API ─────────────────────────────────────────────────────

  /// Process [candidate]: run eligibility screening and, for eligible
  /// youth in auto-randomisation parishes, issue a group assignment.
  ///
  /// Mutates [candidate] in place (sets [EnrollmentCandidate.eligibilityStatus],
  /// [EnrollmentCandidate.groupAssignment], [EnrollmentCandidate.recruitmentPhase])
  /// and returns the same object for convenience.
  Future<EnrollmentCandidate> processEnrollment(
    EnrollmentCandidate candidate,
  ) async {
    final status = EligibilityService.checkEligibility(candidate);
    candidate.eligibilityStatus = status;

    if (status == 'Eligible' &&
        candidate.parish != null &&
        candidate.subcounty != null &&
        candidate.gender != null) {
      final config = _parishes.findConfig(
        candidate.parish!,
        candidate.subcounty!,
      );

      if (config != null && config.isAutoRandomisation) {
        await _assignGroup(candidate, config);
      }
    }

    return candidate;
  }

  /// Reset all in-memory queues (use between tests for a clean state).
  void resetQueues() {
    _phase1Queues.clear();
    _phase2Queues.clear();
  }

  // ── Internal ───────────────────────────────────────────────────────

  Future<void> _assignGroup(
    EnrollmentCandidate candidate,
    ParishConfig config,
  ) async {
    final gender = candidate.gender!;
    final queueKey = '${config.key}_$gender';

    final counts = await _store.getAssignmentCountsByParishGender(
      candidate.parish!,
      candidate.subcounty!,
      gender,
    );
    final treatmentCount = counts['treatment'] ?? 0;
    final controlCount = counts['control'] ?? 0;
    final waitingCount = counts['waiting'] ?? 0;
    final phase2ControlCount = counts['phase2_control'] ?? 0;

    // Phase targets are calculated against the gender-specific effective
    // limit to keep thresholds reachable for each gender queue
    // independently (60 % female / 40 % male split).
    final genderFraction = gender.toLowerCase() == 'female' ? 0.6 : 0.4;
    final syncedLimit = await _store.getParishLimit(
      candidate.parish!,
      candidate.subcounty!,
    );
    final effectiveLimit = syncedLimit ?? config.limit;
    final genderLimit = (effectiveLimit * genderFraction).round();

    final p1TTarget = ParishConfigTargets.phase1TreatmentTarget(genderLimit);
    final p1CTarget = ParishConfigTargets.phase1ControlTarget(genderLimit);
    final p2WTarget = ParishConfigTargets.phase2WaitingTarget(genderLimit);
    final p2CTarget = ParishConfigTargets.phase2ControlTarget(genderLimit);

    final phase1Complete =
        treatmentCount >= p1TTarget && controlCount >= p1CTarget;

    if (!phase1Complete) {
      candidate.groupAssignment = await _dequeuePhase1(queueKey);
      candidate.recruitmentPhase = 'Phase1';
    } else {
      final phase2Complete =
          waitingCount >= p2WTarget && phase2ControlCount >= p2CTarget;
      if (!phase2Complete) {
        candidate.groupAssignment = await _dequeuePhase2(queueKey);
        candidate.recruitmentPhase = 'Phase2';
      }
      // Both phases complete — no assignment issued; the parish-limit
      // gate in the host application should already have blocked entry.
    }
  }

  Future<String> _dequeuePhase1(String queueKey) async {
    var queue = _phase1Queues[queueKey];
    if (queue == null || queue.isEmpty) {
      queue = _generatePhase1Round();
      _phase1Queues[queueKey] = queue;
      await _store.insertRandomisationRound(
        parishGenderKey: queueKey,
        phase: 'Phase1',
        roundOrder: List<String>.from(queue).join(','),
      );
    }
    return queue.removeAt(0);
  }

  Future<String> _dequeuePhase2(String queueKey) async {
    var queue = _phase2Queues[queueKey];
    if (queue == null || queue.isEmpty) {
      queue = _generatePhase2Round();
      _phase2Queues[queueKey] = queue;
      await _store.insertRandomisationRound(
        parishGenderKey: queueKey,
        phase: 'Phase2',
        roundOrder: List<String>.from(queue).join(','),
      );
    }
    return queue.removeAt(0);
  }

  List<String> _generatePhase1Round() {
    final round = ['Treatment', 'Treatment', 'Control'];
    round.shuffle(_random);
    return round;
  }

  List<String> _generatePhase2Round() {
    final round = ['Waiting', 'Control'];
    round.shuffle(_random);
    return round;
  }
}
