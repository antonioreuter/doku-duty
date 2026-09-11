import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/data/pack_source.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';

/// Serves a string as if it were the bundled asset.
class _StringBundle extends CachingAssetBundle {
  _StringBundle(this.contents);

  final Map<String, String> contents;

  @override
  Future<ByteData> load(String key) async {
    final value = contents[key];
    if (value == null) throw FlutterError('asset not found: $key');
    return ByteData.sublistView(Uint8List.fromList(value.codeUnits));
  }
}

void main() {
  const assetPath = BundledPackSource.defaultAssetPath;
  final packJson = File(assetPath).readAsStringSync();

  late AppDatabase db;
  late PackRepository packs;
  final reported = <Object>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    packs = PackRepository(db);
    reported.clear();
  });
  tearDown(() => db.close());

  PackInstaller installerFor(PackSource source) => PackInstaller(
    source: source,
    packs: packs,
    report: (error, stack) => reported.add(error),
  );

  PackSource bundled([String? json]) => BundledPackSource(
    bundle: _StringBundle(<String, String>{assetPath: json ?? packJson}),
  );

  group('first launch', () {
    test('the bundled pack installs and its puzzles are readable', () async {
      expect(
        await installerFor(bundled()).install(),
        PackInstallOutcome.installed,
      );

      expect(await packs.packVersion('frontier-1'), 1);
      for (final rank in Rank.values) {
        final puzzle = await packs.nextUnsolved(rank);
        expect(puzzle, isNotNull, reason: rank.name);
        expect(puzzle!.rank, rank);
        expect(puzzle.clues, hasLength(81));
        expect(puzzle.solution, hasLength(81));
      }
      expect(reported, isEmpty);
    });

    test('every puzzle in the file reaches the database', () async {
      await installerFor(bundled()).install();
      final pack = (Pack.parse(packJson) as ParsedPack).pack;

      final rows = await db
          .customSelect('SELECT COUNT(*) c FROM puzzles')
          .get();
      expect(rows.single.read<int>('c'), pack.puzzles.length);
    });
  });

  group('a later launch', () {
    test('reinstalls nothing and forgets no solved puzzle', () async {
      final installer = installerFor(bundled());
      await installer.install();

      final first = await packs.nextUnsolved(Rank.deputy);
      await packs.markSolved(first!.id);

      expect(await installer.install(), PackInstallOutcome.alreadyInstalled);
      expect(await packs.isSolved(first.id), isTrue);
      expect((await packs.nextUnsolved(Rank.deputy))!.id, isNot(first.id));
    });

    test('an older pack version is not installed over a newer one', () async {
      await packs.installPack(
        packId: 'frontier-1',
        version: 9,
        puzzles: const [],
      );
      expect(
        await installerFor(bundled()).install(),
        PackInstallOutcome.alreadyInstalled,
      );
      expect(await packs.packVersion('frontier-1'), 9);
    });
  });

  group('nothing half-installed', () {
    // The write is one transaction, so a kill part-way leaves the version
    // unrecorded and the next launch installs it again — rather than trusting a
    // pack that is missing most of its puzzles.
    test(
      'a write that fails records no version and stores no puzzle',
      () async {
        await expectLater(
          packs.installPack(
            packId: 'frontier-1',
            version: 1,
            puzzles: <StoredPuzzle>[
              StoredPuzzle(
                id: 'ok',
                clues: '.' * 81,
                solution: '1' * 81,
                rank: Rank.deputy,
                seed: 1,
              ),
              // Rejected by the column's own length constraint, part-way in.
              StoredPuzzle(
                id: 'bad',
                clues: 'too short',
                solution: '1' * 81,
                rank: Rank.deputy,
                seed: 2,
              ),
            ],
          ),
          throwsA(anything),
        );

        expect(await packs.packVersion('frontier-1'), isNull);
        final rows = await db
            .customSelect('SELECT COUNT(*) c FROM puzzles')
            .get();
        expect(rows.single.read<int>('c'), 0);
      },
    );

    test('a failed install is reported and answered, not thrown', () async {
      final broken = bundled(
        packJson.replaceFirst('"clues": "', '"clues": "x'),
      );
      final outcome = await installerFor(broken).install();

      expect(outcome, PackInstallOutcome.unreadable);
      expect(reported, hasLength(1));
      expect(await packs.packVersion('frontier-1'), isNull);
    });

    test('a missing asset is an answer, not an exception', () async {
      final absent = BundledPackSource(
        bundle: _StringBundle(const <String, String>{}),
      );
      expect(
        await installerFor(absent).install(),
        PackInstallOutcome.unreadable,
      );
      expect(reported, hasLength(1));
    });
  });

  // Constraint 1: running out is an ordinary condition, not a wall.
  group('running out is not a wall', () {
    test('exhausting a rank reports absence, not an error', () async {
      await installerFor(bundled()).install();

      var solved = 0;
      while (true) {
        final next = await packs.nextUnsolved(Rank.legend);
        if (next == null) break;
        await packs.markSolved(next.id);
        solved++;
      }

      expect(solved, greaterThan(0));
      expect(await packs.nextUnsolved(Rank.legend), isNull);
      expect(
        () async => packs.nextUnsolved(Rank.legend),
        returnsNormally,
        reason: 'absence is a normal result, never an error',
      );
    });

    test('the other ranks are untouched when one is exhausted', () async {
      await installerFor(bundled()).install();

      while (true) {
        final next = await packs.nextUnsolved(Rank.legend);
        if (next == null) break;
        await packs.markSolved(next.id);
      }

      for (final rank in Rank.values) {
        if (rank == Rank.legend) continue;
        expect(await packs.nextUnsolved(rank), isNotNull, reason: rank.name);
      }
    });
  });
}
