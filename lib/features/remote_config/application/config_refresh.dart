import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/platform_shell/application/crash_reporting.dart';

import '../data/config_cache_repository.dart';
import '../data/config_transport.dart';
import '../data/remote_config_service.dart';
import 'remote_config_provider.dart';

final configTransportProvider = Provider<ConfigTransport>(
  (ref) => HttpConfigTransport(url: HttpConfigTransport.urlFromEnvironment),
);

final configCacheRepositoryProvider = Provider<ConfigCacheRepository>(
  (ref) => ConfigCacheRepository(ref.watch(appDatabaseProvider)),
);

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(
    transport: ref.watch(configTransportProvider),
    report: (error, stack) {
      // ignore: discarded_futures
      reportHandled(error, stack);
    },
  ),
);

/// Loads the cached config, then refreshes it from the network.
///
/// **Started after the first frame, never before it.** Nothing here is on the
/// path to a rendered screen, and nothing the player does waits on it. Until it
/// finishes — or if it never does — every value answers from the compiled-in
/// defaults, which is a fully configured app.
class ConfigRefresher {
  const ConfigRefresher(this._ref);

  final Ref _ref;

  /// Apply the cached config, then fetch a newer one.
  ///
  /// Order matters: the cache is local and quick, so applying it first means an
  /// offline player is on their last known config almost immediately rather
  /// than after a network timeout.
  Future<void> run() async {
    final cache = _ref.read(configCacheRepositoryProvider);
    final cached = await cache.read();
    if (cached != null) {
      _ref.read(remoteConfigProvider.notifier).apply(cached.config);
    }

    final result = await _ref
        .read(remoteConfigServiceProvider)
        .refresh(knownValidator: cached?.validator);

    final fetched = result.fetched;
    if (fetched == null) return;

    _ref.read(remoteConfigProvider.notifier).apply(fetched.config);
    await cache.write(document: fetched.document, validator: fetched.validator);
  }
}

final configRefresherProvider = Provider<ConfigRefresher>(ConfigRefresher.new);
