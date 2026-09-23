import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';

/// The **cabinet** at the reader's text sizes, and without colour.
///
/// Two things are under test. **Four** destinations in the navigation is the
/// case the shell's stacking was built for and never tried; and a shelf of
/// medals is the screen where colour alone would be easiest to reach for, so
/// earned and **unfiled** must each say what they are (constraint 5).
void main() {
  late AppDatabase db;

  final catalogue = AwardCatalogue.forSeason(
    seasonId: 'dust-gulch',
    seasonName: 'Dust Gulch',
  );
  final earned = catalogue.seasonal.firstWhere(
    (a) => a.trigger == AwardTrigger.boss,
  );
  final unfiled = catalogue.seasonal.firstWhere(
    (a) => a.trigger == AwardTrigger.seasonComplete,
  );

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
    // One of each state on the shelf, so both are under test at every scale.
    await TrophyRepository(db).mint(award: earned, seasonName: 'Dust Gulch');
  });
  tearDown(() => db.close());

  Widget app(double scale) => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: const DokuDutyApp(),
    ),
  );

  Finder labelled(String label) =>
      find.bySemanticsLabel(label, skipOffstage: false);

  /// The **cabinet**'s own list. Above 3x text the navigation stacks and
  /// scrolls too, so "the last scrollable" is not a safe way to name it.
  Finder cabinetList() => find.descendant(
    of: find.byKey(const ValueKey<String>('cabinet-screen')),
    matching: find.byType(Scrollable),
  );

  /// Scrolls the **cabinet** to its last row, building everything on the way.
  ///
  /// A lazy list does not build what is below the fold, and a screen reader
  /// walks the whole list — so anything a test says is announced has to have
  /// been built first.
  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('cabinet-open-lessons')),
      200,
      scrollable: cabinetList().first,
      // At 5x on the smallest phone the cabinet runs past the default fifty
      // drags; the length is the point of the check, not a problem with it.
      maxScrolls: 200,
    );
    await tester.pumpAndSettle();
  }

  /// Tall enough that the lazy list builds every row at once. A screen reader
  /// walks the whole list, so everything asserted as announced must exist.
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  void expectNoTruncation(WidgetTester tester, double scale) {
    for (final element in find.byType(Text).evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '"${(element.widget as Text).data}" truncated at ${scale}x',
      );
    }
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
        // Through the navigation, not around it: reaching the fourth
        // destination at this scale is half of what is being checked.
        await goToCabinet(tester);

        expect(find.byKey(const ValueKey<String>('cabinet-screen')), findsOne);
        expect(
          tester.takeException(),
          isNull,
          reason: 'the cabinet overflowed at ${scale}x',
        );
        expectNoTruncation(tester, scale);

        // The list builds lazily, so everything below the fold is checked by
        // scrolling to it — the last row is the **lesson** list.
        await scrollToEnd(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'the cabinet overflowed below the fold at ${scale}x',
        );
        expectNoTruncation(tester, scale);
      });
    }
  });

  group('a screen reader', () {
    testWidgets('every award says what it is and whether it is filed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tall(tester);
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      expect(labelled('${earned.name}, earned'), findsOneWidget);
      expect(labelled('${unfiled.name}, unfiled'), findsOneWidget);
      for (final award in AwardCatalogue.permanent) {
        expect(
          labelled('${award.name}, unfiled'),
          findsOneWidget,
          reason: '${award.id} is not announced',
        );
      }

      handle.dispose();
    });

    testWidgets('every statistic says what it counts', (tester) async {
      final handle = tester.ensureSemantics();
      tall(tester);
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      // A bare "0" is a number with no subject; each is spoken with its name.
      expect(labelled('Puzzles solved, 0'), findsOneWidget);
      expect(labelled('Solved with no mistakes, 0'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Time at the desk, .+'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('colour removed', () {
    testWidgets('earned and unfiled differ in glyph and in word', (
      tester,
    ) async {
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      IconData glyphOf(Award award) => tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(
                ValueKey<String>('cabinet-award-${award.id}'),
                skipOffstage: false,
              ),
              matching: find.byType(Icon),
              skipOffstage: false,
            ),
          )
          .icon!;

      Set<String> wordsOf(Award award) => <String>{
        for (final text
            in find
                .descendant(
                  of: find.byKey(
                    ValueKey<String>('cabinet-award-${award.id}'),
                    skipOffstage: false,
                  ),
                  matching: find.byType(Text),
                  skipOffstage: false,
                )
                .evaluate())
          (text.widget as Text).data!,
      };

      // Two channels that survive a greyscale render, each on its own.
      expect(glyphOf(earned), isNot(glyphOf(unfiled)));
      expect(wordsOf(earned).any((w) => w.startsWith('Earned')), isTrue);
      expect(wordsOf(unfiled), contains('Unfiled'));
      expect(wordsOf(earned), isNot(contains('Unfiled')));
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
