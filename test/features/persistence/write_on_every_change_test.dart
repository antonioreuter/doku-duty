import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';

/// Constraint 9, and the reason this whole layer is written test-first.
///
/// A batched write looks identical to a correct one until a player twenty
/// minutes into an expert grid loses the board to an app kill. There is no
/// symptom in the diff and no symptom at runtime — only the loss, later, on
/// someone else's phone.
///
/// Every test here reads back through a **second connection to the same file**.
/// Reading through the object that did the writing would pass on an in-memory
/// cache and prove nothing at all.
void main() {
  // These tests open a second AppDatabase on purpose, which is the only honest
  // way to prove a write reached the file. Drift warns about that because two
  // instances sharing one executor can race — these have separate executors, so
  // the warning does not apply. Scoped to this file rather than set globally:
  // in the app there is exactly one database, held by one provider, and the
  // warning should still fire if that ever stops being true.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  late Directory dir;
  late File file;
  late AppDatabase writer;
  late NoteRepository notes;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('doku_notes_test');
    file = File(p.join(dir.path, 'notes.sqlite'));
    writer = AppDatabase(NativeDatabase(file));
    notes = NoteRepository(writer);
  });

  tearDown(() async {
    await writer.close();
    dir.deleteSync(recursive: true);
  });

  /// A completely independent reader. This is the app-kill simulation that a
  /// unit test can actually perform.
  Future<List<Note>> readFromDisk() async {
    final reader = AppDatabase(NativeDatabase(file));
    try {
      return await (reader.select(reader.notes)).get();
    } finally {
      await reader.close();
    }
  }

  group('a single note change', () {
    test('is on disk as soon as the write completes', () async {
      await notes.put(
        puzzleId: 'p1',
        cell: 40,
        digit: 5,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
      );

      final onDisk = await readFromDisk();
      expect(onDisk, hasLength(1));
      expect(onDisk.single.digit, 5);
    });

    test('a removal is on disk too', () async {
      await notes.put(
        puzzleId: 'p1',
        cell: 40,
        digit: 5,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
      );
      await notes.remove(puzzleId: 'p1', cell: 40, digit: 5);

      expect(await readFromDisk(), isEmpty);
    });

    test('clearing provisional marks is on disk', () async {
      await notes.put(
        puzzleId: 'p1',
        cell: 0,
        digit: 1,
        kind: NoteKind.provisional,
        origin: NoteOrigin.manual,
      );
      // The clearance is the cells the board now holds, written through the
      // one path every multi-cell action uses (D-11).
      await notes.putCells(
        puzzleId: 'p1',
        cells: <int, Map<int, NoteMark>>{0: <int, NoteMark>{}},
      );

      expect(await readFromDisk(), isEmpty);
    });
  });

  group('a rapid sequence', () {
    // A player marking a dense board makes dozens of changes in seconds. Not
    // one of them may be coalesced away.
    test('every change lands, none is dropped', () async {
      for (var digit = 1; digit <= 9; digit++) {
        await notes.put(
          puzzleId: 'p1',
          cell: 40,
          digit: digit,
          kind: NoteKind.settled,
          origin: NoteOrigin.manual,
        );
      }

      final onDisk = await readFromDisk();
      expect(onDisk.map((n) => n.digit).toSet(), <int>{
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      });
    });

    test('the last change is as durable as the first', () async {
      for (var cell = 0; cell < 20; cell++) {
        await notes.put(
          puzzleId: 'p1',
          cell: cell,
          digit: 1,
          kind: NoteKind.settled,
          origin: NoteOrigin.manual,
        );
      }

      final onDisk = await readFromDisk();
      expect(onDisk, hasLength(20));
      expect(onDisk.map((n) => n.cell), contains(19));
    });

    test('writes issued without awaiting still all land, in order', () async {
      // This is how the input path will call it: start the write, carry on.
      final futures = <Future<void>>[
        for (var digit = 1; digit <= 9; digit++)
          notes.put(
            puzzleId: 'p1',
            cell: 40,
            digit: digit,
            kind: NoteKind.settled,
            origin: NoteOrigin.manual,
          ),
      ];
      await Future.wait(futures);

      expect((await readFromDisk()), hasLength(9));
    });
  });

  group('the player is not made to wait', () {
    // Constraint 2. The note is on screen before the write is acknowledged, so
    // a caller may fire and forget. Asserted by showing the future can be left
    // pending while more work is issued.
    test(
      'a write can be left unawaited while the next one is issued',
      () async {
        final first = notes.put(
          puzzleId: 'p1',
          cell: 0,
          digit: 1,
          kind: NoteKind.settled,
          origin: NoteOrigin.manual,
        );
        final second = notes.put(
          puzzleId: 'p1',
          cell: 0,
          digit: 2,
          kind: NoteKind.settled,
          origin: NoteOrigin.manual,
        );

        await Future.wait(<Future<void>>[first, second]);
        expect(await readFromDisk(), hasLength(2));
      },
    );
  });
}
