/// A slim, plain-Dart model used by [RandomisationEngine] to perform
/// eligibility screening and group allocation.
///
/// Only the fields relevant to eligibility and assignment are included.
/// The host application maps its own full enrollment model to/from this
/// class before calling [RandomisationEngine.processEnrollment].
class EnrollmentCandidate {
  EnrollmentCandidate({
    this.age,
    this.income,
    this.educationLevel,
    this.ownsBusiness,
    this.trainingInterest,
    this.previousParticipation,
    this.gender,
    this.parish,
    this.subcounty,
    this.district,
    this.eligibilityStatus,
    this.groupAssignment,
    this.recruitmentPhase,
  });

  // ── Eligibility inputs ──────────────────────────────────────
  int? age;
  int? income;

  /// Education level as a string code, e.g. 'P5', 'P6', 'P7', 'S1',
  /// 'S2', 'S3'.
  String? educationLevel;

  /// 'Yes' if currently running a business, otherwise 'No' or null.
  String? ownsBusiness;

  /// true if the youth is interested in the training programme.
  bool? trainingInterest;

  /// 'Yes - Educate!' if a previous Educate! participant, otherwise any
  /// other value or null.
  String? previousParticipation;

  // ── Location / group assignment ──────────────────────────────
  String? gender;
  String? parish;
  String? subcounty;
  String? district;

  // ── Outputs (set by RandomisationEngine) ────────────────────
  String? eligibilityStatus;
  String? groupAssignment;
  String? recruitmentPhase;
}
