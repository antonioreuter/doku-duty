import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/config_value.dart';
import '../domain/remote_config.dart';

/// The config currently in effect.
///
/// Starts at the compiled-in defaults and is replaced when a cached or fetched
/// config arrives. It is never absent and never a future: an ad placement
/// deciding whether it may fire cannot await anything, and a value that is
/// merely stale is always better than a caller that has to wait.
class RemoteConfigState extends Notifier<RemoteConfig> {
  @override
  RemoteConfig build() => RemoteConfig.defaults();

  /// Replace the config in effect.
  ///
  /// Applied whole, so a read never sees half of one config and half of
  /// another. Callers read at the moment they act, so nothing that is already
  /// on screen changes underneath the player.
  void apply(RemoteConfig config) => state = config;
}

final remoteConfigProvider = NotifierProvider<RemoteConfigState, RemoteConfig>(
  RemoteConfigState.new,
);

/// Read one value.
///
/// Synchronous by design. If this ever returns a future, every ad placement
/// downstream becomes async and the latency budget goes with it — a test
/// asserts the signature for that reason.
int configValue(Ref ref, ConfigValue value) =>
    ref.watch(remoteConfigProvider)[value];
