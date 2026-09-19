import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/grid_input/presentation/rank_picker_screen.dart';
import 'package:doku_duty/features/grid_input/presentation/settings_screen.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
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
    // The composition root applies these; a test that builds the app directly
    // has to say so too, or a stored setting never reaches the screen.
    persistedStrictModeOverride,
  ],
  child: const DokuDutyApp(),
);

void main() {
  // The whole screen, not a widget out of context. `add-mistake-model` found
  // the grid, the remaining-mistake count, the pad and the ended-attempt panel
  // overflowing a phone together at the reader's largest text size — a failure
  // no component test could see, because a component test picks its own
  // surface. The tools row is new furniture on that same screen, so it gets
  // checked the same way.
  group('the puzzle screen fits a phone', () {
    for (final scale in <double>[1, 2, 3]) {
      testWidgets('nothing overflows at ${scale}x', (tester) async {
        // The smallest phone the app targets (D-84).
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final db = await _seeded(ranks: <Rank>{Rank.deputy});
        addTearDown(db.close);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: _app(db),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'the puzzle screen overflowed at ${scale}x',
        );
      });
    }

    // The tools are the controls a player reaches for, so they have to be on
    // the screen rather than merely in the widget tree.
    testWidgets('the tools are on screen and hittable', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();

      for (final label in const <String>['Notes', 'Fill notes', 'Undo']) {
        expect(find.text(label), findsOneWidget, reason: label);
        final rect = tester.getRect(find.text(label));
        expect(rect.top, greaterThanOrEqualTo(0), reason: '$label off the top');
        expect(
          rect.bottom,
          lessThanOrEqualTo(568),
          reason: '$label off the bottom',
        );
      }
    });

    // The two chain-test controls are absent until there is a test to end, so
    // a player who has never marked a provisional note never sees them.
    testWidgets('the chain-test controls are not there on opening', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();

      expect(find.text('Discard test'), findsNothing);
      expect(find.text('Keep test'), findsNothing);
      expect(
        find.text('Test'),
        findsNothing,
        reason: 'the ink control waits for notes mode',
      );
    });
  });

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

      // Since `add-technique-tutorials`, a **lesson** can stand in front of the
      // grid on a first opening. Skipped here rather than suppressed: what this
      // test is about is the **rank** still being openable, and the skip is the
      // one action a player always has (constraint 1).
      final skip = find.byKey(const ValueKey<String>('lesson-skip'));
      if (skip.evaluate().isNotEmpty) {
        await tester.tap(skip);
        // The seen write is a database round trip and resolves after the frame
        // loop goes quiet, so settling once is not enough.
        await tester.pumpAndSettle();
        await tester.pump();
        await tester.pumpAndSettle();
      }
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
    // that is absent. **Strict mode** was the last one making that promise
    // falsely, and `add-mistake-model` made it true.
    testWidgets('every row shown is a row something reads', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not in effect yet.'), findsNothing);
      for (final entry in SettingsScreen.rows.entries) {
        expect(entry.value.live, isTrue, reason: entry.key.name);
      }
    });

    // The only failure state in the product should never be a surprise, so the
    // row names both of its effects before it is turned on (D-94).
    testWidgets('the strict mode row states both of its effects', (
      tester,
    ) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      final detail = SettingsScreen.rows[AppSetting.strictMode]!.detail;
      expect(detail.toLowerCase(), contains('flag'));
      expect(detail.toLowerCase(), contains('three'));
      expect(detail.toLowerCase(), contains('mistake'));
      // And the player reads it on the screen, not only in the source.
      expect(find.textContaining(detail), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('setting-strictMode')),
        findsOneWidget,
      );
    });

    // D-94: there is no second row offering flagging without the cap.
    testWidgets('there is no auto-check row', (tester) async {
      final db = await _seeded();
      addTearDown(db.close);

      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Auto-check'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('setting-autoCheck')),
        findsNothing,
      );
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

  // Constraint 5: how much of an **attempt** is left is stated as a number.
  // A colour that deepened towards the limit would be the signal resting on
  // hue alone, and a player who cannot read the hue would not know.
  group('the mistakes remaining', () {
    Future<void> openPuzzle(WidgetTester tester, AppDatabase db) async {
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();
    }

    /// Cell 2 is empty and its solution is a 4, so a 7 is wrong.
    Future<void> placeWrongDigit(WidgetTester tester) async {
      // Touch the grid first: the pad's digits are only live once the board
      // has a selection to write into.
      await tester.tap(find.byType(PuzzleGrid));
      await tester.pumpAndSettle();
      final grid = tester.getRect(find.byType(PuzzleGrid));
      final cell = grid.width / 9;
      await tester.tapAt(Offset(grid.left + cell * 2.5, grid.top + cell * 0.5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
    }

    testWidgets('is not shown at all with stakes off', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await openPuzzle(tester, db);

      expect(find.textContaining('mistake'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('mistakes-remaining')),
        findsNothing,
        reason: 'a player with no limit is shown no limit',
      );
    });

    testWidgets('is a number once stakes are on', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);
      await SettingsRepository(db).write(AppSetting.strictMode, value: true);

      await openPuzzle(tester, db);

      expect(find.text('3 mistakes left'), findsOneWidget);
    });

    testWidgets('counts down as mistakes are made', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);
      await SettingsRepository(db).write(AppSetting.strictMode, value: true);

      await openPuzzle(tester, db);

      // Cell 2 is empty and its solution is 4, so a 7 is wrong.
      await placeWrongDigit(tester);

      expect(find.text('2 mistakes left'), findsOneWidget);
      expect(find.text('3 mistakes left'), findsNothing);
    });

    testWidgets('the number is not colour-coded', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);
      await SettingsRepository(db).write(AppSetting.strictMode, value: true);

      await openPuzzle(tester, db);

      /// The count's own Text, found by the row it lives in rather than by the
      /// words it currently shows.
      Color? countColour() => tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('mistakes-remaining')),
              matching: find.byType(Text),
            ),
          )
          .style
          ?.color;

      expect(
        find.byKey(const ValueKey<String>('mistakes-remaining')),
        findsOneWidget,
      );
      final atThree = countColour();

      await placeWrongDigit(tester);

      expect(find.text('2 mistakes left'), findsOneWidget);
      final atTwo = countColour();

      expect(
        atTwo,
        atThree,
        reason: 'the count is the signal; the colour says nothing',
      );
    });
  });

  // D-95. The only failure state in the product, and the two ways out of it.
  group('an attempt that ended', () {
    Future<void> failIt(WidgetTester tester, AppDatabase db) async {
      await SettingsRepository(db).write(AppSetting.strictMode, value: true);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PuzzleGrid));
      await tester.pumpAndSettle();
      final grid = tester.getRect(find.byType(PuzzleGrid));
      final cell = grid.width / 9;
      // Row 0's solution is 534678912, so each of these digits is wrong for
      // the cell it goes in.
      for (final (column, digit) in const <(int, int)>[
        (2, 9),
        (3, 9),
        (5, 9),
      ]) {
        await tester.tapAt(
          Offset(grid.left + cell * (column + 0.5), grid.top + cell * 0.5),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('$digit'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('offers exactly two choices, and sells nothing', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await failIt(tester, db);

      expect(
        find.byKey(const ValueKey<String>('attempt-ended')),
        findsOneWidget,
      );
      expect(find.text('Start again'), findsOneWidget);
      expect(find.text('Back to the map'), findsOneWidget);
      for (final sold in const <String>[
        'Watch',
        'Revive',
        'Continue',
        'Stamps',
      ]) {
        expect(find.textContaining(sold), findsNothing, reason: sold);
      }
    });

    testWidgets('each choice is named and holds the 44pt target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await failIt(tester, db);

      for (final label in const <String>['Start again', 'Back to the map']) {
        final node = tester.getSemantics(find.text(label));
        expect(node.label, label);
        expect(
          tester.getSize(find.text(label)).height,
          greaterThan(0),
          reason: label,
        );
      }
      for (final key in const <String>['attempt-restart', 'attempt-leave']) {
        final size = tester.getSize(find.byKey(ValueKey<String>(key)));
        expect(
          size.height,
          greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
          reason: key,
        );
      }
      handle.dispose();
    });

    testWidgets('the board is kept and the pad goes', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await failIt(tester, db);

      // The grid stays: the player gets to look at what they did (D-95).
      expect(find.byType(PuzzleGrid), findsOneWidget);
      expect(find.text('0 mistakes left'), findsOneWidget);

      // The pad does not. It accepted nothing at this point, and a pad that
      // looks live and swallows every tap is a set of disabled controls
      // (constraint 1). That input is refused is proved on the session, in
      // `attempt_end_test.dart`, where every path is covered rather than one.
      expect(find.byType(NumberPad), findsNothing);
    });

    testWidgets('the pad comes back on a fresh start', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await failIt(tester, db);
      await tester.tap(find.byKey(const ValueKey<String>('attempt-restart')));
      await tester.pumpAndSettle();

      expect(find.byType(NumberPad), findsOneWidget);
    });

    testWidgets('starting again gives a clean board and a clean tally', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await failIt(tester, db);
      await tester.tap(find.byKey(const ValueKey<String>('attempt-restart')));
      await tester.pumpAndSettle();

      expect(find.text('3 mistakes left'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('attempt-ended')), findsNothing);
    });

    testWidgets('leaving changes no other puzzle', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy, Rank.sheriff});
      addTearDown(db.close);

      final before = await PuzzleSaveRepository(db).all();

      await failIt(tester, db);
      await tester.tap(find.byKey(const ValueKey<String>('attempt-leave')));
      await tester.pumpAndSettle();

      final after = await PuzzleSaveRepository(db).all();
      // Only the puzzle that was played has a save; the other rank is
      // untouched, and nothing was recorded as solved.
      expect(
        after.map((save) => save.puzzleId).toSet(),
        <String>{'q-deputy'},
        reason: 'a failed attempt reaches one puzzle and no other',
      );
      expect(before, isEmpty);
      expect(
        await PackRepository(db).nextUnsolved(Rank.sheriff),
        isNotNull,
        reason: 'the other rank still has its puzzle to offer',
      );
      final lifetime = await StatisticsRepository(db).lifetime();
      expect(lifetime.puzzlesSolved, 0);
      expect(lifetime.perfectSolves, 0);
    });

    // 5.4: leaving changes nothing but where the player is.
    testWidgets('leaving returns to the picker with the puzzle unsolved', (
      tester,
    ) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await failIt(tester, db);
      await tester.tap(find.byKey(const ValueKey<String>('attempt-leave')));
      await tester.pumpAndSettle();

      expect(find.byType(RankPickerScreen), findsOneWidget);
      // Still offered, because a failed attempt is not a solve.
      expect(find.byKey(const ValueKey<String>('rank-deputy')), findsOneWidget);
      expect(await PackRepository(db).nextUnsolved(Rank.deputy), isNotNull);
    });
  });

  // The seam the two halves of D-94 meet at. Each half was tested alone —
  // the settings row writes, the session reacts — and neither proved that a
  // switch a player actually flips reaches a puzzle already on screen.
  group('the strict mode switch reaches a live puzzle', () {
    Future<void> openPuzzle(WidgetTester tester, AppDatabase db) async {
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();
    }

    Future<void> toggleStrictMode(WidgetTester tester) async {
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('setting-strictMode')),
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
      await tester.pumpAndSettle();
    }

    testWidgets('turning it on mid-session starts the count', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await openPuzzle(tester, db);
      expect(find.textContaining('mistakes left'), findsNothing);

      await toggleStrictMode(tester);

      expect(
        find.text('3 mistakes left'),
        findsOneWidget,
        reason: 'the switch must reach the session, not only the database',
      );
    });

    testWidgets('and it is stored as well as published', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);

      await openPuzzle(tester, db);
      await toggleStrictMode(tester);

      expect(await SettingsRepository(db).read(AppSetting.strictMode), isTrue);
    });

    testWidgets('turning it off again stops the flagging', (tester) async {
      final db = await _seeded(ranks: <Rank>{Rank.deputy});
      addTearDown(db.close);
      await SettingsRepository(db).write(AppSetting.strictMode, value: true);

      await openPuzzle(tester, db);
      expect(find.text('3 mistakes left'), findsOneWidget);

      await toggleStrictMode(tester);

      expect(find.textContaining('mistakes left'), findsNothing);
      expect(await SettingsRepository(db).read(AppSetting.strictMode), isFalse);
    });
  });
}
