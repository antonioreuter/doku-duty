import '../domain/remote_config.dart';
import 'config_transport.dart';

/// The outcome of a refresh, for the caller that wants to know. Nothing the
/// player sees depends on it.
enum RefreshOutcome { applied, unchanged, unavailable, unusable }

/// A fetched config and the validator to send next time.
class FetchedConfig {
  const FetchedConfig({
    required this.config,
    required this.validator,
    required this.document,
  });

  final RemoteConfig config;
  final String? validator;

  /// The document exactly as fetched, so the cache can store what arrived
  /// rather than a re-serialisation of what was understood.
  final String document;
}

/// Fetches, parses, and hands back a config.
///
/// Every failure path ends the same way: nothing is returned, the caller keeps
/// what is already in effect, and the player is told nothing. There is no state
/// in which this reports a problem to anyone but the crash reporter.
class RemoteConfigService {
  const RemoteConfigService({required this.transport, required this.report});

  final ConfigTransport transport;

  /// Where a failed or unusable fetch is reported. Never the player.
  final void Function(Object error, StackTrace stack) report;

  /// Fetch and parse. Returns null when there is nothing new to apply.
  Future<({RefreshOutcome outcome, FetchedConfig? fetched})> refresh({
    String? knownValidator,
  }) async {
    final response = await transport.fetch(knownValidator: knownValidator);

    switch (response) {
      case ConfigUnchanged():
        return (outcome: RefreshOutcome.unchanged, fetched: null);

      case ConfigUnavailable(:final cause):
        // Reported so a silent outage is diagnosable, never surfaced.
        report(cause, StackTrace.current);
        return (outcome: RefreshOutcome.unavailable, fetched: null);

      case ConfigDocument(:final body, :final validator):
        final parsed = RemoteConfigParser.parse(body);
        if (parsed == null) {
          report(
            FormatException('remote config is not a config document', body),
            StackTrace.current,
          );
          return (outcome: RefreshOutcome.unusable, fetched: null);
        }
        return (
          outcome: RefreshOutcome.applied,
          fetched: FetchedConfig(
            config: parsed,
            validator: validator,
            document: body,
          ),
        );
    }
  }
}
