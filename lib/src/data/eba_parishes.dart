import '../models/parish_config.dart';

/// The standard 36 EBA study parishes with recruitment limits and
/// auto-randomisation flags, as defined in TTK-536 and TTK-499.
///
/// Pass this (or a custom subset) to [RandomisationEngine]:
///
/// ```dart
/// final engine = RandomisationEngine(
///   parishes: EbaParishes.all,
///   store: myStore,
/// );
/// ```
abstract final class EbaParishes {
  EbaParishes._();

  static const List<ParishConfig> all = [
    // ── BUGWERI > IGOMBE — auto-randomisation ─────────────────────
    ParishConfig(
      parish: 'IGOMBE',
      subcounty: 'IGOMBE',
      district: 'BUGWERI',
      limit: 110,
      isAutoRandomisation: true,
      tamPercent: 1.67,
    ),
    ParishConfig(
      parish: 'KIKUNYU',
      subcounty: 'IGOMBE',
      district: 'BUGWERI',
      limit: 107,
      isAutoRandomisation: true,
      tamPercent: 1.62,
    ),

    // ── BUGIRI > NABUKALU ────────────────────────────────────────
    ParishConfig(
      parish: 'ISEGERO',
      subcounty: 'NABUKALU',
      district: 'BUGIRI',
      limit: 192,
    ),

    // ── BUGIRI > NANKOMA — auto-randomisation ─────────────────────
    ParishConfig(
      parish: 'NSONO',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 284,
      isAutoRandomisation: true,
      tamPercent: 4.31,
    ),

    // ── BUGIRI > BUSEMBATIA TC ────────────────────────────────────
    ParishConfig(
      parish: 'BUSEMBATIA MARKET WARD',
      subcounty: 'BUSEMBATIA TC',
      district: 'BUGIRI',
      limit: 179,
    ),
    ParishConfig(
      parish: 'KAKOGE WARD',
      subcounty: 'BUSEMBATIA TC',
      district: 'BUGIRI',
      limit: 179,
    ),
    ParishConfig(
      parish: 'MAJENGO WARD',
      subcounty: 'BUSEMBATIA TC',
      district: 'BUGIRI',
      limit: 186,
    ),

    // ── BUGIRI > BULIDHA ──────────────────────────────────────────
    ParishConfig(
      parish: 'BULUNGULI',
      subcounty: 'BULIDHA',
      district: 'BUGIRI',
      limit: 177,
    ),
    ParishConfig(
      parish: 'BUMOOZI',
      subcounty: 'BULIDHA',
      district: 'BUGIRI',
      limit: 205,
    ),
    ParishConfig(
      parish: 'BUWOOYA',
      subcounty: 'BULIDHA',
      district: 'BUGIRI',
      limit: 208,
    ),
    ParishConfig(
      parish: 'BWIGULA',
      subcounty: 'BULIDHA',
      district: 'BUGIRI',
      limit: 181,
    ),
    ParishConfig(
      parish: 'KALALU',
      subcounty: 'BULIDHA',
      district: 'BUGIRI',
      limit: 104,
    ),
    ParishConfig(
      parish: 'LUBIRA',
      subcounty: 'BULIDHA',
      district: 'BUGIRI',
      limit: 97,
    ),

    // ── BUGIRI > NABUKALU (non-auto) ──────────────────────────────
    ParishConfig(
      parish: 'IDINDA',
      subcounty: 'NABUKALU',
      district: 'BUGIRI',
      limit: 191,
    ),
    ParishConfig(
      parish: 'MINANI',
      subcounty: 'NABUKALU',
      district: 'BUGIRI',
      limit: 184,
    ),
    ParishConfig(
      parish: 'NAMALEMBA',
      subcounty: 'NABUKALU',
      district: 'BUGIRI',
      limit: 202,
    ),
    ParishConfig(
      parish: 'NAMUNYUMYA',
      subcounty: 'NABUKALU',
      district: 'BUGIRI',
      limit: 177,
    ),

    // ── BUGIRI > NANKOMA (non-auto) ───────────────────────────────
    ParishConfig(
      parish: 'BUBUGO',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 106,
    ),
    ParishConfig(
      parish: 'BUPALA',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 198,
    ),
    ParishConfig(
      parish: 'BUSOGA',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 90,
    ),
    ParishConfig(
      parish: 'BUWUNGA',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 106,
    ),

    // ISEGERO also exists in NANKOMA (different from NABUKALU ISEGERO).
    // Use parish + subcounty together to disambiguate.
    // ── auto-randomisation ────────────────────────────────────────
    ParishConfig(
      parish: 'ISEGERO',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 196,
      isAutoRandomisation: true,
      tamPercent: 2.92,
    ),

    ParishConfig(
      parish: 'LUWOOKO',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 182,
    ),
    ParishConfig(
      parish: 'MAGOOLA',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 178,
    ),
    ParishConfig(
      parish: 'NAMBALE',
      subcounty: 'NANKOMA',
      district: 'BUGIRI',
      limit: 185,
    ),

    // ── BUGIRI > BUGIRI TC ────────────────────────────────────────
    ParishConfig(
      parish: 'BUGIRI A',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 195,
    ),
    ParishConfig(
      parish: 'BUGUBO',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 205,
    ),
    ParishConfig(
      parish: 'BUGUNGA',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 199,
    ),
    ParishConfig(
      parish: 'KISEITAKA',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 190,
    ),
    ParishConfig(
      parish: 'NAKAVULE',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 180,
    ),
    ParishConfig(
      parish: 'NAMUKONGE',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 301,
    ),
    ParishConfig(
      parish: 'NDIFAKULYA',
      subcounty: 'BUGIRI TC',
      district: 'BUGIRI',
      limit: 276,
    ),

    // ── BUGIRI > KAPYANGA ─────────────────────────────────────────
    ParishConfig(
      parish: 'BUTYABULE',
      subcounty: 'KAPYANGA',
      district: 'BUGIRI',
      limit: 280,
    ),
    ParishConfig(
      parish: 'LWANIKA',
      subcounty: 'KAPYANGA',
      district: 'BUGIRI',
      limit: 182,
    ),
    ParishConfig(
      parish: 'NKAIZA',
      subcounty: 'KAPYANGA',
      district: 'BUGIRI',
      limit: 100,
    ),
    ParishConfig(
      parish: 'WANGOBO',
      subcounty: 'KAPYANGA',
      district: 'BUGIRI',
      limit: 273,
    ),
  ];

  /// Only the 4 parishes where block randomisation runs automatically.
  static List<ParishConfig> get autoRandomisation =>
      all.where((c) => c.isAutoRandomisation).toList();
}
