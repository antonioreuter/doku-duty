import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the player has opted into stakes.
///
/// One switch carrying both behaviours — a wrong digit is flagged as it is
/// placed, and the third **mistake** ends the **attempt** (D-04, D-94). There
/// is no second setting for one without the other.
///
/// **Off until the player turns it on**, and nothing else may turn it on: not a
/// **rank**, not a **node**, not a remote value. This is the single most
/// consequential default in the product, because the whole positioning is that
/// the player finds their own errors (constraint 1).
///
/// Storage lives in `persistence`, the way **reduce effects** does, so neither
/// feature has to import the other.
class StrictMode extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;

  void toggle() => state = !state;
}

final strictModeProvider = NotifierProvider<StrictMode, bool>(StrictMode.new);
