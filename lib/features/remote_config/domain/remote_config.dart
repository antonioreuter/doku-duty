import 'dart:convert';

import '../../season_map/domain/season.dart';
import 'config_value.dart';

/// A parsed config: every value, always answerable.
///
/// There is no partial state and no null. A caller asks for a value and gets an
/// int — it cannot tell whether a fetch has happened, succeeded, or failed, and
/// it never waits.
class RemoteConfig {
  const RemoteConfig({
    required this.values,
    required this.schemaVersion,
    this.season,
    this.rawSeasonAwards,
  });

  /// Everything at its compiled-in default. What a fresh install runs on, with
  /// no network and no cache.
  factory RemoteConfig.defaults() => RemoteConfig(
    values: <ConfigValue, int>{
      for (final value in ConfigValue.values) value: value.defaultValue,
    },
    schemaVersion: null,
    season: null,
    rawSeasonAwards: null,
  );

  final Map<ConfigValue, int> values;

  /// The published **season**'s `awards`, unparsed. See [_rawAwards].
  final Object? rawSeasonAwards;

  /// The schema version the source declared, or null when it came from the
  /// compiled-in defaults or declared none.
  ///
  /// Recorded rather than enforced. Its job is to let a config from the future
  /// be told apart from a corrupt one when someone is debugging, not to gate
  /// parsing — rejecting a whole config over an unfamiliar version number would
  /// blank the config for every player on an older build the moment a key is
  /// added.
  final int? schemaVersion;

  /// The published **season**, or null when none was published or the one that
  /// was could not be read.
  ///
  /// **Null is not an error and not an empty season.** It means the caller uses
  /// the compiled-in `SeasonOne`, exactly as every [ConfigValue] falls back to
  /// its own compiled-in number. That is what makes a **season** a publish
  /// rather than a release (D-109) without making the network a dependency: an
  /// install that has never been online walks a full 42-**node** trail.
  ///
  /// A [Season] here has already been through [SeasonDefinition], so it
  /// composes. A published document that does not compose leaves this null and
  /// the rest of the config standing — one key at a time, as the existing
  /// requirement demands.
  final Season? season;

  int operator [](ConfigValue value) => values[value] ?? value.defaultValue;
}

/// Turns a fetched document into a [RemoteConfig].
///
/// **Degrades one key at a time.** An unknown key is ignored, so a newer config
/// cannot break an older app. A key that is missing or cannot be interpreted
/// falls back to its own compiled-in value, so one bad number never costs the
/// whole config. Every value that survives is clamped, so a config can only
/// tighten the ad caps.
abstract final class RemoteConfigParser {
  /// Parses [source], or returns null if it is not a config document at all.
  ///
  /// Null means "there was nothing usable here" — the caller keeps whatever was
  /// already in effect. It never means "use the defaults", because a config
  /// already in effect is better than a fresh fall back to compiled-in values.
  static RemoteConfig? parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;

    final parsed = <ConfigValue, int>{};
    for (final value in ConfigValue.values) {
      final raw = decoded[value.key];
      final candidate = _asInt(raw);
      // A missing or unusable key falls back on its own; the rest still apply.
      parsed[value] = candidate == null
          ? value.defaultValue
          : value.clampToDefault(candidate);
    }

    final season = _season(decoded['season']);
    return RemoteConfig(
      values: parsed,
      schemaVersion: _asInt(decoded['schema_version']),
      season: season,
      // Only alongside the **season** that declared them. A refused **season**
      // leaves the compiled-in one in force, and its **award**s would otherwise
      // be filed under that **season**'s id — a territory that never offered
      // them.
      rawSeasonAwards: season == null ? null : _rawAwards(decoded['season']),
    );
  }

  /// The `awards` key of the published **season**, still as JSON.
  ///
  /// **Deliberately unparsed.** An **award** is a `trophy-cabinet` type, and
  /// parsing it here would make `remote-config` — and through it `season-map` —
  /// depend on the **cabinet**. The dependency runs the other way: the
  /// **cabinet** reads this raw and makes its own **award**s of it (D-125).
  ///
  /// Null covers an absent **season**, an absent key, and a malformed one
  /// alike, because all three mean the same thing to the reader: use the
  /// compiled-in list.
  static Object? _rawAwards(Object? raw) {
    if (raw is! Map) return null;
    final awards = raw['awards'];
    return awards is List ? awards : null;
  }

  /// The published **season**, or null if there is not a usable one here.
  ///
  /// A malformed **season** is the same answer as an absent one, on purpose. A
  /// **season** is the one key whose failure is the most visible — it is the
  /// whole trail — and refusing the *document* over it would take the ad caps
  /// down with it. So it degrades like any other key: this one falls back, the
  /// others stand, and the player is told nothing.
  static Season? _season(Object? raw) {
    if (raw == null) return null;
    final parsed = SeasonDefinition.fromJson(raw);
    return switch (parsed) {
      ValidSeason(:final season) => season,
      MalformedSeason() => null,
    };
  }

  /// Accepts what JSON actually produces. A number written without a decimal
  /// point arrives as an int, with one as a double, and a hand-edited file will
  /// eventually contain a quoted number.
  static int? _asInt(Object? raw) => switch (raw) {
    final int value => value,
    final double value when value == value.roundToDouble() => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };
}
