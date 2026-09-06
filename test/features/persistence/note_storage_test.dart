import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('a note row', () {
    // D-15 and D-11. Both distinctions have to exist from day one: adding
    // either later means migrating live saved games.
    test('is identified by its puzzle, its cell, and its digit', () async {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              puzzleId: 'p1',
              cell: 40,
              digit: 5,
              kind: NoteKind.settled,
              origin: NoteOrigin.manual,
            ),
          );

      final rows = await db.select(db.notes).get();
      expect(rows, hasLength(1));
      expect(rows.single.puzzleId, 'p1');
      expect(rows.single.cell, 40);
      expect(rows.single.digit, 5);
    });

    test('carries its kind', () async {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              puzzleId: 'p1',
              cell: 0,
              digit: 1,
              kind: NoteKind.settled,
              origin: NoteOrigin.manual,
            ),
          );
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              puzzleId: 'p1',
              cell: 0,
              digit: 2,
              kind: NoteKind.provisional,
              origin: NoteOrigin.manual,
            ),
          );

      final rows = await db.select(db.notes).get();
      expect(rows.map((r) => (r.digit, r.kind)).toSet(), <(int, NoteKind)>{
        (1, NoteKind.settled),
        (2, NoteKind.provisional),
      });
    });

    test(
      'carries whether the player entered it or the app generated it',
      () async {
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                puzzleId: 'p1',
                cell: 3,
                digit: 7,
                kind: NoteKind.settled,
                origin: NoteOrigin.generated,
              ),
            );

        final row = await db.select(db.notes).getSingle();
        expect(row.origin, NoteOrigin.generated);
      },
    );

    test('cannot hold the same digit twice in one cell', () async {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              puzzleId: 'p1',
              cell: 3,
              digit: 7,
              kind: NoteKind.settled,
              origin: NoteOrigin.manual,
            ),
          );
      await expectLater(
        db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                puzzleId: 'p1',
                cell: 3,
                digit: 7,
                kind: NoteKind.provisional,
                origin: NoteOrigin.manual,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('rejects a digit outside 1 to 9 and a cell outside 0 to 80', () async {
      await expectLater(
        db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                puzzleId: 'p1',
                cell: 0,
                digit: 0,
                kind: NoteKind.settled,
                origin: NoteOrigin.manual,
              ),
            ),
        // Asserting the type matters: `anything` would also pass on a stack
        // overflow from drift's self-referencing CHECK idiom, which would mean
        // the constraint was never reaching sqlite at all.
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                puzzleId: 'p1',
                cell: 81,
                digit: 4,
                kind: NoteKind.settled,
                origin: NoteOrigin.manual,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
