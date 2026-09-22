import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_screen.dart';
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

import '../../support/home_navigation.dart';

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
      StoredPuzzle(
        id: 'only-deputy',
        clues: _clues,
        solution: _solution,
        rank: Rank.deputy,
        seed: 1,
      ),
    ],
  );
  return db;
}

Future<AppDatabase> _seededPair() async {
  final db = AppDatabase(NativeDatabase.memory());
  await PackRepository(db).installPack(
    packId: 'test',
    version: 1,
    puzzles: <StoredPuzzle>[
      for (final id in <String>['deputy-one', 'deputy-two'])
        StoredPuzzle(
          id: id,
          clues: _clues,
          solution: _solution,
          rank: Rank.deputy,
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

/// Play the open puzzle to a finished board, tapping the real grid.
Future<void> _solveOnScreen(WidgetTester tester) async {
  final box = tester.getRect(find.byType(PuzzleGrid));
  final side = box.width < box.height ? box.width : box.height;
  final origin = Offset(
    box.left + (box.width - side) / 2,
    box.top + (box.height - side) / 2,
  );
  final cellSize = side / 9;

  for (var cell = 0; cell < 81; cell++) {
    if (_clues[cell] != '.') continue;
    await tester.tapAt(
      Offset(
        origin.dx + cellSize * (cell % 9 + 0.5),
        origin.dy + cellSize * (cell ~/ 9 + 0.5),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(_solution[cell]).first);
    await tester.pump();
  }
  // Let the completion sequence and the writes finish.
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  // The break this closes: nothing marked a puzzle solved, so `nextUnsolved`
  // handed the same one back forever. Proved from the picker rather than from
  // the repository, because the repository's own tests passed the whole time
  // the app was broken — `markSolved` simply had no caller.
  testWidgets('a solved puzzle is not offered again', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _seeded();
    addTearDown(db.close);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await goToFreePlay(tester);

    // Scoped to the Deputy tile: the other five **rank**s hold no puzzle in
    // this pack and say so from the start, which is the ordinary absence
    // constraint 1 asks for rather than anything this test is about.
    Finder exhaustedDeputy() => find.descendant(
      of: find.byKey(const ValueKey<String>('rank-deputy')),
      matching: find.text('Nothing left here for now'),
    );

    expect(exhaustedDeputy(), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleGrid), findsOneWidget);

    await _solveOnScreen(tester);
    expect(await PackRepository(db).isSolved('only-deputy'), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // The only puzzle at this **rank** is solved, so the tile says so plainly.
    // Before this change it would have offered the same puzzle again.
    expect(
      exhaustedDeputy(),
      findsOneWidget,
      reason: 'the picker still offers a puzzle the player has solved',
    );
  });

  // The other half of the same requirement: where a **rank** still holds an
  // unsolved puzzle, choosing it opens *that* one. The single-puzzle test above
  // proves the solved one is dropped; this proves what arrives in its place.
  testWidgets('the next puzzle at that rank is the one opened', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _seededPair();
    addTearDown(db.close);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();

    await goToFreePlay(tester);

    await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
    await tester.pumpAndSettle();

    // The delegate's configuration, not the route information provider: an
    // imperative push does not update the latter, so it would report the
    // picker's own location for both puzzles and the test would pass without
    // ever looking at a puzzle id.
    // Read off the screen itself. The router was the obvious place to look and
    // the wrong one: an imperative push leaves the reported location at the
    // picker's, so both puzzles would have compared equal and the test would
    // have passed while proving nothing.
    String openPuzzleId() =>
        tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).puzzleId;

    final first = openPuzzleId();
    expect(first, startsWith('deputy-'));

    await _solveOnScreen(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Still a puzzle here, so the tile offers one rather than reporting the
    // **rank** exhausted.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('rank-deputy')),
        matching: find.text('Nothing left here for now'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
    await tester.pumpAndSettle();

    expect(find.byType(PuzzleGrid), findsOneWidget);
    expect(
      openPuzzleId(),
      isNot(first),
      reason: 'the puzzle just completed was handed back',
    );
  });
}
