import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/persistence/application/settings_providers.dart';
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

  await runWithCrashReporting(
    config,
    () => runApp(
      ProviderScope(
        overrides: [
          flavourConfigProvider.overrideWithValue(config),
          // Settings come from storage in the real app. The override lives here
          // rather than inside either feature so neither imports the other.
          persistedReduceEffectsOverride,
        ],
        child: const DokuDutyApp(),
      ),
    ),
  );
}
