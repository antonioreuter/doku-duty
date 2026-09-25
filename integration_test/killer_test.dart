import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';

import '../test/features/puzzle_engine/support/killer.dart';
import '../test/support/trail_navigation.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// A **variant node** on a real platform: a **killer** board, opened from the
/// **trail**, drawn inside the safe area, and cleaned the way D-130 says.
///
/// ```
/// flutter test integration_test/killer_test.dart -d <device> --flavor dev
/// ```
///
/// What a person still has to check by eye: the dashed outlines and sums read
/// at arm's length on the smallest phone, and the notes below the sum band are
/// legible at 8.3px (D-129).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late File file;

  // Cage 'i' of the reference shape joins r3c2 and r4c1, which share no row,
  // column or block — only the **cage** makes them **peer**s.
  const placed = 19;
  const mate = 27;
  final variant = SeasonOne.season.nodes.firstWhere(
    (n) => n.type == NodeType.variant,
  );
  final puzzleId = 'killer-${variant.rank!.name}';

  setUp(() async {
    file = File(
      '${Directory.systemTemp.createTempSync('killer').path}/killer.sqlite',
    );
    db = AppDatabase(NativeDatabase(file));
    await PackRepository(db).installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[
        StoredPuzzle(
          id: puzzleId,
          clues: '.' * 81,
          solution: _solution,
          rank: variant.rank!,
          seed: 1,
          cages: jsonEncode(referenceKillerCages(_solution).toJson()),
        ),
      ],
    );
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < variant.position; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }
    // The candidate **auto-cleanup** has to reach, marked before the board
    // opens so it comes back through real storage.
    await NoteRepository(db).put(
      puzzleId: puzzleId,
      cell: mate,
      digit: 4,
      kind: NoteKind.settled,
      origin: NoteOrigin.manual,
    );
  });
  tearDown(() async {
    await db.close();
    if (file.existsSync()) file.deleteSync();
  });

  Widget app() => ProviderScope(
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

  testWidgets('a variant node opens a killer board inside the safe area', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openTrailNode(tester, variant.position);

    final grid = find.byType(PuzzleGrid);
    expect(grid, findsOneWidget);
    expect(tester.widget<PuzzleGrid>(grid).board.cages, isNotNull);

    final view = tester.view;
    final rect = tester.getRect(grid);
    final topInset = view.padding.top / view.devicePixelRatio;
    final width = view.physicalSize.width / view.devicePixelRatio;
    expect(rect.top, greaterThanOrEqualTo(topInset));
    expect(rect.right, lessThanOrEqualTo(width + 0.5));
    debugPrint(
      'killer grid ${rect.width.toStringAsFixed(1)}pt wide, cell '
      '${(rect.width / 9).toStringAsFixed(1)}pt, top inset '
      '${topInset.toStringAsFixed(1)}pt',
    );
  });

  testWidgets('a value placed in a cage cleans its cage mate (D-130)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openTrailNode(tester, variant.position);

    final grid = find.byType(PuzzleGrid);
    expect(
      tester.widget<PuzzleGrid>(grid).board.notesAt(mate).contains(4),
      isTrue,
    );

    final rect = tester.getRect(grid);
    final metrics = GridMetrics.fit(rect.size);
    await tester.tapAt(rect.topLeft + metrics.cellRect(placed).center);
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byType(NumberPad), matching: find.text('4')),
    );
    await tester.pumpAndSettle();

    final board = tester.widget<PuzzleGrid>(grid).board;
    expect(board.digitAt(placed), 4);
    expect(board.notesAt(mate).contains(4), isFalse);
  });
}
