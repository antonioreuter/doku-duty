import 'package:doku_duty/features/daily_challenge/application/daily_providers.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The **calendar** at the reader's text sizes, and without colour.
///
/// Constraint 5 is the one under test. This screen is the whole record of a
/// habit — a grid of coloured squares with numbers in them says nothing to a
/// player who cannot separate the hues, and nothing at all to a screen reader.
/// Every day therefore says what it is in words.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'a11y',
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

    // A month with every state in it: a first day on the 8th, a genuine miss
    // on the 9th, a run from the 10th with a freeze bridging the 13th, and
    // days still to come. Today is the 16th, so the run is alive.
    final repository = DailyRepository(db);
    for (final day in <int>[8, 10, 11, 12, 14, 15]) {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
      );
    }
    await repository.recordFrozen(<DailyDate>[DailyDate(2026, 3, 13)]);
  });
  tearDown(() => db.close());

  Widget app(double scale) => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
      dailyClockProvider.overrideWithValue(
        DailyClock(offset: Duration.zero, now: () => DateTime(2026, 3, 16, 10)),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: const DokuDutyApp(),
    ),
  );

  /// A semantics label anywhere in the tree, built or scrolled out of view.
  ///
  /// The month grid is inside a scrolling list, so the last week of it is
  /// offstage on a 320×568 screen — and offstage is still something a screen
  /// reader walks.
  Finder labelled(WidgetTester tester, String label) =>
      find.bySemanticsLabel(label, skipOffstage: false);

  Future<void> openDaily(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('nav-daily')));
    await tester.pumpAndSettle();
  }

  group('dynamic type', () {
    for (final scale in <double>[1, 2, 3, 4, 5]) {
      testWidgets('nothing overflows or truncates at ${scale}x', (
        tester,
      ) async {
        // The smallest phone the app targets (D-84).
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(app(scale));
        await tester.pumpAndSettle();
        await openDaily(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'the daily overflowed at ${scale}x',
        );

        for (final element in find.byType(Text).evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '"${(element.widget as Text).data}" truncated at ${scale}x',
          );
        }
      });
    }
  });

  group('a screen reader', () {
    testWidgets('every day says what it is, in words', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await openDaily(tester);

      // The four states the month contains, each spoken. A player who cannot
      // see the grid gets the same information from it that a sighted player
      // does.
      expect(labelled(tester, '10 completed'), findsOneWidget);
      expect(labelled(tester, '13 streak freeze used'), findsOneWidget);
      expect(labelled(tester, '9 missed'), findsOneWidget);
      expect(labelled(tester, '20 not yet'), findsOneWidget);

      // And a day before the player ever played is not called a miss.
      expect(labelled(tester, '2 no record'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the streak and the freeze are stated, not implied', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(find.text('Streak freeze ready'), findsOneWidget);
      expect(find.textContaining('in a row'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('today names its rank, which the player cannot infer', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await openDaily(tester);

      // 2026-03-16 is a Monday. The board is the same for everybody at that
      // rank whatever ladder the player is on (D-116), so it is said out loud
      // rather than left to be guessed from the grid.
      expect(labelled(tester, 'Play today, greenhorn'), findsOneWidget);

      handle.dispose();
    });
  });

  group('colour removed', () {
    testWidgets('every day state is still distinguishable', (tester) async {
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await openDaily(tester);

      // The words are the non-colour channel and they are all different, so a
      // greyscale render loses nothing a player needs. The glyphs are a third
      // channel on top of that.
      final labels = <String>{
        for (final day in <int>[2, 9, 10, 13, 20])
          tester
              .widget<Semantics>(
                find
                    .ancestor(
                      of: find.byKey(
                        ValueKey<String>(
                          'daily-day-2026-03-${day.toString().padLeft(2, '0')}',
                        ),
                        skipOffstage: false,
                      ),
                      matchRoot: false,
                      matching: find.byType(Semantics),
                    )
                    .first,
              )
              .properties
              .label!,
      };

      expect(labels, hasLength(5));
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
