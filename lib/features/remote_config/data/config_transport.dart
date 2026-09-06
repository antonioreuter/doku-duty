import 'dart:async';
import 'dart:io';

/// What came back from a fetch.
sealed class ConfigResponse {
  const ConfigResponse();
}

/// A new document. [validator] is the server's entity tag, if it gave one.
class ConfigDocument extends ConfigResponse {
  const ConfigDocument({required this.body, this.validator});

  final String body;
  final String? validator;
}

/// The document has not changed since [ConfigDocument.validator] was issued.
///
/// The CDN's short TTL means most fetches end here, costing a round trip and no
/// payload.
class ConfigUnchanged extends ConfigResponse {
  const ConfigUnchanged();
}

/// Nothing usable came back. Deliberately carries no detail for the caller to
/// branch on: every failure has the same consequence, which is that the values
/// already in effect stay in effect.
class ConfigUnavailable extends ConfigResponse {
  const ConfigUnavailable(this.cause);

  final Object cause;
}

/// Fetches the config document.
///
/// An interface rather than a class so every test in this feature runs without
/// a network, and so the one place that does I/O is small enough to read.
abstract interface class ConfigTransport {
  /// Fetch, sending a conditional request when [knownValidator] is given.
  Future<ConfigResponse> fetch({String? knownValidator});
}

/// The real transport.
///
/// `dart:io`'s `HttpClient` rather than a package: this is a single GET, and a
/// dependency to replace it would still need the seam above for testing.
class HttpConfigTransport implements ConfigTransport {
  HttpConfigTransport({
    required this.url,
    this.timeout = const Duration(seconds: 10),
  });

  /// Supplied at build time:
  ///
  ///     flutter build ... --dart-define=REMOTE_CONFIG_URL=https://...
  ///
  /// Empty by default, which disables fetching outright — a build with no URL
  /// behaves exactly like one that has never been online, which is a fully
  /// working app.
  static const String urlFromEnvironment = String.fromEnvironment(
    'REMOTE_CONFIG_URL',
  );

  final String url;

  /// Bounded so a hanging request cannot leave anything waiting forever. It is
  /// not on any path the player is on, but an unbounded future is still a leak.
  final Duration timeout;

  @override
  Future<ConfigResponse> fetch({String? knownValidator}) async {
    if (url.isEmpty) {
      return const ConfigUnavailable('no remote config URL is configured');
    }

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
      if (knownValidator != null) {
        request.headers.set(HttpHeaders.ifNoneMatchHeader, knownValidator);
      }
      final response = await request.close().timeout(timeout);

      if (response.statusCode == HttpStatus.notModified) {
        await response.drain<void>();
        return const ConfigUnchanged();
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return ConfigUnavailable('status ${response.statusCode}');
      }

      final body = await response
          .transform(const SystemEncoding().decoder)
          .join()
          .timeout(timeout);

      return ConfigDocument(
        body: body,
        validator: response.headers.value(HttpHeaders.etagHeader),
      );
    } on Object catch (error) {
      // Every failure is the same failure: no network, DNS, TLS, timeout, a
      // malformed URL. The caller does not branch on which.
      return ConfigUnavailable(error);
    } finally {
      client.close(force: true);
    }
  }
}
