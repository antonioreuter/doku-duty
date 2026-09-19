/// The settings the app stores, and what each one is when the player has never
/// touched it.
///
/// The defaults live here, in one place, rather than at each call site. Three of
/// the ten constraints are expressed as a default, and a default that is
/// scattered is a default that drifts.
enum AppSetting {
  /// Immediate error flagging and a three-**mistake** limit, together.
  ///
  /// **Off.** This is the single most consequential default in the product: the
  /// whole positioning is that the player finds their own errors, which is the
  /// actual skill sudoku teaches (D-04, constraint 1). Shipping it on would
  /// make the app indistinguishable from every competitor. Turning it on is a
  /// deliberate act, so it never feels imposed.
  ///
  /// One switch carrying both behaviours, not two (D-94). `autoCheck` stood
  /// beside this from `add-persistence-layer` until `add-mistake-model` retired
  /// it: flagging without a cap and a cap without flagging are both halves of a
  /// thing nobody asked for, and a stored setting nothing reads is worse than
  /// none. A row left on disk under the old key is inert — [AppSetting.values]
  /// is what `readAll` maps, so a key no setting owns is simply not returned.
  strictMode(defaultValue: false),

  /// The in-app switch that silences tokenised motion.
  ///
  /// **Off.** The player has opted into nothing. Independent of the OS
  /// reduce-motion setting, which is read separately and is not stored here.
  reduceEffects(defaultValue: false),

  /// Stop drawing the **completion tint** on the cells of a complete **unit**.
  ///
  /// **Off**, so the tints are drawn. Phrased as *hide* rather than *show* on
  /// purpose: every setting in this enum is off until the player turns it on,
  /// and the tints are the default behaviour, so the switch has to name the
  /// departure from it. A `showCompletionTints` defaulting to true would be the
  /// one row in the app whose default was "on", and the rule that keeps this
  /// list honest is the one that has no exceptions.
  ///
  /// The **corner mark** is not affected by this. Hiding the tint hides a
  /// convenience; the mark is the signal, and completion has to stay readable
  /// without colour whatever the player has chosen (D-50, constraint 5).
  hideCompletionTints(defaultValue: false),

  /// Lock a digit, then tap cells to place it (`docs/SPEC.md` §3.4).
  ///
  /// **Off.** Cell-first is the mode that needs no explaining, so it is what a
  /// player meets first. Digit-first is for someone filling many of one digit,
  /// which is a habit they arrive at rather than start with.
  numberFirstInput(defaultValue: false);

  const AppSetting({required this.defaultValue});

  /// The value returned when the player has never chosen one.
  final bool defaultValue;

  /// The key this setting is stored under. The enum name, so renaming the enum
  /// without a migration is a visible break rather than a silent reset.
  String get key => name;
}
