# Contributing

Thank you for working on the EBA randomisation engine. This document covers how to make changes safely and how the package fits into the larger system.

---

## Development environment

- **Dart SDK ≥ 3.8.1** — no Flutter required
- A Dart IDE: VS Code with the [Dart extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code), or IntelliJ/Android Studio

```bash
git clone https://github.com/KalembaUG/eba_randomisation.git
cd eba_randomisation
dart pub get
dart test   # should print "+64: All tests passed!"
```

---

## Repository layout

```
lib/
  eba_randomisation.dart          ← barrel export (public API only)
  src/
    engine/
      eligibility_service.dart    ← pure-static eligibility check
      randomisation_engine.dart   ← stateful block-randomisation engine
    models/
      enrollment_candidate.dart   ← plain-Dart model (no DB, no Flutter)
      parish_config.dart          ← ParishConfig + extensions
    data/
      eba_parishes.dart           ← EbaParishes.all (36 parishes)
    stores/
      randomisation_store.dart    ← abstract interface (3 methods)
      in_memory_store.dart        ← test double
      sqflite_store.dart          ← SQLite impl (sqflite_common)
test/
  helpers/test_parishes.dart      ← shared fixtures
  eligibility_test.dart
  block_randomisation_test.dart
  phase_transition_test.dart
  parish_config_test.dart
  sqflite_store_test.dart
```

---

## Architecture decisions

### Why `sqflite_common` instead of `sqflite`?

`sqflite` depends on Flutter and cannot be used in a pure-Dart package. `sqflite_common` provides the same `DatabaseFactory` interface. In the mobile app, `sqflite`'s `databaseFactory` is passed in. In tests, `sqflite_common_ffi`'s `databaseFactoryFfi` is used — identical SQL, identical schema, no emulator needed.

### Why is the store injected rather than hardcoded?

Three reasons:
1. **Testability** — `InMemoryRandomisationStore` gives instant zero-setup tests with no file I/O.
2. **Platform independence** — any `DatabaseFactory` works.
3. **App integration** — `EnrollmentDatabase` in `lewis-educate` implements `RandomisationStore` directly, delegating to existing SQL queries without an extra database.

### Why is `RandomisationEngine` an instance, not a static class?

Static classes with mutable state are impossible to reset between tests and impossible to run in parallel (e.g. for load testing or multi-parish simulations). Instance state means each test gets its own fresh engine.

---

## Making changes

### Changing an eligibility rule

Edit `lib/src/engine/eligibility_service.dart`. Also update the corresponding tests in `test/eligibility_test.dart` and update the eligibility table in `README.md`.

### Changing a parish limit

Edit `lib/src/data/eba_parishes.dart`. The `parish_config_test.dart` test for `EbaParishes.all.length == 36` will fail if you add or remove a parish — update it accordingly. Also update the parish table in `README.md`.

### Adding a new store backend (e.g. Firestore, REST)

Create a new file in `lib/src/stores/` that `implements RandomisationStore`. The three required methods are:

```dart
Future<Map<String, int>> getAssignmentCountsByParishGender(
  String parish, String subcounty, String gender);

Future<void> insertRandomisationRound({
  required String parishGenderKey,
  required String phase,
  required String roundOrder,
});

Future<int?> getParishLimit(String parish, String subcounty);
```

Export the new class from `lib/eba_randomisation.dart`.

### Changing phase target percentages

The target math lives in `ParishConfigTargets` in `lib/src/models/parish_config.dart`. Update the four static methods there. Also update `test/parish_config_test.dart` (the target math tests) and the phase model table in `README.md`.

---

## Test guidelines

- **Always test with a seeded `Random`** when the test outcome must be deterministic:
  ```dart
  RandomisationEngine(parishes: ..., store: ..., random: Random(42))
  ```
- **Use `InMemoryRandomisationStore`** for unit tests — it is fast and requires no teardown.
- **Use `SqfliteRandomisationStore(databaseFactoryFfi, dbName: ':memory:')`** for integration tests that need to verify real SQL behaviour.
- **Call `engine.resetQueues()`** in `tearDown` when using a shared engine instance across tests.
- **Call `store.reset()`** in `tearDown` when using a shared `InMemoryRandomisationStore`.

---

## Releasing a new version

1. Update `version` in `pubspec.yaml` following [semver](https://semver.org):
   - Bug fix → patch (`0.1.0` → `0.1.1`)
   - New feature, backward-compatible → minor (`0.1.0` → `0.2.0`)
   - Breaking API change → major (`0.1.0` → `1.0.0`)
2. Update `CHANGELOG.md` (create it if it doesn't exist).
3. Run `dart test` — all tests must pass.
4. Commit and push:
   ```bash
   git add .
   git commit -m "chore: bump version to x.y.z"
   git tag vx.y.z
   git push && git push --tags
   ```

---

## Integration with lewis-educate (Flutter app)

The app references this package via a local path dependency:

```yaml
# lewis-educate/pubspec.yaml
eba_randomisation:
  path: ../eba_randomisation
```

`EnrollmentDatabase` in the app implements `RandomisationStore`, and `EligibilityService` in the app delegates all logic to `RandomisationEngine` from this package. If you change the `RandomisationStore` interface here, you must update `EnrollmentDatabase` in lewis-educate accordingly.
