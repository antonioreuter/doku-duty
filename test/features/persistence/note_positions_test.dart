import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';

/// Constraint 3, at the storage layer.
///
/// A candidate's identity is its digit, so removing one cannot move another.
/// A list-shaped schema would need compacting on removal, and no amount of care
/// in the renderer could undo that. This asserts the shape, which is the part
/// that has to be right from day one.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addNote(int digit, {NoteKind kind = NoteKind.settled}) => db
      .into(db.notes)
      .insert(
        NotesCompanion.insert(
          puzzleId: 'p1',
          cell: 40,
          digit: digit,
          kind: kind,
          origin: NoteOrigin.manual,
        ),
      );

  Future<List<int>> digitsInCell() async {
    final rows =
        await (db.select(db.notes)
              ..where((n) => n.cell.equals(40))
              ..orderBy([(n) => OrderingTerm(expression: n.digit)]))
            .get();
    return rows.map((r) => r.digit).toList();
  }

  test('removing a candidate leaves every other digit unchanged', () async {
    for (final digit in <int>[1, 3, 5, 7, 9]) {
      await addNote(digit);
    }
    expect(await digitsInCell(), <int>[1, 3, 5, 7, 9]);

    await (db.delete(
      db.notes,
    )..where((n) => n.cell.equals(40) & n.digit.equals(5))).go();

    // 1, 3, 7 and 9 are still 1, 3, 7 and 9 — not shifted into the gap.
    expect(await digitsInCell(), <int>[1, 3, 7, 9]);
  });

  test(
    'the surviving notes are byte-identical apart from the removed one',
    () async {
      for (final digit in <int>[2, 4, 6]) {
        await addNote(digit);
      }
      final before = await (db.select(
        db.notes,
      )..where((n) => n.digit.isIn(<int>[2, 6]))).get();

      await (db.delete(db.notes)..where((n) => n.digit.equals(4))).go();

      final after = await (db.select(
        db.notes,
      )..where((n) => n.digit.isIn(<int>[2, 6]))).get();
      expect(after, before);
    },
  );

  test(
    'a reload returns the same digits, in any order the caller asks for',
    () async {
      for (final digit in <int>[9, 1, 5]) {
        await addNote(digit);
      }
      await (db.delete(db.notes)..where((n) => n.digit.equals(1))).go();

      // Reopening through a second query object is the closest a unit test gets
      // to a reload; group 3 covers a genuinely separate connection.
      expect(await digitsInCell(), <int>[5, 9]);
    },
  );

  test('nothing in the schema encodes a position or an index', () async {
    // If a slot or ordinal ever appears as a column, this is where the reflow
    // bug enters. The column list is the assertion.
    final columns = db.notes.$columns.map((c) => c.name).toSet();
    expect(columns, <String>{
      'puzzle_id',
      'cell',
      'digit',
      'kind',
      'origin',
      'updated_at',
      'pending_upload',
    });
  });
}
