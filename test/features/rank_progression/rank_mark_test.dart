import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Future<AppDatabase> _seeded() async {
  final db = AppDatabase(NativeDatabase.memory());
  await PackRepository(db).installPack(
    packId: 'test',
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
  return db;
}

Widget _app(AppDatabase db) => ProviderScope(
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

Finder _markOn(Rank rank) => find.descendant(
  of: find.byKey(ValueKey<String>('rank-${rank.name}')),
  matching: find.textContaining('Above your rank'),
);

Future<void> _solvedAt(AppDatabase db, Rank rank) =>
    ProgressionRepository(db).record(
      puzzleId: 'q-${rank.name}',
      techniquesRequired: <Technique>{Technique.nakedSingle},
      timeTaken: const Duration(minutes: 1),
      attempt: Attempt.fresh,
    );

void main() {
  group('the mark', () {
    testWidgets('a new player sees the five ranks above Greenhorn marked', (
      tester,
    ) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      expect(_markOn(Rank.greenhorn), findsNothing);
      for (final rank in <Rank>[
        Rank.deputy,
        Rank.sheriff,
        Rank.marshal,
        Rank.ranger,
        Rank.legend,
      ]) {
        expect(_markOn(rank), findsOneWidget, reason: '$rank was not marked');
      }
    });

    testWidgets(
      'solving above your rank clears that rank and every one below',
      (tester) async {
        final db = await _seeded();
        addTearDown(db.close);

        await _solvedAt(db, Rank.marshal);

        await tester.pumpWidget(_app(db));
        await tester.pumpAndSettle();

        for (final rank in <Rank>[
          Rank.greenhorn,
          Rank.deputy,
          Rank.sheriff,
          Rank.marshal,
        ]) {
          expect(_markOn(rank), findsNothing, reason: '$rank is still marked');
        }
        expect(_markOn(Rank.ranger), findsOneWidget);
        expect(_markOn(Rank.legend), findsOneWidget);
      },
    );

    testWidgets('a player at Legend has nothing marked', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await _solvedAt(db, Rank.legend);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      for (final rank in Rank.values) {
        expect(_markOn(rank), findsNothing);
      }
    });
  });

  group('a mark is not a lock', () {
    testWidgets('a marked rank opens on one tap, with nothing to dismiss', (
      tester,
    ) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      expect(_markOn(Rank.legend), findsOneWidget);

      // One tap. No confirmation to accept, no warning to dismiss, no second
      // step of any kind (constraint 1).
      await tester.tap(find.byKey(const ValueKey<String>('rank-legend')));
      await tester.pumpAndSettle();

      expect(find.byType(PuzzleGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no tile on the picker is disabled', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      for (final rank in Rank.values) {
        final tile = tester.widget<ListTile>(
          find.byKey(ValueKey<String>('rank-${rank.name}')),
        );
        expect(
          tile.onTap,
          isNotNull,
          reason: '${rank.name} is disabled — constraint 1 forbids it',
        );
        expect(tile.enabled, isTrue);
      }
    });

    testWidgets('the mark is carried in words, not by colour', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      // The words are the signal. A screen reader reaches the same sentence a
      // sighted player reads, and removing every colour from the tile would
      // not remove the mark (constraint 5).
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('rank-ranger')),
          matching: find.textContaining('Above your rank'),
        ),
      );
      expect(text.data, contains('Above your rank'));
    });
  });

  group('the first frame', () {
    testWidgets('all six ranks paint before progression is read', (
      tester,
    ) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      // One frame only: nothing has been read from the database yet.
      await tester.pump();

      for (final rank in Rank.values) {
        expect(
          find.byKey(ValueKey<String>('rank-${rank.name}')),
          findsOneWidget,
          reason: '${rank.name} was not on the first frame',
        );
      }
      // And nothing is marked yet, which is the safe way round: an unmarked
      // row is openable, so a player is never briefly told less than the truth
      // in a direction that would stop them.
      for (final rank in Rank.values) {
        expect(_markOn(rank), findsNothing);
      }

      await tester.pumpAndSettle();
      expect(_markOn(Rank.legend), findsOneWidget);
    });
  });
}
