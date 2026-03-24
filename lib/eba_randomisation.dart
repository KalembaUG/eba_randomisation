/// EBA youth-recruitment block-randomisation package.
///
/// ## Quick start
///
/// ```dart
/// import 'package:eba_randomisation/eba_randomisation.dart';
/// import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // desktop / CI
///
/// void main() async {
///   sqfliteFfiInit();
///   final engine = RandomisationEngine(
///     parishes: EbaParishes.all,
///     store: SqfliteRandomisationStore(databaseFactoryFfi),
///   );
///
///   final candidate = EnrollmentCandidate(
///     age: 22, income: 80000,
///     educationLevel: 'S2', trainingInterest: true,
///     previousParticipation: 'No', ownsBusiness: 'No',
///     gender: 'Female', parish: 'IGOMBE', subcounty: 'IGOMBE',
///     district: 'BUGWERI',
///   );
///
///   await engine.processEnrollment(candidate);
///   print(candidate.groupAssignment); // Treatment | Control | Waiting | null
/// }
/// ```
///
/// ## Key types
///
/// | Type | Role |
/// |------|------|
/// | [RandomisationEngine] | Orchestrates eligibility + block randomisation |
/// | [EligibilityService] | Pure static eligibility screening |
/// | [ParishConfig] | Parish metadata + phase-target helpers |
/// | [EbaParishes] | Standard 36-parish list |
/// | [RandomisationStore] | Abstract store interface |
/// | [InMemoryRandomisationStore] | Zero-setup store for unit tests |
/// | [SqfliteRandomisationStore] | SQLite store (mobile + desktop / CI) |
/// | [EnrollmentCandidate] | Candidate model (input + output) |

// Engine
export 'src/engine/eligibility_service.dart';
export 'src/engine/randomisation_engine.dart';

// Models
export 'src/models/enrollment_candidate.dart';
export 'src/models/parish_config.dart';

// Data
export 'src/data/eba_parishes.dart';

// Stores
export 'src/stores/in_memory_store.dart';
export 'src/stores/randomisation_store.dart';
export 'src/stores/sqflite_store.dart';
