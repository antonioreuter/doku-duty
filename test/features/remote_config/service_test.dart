import 'dart:async';

import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/data/config_transport.dart';
import 'package:doku_duty/features/remote_config/data/remote_config_service.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';

/// A transport that answers whatever the test tells it to. No network anywhere
/// in this file — that is the point of the seam.
class _FakeTransport implements ConfigTransport {
  _FakeTransport(this._answer);

  final Future<ConfigResponse> Function(String? knownValidator) _answer;
  final List<String?> validatorsSent = <String?>[];

  @override
  Future<ConfigResponse> fetch({String? knownValidator}) {
    validatorsSent.add(knownValidator);
    return _answer(knownValidator);
  }
}

void main() {
  final reported = <Object>[];
  RemoteConfigService serviceWith(_FakeTransport transport) =>
      RemoteConfigService(
        transport: transport,
        report: (error, _) => reported.add(error),
      );

  setUp(reported.clear);

  group('a successful fetch', () {
    test('replaces the values in effect', () async {
      final transport = _FakeTransport(
        (_) async => ConfigDocument(
          body: '{"${ConfigValue.interstitialsPerSession.key}": 3}',
          validator: 'W/"abc"',
        ),
      );

      final result = await serviceWith(transport).refresh();

      expect(result.outcome, RefreshOutcome.applied);
      expect(result.fetched!.config[ConfigValue.interstitialsPerSession], 3);
      expect(result.fetched!.validator, 'W/"abc"');
      expect(reported, isEmpty);
    });

    test(
      'sends the known validator so an unchanged document costs no payload',
      () async {
        final transport = _FakeTransport((_) async => const ConfigUnchanged());
        final result = await serviceWith(
          transport,
        ).refresh(knownValidator: 'W/"abc"');

        expect(transport.validatorsSent, <String?>['W/"abc"']);
        expect(result.outcome, RefreshOutcome.unchanged);
        expect(result.fetched, isNull);
      },
    );
  });

  group('every failure leaves the previous values untouched', () {
    // The requirement is that nothing is returned to apply. The caller cannot
    // distinguish these cases in what it shows, only in what it reports.
    test('the transport reports it is unavailable', () async {
      final transport = _FakeTransport(
        (_) async => const ConfigUnavailable('offline'),
      );
      final result = await serviceWith(transport).refresh();

      expect(result.outcome, RefreshOutcome.unavailable);
      expect(result.fetched, isNull);
      expect(reported, hasLength(1));
    });

    test('the body is malformed', () async {
      final transport = _FakeTransport(
        (_) async => const ConfigDocument(body: '{not json'),
      );
      final result = await serviceWith(transport).refresh();

      expect(result.outcome, RefreshOutcome.unusable);
      expect(result.fetched, isNull);
      expect(reported, hasLength(1));
    });

    test('the body is empty', () async {
      final transport = _FakeTransport(
        (_) async => const ConfigDocument(body: ''),
      );
      final result = await serviceWith(transport).refresh();

      expect(result.outcome, RefreshOutcome.unusable);
      expect(result.fetched, isNull);
    });

    test('the body is an array', () async {
      final transport = _FakeTransport(
        (_) async => const ConfigDocument(body: '[]'),
      );
      expect((await serviceWith(transport).refresh()).fetched, isNull);
    });

    test('the transport throws rather than returning', () async {
      final transport = _FakeTransport((_) async => throw StateError('boom'));
      await expectLater(
        serviceWith(transport).refresh(),
        throwsStateError,
        reason:
            'a transport that throws is a bug in the transport; the real '
            'one converts every failure into ConfigUnavailable',
      );
    });
  });

  group('the player is never told', () {
    test(
      'a failure reports to the crash reporter and returns nothing to show',
      () async {
        final transport = _FakeTransport(
          (_) async => const ConfigUnavailable('dns'),
        );
        final result = await serviceWith(transport).refresh();

        // Reported: the outage is diagnosable.
        expect(reported, hasLength(1));
        // Nothing to show: the outcome carries no message, no retry, no state
        // any UI could render as an error.
        expect(result.fetched, isNull);
        expect(result.outcome, RefreshOutcome.unavailable);
      },
    );
  });
}
