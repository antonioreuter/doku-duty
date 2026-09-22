import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:doku_duty/features/season_map/presentation/trail_screen.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// The **trail** on a real platform.
///
/// The host suite proves the rule, the ordering, and the words. What this adds
/// is the device itself: a real safe area on a notched phone, a real scroll
/// over 42 **node**s, and progress read back through a database file the
/// platform wrote rather than an in-memory one.
///
/// **This is the device runner for this change's platform checks.** Run it on
/// the first physical phone that comes to hand:
///
/// ```
/// flutter test integration_test/season_map_test.dart -d <device> --flavor dev
/// ```
///
/// It cannot check everything a person can. Whether the trail *looks* right is
/// still a pair of eyes; what this settles is that it lays out inside the safe
/// area, that every one of the 42 is reachable by scrolling, and that walking
/// a **node** survives the round trip through real storage.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The round-trip test deliberately opens a second database over the same
  // file — that is the whole point of it, and it is what a relaunch does.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late File file;

  setUp(() async {
    // A real file, not memory: the point of running here is the platform's own
    // SQLite writing to the platform's own disk.
    file = File(
      '${Directory.systemTemp.createTempSync('season_map').path}/trail.sqlite',
    );
    db = AppDatabase(NativeDatabase(file));
    await PackRepository(db).installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          for (var i = 0; i < 3; i++)
            StoredPuzzle(
              id: '${rank.name}-$i',
              clues: _clues,
              solution: _solution,
              rank: rank,
              seed: i,
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

  Finder node(int position) =>
      find.byKey(ValueKey<String>('trail-node-$position'), skipOffstage: false);

  testWidgets('the trail lays out inside the safe area', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(TrailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    final view = tester.view;
    final padding = view.padding;
    final screenHeight = view.physicalSize.height / view.devicePixelRatio;
    final topInset = padding.top / view.devicePixelRatio;
    final bottomInset = padding.bottom / view.devicePixelRatio;

    // The navigation is the piece most likely to be eaten by a home indicator,
    // because it sits at the very bottom by definition.
    final nav = tester.getRect(find.byKey(const ValueKey<String>('home-nav')));
    expect(
      nav.bottom,
      lessThanOrEqualTo(screenHeight + 0.5),
      reason: 'the navigation ran off the bottom of the screen',
    );

    // Nothing the player has to read may sit under the notch.
    final header = tester.getRect(
      find.byKey(const ValueKey<String>('trail-season-name')),
    );
    expect(
      header.top,
      greaterThanOrEqualTo(topInset),
      reason: 'the season name is under the notch',
    );

    debugPrint(
      'safe area — top ${topInset.toStringAsFixed(1)}pt, '
      'bottom ${bottomInset.toStringAsFixed(1)}pt, '
      'nav bottom ${nav.bottom.toStringAsFixed(1)}pt of '
      '${screenHeight.toStringAsFixed(1)}pt',
    );
  });

  testWidgets('the current node is reachable without scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // A fresh **season** puts the player at **node** 1, and someone opening
    // the app should not have to hunt for where they are.
    expect(node(1), findsOneWidget);
    final marker = tester.getRect(node(1));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(marker.top, greaterThan(0));
    expect(marker.bottom, lessThan(screenHeight));
  });

  testWidgets('all 42 nodes are reachable by scrolling', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (var position = 1; position <= 42; position++) {
      if (node(position).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          node(position),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }
      expect(node(position), findsOneWidget, reason: 'node $position');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('walking a node survives the round trip through real storage', (
    tester,
  ) async {
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // A **chest node** is the one type that completes without a puzzle, so it
    // exercises the write end to end in one tap.
    final chest = SeasonOne.season.nodes
        .firstWhere((n) => n.type == NodeType.chest)
        .position;
    for (var p = 1; p < chest; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }

    final written = await seasons.progressFor(SeasonOne.id);
    expect(written.currentPosition, chest);

    // Read back through a second repository over the same file — the same
    // question a relaunch asks (constraint 9).
    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    final afterRelaunch = await SeasonRepository(
      reopened,
    ).progressFor(SeasonOne.id);
    expect(afterRelaunch.completedCount, chest - 1);
    expect(afterRelaunch.stateOf(1), NodeState.completed);
    expect(afterRelaunch.currentPosition, chest);
  });
}
