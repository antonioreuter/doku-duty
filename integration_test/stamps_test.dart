import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/stamps/data/stamp_repository.dart';

import '../test/support/home_navigation.dart';
import '../test/support/trail_navigation.dart';

/// **Stamp**s on a real platform.
///
/// The host suite proves the rules, the keys and the transactions. What this
/// adds is the device: a **chest node** opened by tapping the real **trail**,
/// the 12 shown in its message and in the **cabinet**, and the balance read
/// back through a database file the platform wrote — which is what a player
/// killing the app and relaunching it sees.
///
/// ```
/// flutter test integration_test/stamps_test.dart -d <device> --flavor dev
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late File file;

  final firstChest = SeasonOne.season.nodes
      .firstWhere((node) => node.type == NodeType.chest)
      .position;

  setUp(() async {
    file = File(
      '${Directory.systemTemp.createTempSync('stamps').path}/stamps.sqlite',
    );
    db = AppDatabase(NativeDatabase(file));
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < firstChest; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }
  });

  tearDown(() async {
    await db.close();
    if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
  });

  Widget app(AppDatabase database) => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => database),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
    ],
    child: const DokuDutyApp(),
  );

  testWidgets('a chest pays 12, and the balance survives a relaunch', (
    tester,
  ) async {
    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    await openTrailNode(tester, firstChest);
    expect(find.text('Chest opened · +12 Stamps'), findsOneWidget);

    await goToCabinet(tester);
    expect(find.bySemanticsLabel('Stamps, 12'), findsOneWidget);

    // The relaunch: the app torn down, the file closed, a new connection over
    // the same file, and the app built again from nothing (constraint 9).
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    db = AppDatabase(NativeDatabase(file));

    expect(await StampRepository(db).balance(), 12);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();
    await goToCabinet(tester);
    expect(find.bySemanticsLabel('Stamps, 12'), findsOneWidget);
  });

  testWidgets('the balance line fits the smallest phone at the largest text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Stamps, 0'), findsOneWidget);
  });
}
