import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../domain/flavour.dart';

/// The DSN, supplied at build time and never committed:
///
///     flutter build ... --dart-define=SENTRY_DSN=https://...
///
/// Empty by default. An empty DSN disables the Sentry SDK outright, which is
/// what a developer build, a CI build, and any build missing the secret should
/// do — no native SDK start, no endpoint, no upload.
const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Runs [appRunner] with crash reporting attached.
///
/// Uses Sentry's documented `appRunner` form so that errors thrown during
/// startup are captured. Deferring the call to after the first frame was
/// measured and made no difference to cold start, so the non-standard shape
/// bought nothing and was dropped — see the cold-start note in this change's
/// tasks.md.
///
/// Reporting never gates the app: with no DSN the SDK is skipped entirely, and
/// if [SentryFlutter.init] throws for any reason the app is run anyway. A
/// player must never see a launch fail because a reporting endpoint was
/// unhappy.
Future<void> runWithCrashReporting(
  FlavourConfig config,
  FutureOr<void> Function() appRunner,
) async {
  if (sentryDsn.isEmpty) {
    await appRunner();
    return;
  }

  try {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      // Keeps dev noise out of prod release health.
      options.environment = config.sentryEnvironment;
      // Release health: sessions per release, crash-free rate.
      options.enableAutoSessionTracking = true;
      // Nothing here is worth a player's personal data.
      options.sendDefaultPii = false;
      options.debug = false;
    }, appRunner: appRunner);
  } catch (_) {
    // Reporting is not a feature the player asked for. If it cannot start,
    // the app still does.
    await appRunner();
  }
}

/// Report a caught error that the app recovered from.
///
/// Distinct from an uncaught crash: the app is fine, but something happened
/// that someone should know about — a database that had to be reset, for
/// instance. Silent when reporting is not configured, and never throws at the
/// caller, because a failure to report is not worth failing over.
Future<void> reportHandled(Object error, StackTrace stack) async {
  if (sentryDsn.isEmpty) return;
  try {
    await Sentry.captureException(error, stackTrace: stack);
  } catch (_) {
    // Nothing to do, and nothing to tell the player.
  }
}
