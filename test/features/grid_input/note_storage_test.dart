import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

void main() {
  late AppDatabase db;
  late NoteRepository notes;
  late RepositoryBoardSink sink;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notes = NoteRepository(db);
    sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);
  });
  tearDown(() => db.close());

  Board boardWith(Map<int, List<int>> marks) {
    var board = Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);
    for (final entry in marks.entries) {
      for (final digit in entry.value) {
        board = (board.toggleNote(entry.key, digit) as EditApplied).board;
      }
    }
    return board;
  }

  // This change writes settled/manual and nothing else, so changes 8 and 9
  // inherit a clean slate rather than having to work out what existing rows
  // mean.
  test('every note is written settled and manual', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1, 4, 9]),
    });

    final stored = await notes.notesFor('q1');
    expect(stored, hasLength(3));
    for (final note in stored) {
      expect(note.kind, NoteKind.settled, reason: 'digit ${note.digit}');
      expect(note.origin, NoteOrigin.manual, reason: 'digit ${note.digit}');
    }
  });

  // Still true after `add-note-automation`: the fill writes a second *origin*,
  // never a second *ink*. The turquoise is `add-provisional-notes`, and the
  // capability that adds it must inherit a store in which no existing row is
  // provisional.
  test('the provisional ink is never written by this change', () async {
    final source = File(
      'lib/features/grid_input/application/grid_providers.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('NoteKind.provisional')));
  });

  // D-15. Both origins in one cell, told apart in storage and nowhere else.
  test('a generated candidate is stored as generated', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1]).withGenerated(4),
    });

    final stored = await notes.notesInCell('q1', 2);
    final byDigit = <int, Note>{for (final n in stored) n.digit: n};

    expect(byDigit[1]!.origin, NoteOrigin.manual);
    expect(byDigit[4]!.origin, NoteOrigin.generated);
    // One ink, whatever marked it.
    expect(byDigit[1]!.kind, NoteKind.settled);
    expect(byDigit[4]!.kind, NoteKind.settled);
  });

  test('taking over a generated candidate rewrites its origin', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.none.withGenerated(4),
    });
    expect(
      (await notes.notesInCell('q1', 2)).single.origin,
      NoteOrigin.generated,
    );

    // The player removed it and marked it again: it is theirs now.
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[4]),
    });

    expect((await notes.notesInCell('q1', 2)).single.origin, NoteOrigin.manual);
  });

  test('origin survives the round trip through the database', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1, 5]).withGenerated(4).withGenerated(9),
    });

    final stored = await notes.notesFor('q1');
    var rebuilt = NoteSet.none;
    for (final note in stored) {
      rebuilt = note.origin == NoteOrigin.generated
          ? rebuilt.withGenerated(note.digit)
          : rebuilt.with_(note.digit);
    }

    expect(rebuilt.manual, <int>[1, 5]);
    expect(rebuilt.generated, <int>[4, 9]);
  });

  test('a candidate round-trips through the database', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1, 5]),
    });
    await sink.writeNotes('q1', <int, NoteSet>{
      40: NoteSet.of(const <int>[9]),
    });

    final stored = await notes.notesFor('q1');
    final byCell = <int, NoteSet>{};
    for (final note in stored) {
      byCell[note.cell] = (byCell[note.cell] ?? NoteSet.none).with_(note.digit);
    }

    expect(byCell[2], NoteSet.of(const <int>[1, 5]));
    expect(byCell[40], NoteSet.of(const <int>[9]));
  });

  // Constraint 3, at the storage layer: removing a candidate deletes one row
  // and the other eight never referred to it.
  test('removing one candidate leaves the others as rows', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1, 2, 3, 4, 5]),
    });
    expect(await notes.notesInCell('q1', 2), hasLength(5));

    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1, 2, 4, 5]),
    });

    final remaining = await notes.notesInCell('q1', 2);
    expect(remaining.map((note) => note.digit).toList()..sort(), <int>[
      1,
      2,
      4,
      5,
    ]);
  });

  test('clearing a cell removes every row for it', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1, 2, 3]),
    });
    await sink.writeNotes('q1', <int, NoteSet>{2: NoteSet.none});

    expect(await notes.notesInCell('q1', 2), isEmpty);
  });

  test('one puzzle\'s notes do not reach another', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1]),
    });
    await sink.writeNotes('q2', <int, NoteSet>{
      2: NoteSet.of(const <int>[9]),
    });

    expect((await notes.notesFor('q1')).single.digit, 1);
    expect((await notes.notesFor('q2')).single.digit, 9);
  });

  // D-15 survives an app kill, which is the only reason to store it at all.
  test('a puzzle saved with mixed origins reopens with each intact', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1]).withGenerated(4),
    });
    await sink.writeNotes('q1', <int, NoteSet>{
      11: NoteSet.none.withGenerated(9),
    });
    await sink.writeNotes('q1', <int, NoteSet>{
      40: NoteSet.of(const <int>[3, 6]),
    });

    // What `puzzleOpeningProvider` rebuilds from the rows, on the same path.
    final byCell = <int, NoteSet>{};
    for (final note in await notes.notesFor('q1')) {
      final set = byCell[note.cell] ?? NoteSet.none;
      byCell[note.cell] = note.origin == NoteOrigin.generated
          ? set.withGenerated(note.digit)
          : set.with_(note.digit);
    }

    expect(byCell[2], NoteSet.of(const <int>[1]).withGenerated(4));
    expect(byCell[11], NoteSet.none.withGenerated(9));
    expect(byCell[40], NoteSet.of(const <int>[3, 6]));
    expect(byCell[40]!.generated, isEmpty);
  });

  test('the board and its notes are written together', () async {
    final board = boardWith(<int, List<int>>{
      2: <int>[3, 6],
    });
    await sink.write('q1', board);
    await sink.writeNotes('q1', <int, NoteSet>{2: board.notesAt(2)});

    final saves = await PuzzleSaveRepository(db).all();
    expect(saves.single.puzzleId, 'q1');
    expect(await notes.notesInCell('q1', 2), hasLength(2));
  });
}
