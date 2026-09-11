import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/data/pack_source.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';

/// The half of the shipped **pack** a host test cannot reach.
///
/// Host tests read the file from disk, so a pack that is generated, committed,
/// and then never bundled passes every one of them and ships an app with no
/// content. Only a real bundle on a real platform can tell — the same shape of
/// defect D-77 records, where 227 green host tests hid an app that could not
/// open its database on Android.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Kept in step with `tool/generate_pack.dart` and the host audit.
  const expectedPuzzles = 305;

  testWidgets('the pack is inside the app and reads back whole', (
    tester,
  ) async {
    final result = await const BundledPackSource().read();

    expect(
      result,
      isA<ParsedPack>(),
      reason: result is InvalidPack
          ? 'the bundled pack is unusable: ${result.description}'
          : '',
    );
    final pack = (result as ParsedPack).pack;
    expect(pack.packId, 'frontier-1');
    expect(pack.puzzles, hasLength(expectedPuzzles));
  });

  testWidgets('it installs into the real database and every rank has content', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final packs = PackRepository(db);

    final outcome = await PackInstaller(
      source: const BundledPackSource(),
      packs: packs,
      report: (error, stack) => fail('install reported $error'),
    ).install();

    expect(outcome, PackInstallOutcome.installed);
    for (final rank in Rank.values) {
      final puzzle = await packs.nextUnsolved(rank);
      expect(puzzle, isNotNull, reason: 'no ${rank.name} puzzle on device');
      expect(puzzle!.clues.length, 81);
    }

    final rows = await db.customSelect('SELECT COUNT(*) c FROM puzzles').get();
    expect(rows.single.read<int>('c'), expectedPuzzles);
  });
}
