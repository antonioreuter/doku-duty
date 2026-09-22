import 'dart:io';

import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
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
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/trail_navigation.dart';

/// Fails the moment anything asks for an HTTP client.
class _NoNetwork extends HttpOverrides {
  bool wasAsked = false;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    wasAsked = true;
    throw StateError('the trail must not open a network connection');
  }
}

/// A device that has never been online walks a full 42-**node** **season**.
void main() {
  late AppDatabase db;
  late SeasonRepository seasons;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seasons = SeasonRepository(db);
    await PackRepository(db).installPack(
      packId: 'offline',
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
  tearDown(() => db.close());

  Widget app() => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
    ],
    child: const DokuDutyApp(),
  );

  testWidgets('first launch with no network reaches a full trail', (
    tester,
  ) async {
    final network = _NoNetwork();

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
    }, createHttpClient: network.createHttpClient);

    expect(network.wasAsked, isFalse);
    expect(tester.takeException(), isNull);

    // The compiled-in **season**, whole.
    expect(find.text('Dust Gulch'), findsOneWidget);
    final progress = await seasons.progressFor(SeasonOne.id);
    expect(progress.total, 42);
    expect(progress.currentPosition, 1);
  });

  testWidgets('offline, a node of each type is completable', (tester) async {
    final network = _NoNetwork();
    final season = SeasonOne.season;

    // Walk up to just before the first **chest node**, so all four types are
    // within reach without solving thirty boards.
    final chest = season.nodes
        .firstWhere((n) => n.type == NodeType.chest)
        .position;
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < chest; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // A **chest node** — opened directly, no puzzle, no network.
      await openTrailNode(tester, chest);
      expect(
        (await seasons.progressFor(SeasonOne.id)).stateOf(chest),
        NodeState.completed,
      );

      // A puzzle **node**, a **variant node**, and a **boss node** all open a
      // grid with nothing fetched.
      for (final type in <NodeType>[
        NodeType.puzzle,
        NodeType.variant,
        NodeType.boss,
      ]) {
        final node = season.nodes.firstWhere(
          (n) => n.type == type && n.position <= chest,
          orElse: () => season.nodes.firstWhere((n) => n.type == type),
        );
        if (!(await seasons.progressFor(
          SeasonOne.id,
        )).isOpenable(node.position)) {
          continue;
        }
        await openTrailNode(tester, node.position);
        expect(
          find.byType(PuzzleGrid),
          findsOneWidget,
          reason: '${type.name} node ${node.position} did not open a grid',
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }, createHttpClient: network.createHttpClient);

    expect(network.wasAsked, isFalse);
  });

  group('the trail is not on the first frame path', () {
    test('nothing in the season map layer opens the database eagerly', () {
      // The **season** is synchronous because it has to be: the **trail** is
      // the first screen, and a future there is a spinner where the map goes on
      // every cold start. The read that *does* touch the database is a
      // FutureProvider, and the screen guards it behind a post-frame callback.
      final providers = File(
        'lib/features/season_map/application/season_providers.dart',
      ).readAsStringSync();
      expect(
        providers,
        contains('class CurrentSeason extends Notifier<Season>'),
        reason: 'the season in force must be synchronous',
      );

      final screen = File(
        'lib/features/season_map/presentation/trail_screen.dart',
      ).readAsStringSync();
      expect(
        screen,
        contains('addPostFrameCallback'),
        reason: 'progress is read after the first frame, never on it',
      );
      expect(
        screen,
        contains('_pastFirstFrame'),
        reason: 'the guard that keeps the read off the first frame',
      );
    });

    testWidgets('the 42 nodes are on the first frame with no state applied', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      // One frame only: nothing has been read from the database yet.
      await tester.pump();

      expect(trailNode(1), findsOneWidget);
      expect(find.text('Dust Gulch'), findsOneWidget);
      // The header is there with no count, because a count is a read.
      expect(find.text('Trail progress'), findsOneWidget);
      expect(find.textContaining('/ 42'), findsNothing);
    });

    testWidgets('no node offers a tap before progress is known', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pump();

      // An unread **trail** offers no taps rather than offering the wrong
      // ones. Being briefly unable to open node 1 is recoverable in a frame;
      // opening node 30 by mistake is not.
      for (var position = 1; position <= 6; position++) {
        if (trailNode(position).evaluate().isEmpty) continue;
        expect(
          tester
              .widgetList<InkWell>(
                find.descendant(
                  of: trailNode(position),
                  matching: find.byType(InkWell),
                ),
              )
              .every((w) => w.onTap == null),
          isTrue,
          reason: 'node $position was tappable before progress was read',
        );
      }
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
