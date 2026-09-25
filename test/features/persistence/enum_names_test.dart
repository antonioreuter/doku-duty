import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';

import 'support/fixture_pack.dart';

/// `Rank` and `Technique` moved to `lib/features/puzzle_engine/domain/` with
/// `add-puzzle-engine`. Drift writes them as `enum.name`, so the move is only
/// safe while every stored name is byte-for-byte what it was — a rename would
/// invalidate every saved statistic without touching a line of persistence
/// code, and nothing else in the suite would notice.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('the stored rank names are unchanged by the move', () {
    expect(Rank.values.map((rank) => rank.name), <String>[
      'greenhorn',
      'deputy',
      'sheriff',
      'marshal',
      'ranger',
      'legend',
    ]);
  });

  test('the stored technique names are unchanged by the move', () {
    expect(Technique.values.map((technique) => technique.name), <String>[
      'fullHouse',
      'nakedSingle',
      'cageCombination',
      'hiddenSingle',
      'nakedPair',
      'pointingPair',
      'fortyFiveRule',
      'boxLineReduction',
      'nakedTriple',
      'hiddenPair',
      'xWing',
      'swordfish',
      'xyWing',
      'simpleChain',
    ]);
  });

  test('a rank written as text comes back as the same rank', () async {
    final packs = PackRepository(db);
    await packs.installPack(
      packId: fixturePackId,
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values) fixturePuzzle('p-${rank.name}', rank),
      ],
    );

    for (final rank in Rank.values) {
      final stored = await packs.puzzleById('p-${rank.name}');
      expect(stored!.rank, rank);
    }

    final raw = await db
        .customSelect('SELECT id, rank FROM puzzles ORDER BY id')
        .get();
    expect(
      raw.map((row) => row.read<String>('rank')).toSet(),
      Rank.values.map((rank) => rank.name).toSet(),
    );
  });

  test(
    'a technique written as text comes back as the same technique',
    () async {
      final stats = StatisticsRepository(db);
      for (final technique in Technique.values) {
        await stats.recordSolve(
          techniquesRequired: <Technique>{technique},
          timeTaken: const Duration(minutes: 1),
          attempt: Attempt.fresh,
        );
      }

      for (final technique in Technique.values) {
        expect(await stats.countFor(technique), 1);
      }

      final raw = await db
          .customSelect('SELECT technique FROM technique_stats')
          .get();
      expect(
        raw.map((row) => row.read<String>('technique')).toSet(),
        Technique.values.map((technique) => technique.name).toSet(),
      );
    },
  );
}
