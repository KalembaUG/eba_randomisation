import 'package:eba_randomisation/eba_randomisation.dart';

/// Pre-built [ParishConfig] objects for tests.
///
/// Any test that needs an auto-randomisation parish uses [igombe]; any test
/// that needs a non-auto parish uses [bulunguli].
abstract final class TestParishes {
  TestParishes._();

  static const ParishConfig igombe = ParishConfig(
    parish: 'IGOMBE',
    subcounty: 'IGOMBE',
    district: 'BUGWERI',
    limit: 110,
    isAutoRandomisation: true,
    tamPercent: 1.67,
  );

  static const ParishConfig kikunyu = ParishConfig(
    parish: 'KIKUNYU',
    subcounty: 'IGOMBE',
    district: 'BUGWERI',
    limit: 107,
    isAutoRandomisation: true,
    tamPercent: 1.62,
  );

  static const ParishConfig isegeroNankoma = ParishConfig(
    parish: 'ISEGERO',
    subcounty: 'NANKOMA',
    district: 'BUGIRI',
    limit: 196,
    isAutoRandomisation: true,
    tamPercent: 2.92,
  );

  static const ParishConfig nsono = ParishConfig(
    parish: 'NSONO',
    subcounty: 'NANKOMA',
    district: 'BUGIRI',
    limit: 284,
    isAutoRandomisation: true,
    tamPercent: 4.31,
  );

  static const ParishConfig bulunguli = ParishConfig(
    parish: 'BULUNGULI',
    subcounty: 'BULIDHA',
    district: 'BUGIRI',
    limit: 177,
  );

  /// Minimal one-parish list suitable for most engine tests.
  static const List<ParishConfig> igombeOnly = [igombe];

  /// All four auto-randomisation parishes.
  static const List<ParishConfig> autoOnly = [
    igombe,
    kikunyu,
    isegeroNankoma,
    nsono,
  ];

  /// Helper: create an eligible [EnrollmentCandidate] for [igombe].
  static EnrollmentCandidate eligibleFemale({
    String parish = 'IGOMBE',
    String subcounty = 'IGOMBE',
    String district = 'BUGWERI',
  }) => EnrollmentCandidate(
    age: 22,
    income: 20000,
    educationLevel: 'S2',
    trainingInterest: true,
    previousParticipation: 'No',
    ownsBusiness: 'No',
    gender: 'Female',
    parish: parish,
    subcounty: subcounty,
    district: district,
  );

  static EnrollmentCandidate eligibleMale({
    String parish = 'IGOMBE',
    String subcounty = 'IGOMBE',
    String district = 'BUGWERI',
  }) => EnrollmentCandidate(
    age: 25,
    income: 20000,
    educationLevel: 'P7',
    trainingInterest: true,
    previousParticipation: 'No',
    ownsBusiness: 'No',
    gender: 'Male',
    parish: parish,
    subcounty: subcounty,
    district: district,
  );
}
