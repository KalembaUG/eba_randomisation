# Changelog

All notable changes to this package are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.1.0] — 2026-03-24

### Added
- `RandomisationEngine` — block-randomisation engine for EBA youth recruitment (TTK-499).
- `EligibilityService` — static 6-criteria eligibility screening.
- `EnrollmentCandidate` — plain-Dart input/output model.
- `ParishConfig` + `ParishConfigTargets` + `ParishConfigList` extensions.
- `EbaParishes.all` — const list of all 36 EBA study parishes.
- `RandomisationStore` — abstract store interface (3 methods).
- `InMemoryRandomisationStore` — zero-setup test double.
- `SqfliteRandomisationStore` — SQLite store via `sqflite_common`; works on mobile and desktop/CI via `sqflite_common_ffi`.
- 64 tests covering eligibility rules, block randomisation ratio, phase transitions, parish config math, and SQLite store behaviour.
- `README.md` — developer usage guide.
- `TESTING_GUIDE.md` — step-by-step non-developer testing guide.
- `CONTRIBUTING.md` — architecture notes and contribution workflow.
