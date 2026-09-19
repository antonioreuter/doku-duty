import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the player has asked for the **completion tint** not to be drawn.
///
/// **Off until the player turns it on**, like every other setting in the app,
/// which is why it is phrased as *hide* rather than *show*: the tints are the
/// default behaviour, so the switch names the departure from it rather than the
/// behaviour itself.
///
/// It hides the tint and nothing else. The **corner mark** is drawn either way,
/// because completion has to stay readable without colour whatever the player
/// has chosen — a setting that made a state unreadable would be constraint 5
/// broken by a switch instead of by a palette (D-50).
///
/// Storage lives in `persistence`, the way **reduce effects** and **strict
/// mode** do: the persisted subclass is declared there and applied at the
/// composition root, so this feature never imports a database.
class HideCompletionTints extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;

  void toggle() => state = !state;
}

final hideCompletionTintsProvider = NotifierProvider<HideCompletionTints, bool>(
  HideCompletionTints.new,
);
