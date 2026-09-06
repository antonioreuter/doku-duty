import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';

import 'support/fixture_pack.dart';

void main() {
  test('the fixture pack installs one puzzle at every rank', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final packs = PackRepository(db);

    await installFixturePack(packs);

    for (final rank in Rank.values) {
      expect(await packs.nextUnsolved(rank), isNotNull, reason: rank.name);
    }
    expect(await packs.packVersion(fixturePackId), 1);
  });
}
