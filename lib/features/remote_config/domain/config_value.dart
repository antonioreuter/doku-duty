/// Every value a remote config may change, and what it is when none has been
/// applied.
///
/// A closed set with its defaults in one place, for the same reason the settings
/// store works that way: a default that is scattered is a default that drifts.
///
/// **What is deliberately absent matters as much as what is here.** Nothing in
/// this set can affect *when* an ad may appear. That an interstitial fires only
/// after a node completes, after the celebration, and after an explicit tap, and
/// never on a chest, boss, or daily node, is compiled in and unreachable from
/// any config (constraint 6). Only volume is tunable, and only downward.
library;

/// The direction a remote value is allowed to move.
enum ClampDirection {
  /// A remote value may only be greater than or equal to the default.
  /// Used where a larger number means a stricter limit — a longer gap.
  atLeastDefault,

  /// A remote value may only be less than or equal to the default.
  /// Used where a smaller number means a stricter limit — fewer ads.
  atMostDefault,
}

enum ConfigValue {
  /// Minimum completed nodes between interstitials (D-24: one per three).
  ///
  /// A larger number is stricter, so remote may only raise it.
  interstitialNodeInterval(
    key: 'ads.interstitial_node_interval',
    defaultValue: 3,
    clamp: ClampDirection.atLeastDefault,
  ),

  /// Minimum seconds between interstitials (D-24: ninety).
  ///
  /// A longer gap is stricter, so remote may only raise it.
  interstitialMinimumGapSeconds(
    key: 'ads.interstitial_minimum_gap_seconds',
    defaultValue: 90,
    clamp: ClampDirection.atLeastDefault,
  ),

  /// Maximum interstitials in one session (D-24: six).
  ///
  /// Fewer is stricter, so remote may only lower it.
  interstitialsPerSession(
    key: 'ads.interstitials_per_session',
    defaultValue: 6,
    clamp: ClampDirection.atMostDefault,
  );

  const ConfigValue({
    required this.key,
    required this.defaultValue,
    required this.clamp,
  });

  /// The key this value is published under. Stable: renaming it silently
  /// reverts every player to the default until the file is republished.
  final String key;

  /// The value compiled into the binary, and the limit a remote config is
  /// measured against. These are D-24's numbers.
  final int defaultValue;

  /// Which way a remote value is permitted to move.
  ///
  /// D-24 states its numbers as *hard limits*, so a config may tighten them and
  /// may not loosen them. Loosening remains possible — it requires amending
  /// D-24 and shipping a build, which is the bar every other product constraint
  /// has. The alternative would let an S3 upload remove half of constraint 6
  /// with no review.
  final ClampDirection clamp;

  /// [candidate] if it is at least as strict as the default, otherwise the
  /// default.
  int clampToDefault(int candidate) => switch (clamp) {
    ClampDirection.atLeastDefault =>
      candidate >= defaultValue ? candidate : defaultValue,
    ClampDirection.atMostDefault =>
      candidate <= defaultValue ? candidate : defaultValue,
  };
}
