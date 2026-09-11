import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/persistence/application/settings_providers.dart';
import 'features/puzzle_engine/application/pack_providers.dart';
import 'features/remote_config/application/config_refresh.dart';
import 'features/platform_shell/application/crash_reporting.dart';
import 'features/platform_shell/application/flavour_provider.dart';
import 'features/platform_shell/application/orientation.dart';
import 'features/platform_shell/domain/flavour.dart';
import 'features/platform_shell/presentation/app.dart';

/// The single startup path, shared by the three entry points.
///
/// Nothing that can wait belongs here. Every millisecond spent before
/// [runApp] is paid on every cold start for the life of the app, and the
/// 2-second budget in `openspec/project.md` is measured from here.
Future<void> bootstrap(FlavourConfig config) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Not awaited: the platform channel round trip must not sit on the path to
  // the first frame.
  unawaited(applyOrientationLock(currentDeviceClass(binding)));

  final container = ProviderContainer(
    overrides: [
      flavourConfigProvider.overrideWithValue(config),
      // Settings come from storage in the real app. The override lives here
      // rather than inside either feature so neither imports the other.
      persistedReduceEffectsOverride,
    ],
  );

  await runWithCrashReporting(
    config,
    () => runApp(
      UncontrolledProviderScope(
        container: container,
        child: const DokuDutyApp(),
      ),
    ),
  );

  // After the first frame, never before it. The config refresh opens the
  // database and may touch the network; neither belongs on the path to a
  // rendered screen, and every value answers from its compiled-in default
  // until this finishes — or if it never does.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(container.read(configRefresherProvider).run());
    // Three hundred inserts on a fresh install, and nothing a player does waits
    // on them. Same rule as the config refresh: after the frame, never before.
    //
    // Started through the provider rather than by calling the installer, so
    // this and the first screen share one install instead of racing two.
    unawaited(container.read(packInstallationProvider.future));
  });
}
