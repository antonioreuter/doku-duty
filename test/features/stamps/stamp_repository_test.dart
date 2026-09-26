import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/stamps/data/stamp_repository.dart';
import 'package:doku_duty/features/stamps/domain/earning.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late StampRepository stamps;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    stamps = StampRepository(db);
  });
  tearDown(() => db.close());

  const day = Earning(key: 'daily:2026-04-09', amount: 2);
  const perfect = Earning(key: 'perfect:p-1', amount: 3);

  test('a new player has a balance of 0, not nothing', () async {
    expect(await stamps.balance(), 0);
  });

  test('the balance is the sum of the earnings', () async {
    await stamps.earn(<Earning>[day, perfect]);
    expect(await stamps.balance(), 5);
  });

  test('earning the same event twice keeps one row and pays once', () async {
    await stamps.earn(<Earning>[day]);
    await stamps.earn(<Earning>[day]);

    expect(await db.select(db.earnings).get(), hasLength(1));
    expect(await stamps.balance(), 2);
  });

  test('earn reports only what it newly wrote', () async {
    // What the notice shows: an event already paid is not paid again, so it
    // must not be announced again either.
    expect(await stamps.earn(<Earning>[day]), <Earning>[day]);
    expect(await stamps.earn(<Earning>[day, perfect]), <Earning>[perfect]);
  });

  test('the balance survives closing and reopening the file', () async {
    final dir = Directory.systemTemp.createTempSync('stamps');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/stamps.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await StampRepository(first).earn(<Earning>[day, perfect]);
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await StampRepository(reopened).balance(), 5);
  });
}
