import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/application/database_provider.dart';
import '../../persistence/data/pack_repository.dart';
import '../../platform_shell/application/crash_reporting.dart';
import '../data/pack_source.dart';
import 'pack_installer.dart';

final packSourceProvider = Provider<PackSource>(
  (ref) => const BundledPackSource(),
);

final packRepositoryProvider = Provider<PackRepository>(
  (ref) => PackRepository(ref.watch(appDatabaseProvider)),
);

/// The bundled **pack**, installed once.
///
/// **Everything that reads the pack awaits this first.** The install and the
/// first screen both start after the first frame, so without a rendezvous they
/// race: a reader that queries a **rank** before the install commits sees an
/// empty table, reports nothing left at that **rank**, and never asks again.
/// The player is told two-thirds of the content does not exist.
///
/// A [FutureProvider] caches its result, so however many readers await this,
/// the install happens once.
final packInstallationProvider = FutureProvider<PackInstallOutcome>(
  (ref) => ref.watch(packInstallerProvider).install(),
);

/// Installs the bundled **pack**, after the first frame.
final packInstallerProvider = Provider<PackInstaller>(
  (ref) => PackInstaller(
    source: ref.watch(packSourceProvider),
    packs: ref.watch(packRepositoryProvider),
    report: (error, stack) {
      // ignore: discarded_futures
      reportHandled(error, stack);
    },
  ),
);
