import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/grid_input/presentation/rank_picker_screen.dart';
import 'package:doku_duty/features/grid_input/presentation/settings_screen.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Future<AppDatabase> _seeded({Set<Rank> ranks = const <Rank>{}}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await PackRepository(db).installPack(
    packId: 'test',
    version: 1,
    puzzles: <StoredPuzzle>[
      for (final rank in ranks)
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
    // These tests seed the database themselves, so the bundled pack must not
    // also install into it. `first_launch_test.dart` is where the install and
    // the picker are exercised together.
    packInstallationProvider.overrideWith(
      (ref) async => PackInstallOutcome.alreadyInstalled,
    ),
  ],
  child: const DokuDutyApp(),
);

void main() {
  group('the rank picker', () {
    testWidgets('shows all six ranks, named as ranks', (tester) async {
      final db = await _seeded(ranks: Rank.values.toSet());
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      // "Sheriff rank", never a bare rank name: Sheriff and Deputy are
      // characters too, and the player is the Deputy (D-57).
      expect(find.text('Greenhorn rank'), findsOneWidget);
      expect(find.text('Sheriff rank'), findsOneWidget);
      expect(find.text('Legend rank'), findsOneWidget);
      for (final rank in Rank.values) {
        expect(
          find.byKey(ValueKey<String>('rank-${rank.name}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('choosing a rank opens an unsolved puzzle of that rank', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();

      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    // Constraint 1: nothing left is an ordinary absence, never a lock or a
    // failure state.
    testWidgets('a rank with nothing left says so and blocks nothing', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      expect(find.text('Nothing left here for now'), findsNWidgets(5));

      // Tapping an exhausted rank does nothing at all — no error, no dialog.
      await tester.tap(find.byKey(const ValueKey<String>('rank-legend')));
      await tester.pumpAndSettle();
      expect(find.byType(RankPickerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the other ranks are unaffected when one is exhausted', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy, Rank.marshal});
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('rank-marshal')));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    // The six rows need nothing but `Rank.values`; which puzzle is next lives
    // in the database, and opening it is not allowed on the first frame.
    testWidgets('the rows are on screen before the pack has been read', (
      tester,
    ) async {
      final db = await _seeded(ranks: Rank.values.toSet());
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));

      expect(find.text('Greenhorn rank'), findsOneWidget);
      expect(find.text('Nothing left here for now'), findsNothing);
    });
  });

  group('settings', () {
    testWidgets('every stored setting has a row', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      for (final setting in AppSetting.values) {
        expect(
          find.byKey(ValueKey<String>('setting-${setting.name}')),
          findsOneWidget,
          reason: setting.name,
        );
      }
    });

    // The single most consequential default in the product: shipping auto-check
    // on would make the app indistinguishable from every competitor (D-04).
    testWidgets('a new player gets auto-check and strict mode off', (
      tester,
    ) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      for (final setting in AppSetting.values) {
        final tile = tester.widget<SwitchListTile>(
          find.byKey(ValueKey<String>('setting-${setting.name}')),
        );
        expect(tile.value, isFalse, reason: setting.name);
        expect(setting.defaultValue, isFalse, reason: setting.name);
      }
    });

    testWidgets('changing a setting persists it', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('setting-numberFirstInput')),
      );
      await tester.pumpAndSettle();

      expect(
        await SettingsRepository(db).read(AppSetting.numberFirstInput),
        isTrue,
      );
      final tile = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey<String>('setting-numberFirstInput')),
      );
      expect(tile.value, isTrue, reason: 'the row shows what is stored');
    });

    // A row that appears to work but is read by nothing is worse than a row
    // that is absent.
    testWidgets('a setting nothing implements yet says so', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not in effect yet.'), findsNWidgets(2));
      expect(SettingsScreen.rows[AppSetting.autoCheck]!.live, isFalse);
      expect(SettingsScreen.rows[AppSetting.strictMode]!.live, isFalse);
      expect(SettingsScreen.rows[AppSetting.numberFirstInput]!.live, isTrue);
    });
  });

  // The stored choice is what the next puzzle opens in.
  testWidgets('the input mode comes from the stored setting', (tester) async {
    final db = await _seeded(ranks: <Rank>{Rank.deputy});
    addTearDown(db.close);
    await SettingsRepository(
      db,
    ).write(AppSetting.numberFirstInput, value: true);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) => db)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(inputModeProvider.future),
      InputMode.digitFirst,
    );

    await SettingsRepository(
      db,
    ).write(AppSetting.numberFirstInput, value: false);
    container.invalidate(inputModeProvider);
    expect(await container.read(inputModeProvider.future), InputMode.cellFirst);
  });
}
