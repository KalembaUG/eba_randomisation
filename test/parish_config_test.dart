import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:test/test.dart';

import 'helpers/test_parishes.dart';

void main() {
  group('ParishConfig', () {
    test('key is district_subcounty_parish', () {
      expect(TestParishes.igombe.key, 'BUGWERI_IGOMBE_IGOMBE');
    });

    test('totalCapacity for auto parish ≈ limit × 5/3', () {
      // limit=110 → totalCapacity = 110 + (110÷3)×2 = 110 + 72 = 182
      expect(TestParishes.igombe.totalCapacity, 110 + (110 ~/ 3) * 2);
    });

    test('totalCapacity for non-auto parish equals limit', () {
      expect(
        TestParishes.bulunguli.totalCapacity,
        TestParishes.bulunguli.limit,
      );
    });
  });

  group('ParishConfigTargets', () {
    test('phase1TreatmentTarget = floor(limit × 0.8451)', () {
      expect(ParishConfigTargets.phase1TreatmentTarget(90), 76);
      expect(ParishConfigTargets.phase1TreatmentTarget(110), 92);
      expect(ParishConfigTargets.phase1TreatmentTarget(18), 15);
    });

    test('phase1ControlTarget = floor(limit × 0.1549)', () {
      expect(ParishConfigTargets.phase1ControlTarget(90), 13);
      expect(ParishConfigTargets.phase1ControlTarget(110), 17);
      expect(ParishConfigTargets.phase1ControlTarget(18), 2);
    });

    test('phase2WaitingTarget = floor(limit / 3)', () {
      expect(ParishConfigTargets.phase2WaitingTarget(90), 30);
    });

    test('phase2ControlTarget = floor(limit / 3)', () {
      expect(ParishConfigTargets.phase2ControlTarget(90), 30);
    });
  });

  group('ParishConfigList extensions', () {
    const parishes = [
      TestParishes.igombe,
      TestParishes.isegeroNabukalu,
      ParishConfig(
        parish: 'ISEGERO',
        subcounty: 'NANKOMA',
        district: 'BUGIRI',
        limit: 196,
      ),
      TestParishes.bulunguli,
    ];

    test('findConfig returns correct parish when exact match', () {
      final config = parishes.findConfig('IGOMBE', 'IGOMBE');
      expect(config, isNotNull);
      expect(config!.limit, 110);
    });

    test('findConfig distinguishes ISEGERO/NABUKALU from ISEGERO/NANKOMA', () {
      final nabukalu = parishes.findConfig('ISEGERO', 'NABUKALU');
      final nankoma = parishes.findConfig('ISEGERO', 'NANKOMA');
      expect(nabukalu?.isAutoRandomisation, isTrue);
      expect(nankoma?.isAutoRandomisation, isFalse);
      expect(nabukalu?.limit, 192);
      expect(nankoma?.limit, 196);
    });

    test('findConfig is case-insensitive', () {
      expect(parishes.findConfig('igombe', 'igombe'), isNotNull);
      expect(parishes.findConfig('IGOMBE', 'igombe'), isNotNull);
    });

    test('findConfig returns null for unknown parish', () {
      expect(parishes.findConfig('UNKNOWN', 'UNKNOWN'), isNull);
    });

    test('isAutoRandomisation returns true for auto-randomisation parish', () {
      expect(parishes.isAutoRandomisation('IGOMBE', 'IGOMBE'), isTrue);
    });

    test('isAutoRandomisation returns false for non-auto parish', () {
      expect(parishes.isAutoRandomisation('BULUNGULI', 'BULIDHA'), isFalse);
    });
  });

  group('EbaParishes', () {
    test('all contains 36 parishes', () {
      expect(EbaParishes.all.length, 36);
    });

    test('autoRandomisation contains exactly 4 parishes', () {
      expect(EbaParishes.autoRandomisation.length, 4);
    });

    test('auto parishes are IGOMBE, KIKUNYU, ISEGERO/NABUKALU, NSONO', () {
      final autoKeys = EbaParishes.autoRandomisation.map((c) => c.key).toSet();
      expect(autoKeys, {
        'BUGWERI_IGOMBE_IGOMBE',
        'BUGWERI_IGOMBE_KIKUNYU',
        'BUGIRI_NABUKALU_ISEGERO',
        'BUGIRI_NANKOMA_NSONO',
      });
    });
  });
}
