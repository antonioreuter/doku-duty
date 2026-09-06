import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/haptics.dart';

/// Fires the haptic vocabulary.
///
/// Every call is best-effort. A device without the hardware, or a player who has
/// turned system haptics off, must produce silence rather than an error — the
/// haptic is a garnish on an event that has already happened visually.
class HapticService {
  const HapticService({this.isEnabled = true});

  /// Whether haptics fire at all. Follows the same reduce-effects switch as
  /// motion: a player who has asked for less has asked for less of all of it.
  final bool isEnabled;

  /// Fire [haptic], or do nothing if haptics are off or unavailable.
  ///
  /// Returns as soon as the first pulse is dispatched. The double tap's second
  /// pulse is scheduled rather than awaited, so a caller that writes
  /// `await fire(...)` in a tap handler does not stall input for the gap
  /// between them — constraint 2 holds even when the call site is careless.
  Future<void> fire(DokuHaptic? haptic) async {
    if (haptic == null || !isEnabled) return;
    try {
      await switch (haptic) {
        DokuHaptic.selectionTick => HapticFeedback.selectionClick(),
        DokuHaptic.lightImpact => HapticFeedback.lightImpact(),
        DokuHaptic.mediumImpact => HapticFeedback.mediumImpact(),
        // Two light taps, because the event is two digits noticing each other.
        DokuHaptic.lightDoubleTap => _firstOfDoubleTap(),
        DokuHaptic.success => HapticFeedback.heavyImpact(),
      };
    } on PlatformException {
      // No hardware, or the platform declined. Nothing to tell the player.
    } on MissingPluginException {
      // No platform side at all — a unit test host, or a stripped build.
    }
  }

  static Future<void> _firstOfDoubleTap() async {
    await HapticFeedback.lightImpact();
    // Scheduled, not awaited. The gap is felt by the player, never waited on by
    // the caller.
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 90)).then((_) async {
        try {
          await HapticFeedback.lightImpact();
        } on PlatformException {
          // Same silence as the first pulse.
        } on MissingPluginException {
          // No platform side.
        }
      }),
    );
  }
}
