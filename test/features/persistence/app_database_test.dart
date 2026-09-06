import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the database', () {
    test('opens at schema version 1', () async {
      expect(db.schemaVersion, 1);
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
