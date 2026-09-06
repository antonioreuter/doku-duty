import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';

void main() {
  late AppDatabase db;
  late PuzzleSaveRepository saves;
  late NoteRepository notes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saves = PuzzleSaveRepository(db);
    notes = NoteRepository(db);
  });
  tearDown(() => db.close());

  group('a save', () {
    test('holds the placed values and the elapsed time', () async {
      await saves.save(
        puzzleId: 'p1',
        placedValues: <int, int>{0: 5, 40: 9},
        elapsed: const Duration(minutes: 3, seconds: 20),
      );

      final resumed = await saves.inProgress();
      expect(resumed, isNotNull);
      expect(resumed!.puzzleId, 'p1');
      expect(resumed.placedValues, <int, int>{0: 5, 40: 9});
      expect(resumed.elapsed, const Duration(minutes: 3, seconds: 20));
    });

    test('there is exactly one save per puzzle', () async {
      await saves.save(
        puzzleId: 'p1',
        placedValues: <int, int>{0: 5},
        elapsed: Duration.zero,
      );
      await saves.save(
        puzzleId: 'p1',
        placedValues: <int, int>{0: 5, 1: 6},
        elapsed: const Duration(seconds: 10),
      );

      final all = await saves.all();
      expect(all, hasLength(1));
      expect(all.single.placedValues, <int, int>{0: 5, 1: 6});
    });

    test('an empty grid round-trips', () async {
      await saves.save(
        puzzleId: 'p1',
        placedValues: const <int, int>{},
        elapsed: Duration.zero,
      );
      expect((await saves.inProgress())!.placedValues, isEmpty);
    });
  });

  group('elapsed time', () {
    // D-06. The timer is display-only, which is exactly why it has to be
    // honest — a resumed puzzle that counts the hours the app was closed makes
    // a personal best meaningless.
    test('resumes from where it stopped', () async {
      await saves.save(
        puzzleId: 'p1',
        placedValues: const <int, int>{},
        elapsed: const Duration(minutes: 12),
      );
      expect((await saves.inProgress())!.elapsed, const Duration(minutes: 12));
    });

    test('time with the app closed is not counted', () async {
      await saves.save(
        puzzleId: 'p1',
        placedValues: const <int, int>{},
        elapsed: const Duration(minutes: 12),
        // A save written well in the past. Nothing may infer elapsed time from
        // wall-clock difference.
        at: DateTime.utc(2020),
      );
      expect((await saves.inProgress())!.elapsed, const Duration(minutes: 12));
    });
  });

  group('completion', () {
    test('a completed puzzle is no longer offered for resume', () async {
      await saves.save(
        puzzleId: 'p1',
        placedValues: <int, int>{0: 5},
        elapsed: const Duration(minutes: 1),
      );
      await saves.complete('p1');

      expect(await saves.inProgress(), isNull);
    });

    test('completing also clears the notes that belonged to it', () async {
      await notes.put(
        puzzleId: 'p1',
        cell: 0,
        digit: 1,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
      );
      await saves.save(
        puzzleId: 'p1',
        placedValues: <int, int>{0: 5},
        elapsed: Duration.zero,
      );

      await saves.complete('p1');
      expect(await notes.notesFor('p1'), isEmpty);
    });
  });

  group('a cell holds a value or notes, never both', () {
    // D-16. The completion check the spec once proposed is unnecessary because
    // the model makes the situation impossible — so the model has to actually
    // make it impossible.
    test('placing a value clears that cell\'s notes', () async {
      for (final digit in <int>[1, 2, 3]) {
        await notes.put(
          puzzleId: 'p1',
          cell: 40,
          digit: digit,
          kind: NoteKind.settled,
          origin: NoteOrigin.manual,
        );
      }

      await saves.placeValue(puzzleId: 'p1', cell: 40, value: 7);

      expect(await notes.notesInCell('p1', 40), isEmpty);
      expect((await saves.inProgress())!.placedValues[40], 7);
    });

    test('clearing a value leaves the cell empty of both', () async {
      await saves.placeValue(puzzleId: 'p1', cell: 40, value: 7);
      await saves.clearValue(puzzleId: 'p1', cell: 40);

      expect((await saves.inProgress())!.placedValues, isEmpty);
      expect(await notes.notesInCell('p1', 40), isEmpty);
    });
  });
}
