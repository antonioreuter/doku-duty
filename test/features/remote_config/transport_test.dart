import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/data/config_transport.dart';

/// Exercises the real transport against a local server, because the behaviour
/// that matters here — timeouts, status codes, conditional requests — is the
/// part a fake cannot tell you anything about.
void main() {
  late HttpServer server;
  late String url;

  Future<void> serve(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    url = 'http://${server.address.host}:${server.port}/config.json';
    unawaited(server.forEach(handler));
  }

  tearDown(() => server.close(force: true));

  test('a 200 returns the body and the validator', () async {
    await serve((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.etagHeader, 'W/"v1"')
        ..write('{"schema_version": 1}');
      request.response.close();
    });

    final response = await HttpConfigTransport(url: url).fetch();
    expect(response, isA<ConfigDocument>());
    expect((response as ConfigDocument).body, contains('schema_version'));
    expect(response.validator, 'W/"v1"');
  });

  test('a known validator is sent, and a 304 costs no payload', () async {
    String? received;
    await serve((request) {
      received = request.headers.value(HttpHeaders.ifNoneMatchHeader);
      request.response.statusCode = HttpStatus.notModified;
      request.response.close();
    });

    final response = await HttpConfigTransport(
      url: url,
    ).fetch(knownValidator: 'W/"v1"');
    expect(received, 'W/"v1"');
    expect(response, isA<ConfigUnchanged>());
  });

  test('an error status is unavailable, not a document', () async {
    await serve((request) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
    });

    expect(
      await HttpConfigTransport(url: url).fetch(),
      isA<ConfigUnavailable>(),
    );
  });

  test('a hanging request is abandoned rather than waiting forever', () async {
    // The requirement is boundedness. A server that accepts and never answers
    // is exactly the case an unbounded fetch leaks on.
    await serve((request) {
      // Deliberately never responds.
    });

    final stopwatch = Stopwatch()..start();
    final response = await HttpConfigTransport(
      url: url,
      timeout: const Duration(milliseconds: 300),
    ).fetch();
    stopwatch.stop();

    expect(response, isA<ConfigUnavailable>());
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason: 'the fetch was not bounded',
    );
  });

  test('an unreachable host is unavailable, not a throw', () async {
    await serve((request) => request.response.close());
    final dead = 'http://${server.address.host}:1/config.json';
    await server.close(force: true);
    await serve((request) => request.response.close());

    final response = await HttpConfigTransport(
      url: dead,
      timeout: const Duration(seconds: 2),
    ).fetch();
    expect(response, isA<ConfigUnavailable>());
  });

  test('a build with no URL never fetches at all', () async {
    // An unconfigured build behaves exactly like one that has never been
    // online, which is a fully working app.
    final response = await HttpConfigTransport(url: '').fetch();
    expect(response, isA<ConfigUnavailable>());
  });

  test('a malformed URL is unavailable, not a crash', () async {
    final response = await HttpConfigTransport(url: 'not a url at all').fetch();
    expect(response, isA<ConfigUnavailable>());
  });
}
