import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/motion.dart';

/// Whether the player has asked the app for fewer effects.
///
/// Independent of the OS setting on purpose: a player may want animation
/// elsewhere on their phone and not here, or the reverse. Defaults to off, and
/// this change does not persist it — storage is `add-persistence-layer`.
class ReduceEffects extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;

  void toggle() => state = !state;
}

final reduceEffectsProvider = NotifierProvider<ReduceEffects, bool>(
  ReduceEffects.new,
);

/// The resolved motion settings: either switch alone is enough to silence
/// motion, and neither can re-enable it over the other.
class MotionSettings {
  const MotionSettings({
    required this.osReduceMotion,
    required this.reduceEffects,
  });

  final bool osReduceMotion;
  final bool reduceEffects;

  bool get isMotionReduced => osReduceMotion || reduceEffects;

  /// [motion] as it should actually run under these settings.
  ///
  /// Reduced motion resolves to the end state instantly. Nothing is lost: every
  /// state an animation conveys is also carried by the value it lands on, which
  /// is why colour is never the only signal (constraint 5).
  Duration resolve(DokuMotion motion) =>
      motion.resolve(reduceMotion: isMotionReduced);
}

/// Reads the OS reduce-motion setting and combines it with the in-app switch.
final motionSettingsProvider = Provider<MotionSettings>((ref) {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final osReduceMotion = MediaQueryData.fromView(view).disableAnimations;
  return MotionSettings(
    osReduceMotion: osReduceMotion,
    reduceEffects: ref.watch(reduceEffectsProvider),
  );
});
