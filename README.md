# eba_randomisation

Pure-Dart block-randomisation engine for the **EBA youth recruitment study** (TTK-499).

---

## What this package does

When a field agent enrols a young person, this engine:

1. **Screens eligibility** — checks 6 criteria (age, income, education, interest, prior participation, business ownership).
2. **Assigns a study group** — for the 4 auto-randomisation parishes, eligible youth are allocated to Treatment, Control, or Waiting using a **block randomisation** design so the ratio stays balanced even as enrolments trickle in over weeks.

The engine runs entirely **offline** — no server call, no internet connection needed.

---

## Block randomisation design

| Phase | Round size | Possible assignments | Phase ends when |
|-------|-----------|----------------------|----------------|
| **Phase 1** | 3 | 2 × Treatment + 1 × Control (shuffled) | Treatment ≥ 67 % AND Control ≥ 33 % of gender limit |
| **Phase 2** | 2 | 1 × Waiting + 1 × Control (shuffled) | Waiting ≥ 33 % AND Phase-2 Control ≥ 33 % of gender limit |

Phases are tracked **per parish per gender** independently, so the female queue and male queue never interfere.

### Auto-randomisation parishes

| Parish | Subcounty | District | Recruitment limit |
|--------|-----------|----------|-------------------|
| IGOMBE | IGOMBE | BUGWERI | 110 |
| KIKUNYU | IGOMBE | BUGWERI | 107 |
| ISEGERO | NABUKALU | BUGIRI | 192 |
| NSONO | NANKOMA | BUGIRI | 284 |

All other 32 parishes in the study are manual-assignment — the engine screens eligibility but does not assign a group.

---

## Package structure

```
eba_randomisation/
├── lib/
│   ├── eba_randomisation.dart       ← single public import
│   └── src/
│       ├── engine/
│       │   ├── eligibility_service.dart   ← pure eligibility check
│       │   └── randomisation_engine.dart  ← main engine class
│       ├── models/
│       │   ├── enrollment_candidate.dart  ← input/output model
│       │   └── parish_config.dart         ← parish metadata + target helpers
│       ├── data/
│       │   └── eba_parishes.dart          ← all 36 study parishes
│       └── stores/
│           ├── randomisation_store.dart   ← abstract store interface
│           ├── in_memory_store.dart       ← zero-setup store for tests
│           └── sqflite_store.dart         ← SQLite store (mobile + desktop)
└── test/
    ├── helpers/
    │   └── test_parishes.dart             ← shared test fixtures
    ├── eligibility_test.dart              ← eligibility criteria tests
    ├── block_randomisation_test.dart      ← round structure + ratio tests
    ├── phase_transition_test.dart         ← phase 1→2 transition tests
    ├── parish_config_test.dart            ← parish config + target math tests
    └── sqflite_store_test.dart            ← SQLite store integration tests
```

---

## Running the tests

> **For first-time testers or non-developers, see [TESTING_GUIDE.md](TESTING_GUIDE.md) for step-by-step setup instructions.**

If you already have Dart installed:

```bash
cd eba_randomisation
dart pub get
dart test
```

Expected output:
```
00:02 +64: All tests passed!
```

---

## Using the engine in Dart/Flutter

### In a Flutter mobile app

```dart
import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

final engine = RandomisationEngine(
  parishes: EbaParishes.all,
  store: SqfliteRandomisationStore(databaseFactory),
);

final candidate = EnrollmentCandidate(
  age: 22,
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

await engine.processEnrollment(candidate);

print(candidate.eligibilityStatus); // 'Eligible'
print(candidate.groupAssignment);   // 'Treatment' | 'Control' | 'Waiting'
print(candidate.recruitmentPhase);  // 'Phase1' | 'Phase2'
```

### In a desktop Dart script or CI test

```dart
import 'package:eba_randomisation/eba_randomisation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();

  final engine = RandomisationEngine(
    parishes: EbaParishes.all,
    store: SqfliteRandomisationStore(databaseFactoryFfi),
  );

  // ... same as above
}
```

### Custom parish list (for sub-studies or pilots)

```dart
final engine = RandomisationEngine(
  parishes: [
    ParishConfig(
      parish: 'MY_PARISH',
      subcounty: 'MY_SUBCOUNTY',
      district: 'MY_DISTRICT',
      limit: 50,
      isAutoRandomisation: true,
    ),
  ],
  store: InMemoryRandomisationStore(),
);
```

### Deterministic tests with a seeded random

```dart
final engine = RandomisationEngine(
  parishes: EbaParishes.all,
  store: InMemoryRandomisationStore(),
  random: Random(42), // same seed → same sequence every run
);
```

---

## Key types

| Type | Description |
|------|-------------|
| `RandomisationEngine` | Main entry point. Call `processEnrollment(candidate)` |
| `EligibilityService` | Static helper: `checkEligibility(candidate)` returns `'Eligible'` or `'Ineligible'` |
| `EnrollmentCandidate` | Holds all fields needed for screening + receives the assignment result |
| `ParishConfig` | Parish metadata: name, subcounty, district, limit, auto-randomisation flag |
| `EbaParishes.all` | Const list of all 36 EBA study parishes |
| `RandomisationStore` | Abstract interface — implement this to connect any database |
| `InMemoryRandomisationStore` | Test double: zero-setup, fast, no file I/O |
| `SqfliteRandomisationStore` | Production store: SQLite via `sqflite_common` |

---

## Eligibility criteria

A candidate is **Eligible** only if **all six** conditions are met:

| # | Field | Rule |
|---|-------|------|
| 1 | `age` | 18 – 30 (inclusive) |
| 2 | `income` | ≤ 300,000 UGX (gross earnings last 2 weeks) |
| 3 | `educationLevel` | P5, P6, P7, S1, S2, or S3 |
| 4 | `trainingInterest` | must be `true` |
| 5 | `previousParticipation` | must **not** be `'Yes - Educate!'` |
| 6 | `ownsBusiness` | must **not** be `'Yes'` |

---

## How `EnrollmentDatabase` connects (lewis-educate app)

The existing `EnrollmentDatabase` singleton in the Flutter app implements the `RandomisationStore` interface directly, so no extra database is needed. The engine's three store calls map to existing SQL queries in the app DB:

| `RandomisationStore` method | Maps to |
|-----------------------------|---------|
| `getAssignmentCountsByParishGender` | aggregate query on `enrollments` table |
| `insertRandomisationRound` | insert into `randomisation_rounds` table |
| `getParishLimit` | lookup in `parish_limits` table |

---

## Requirements

| Tool | Minimum version |
|------|----------------|
| Dart SDK | 3.8.1 |

No Flutter, no emulator, no device — runs on any Mac, Windows, or Linux machine with Dart installed.
