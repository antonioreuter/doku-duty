import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/puzzle_engine/data/pack_source.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// A **pack** that takes a moment to arrive.
///
/// The delay is the whole point: it widens the window in which the first
/// screen could read an empty table, so a reader that does not wait for the
/// install fails here every time rather than on an unlucky morning.
class _SlowPackSource implements PackSource {
  _SlowPackSource(this.delay);

  final Duration delay;
  var reads = 0;

  static final String _json = Pack(
    packId: 'frontier-1',
    version: 1,
    puzzles: <PackPuzzle>[
      for (final rank in Rank.values)
        PackPuzzle(
          id: 'q-${rank.name}',
          clues: _clues,
          solution: _solution,
          rank: rank,
          seed: rank.index,
        ),
    ],
  ).encode();

  @override
  Future<PackParseResult> read() async {
    reads++;
    await Future<void>.delayed(delay);
    return Pack.parse(_json);
  }
}

/// Advances past the install's delay and then settles.
///
/// `pumpAndSettle` alone is not enough: a pending timer schedules no frame, so
/// it returns without the clock having moved.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late _SlowPackSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = _SlowPackSource(const Duration(milliseconds: 80));
  });
  tearDown(() => db.close());

  Widget app() => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packSourceProvider.overrideWithValue(source),
    ],
    child: const DokuDutyApp(),
  );

  // The bug: the install and the first screen both start after the first frame,
  // so a rank queried mid-install came back empty. The picker reported nothing
  // left at that rank and never asked again — on a fresh install, with a full
  // pack sitting in the binary.
  testWidgets('a fresh install never reports a rank as empty', (tester) async {
    await tester.pumpWidget(app());

    // Every frame from the first to the last: at no point may the picker claim
    // a rank is exhausted. Before the pack lands it knows nothing, and knowing
    // nothing is not the same as knowing there is nothing.
    for (var frame = 0; frame < 12; frame++) {
      expect(
        find.text('Nothing left here for now'),
        findsNothing,
        reason: 'claimed a rank was empty on frame $frame',
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await _settle(tester);

    expect(find.text('Nothing left here for now'), findsNothing);
    for (final rank in Rank.values) {
      expect(find.text('${_titled(rank.name)} rank'), findsOneWidget);
    }
  });

  testWidgets('every rank is playable once the pack has landed', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await _settle(tester);

    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey<String>('rank-greenhorn')),
    );
    expect(tile.onTap, isNotNull, reason: 'the rank is playable');

    await tester.tap(find.byKey(const ValueKey<String>('rank-greenhorn')));
    await tester.pumpAndSettle();

    expect(find.byType(PuzzleGrid), findsOneWidget);
  });

  // A FutureProvider caches, so however many readers await the install, it
  // happens once. Two installs racing each other is the bug wearing a hat.
  testWidgets('the pack is installed exactly once', (tester) async {
    await tester.pumpWidget(app());
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey<String>('rank-deputy')));
    await _settle(tester);

    expect(source.reads, 1);
  });

  testWidgets('a rank with nothing in the pack still reports it', (
    tester,
  ) async {
    // The empty answer must survive the fix: a rank that genuinely has no
    // puzzle is still an ordinary absence, not a lock (constraint 1).
    final packs = ProviderContainer(
      overrides: [
        flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
        appDatabaseProvider.overrideWith((ref) => db),
        packSourceProvider.overrideWithValue(
          _EmptyForOneRank(const Duration(milliseconds: 10)),
        ),
      ],
    );
    addTearDown(packs.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: packs, child: const DokuDutyApp()),
    );
    await _settle(tester);

    expect(find.text('Nothing left here for now'), findsOneWidget);
    expect(find.text('Legend rank'), findsOneWidget);
  });
}

/// A pack holding every **rank** but Legend.
class _EmptyForOneRank implements PackSource {
  _EmptyForOneRank(this.delay);

  final Duration delay;

  @override
  Future<PackParseResult> read() async {
    await Future<void>.delayed(delay);
    return Pack.parse(
      Pack(
        packId: 'frontier-1',
        version: 1,
        puzzles: <PackPuzzle>[
          for (final rank in Rank.values)
            if (rank != Rank.legend)
              PackPuzzle(
                id: 'q-${rank.name}',
                clues: _clues,
                solution: _solution,
                rank: rank,
                seed: rank.index,
              ),
        ],
      ).encode(),
    );
  }
}

String _titled(String name) => '${name[0].toUpperCase()}${name.substring(1)}';
