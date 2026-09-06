import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/remote_config/application/config_refresh.dart';
import 'package:doku_duty/features/remote_config/application/remote_config_provider.dart';
import 'package:doku_duty/features/remote_config/data/config_transport.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';

/// A transport that records whether anyone asked it for anything.
class _CountingTransport implements ConfigTransport {
  int fetches = 0;

  @override
  Future<ConfigResponse> fetch({String? knownValidator}) async {
    fetches++;
    return const ConfigUnavailable('not expected in this test');
  }
}

void main() {
  late _CountingTransport transport;
  late AppDatabase db;

  setUp(() {
    transport = _CountingTransport();
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  overrides() => [
    flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
    appDatabaseProvider.overrideWithValue(db),
    configTransportProvider.overrideWithValue(transport),
  ];

  testWidgets('building the app shell performs no fetch', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const DokuDutyApp()),
    );
    await tester.pump();

    // The refresh is started from bootstrap's post-frame callback, not from
    // building the widget tree. One eager `watch` breaks this, and the symptom
    // — a slower cold start and a network call before the first frame — is not
    // something anyone notices in review.
    expect(transport.fetches, 0);
  });

  testWidgets('the app renders on compiled-in values before any refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const DokuDutyApp()),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DokuDutyApp)),
    );
    expect(
      container.read(remoteConfigProvider)[ConfigValue.interstitialsPerSession],
      6,
    );
  });

  group('a refresh mid-session', () {
    testWidgets('replaces the values in effect without disturbing the screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(overrides: overrides(), child: const DokuDutyApp()),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DokuDutyApp)),
      );
      final before = tester.widget(find.byType(DokuDutyApp));

      container
          .read(remoteConfigProvider.notifier)
          .apply(
            const RemoteConfig(
              values: <ConfigValue, int>{
                ConfigValue.interstitialsPerSession: 2,
              },
              schemaVersion: 1,
            ),
          );
      await tester.pump();

      expect(
        container.read(
          remoteConfigProvider,
        )[ConfigValue.interstitialsPerSession],
        2,
      );
      expect(
        tester.widget(find.byType(DokuDutyApp)),
        same(before),
        reason: 'a config change rebuilt the app shell',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
