import 'dart:io';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/season.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/presentation/trail_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The **trail** at two points, and what a **season** repaint may touch.
///
/// The node states are made of a colour, a size, and a glyph together — which
/// is precisely the kind of thing a unit test cannot see going wrong. A golden
/// catches the **current node** quietly stopping being larger, a **chest node**
/// losing its own colour, or a state becoming carried by colour alone.
void main() {
  setUpAll(_loadFont);

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'golden',
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

  Future<void> pumpAndMatch(WidgetTester tester, String name) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TrailScreen),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('a new player — node 1 current, everything ahead unreached', (
    tester,
  ) async {
    await pumpAndMatch(tester, 'trail_new_player');
  });

  testWidgets('mid-season — completions behind, a chest in view', (
    tester,
  ) async {
    // Node 12, so the trail shows completions behind, the current node, the
    // first **chest node** at 11 completed, and unreached nodes ahead.
    await walkTo(12);
    await pumpAndMatch(tester, 'trail_mid_season');
  });

  group('a season repaint touches surfaces only (constraint 4, D-55)', () {
    test('only the two surface tokens are repaintable', () {
      expect(
        PaletteToken.values.where((t) => t.isSurface).toList(),
        <PaletteToken>[PaletteToken.bone, PaletteToken.sand],
      );
      expect(PaletteToken.stateColours, hasLength(6));
    });

    test('a season has nowhere to put a state colour', () {
      // The guarantee is structural. `SeasonTheme` has a field for each of the
      // two surfaces and none of any kind for a state colour, so a **season**
      // document asking for a different completion green is not refused so
      // much as unable to ask — and every state colour a **node** uses comes
      // back unchanged.
      const repaint = SeasonTheme(
        id: 'copper-hollow',
        name: 'Copper Hollow',
        bone: 0xEFE3D0,
        sand: 0xD8C6A0,
      );
      const palette = SeasonPalette(repaint);

      expect(palette.valueOf(PaletteToken.bone), 0xEFE3D0);
      expect(palette.valueOf(PaletteToken.sand), 0xD8C6A0);
      for (final token in PaletteToken.stateColours) {
        expect(
          palette.valueOf(token),
          token.value,
          reason: '${token.name} was repainted by a season',
        );
      }
    });

    test('a published palette reaches the season, state colours do not', () {
      final parsed = SeasonDefinition.fromJson(<String, Object?>{
        'id': 'copper-hollow',
        'name': 'Copper Hollow',
        'starts_at': '2026-11-02T00:00:00Z',
        'length_days': 42,
        'palette': <String, Object?>{
          'bone': '#EFE3D0',
          'sand': 0xD8C6A0,
          // Offered by a document that read the design doc and not D-55.
          // There is no field for it, so it lands nowhere.
          'cactus_green': '#123456',
        },
        'nodes': <Object?>[
          for (final node in SeasonOne.season.nodes) node.toJson(),
        ],
      });

      final season = (parsed as ValidSeason).season;
      expect(season.theme.bone, 0xEFE3D0);
      expect(season.theme.sand, 0xD8C6A0);
      final palette = SeasonPalette(season.theme);
      for (final token in PaletteToken.stateColours) {
        expect(palette.valueOf(token), token.value, reason: token.name);
      }
    });

    test('a season with no palette keeps the default surfaces', () {
      expect(SeasonOne.season.theme.bone, SeasonTheme.defaultTheme.bone);
      expect(SeasonOne.season.theme.sand, SeasonTheme.defaultTheme.sand);
    });
  });
}

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
