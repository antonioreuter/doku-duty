import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/daily_challenge/application/daily_providers.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/stamps/data/stamp_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/application/minting_service.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';

import '../test/support/home_navigation.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// The **cabinet** on a real platform.
///
/// The host suite proves the rules, the words, and the text scales. What this
/// adds is the device: a real safe area with **four** destinations in the
/// navigation, and a **trophy** minted through the platform's own SQLite and
/// read back the way a relaunch reads it.
///
/// **This is the device runner for this change's platform checks.**
///
/// ```
/// flutter test integration_test/trophy_cabinet_test.dart -d <device> --flavor dev
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The round-trip test opens a second database over the same file on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late File file;

  setUp(() async {
    file = File(
      '${Directory.systemTemp.createTempSync('cabinet').path}/cabinet.sqlite',
    );
    db = AppDatabase(NativeDatabase(file));
    await PackRepository(db).installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          StoredPuzzle(
            id: 'q-${rank.name}',
            clues: _clues,
            solution: _solution,
            rank: rank,
            seed: 1,
          ),
      ],
    );
  });
  tearDown(() async {
    await db.close();
    if (file.existsSync()) file.deleteSync();
  });

  Widget app() => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
      persistedStrictModeOverride,
    ],
    child: const DokuDutyApp(),
  );

  final catalogue = AwardCatalogue.forSeason(
    seasonId: SeasonOne.id,
    seasonName: SeasonOne.season.name,
  );

  testWidgets('the cabinet lays out inside the safe area', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    expect(tester.takeException(), isNull);

    final view = tester.view;
    final screenHeight = view.physicalSize.height / view.devicePixelRatio;
    final topInset = view.padding.top / view.devicePixelRatio;
    final bottomInset = view.padding.bottom / view.devicePixelRatio;

    // Four destinations is the case the bar was never tried with.
    for (final label in <String>['Trail', 'Daily', 'Free play', 'Cabinet']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('home-nav')),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: '$label is missing from the navigation',
      );
    }
    final nav = tester.getRect(find.byKey(const ValueKey<String>('home-nav')));
    expect(
      nav.bottom,
      lessThanOrEqualTo(screenHeight + 0.5),
      reason: 'the navigation ran off the bottom of the screen',
    );

    // The cabinet has no app bar, so nothing but its own SafeArea keeps the
    // title out from under the notch.
    final title = tester.getRect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('cabinet-screen')),
        matching: find.text('Cabinet'),
      ),
    );
    expect(
      title.top,
      greaterThanOrEqualTo(topInset),
      reason: 'the cabinet title is under the notch',
    );

    debugPrint(
      'safe area — top ${topInset.toStringAsFixed(1)}pt, '
      'bottom ${bottomInset.toStringAsFixed(1)}pt, '
      'nav bottom ${nav.bottom.toStringAsFixed(1)}pt of '
      '${screenHeight.toStringAsFixed(1)}pt',
    );
  });

  testWidgets('a fresh install shows every award unfiled', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    for (final award in catalogue.awards) {
      expect(
        find.byKey(
          ValueKey<String>('cabinet-award-${award.id}'),
          skipOffstage: false,
        ),
        findsOneWidget,
        reason: '${award.id} is hidden rather than unfiled',
      );
    }
    expect(find.text('Unfiled', skipOffstage: false), findsWidgets);
  });

  testWidgets('a minted trophy survives the round trip through real storage', (
    tester,
  ) async {
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);
    final boss = catalogue.seasonal.firstWhere((a) => a.nodePosition == 22);

    await MintingService(
      database: db,
      seasons: seasons,
      trophies: TrophyRepository(db),
      daily: ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
      ).read(dailyServiceProvider),
      stamps: StampRepository(db),
    ).completeNode(
      seasonId: SeasonOne.id,
      seasonName: SeasonOne.season.name,
      position: 22,
      type: NodeType.boss,
      nodeCount: SeasonOne.season.nodes.length,
      catalogue: catalogue,
    );

    // A second connection over the same file — the question a relaunch asks
    // (constraint 9). The completion and its **trophy** arrive together.
    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await TrophyRepository(reopened).earnedIds(), <String>{boss.id});
    final progress = await SeasonRepository(reopened).progressFor(SeasonOne.id);
    expect(progress.completedCount, 1);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    final entry = find.byKey(
      ValueKey<String>('cabinet-award-${boss.id}'),
      skipOffstage: false,
    );
    expect(
      find.descendant(
        of: entry,
        matching: find.textContaining('Earned'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
