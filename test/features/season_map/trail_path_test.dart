import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/presentation/trail_path_painter.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/trail_navigation.dart';

/// The **trail**'s connecting line, as the requirement states it.
///
/// The painter's own geometry is covered in `trail_path_painter_test.dart`.
/// What is under test here is the line *as the player meets it*: that it is
/// there on the first frame, that it says nothing about progress (D-113), and
/// that a screen reader never mentions it.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'path',
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

  Future<void> walkTo(int position) async {
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < position; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }
  }

  /// Every trail painter currently built, in list order.
  /// `skipOffstage: false` deliberately: the list builds a little beyond what
  /// it shows, and those rows carry semantics, so a count taken only of the
  /// visible ones would not line up with what a screen reader walks.
  List<TrailPathPainter> paintersOn(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint, skipOffstage: false))
      .map((p) => p.painter)
      .whereType<TrailPathPainter>()
      .toList();

  group('the trail is drawn as a linked path', () {
    testWidgets('a line is drawn for every node on screen', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final painters = paintersOn(tester);
      expect(painters, isNotEmpty);

      // One painter per built node, and the sides alternate down the list —
      // which is what makes the line a winding path rather than a straight
      // rail down the middle.
      for (var i = 1; i < painters.length; i++) {
        expect(
          painters[i].isLeft,
          isNot(painters[i - 1].isLeft),
          reason: 'two adjacent nodes sat on the same side',
        );
      }
    });

    testWidgets('the line stops at both ends of the season', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Node 1 opens the trail: nothing above it to join.
      expect(paintersOn(tester).first.isFirst, isTrue);
      expect(paintersOn(tester).first.isLast, isFalse);

      await scrollToNode(tester, 42);
      final last = paintersOn(tester).last;
      expect(last.isLast, isTrue, reason: 'the line ran off the end');
    });
  });

  group('the line carries no state', () {
    testWidgets('a completed stretch is drawn exactly like an unreached one', (
      tester,
    ) async {
      // Node 1 to 7 are behind the player, 8 is current, the rest are ahead.
      await walkTo(8);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final painters = paintersOn(tester);

      // Group by side, because side is the only thing that legitimately
      // differs between rows. Within a side, every painter must be identical
      // apart from the two end flags — no completion, no rank, nothing.
      for (final side in <bool>[true, false]) {
        final onSide = painters
            .where((p) => p.isLeft == side && !p.isFirst && !p.isLast)
            .toList();
        if (onSide.length < 2) continue;

        for (final p in onSide.skip(1)) {
          expect(
            p.shouldRepaint(onSide.first),
            isFalse,
            reason:
                'a painter differed from another on the same side, so '
                'something about node state reached the line (D-113)',
          );
        }
      }
    });

    testWidgets('walking the trail does not change the line behind you', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final fresh = paintersOn(
        tester,
      ).where((p) => !p.isFirst && !p.isLast).toList();

      // Same trail, eight nodes later.
      await walkTo(8);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final walked = paintersOn(
        tester,
      ).where((p) => !p.isFirst && !p.isLast).toList();

      final a = fresh.firstWhere((p) => p.isLeft);
      final b = walked.firstWhere((p) => p.isLeft);
      expect(
        b.shouldRepaint(a),
        isFalse,
        reason: 'progress leaked into the line',
      );
    });
  });

  group('the line is not announced', () {
    test('the painter contributes no semantics node', () {
      // This is the mechanism, not a proxy for it: a `CustomPainter` adds a
      // semantics node only when it supplies a `semanticsBuilder`, and this
      // one must never supply any. Wrapping the `CustomPaint` in
      // `ExcludeSemantics` would be the wrong fix — its child is the marker,
      // so that would silence the labels a screen reader actually needs.
      const painter = TrailPathPainter(
        isLeft: true,
        isFirst: false,
        isLast: false,
      );
      expect(painter.semanticsBuilder, isNull);
    });

    testWidgets('the trail announces exactly its nodes, and nothing more', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // One spoken node per marker. If the line had contributed a semantics
      // node of its own, the trail would announce more than it has markers.
      final spoken = find.bySemanticsLabel(
        RegExp(r'^Node '),
        skipOffstage: false,
      );
      expect(spoken.evaluate(), hasLength(paintersOn(tester).length));

      handle.dispose();
    });
  });

  group('the line is there before progress is known', () {
    testWidgets('it paints on the first frame, before the database resolves', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      // Deliberately no settle: this is the first frame, when progress is
      // still an `AsyncValue.loading` and no node has a state yet.
      await tester.pump();

      final painters = paintersOn(tester);
      expect(
        painters,
        isNotEmpty,
        reason: 'the trail drew its nodes but not the line linking them',
      );

      // And it is the finished line, not a stub waiting on state: every row
      // except the first already has its incoming curve.
      expect(painters.skip(1).every((p) => !p.isFirst), isTrue);
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
