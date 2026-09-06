import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/remote_config/data/config_cache_repository.dart';
import 'package:doku_duty/features/remote_config/data/config_transport.dart';
import 'package:doku_duty/features/remote_config/data/remote_config_service.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';

/// The parts a host test cannot reach: the schema version a real device
/// actually opens, and a real HTTP round trip through the platform's own
/// networking stack.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the device database opens at schema version 2', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();

    expect(db.schemaVersion, 2);
    // The version 2 table is present and usable, which is what a migration or
    // a fresh create both have to end at.
    expect(await db.select(db.configCache).get(), isEmpty);
  });

  testWidgets('a config fetched over the network is cached and re-read', (
    tester,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.forEach((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.etagHeader, 'W/"device"')
        ..write(
          '{"schema_version": 1, '
          '"${ConfigValue.interstitialsPerSession.key}": 2}',
        );
      request.response.close();
    });
    final url = 'http://${server.address.host}:${server.port}/config.json';

    final reported = <Object>[];
    final service = RemoteConfigService(
      transport: HttpConfigTransport(url: url),
      report: (error, _) => reported.add(error),
    );

    final result = await service.refresh();
    expect(result.outcome, RefreshOutcome.applied, reason: '$reported');
    expect(result.fetched!.config[ConfigValue.interstitialsPerSession], 2);

    final db = AppDatabase.open();
    addTearDown(db.close);
    final cache = ConfigCacheRepository(db);
    await cache.write(
      document: result.fetched!.document,
      validator: result.fetched!.validator,
    );

    final reread = await cache.read();
    expect(reread!.config[ConfigValue.interstitialsPerSession], 2);
    expect(reread.validator, 'W/"device"');

    await cache.clear();
  });

  testWidgets('a config that loosens a cap is clamped on the device too', (
    tester,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.forEach((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('{"${ConfigValue.interstitialsPerSession.key}": 99}');
      request.response.close();
    });

    final service = RemoteConfigService(
      transport: HttpConfigTransport(
        url: 'http://${server.address.host}:${server.port}/config.json',
      ),
      report: (_, _) {},
    );

    final result = await service.refresh();
    expect(
      result.fetched!.config[ConfigValue.interstitialsPerSession],
      6,
      reason: 'D-24 is a hard limit on the device as much as in a unit test',
    );
  });

  testWidgets('no network means the compiled-in values, and no complaint', (
    tester,
  ) async {
    final service = RemoteConfigService(
      transport: HttpConfigTransport(
        url: 'http://127.0.0.1:1/config.json',
        timeout: const Duration(seconds: 2),
      ),
      report: (_, _) {},
    );

    final result = await service.refresh();
    expect(result.outcome, RefreshOutcome.unavailable);
    expect(result.fetched, isNull);
  });
}
