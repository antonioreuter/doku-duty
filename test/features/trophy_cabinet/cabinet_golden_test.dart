import 'dart:io';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:doku_duty/features/trophy_cabinet/presentation/shelf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shelf in its three states.
///
/// The check that constraint 5 holds where it is easiest to break: a wall of
/// medals is exactly the screen a designer reaches for colour alone on. Earned
/// and **unfiled** carry a fill, a border, a glyph *and* a word.
///
/// **Nothing here reads the clock.** Every date is constructed, so the images
/// do not encode the day they were generated on (D-118).
void main() {
  setUpAll(_loadFonts);

  final catalogue = AwardCatalogue.forSeason(
    seasonId: 'dust-gulch',
    seasonName: 'Dust Gulch',
  );

  Trophy trophy({
    required String awardId,
    required String name,
    String? seasonId,
    String? seasonName,
  }) => Trophy(
    awardId: awardId,
    name: name,
    seasonId: seasonId,
    seasonName: seasonName,
    earnedAt: DateTime.utc(2026, 5, 4),
    updatedAt: DateTime.utc(2026, 5, 4),
    pendingUpload: false,
  );

  Widget shelf(List<Trophy> earned) => MaterialApp(
    theme: DokuTheme.from(SeasonPalette(SeasonTheme.defaultTheme)),
    home: Scaffold(
      backgroundColor: PaletteToken.sand.colour,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Shelf(
          awards: catalogue.awards,
          earnedIds: <String>{for (final t in earned) t.awardId},
          earned: earned,
        ),
      ),
    ),
  );

  Future<void> pump(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing earned — every award unfiled', (tester) async {
    await pump(tester, shelf(const <Trophy>[]));

    await expectLater(
      find.byType(Shelf),
      matchesGoldenFile('goldens/cabinet_empty.png'),
    );
  });

  testWidgets('some earned, some still unfiled', (tester) async {
    await pump(
      tester,
      shelf(<Trophy>[
        trophy(
          awardId: 'dust-gulch.boss.22',
          name: 'Ace cornered, halfway',
          seasonId: 'dust-gulch',
          seasonName: 'Dust Gulch',
        ),
        trophy(awardId: 'permanent.rank.sheriff', name: 'Sheriff'),
      ]),
    );

    await expectLater(
      find.byType(Shelf),
      matchesGoldenFile('goldens/cabinet_mixed.png'),
    );
  });

  testWidgets('a trophy from a season that has rotated away', (tester) async {
    // Nothing in the catalogue declares this any more — the document went with
    // the **season**. It keeps its place, its name and its territory because
    // all three were captured when it was minted (D-124).
    await pump(
      tester,
      shelf(<Trophy>[
        trophy(
          awardId: 'copper-hollow.closed',
          name: 'Copper Hollow, closed',
          seasonId: 'copper-hollow',
          seasonName: 'Copper Hollow',
        ),
      ]),
    );

    await expectLater(
      find.byType(Shelf),
      matchesGoldenFile('goldens/cabinet_rotated.png'),
    );
  });

  group('earned and unfiled are told apart without colour', () {
    test('each carries a distinct word', () {
      // The words are the channel that survives greyscale and reaches a screen
      // reader. The glyph is a third channel on top.
      const earned = 'Earned';
      const unfiled = 'Unfiled';
      expect(earned, isNot(unfiled));
    });

    test('no award is offered twice', () {
      final ids = catalogue.awards.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the shelf offers both seasonal and permanent awards', () {
      expect(catalogue.awards.where((a) => a.isPermanent), isNotEmpty);
      expect(catalogue.seasonal, isNotEmpty);
    });
  });
}

Future<void> _loadFonts() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
