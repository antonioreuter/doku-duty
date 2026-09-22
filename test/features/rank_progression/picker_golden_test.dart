import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/grid_input/presentation/free_play_screen.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
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
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';

import '../../support/home_navigation.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<AppDatabase> _seeded() async {
  final db = AppDatabase(NativeDatabase.memory());
  await PackRepository(db).installPack(
    packId: 'test',
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

/// The picker at three points on the ladder.
///
/// The mark is the thing under test and it is made of words, so a golden is
/// what catches it changing: a subtitle that grew a second line, a mark that
/// stopped clearing, or a colour quietly becoming the signal instead of the
/// sentence (constraint 5).
void main() {
  setUpAll(_loadFont);

  Future<void> pumpAndMatch(
    WidgetTester tester,
    AppDatabase db,
    String name,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    // The app opens on the **trail**; **free play** is the other tab (D-111).
    await goToFreePlay(tester);
    await expectLater(
      find.byType(FreePlayScreen),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('a new player — every rank above Greenhorn marked', (
    tester,
  ) async {
    final db = await _seeded();
    addTearDown(db.close);
    await pumpAndMatch(tester, db, 'picker_new_player');
  });

  testWidgets('mid-ladder — the marks below have cleared', (tester) async {
    final db = await _seeded();
    addTearDown(db.close);
    await ProgressionRepository(db).record(
      puzzleId: 'q-${Rank.sheriff.name}',
      techniquesRequired: <Technique>{Technique.nakedPair},
      timeTaken: const Duration(minutes: 4),
      attempt: Attempt.fresh,
    );
    await pumpAndMatch(tester, db, 'picker_mid_ladder');
  });

  testWidgets('at Legend — nothing marked at all', (tester) async {
    final db = await _seeded();
    addTearDown(db.close);
    await ProgressionRepository(db).record(
      puzzleId: 'q-${Rank.legend.name}',
      techniquesRequired: <Technique>{Technique.simpleChain},
      timeTaken: const Duration(minutes: 20),
      attempt: Attempt.fresh,
    );
    await pumpAndMatch(tester, db, 'picker_legend');
  });
}
