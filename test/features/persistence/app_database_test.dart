import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the database', () {
    test('opens at the current schema version', () async {
      // Bumped to 2 by add-remote-config, which added the config cache table,
      // and to 3 by add-mistake-model, which added the **mistake** tally to a
      // save. Asserted by number rather than loosely, so a schema change has
      // to change a test that names the version — and, with it, produce a
      // snapshot and a migration.
      expect(db.schemaVersion, 3);
      // Force the connection open — schemaVersion alone is a Dart getter and
      // would pass without sqlite ever being touched.
      await db.customSelect('SELECT 1').get();
    });

    test('closes cleanly', () async {
      await db.customSelect('SELECT 1').get();
      await expectLater(db.close(), completes);
      // Re-open for the tearDown to close without error.
      db = AppDatabase(NativeDatabase.memory());
    });
  });
}
