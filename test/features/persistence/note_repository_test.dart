import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';

void main() {
  late AppDatabase db;
  late NoteRepository notes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notes = NoteRepository(db);
  });
  tearDown(() => db.close());

  Future<void> put(
    int cell,
    int digit, {
    NoteKind kind = NoteKind.settled,
    NoteOrigin origin = NoteOrigin.manual,
  }) => notes.put(
    puzzleId: 'p1',
    cell: cell,
    digit: digit,
    kind: kind,
    origin: origin,
  );

  group('clearing provisional marks', () {
    // D-11. The one-action clear is what makes a second ink worth having: a
    // player tests a hypothesis, and abandoning it must cost one tap, not
    // nine erasures.
    test('removes every provisional note and no settled note', () async {
      await put(0, 1);
      await put(0, 2, kind: NoteKind.provisional);
      await put(10, 3, kind: NoteKind.provisional);
      await put(10, 4);

      await notes.clearProvisional('p1');

      final remaining = await notes.notesFor('p1');
      expect(remaining.map((n) => n.digit).toSet(), <int>{1, 4});
      expect(remaining.every((n) => n.kind == NoteKind.settled), isTrue);
    });

    test('leaves other puzzles alone', () async {
      await put(0, 1, kind: NoteKind.provisional);
      await notes.put(
        puzzleId: 'p2',
        cell: 0,
        digit: 1,
        kind: NoteKind.provisional,
        origin: NoteOrigin.manual,
      );

      await notes.clearProvisional('p1');

      expect(await notes.notesFor('p1'), isEmpty);
      expect(await notes.notesFor('p2'), hasLength(1));
    });

    test('is a no-op when there are no provisional marks', () async {
      await put(0, 1);
      await notes.clearProvisional('p1');
      expect(await notes.notesFor('p1'), hasLength(1));
    });
  });

  group('provenance', () {
    // D-15. Identical on screen, distinguishable in the data — undo,
    // auto-cleanup, and "clear notes" all need to know which is which.
    test(
      'manual and generated notes coexist in one cell and stay apart',
      () async {
        await put(40, 1);
        await put(40, 2, origin: NoteOrigin.generated);
        await put(40, 3, origin: NoteOrigin.generated);

        final inCell = await notes.notesInCell('p1', 40);
        expect(
          inCell
              .where((n) => n.origin == NoteOrigin.manual)
              .map((n) => n.digit),
          <int>[1],
        );
        expect(
          inCell
              .where((n) => n.origin == NoteOrigin.generated)
              .map((n) => n.digit)
              .toSet(),
          <int>{2, 3},
        );
      },
    );

    test('re-marking a generated note by hand makes it manual', () async {
      await put(40, 5, origin: NoteOrigin.generated);
      await put(40, 5);

      final inCell = await notes.notesInCell('p1', 40);
      expect(inCell, hasLength(1), reason: 'not duplicated');
      expect(inCell.single.origin, NoteOrigin.manual);
    });

    test('re-marking a candidate does not throw at the player', () async {
      await put(40, 5);
      await expectLater(put(40, 5), completes);
    });
  });

  group('removal', () {
    test('removes exactly one candidate', () async {
      await put(0, 1);
      await put(0, 2);
      await notes.remove(puzzleId: 'p1', cell: 0, digit: 1);
      expect((await notes.notesInCell('p1', 0)).map((n) => n.digit), <int>[2]);
    });
  });
}
