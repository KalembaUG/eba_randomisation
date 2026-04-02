import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:test/test.dart';

void main() {
  EnrollmentCandidate candidate({
    int age = 22,
    int income = 80000,
    String educationLevel = 'S2',
    bool trainingInterest = true,
    String previousParticipation = 'No',
    String ownsBusiness = 'No',
  }) => EnrollmentCandidate(
    age: age,
    income: income,
    educationLevel: educationLevel,
    trainingInterest: trainingInterest,
    previousParticipation: previousParticipation,
    ownsBusiness: ownsBusiness,
  );

  group('EligibilityService.checkEligibility', () {
    test('eligible candidate returns Eligible', () {
      expect(EligibilityService.checkEligibility(candidate()), 'Eligible');
    });

    group('age criterion (18 – 30)', () {
      test('age 17 → Ineligible', () {
        expect(
          EligibilityService.checkEligibility(candidate(age: 17)),
          'Ineligible',
        );
      });
      test('age 18 → Eligible', () {
        expect(
          EligibilityService.checkEligibility(candidate(age: 18)),
          'Eligible',
        );
      });
      test('age 30 → Eligible', () {
        expect(
          EligibilityService.checkEligibility(candidate(age: 30)),
          'Eligible',
        );
      });
      test('age 31 → Ineligible', () {
        expect(
          EligibilityService.checkEligibility(candidate(age: 31)),
          'Ineligible',
        );
      });
    });

    group('income criterion (≤ 300 000)', () {
      test('income 300 000 → Eligible', () {
        expect(
          EligibilityService.checkEligibility(candidate(income: 300000)),
          'Eligible',
        );
      });
      test('income 300 001 → Ineligible', () {
        expect(
          EligibilityService.checkEligibility(candidate(income: 300001)),
          'Ineligible',
        );
      });
    });

    group('education level criterion', () {
      for (final level in ['P5', 'P6', 'P7', 'S1', 'S2', 'S3']) {
        test('$level → Eligible', () {
          expect(
            EligibilityService.checkEligibility(
              candidate(educationLevel: level),
            ),
            'Eligible',
          );
        });
      }
      for (final level in ['P4', 'S4', 'S5', 'S6', 'University', 'None']) {
        test('$level → Ineligible', () {
          expect(
            EligibilityService.checkEligibility(
              candidate(educationLevel: level),
            ),
            'Ineligible',
          );
        });
      }
    });

    group('training interest criterion', () {
      test('trainingInterest false → Ineligible', () {
        expect(
          EligibilityService.checkEligibility(
            candidate(trainingInterest: false),
          ),
          'Ineligible',
        );
      });
    });

    group('previous participation criterion', () {
      test('"Yes - Educate!" → Ineligible', () {
        expect(
          EligibilityService.checkEligibility(
            candidate(previousParticipation: 'Yes - Educate!'),
          ),
          'Ineligible',
        );
      });
      test('"Yes - Other" → Eligible', () {
        expect(
          EligibilityService.checkEligibility(
            candidate(previousParticipation: 'Yes - Other'),
          ),
          'Eligible',
        );
      });
      test('"No" → Eligible', () {
        expect(
          EligibilityService.checkEligibility(
            candidate(previousParticipation: 'No'),
          ),
          'Eligible',
        );
      });
    });
  });
}
