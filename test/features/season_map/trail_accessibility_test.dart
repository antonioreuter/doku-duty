import 'dart:io';

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
import 'package:doku_duty/features/season_map/presentation/trail_node_marker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/trail_navigation.dart';

/// The **trail** at the reader's text sizes, and without colour.
///
/// Constraint 5 is the one under test: no state on this screen may be carried
/// by colour alone. Every **node** says what it is and where the player stands
/// in words, and those words have to survive both a screen reader and the
/// largest text a player can ask for on the smallest phone the app targets.
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

  Future<void> walkTo(int position) async {
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < position; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
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

        await walkTo(4);
        await tester.pumpWidget(app(scale));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'the trail overflowed at ${scale}x',
        );

        // On screen is not enough — the words have to be all there. A header
        // cut to "Trail progre…" is a header that stopped saying what it means.
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

    testWidgets('the navigation grows with the text rather than clipping', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      final atOne = tester.getSize(
        find.byKey(const ValueKey<String>('home-nav')),
      );

      await tester.pumpWidget(app(3));
      await tester.pumpAndSettle();
      final atThree = tester.getSize(
        find.byKey(const ValueKey<String>('home-nav')),
      );

      // Material's own NavigationBar has a fixed height and overflowed here by
      // 139 pixels at 4x. The replacement grows instead — the same answer the
      // **tools row** gave on the pad (D-100).
      expect(atThree.height, greaterThan(atOne.height));
    });
  });

  group('a screen reader', () {
    testWidgets('every node announces its number, type, and state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await walkTo(4);
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();

      // The label is the whole announcement, and it is the only route a
      // screen reader has to a node's state. Asserted on its own rather than
      // through `matchesSemantics`, which also pins framework flags this test
      // has no opinion about.
      expect(
        tester.getSemantics(trailNode(1)).label,
        'Node 1, Puzzle, Completed',
      );
      expect(
        tester.getSemantics(trailNode(5)).label,
        'Node 5, Puzzle, Not yet reached',
      );
      // Completed is reachable, not yet reached is not — and the difference is
      // carried as a button rather than only as a colour.
      expect(
        tester.getSemantics(trailNode(1)).flagsCollection.isButton,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('a node above the players rank says so', (tester) async {
      final handle = tester.ensureSemantics();
      await walkTo(9);
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      // The list builds lazily, so node 9 has to be walked to before a reader
      // could reach it either.
      await scrollToNode(tester, 9);

      expect(
        tester.getSemantics(trailNode(9)).label,
        'Node 9, Puzzle, Current, Above your rank',
      );
      handle.dispose();
    });

    testWidgets('the navigation names both destinations', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();

      final trail = tester.getSemantics(
        find.byKey(const ValueKey<String>('nav-trail')),
      );
      final freePlay = tester.getSemantics(
        find.byKey(const ValueKey<String>('nav-free-play')),
      );

      expect(trail.label, 'Trail');
      expect(freePlay.label, 'Free play');
      // Which tab is open reaches a reader as a flag, so it is not carried by
      // the gold icon alone (constraint 5).
      // Which tab is open differs between the two as a semantic flag, so it is
      // not carried by the gold icon alone (constraint 5). Asserted as a
      // difference rather than against a named constant, because the flag is a
      // tristate whose type the framework does not export.
      expect(
        trail.flagsCollection.isSelected,
        isNot(freePlay.flagsCollection.isSelected),
      );
      handle.dispose();
    });
  });

  group('colour removed', () {
    testWidgets('every state is still distinguishable', (tester) async {
      await walkTo(4);
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();

      TrailNodeMarker at(int p) => tester.widget<TrailNodeMarker>(trailNode(p));

      // Three states, three different glyphs, and a size that differs for the
      // current one. None of that is colour.
      expect(at(1).state, NodeState.completed);
      expect(at(4).state, NodeState.current);
      expect(at(5).state, NodeState.notYetReached);
      expect(<String>{
        at(1).semanticLabel,
        at(4).semanticLabel,
        at(5).semanticLabel,
      }, hasLength(3));
    });

    testWidgets('a chest and a boss stay identifiable without colour', (
      tester,
    ) async {
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();

      final season = SeasonOne.season;
      final chest = season.nodes.firstWhere((n) => n.type == NodeType.chest);
      final boss = season.nodes.firstWhere((n) => n.type == NodeType.boss);

      await scrollToNode(tester, chest.position);
      expect(
        tester.widget<TrailNodeMarker>(trailNode(chest.position)).semanticLabel,
        contains('Chest'),
      );
      await scrollToNode(tester, boss.position);
      expect(
        tester.widget<TrailNodeMarker>(trailNode(boss.position)).semanticLabel,
        contains('Boss'),
      );
    });
  });

  group('reduce motion', () {
    test('the trail has no motion to silence', () {
      // Asserted rather than assumed. The **trail** animates nothing — no
      // node reveal, no path draw, no celebration — so there is nothing for
      // reduce-effects or the OS setting to turn off. A later change adding
      // motion here has to make it respect both, and this test is where that
      // omission shows up.
      final screen = File(
        'lib/features/season_map/presentation/trail_screen.dart',
      ).readAsStringSync();
      final marker = File(
        'lib/features/season_map/presentation/trail_node_marker.dart',
      ).readAsStringSync();
      for (final source in <String>[screen, marker]) {
        for (final animation in const <String>[
          'AnimatedContainer',
          'AnimationController',
          'TweenAnimationBuilder',
          'AnimatedOpacity',
          'Hero(',
        ]) {
          expect(
            source,
            isNot(contains(animation)),
            reason: '$animation on the trail must respect reduce effects',
          );
        }
      }
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
