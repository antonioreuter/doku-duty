import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/domain/completion_sequence.dart';
import 'package:doku_duty/features/design_system/application/motion_settings.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
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
import 'package:doku_duty/features/stamps/application/earn_notice.dart';

import '../../support/home_navigation.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// The earn notice on the puzzle screen, as a player meets it (D-134).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
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
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, {bool reduceEffects = false}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
          appDatabaseProvider.overrideWith((ref) => db),
          packInstallationProvider.overrideWith(
            (ref) async => PackInstallOutcome.alreadyInstalled,
          ),
          persistedStrictModeOverride,
        ],
        child: const DokuDutyApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (reduceEffects) {
      ProviderScope.containerOf(
        tester.element(find.byType(DokuDutyApp)),
      ).read(reduceEffectsProvider.notifier).set(true);
      await tester.pumpAndSettle();
    }
    await goToFreePlay(tester);
    await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
    await tester.pumpAndSettle();
    final skip = find.byKey(const ValueKey<String>('lesson-skip'));
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle();
    }
  }

  Offset cellCentre(WidgetTester tester, int cell) {
    final box = tester.getRect(find.byType(PuzzleGrid));
    final side = box.width < box.height ? box.width : box.height;
    final size = side / 9;
    return Offset(
      box.left + (box.width - side) / 2 + size * (cell % 9 + 0.5),
      box.top + (box.height - side) / 2 + size * (cell ~/ 9 + 0.5),
    );
  }

  /// Fill every empty cell; with [slip], put a wrong digit in the first one
  /// and correct it — a **mistake** that still costs the perfect solve.
  Future<void> play(WidgetTester tester, {bool slip = false}) async {
    final empty = <int>[
      for (var cell = 0; cell < 81; cell++)
        if (_clues[cell] == '.') cell,
    ];
    if (slip) {
      final cell = empty.first;
      final wrong = int.parse(_solution[cell]) % 9 + 1;
      await tester.tapAt(cellCentre(tester, cell));
      await tester.pump();
      await tester.tap(find.text('$wrong').first);
      await tester.pump();
    }
    for (final cell in empty) {
      await tester.tapAt(cellCentre(tester, cell));
      await tester.pump();
      await tester.tap(find.text(_solution[cell]).first);
      await tester.pump();
    }
    // Let the writes land without advancing the celebration's clock much.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  Finder notice() => find.byKey(const ValueKey<String>('earn-notice'));

  testWidgets('a perfect solve: 3, after the celebration, then gone', (
    tester,
  ) async {
    await open(tester);
    await play(tester);

    expect(notice(), findsNothing, reason: 'shown over the celebration');

    await tester.pump(CompletionSequence.duration);
    await tester.pump();
    expect(find.text('+3 Stamps'), findsOneWidget);
    expect(find.bySemanticsLabel('3 stamps earned'), findsOneWidget);

    await tester.pump(EarnNotice.shownFor);
    await tester.pumpAndSettle();
    expect(notice(), findsNothing, reason: 'the notice did not go away');
  });

  testWidgets('under reduce-motion it shows at once', (tester) async {
    await open(tester, reduceEffects: true);
    await play(tester);

    expect(find.text('+3 Stamps'), findsOneWidget);
    await tester.pump(EarnNotice.shownFor);
  });

  testWidgets('a solve with a mistake earns nothing, so no notice', (
    tester,
  ) async {
    await open(tester);
    await play(tester, slip: true);

    await tester.pump(CompletionSequence.duration);
    await tester.pump(const Duration(seconds: 1));
    expect(notice(), findsNothing);
  });

  testWidgets('a tap on the notice reaches the grid under it', (tester) async {
    await open(tester, reduceEffects: true);
    await play(tester);
    expect(notice(), findsOneWidget);

    // Not modal and takes no input (constraint 2): what is hit at the
    // notice's centre is the grid, not the notice.
    final result = HitTestResult();
    tester.binding.hitTestInView(
      result,
      tester.getCenter(notice()),
      tester.view.viewId,
    );
    final grid = tester.renderObject(find.byType(PuzzleGrid));
    expect(
      result.path.map((entry) => entry.target),
      contains(grid),
      reason: 'the notice swallowed a tap meant for the screen',
    );
    await tester.pump(EarnNotice.shownFor);
  });
}
