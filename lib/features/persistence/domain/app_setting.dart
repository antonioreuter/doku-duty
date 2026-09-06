/// The settings the app stores, and what each one is when the player has never
/// touched it.
///
/// The defaults live here, in one place, rather than at each call site. Three of
/// the ten constraints are expressed as a default, and a default that is
/// scattered is a default that drifts.
enum AppSetting {
  /// Immediate error flagging and a three-mistake limit.
  ///
  /// **Off.** Strict mode is opt-in, and turning it on is a deliberate act so
  /// it never feels imposed (D-04, constraint 1).
  strictMode(defaultValue: false),

  /// Flagging a wrong digit as it is placed.
  ///
  /// **Off.** This is the single most consequential default in the product: the
  /// whole positioning is that the player finds their own errors, which is the
  /// actual skill sudoku teaches (D-04, constraint 1). Shipping this on would
  /// make the app indistinguishable from every competitor.
  autoCheck(defaultValue: false),

  /// The in-app switch that silences tokenised motion.
  ///
  /// **Off.** The player has opted into nothing. Independent of the OS
  /// reduce-motion setting, which is read separately and is not stored here.
  reduceEffects(defaultValue: false);

  const AppSetting({required this.defaultValue});

  /// The value returned when the player has never chosen one.
  final bool defaultValue;

  /// The key this setting is stored under. The enum name, so renaming the enum
  /// without a migration is a visible break rather than a silent reset.
  String get key => name;
}
