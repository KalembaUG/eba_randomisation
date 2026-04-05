import '../models/enrollment_candidate.dart';

/// Pure eligibility screening — no database required.
///
/// Implements the 5 criteria from TTK-498 / TTK-499:
/// 1. Age 18–30
/// 2. Income ≤ 30,000 UGX in the last two weeks
/// 3. Education level P5–S3
/// 4. Interested in the training programme
/// 5. No previous Educate! participation
class EligibilityService {
  EligibilityService._();

  static const _eligibleEducation = {'P5', 'P6', 'P7', 'S1', 'S2', 'S3'};

  /// Returns `'Eligible'` or `'Ineligible'`.
  static String checkEligibility(EnrollmentCandidate candidate) {
    final age = candidate.age;
    final income = candidate.income;
    final education = candidate.educationLevel;
    final interested = candidate.trainingInterest;
    final previousParticipant = candidate.previousParticipation;

    if (age == null || age < 18 || age > 30) return 'Ineligible';
    if (income == null || income > 30000) return 'Ineligible';
    if (education == null || !_eligibleEducation.contains(education)) {
      return 'Ineligible';
    }
    if (interested != true) return 'Ineligible';
    if (previousParticipant == 'Yes - Educate!') return 'Ineligible';

    return 'Eligible';
  }
}
