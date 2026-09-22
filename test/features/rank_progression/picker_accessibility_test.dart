import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Widget _app(AppDatabase db, double scale) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
  child: ProviderScope(
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

void main() {
  // The pad overflowed at the reader's largest text before (D-84, D-93), and
  // the mark adds a second line to a tile that had at most one. This is the
  // same failure waiting in a new place.
  group('the mark at the reader\'s text sizes', () {
    for (final scale in <double>[1, 2, 3, 4, 5]) {
      testWidgets('nothing overflows or truncates at ${scale}x', (
        tester,
      ) async {
        // The smallest phone the app targets (D-84).
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final db = await _seeded();
        addTearDown(db.close);
        await ProgressionRepository(db).record(
          puzzleId: 'q-${Rank.deputy.name}',
          techniquesRequired: <Technique>{Technique.hiddenSingle},
          timeTaken: const Duration(minutes: 2),
          attempt: Attempt.fresh,
        );

        await tester.pumpWidget(_app(db, scale));
        await tester.pumpAndSettle();

        await goToFreePlay(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'the picker overflowed at ${scale}x',
        );

        // On screen is not enough — the words have to be all there. A mark cut
        // to "Above your…" is a mark that stopped saying what it means.
        for (final element
            in find.textContaining('Above your rank').evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: 'the mark was truncated at ${scale}x',
          );
        }
      });
    }
  });

  testWidgets('the mark reaches a screen reader as the words it shows', (
    tester,
  ) async {
    // Disposed inside the test body, not in a tear-down: the framework checks
    // for a leaked handle before tear-downs run.
    final handle = tester.ensureSemantics();

    final db = await _seeded();
    addTearDown(db.close);

    await tester.pumpWidget(_app(db, 1));
    await tester.pumpAndSettle();

    await goToFreePlay(tester);

    // One string serves both, so the label a reader hears and the label a
    // player sees cannot drift apart (constraint 5).
    expect(find.bySemanticsLabel(RegExp('Above your rank')), findsWidgets);
    handle.dispose();
  });

  testWidgets('the mark brings no motion with it', (tester) async {
    final db = await _seeded();
    addTearDown(db.close);

    await tester.pumpWidget(_app(db, 1));
    await tester.pumpAndSettle();

    await goToFreePlay(tester);

    // Asserted rather than assumed. Nothing about a **rank** mark animates, so
    // there is nothing for **reduce effects** to silence — and if that ever
    // stops being true, this fails and the motion has to be given a switch.
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'something on the picker is animating',
    );
  });
}
