import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/puzzle_engine/data/pack_source.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
const String _puzzleId = 'q-greenhorn';

/// Counts commits while the writes go to the real database underneath.
///
/// One [writeNotes] call is one `putCells` transaction, so counting the calls
/// counts the commits without reaching inside drift.
final class _CountingSink implements BoardSink {
  _CountingSink(this._inner);

  final RepositoryBoardSink _inner;
  int noteCommits = 0;

  @override
  Future<void> write(String puzzleId, Board board, {required int mistakes}) =>
      _inner.write(puzzleId, board, mistakes: mistakes);

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) {
    noteCommits++;
    return _inner.writeNotes(puzzleId, byCell);
  }

  @override
  Future<void> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) => _inner.complete(
    puzzleId,
    techniquesRequired: techniquesRequired,
    attempt: attempt,
  );
}

/// A one-puzzle **pack**, so the opening provider has a row to find.
final class _FakePackSource implements PackSource {
  @override
  Future<PackParseResult> read() async => Pack.parse(
    Pack(
      packId: 'frontier-1',
      version: 1,
      puzzles: <PackPuzzle>[
        PackPuzzle(
          id: _puzzleId,
          clues: _clues,
          solution: _solution,
          rank: Rank.greenhorn,
          seed: 1,
        ),
      ],
    ).encode(),
  );
}

void main() {
  late AppDatabase db;
  late NoteRepository notes;
  late RepositoryBoardSink sink;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notes = NoteRepository(db);
    sink = RepositoryBoardSink(
      PuzzleSaveRepository(db),
      notes,
      ProgressionRepository(db),
    );
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

  Future<Map<int, Note>> storedIn(int cell, {String puzzleId = 'q1'}) async =>
      <int, Note>{
        for (final note in await notes.notesInCell(puzzleId, cell))
          note.digit: note,
      };

  // A candidate marked with no ink named is a settled one, and the default did
  // not move when the second ink arrived.
  test('a hand-marked note is written settled and manual', () async {
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

  // The requirement that forbade a provisional row was waiting for this change
  // and is removed by it: writing the second ink is now the point.
  test('both inks in one cell are stored apart', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[1]).with_(4, ink: NoteKind.provisional),
    });

    final byDigit = await storedIn(2);
    expect(byDigit[1]!.kind, NoteKind.settled);
    expect(byDigit[4]!.kind, NoteKind.provisional);
  });

  // D-15: two questions about one candidate. The ink is what the player means
  // by it; the origin is who marked it first. Neither answers the other.
  test('ink and origin are written independently', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.none
          .withGenerated(4)
          .reInked(4, NoteKind.provisional)
          .with_(7, ink: NoteKind.provisional)
          .withGenerated(9),
    });

    final byDigit = await storedIn(2);
    expect(byDigit[4]!.kind, NoteKind.provisional);
    expect(byDigit[4]!.origin, NoteOrigin.generated);
    expect(byDigit[7]!.kind, NoteKind.provisional);
    expect(byDigit[7]!.origin, NoteOrigin.manual);
    expect(byDigit[9]!.kind, NoteKind.settled);
    expect(byDigit[9]!.origin, NoteOrigin.generated);
  });

  // Re-inking is an edit to the row that is already there, so the row has to
  // move with it rather than the write seeing only presence.
  test('re-inking a stored candidate rewrites its ink', () async {
    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[3]),
    });
    expect((await storedIn(2))[3]!.kind, NoteKind.settled);

    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[3]).reInked(3, NoteKind.provisional),
    });
    expect((await storedIn(2))[3]!.kind, NoteKind.provisional);

    await sink.writeNotes('q1', <int, NoteSet>{
      2: NoteSet.of(const <int>[3]),
    });
    expect((await storedIn(2))[3]!.kind, NoteKind.settled);
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

  // D-11 and D-15 both survive an app kill, which is the only reason to store
  // either. Read back through `puzzleOpeningProvider` itself rather than a
  // rebuild written beside it: a second copy of the load path is how the two
  // come to disagree about what a row means.
  group('reopening a puzzle', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          packSourceProvider.overrideWithValue(_FakePackSource()),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<Map<int, NoteSet>> reopen() async {
      final opening = await container.read(
        puzzleOpeningProvider(_puzzleId).future,
      );
      return opening!.notes;
    }

    test('each candidate comes back in its own ink, slot and origin', () async {
      await sink.writeNotes(_puzzleId, <int, NoteSet>{
        2: NoteSet.of(const <int>[
          1,
        ]).with_(4, ink: NoteKind.provisional).withGenerated(9),
        11: NoteSet.none.withGenerated(9).reInked(9, NoteKind.provisional),
        40: NoteSet.of(const <int>[3, 6]),
      });

      final byCell = await reopen();

      expect(byCell[2]!.settled, <int>[1, 9]);
      expect(byCell[2]!.provisional, <int>[4]);
      expect(byCell[2]!.generated, <int>[9]);
      expect(byCell[11]!.provisional, <int>[9]);
      expect(byCell[11]!.generated, <int>[9]);
      expect(byCell[40], NoteSet.of(const <int>[3, 6]));
      expect(byCell[40]!.provisional, isEmpty);
      expect(byCell[40]!.generated, isEmpty);
    });

    // Constraint 3 across the round trip: a digit's slot is the digit's, so a
    // reopened board is read exactly as the one that was left.
    test('a slot is the digit\'s, whichever ink came back', () async {
      await sink.writeNotes(_puzzleId, <int, NoteSet>{
        2: NoteSet.of(const <int>[1, 5, 9]).reInked(5, NoteKind.provisional),
      });

      final byCell = await reopen();

      for (final digit in const <int>[1, 5, 9]) {
        expect(NoteSet.slotOf(digit), (
          row: (digit - 1) ~/ 3,
          column: (digit - 1) % 3,
        ));
        expect(byCell[2]!.contains(digit), isTrue);
      }
    });
  });

  // Constraint 9 for the two board-wide inking actions. Each reaches many
  // cells, so each is exactly where a well-meaning per-cell loop would be
  // written — one that looks identical to a correct write until a kill part-way
  // through leaves a board half re-inked.
  group('a clearance and a promotion are each one commit', () {
    late _CountingSink counting;
    late PuzzleController controller;

    /// Three cells, both inks, so a clearance has something to leave behind
    /// and a promotion has something to keep.
    PuzzleSession sessionWithBothInks() {
      var board = Board.forPuzzle(
        givens: (Grid.parse(_clues) as ValidGrid).grid,
      );
      for (final entry in const <int, List<int>>{
        2: <int>[1, 4],
        11: <int>[3],
        40: <int>[7, 9],
      }.entries) {
        for (final digit in entry.value) {
          board = (board.toggleNote(entry.key, digit) as EditApplied).board;
        }
      }
      for (final cell in const <int>[2, 40]) {
        board =
            (board.toggleNote(
                      cell,
                      board.notesAt(cell).digits.first,
                      ink: NoteKind.provisional,
                    )
                    as EditApplied)
                .board;
      }
      return PuzzleSession.start(
        solution: (Grid.parse(_solution) as ValidGrid).grid,
        board: board,
        mode: InputMode.cellFirst,
      );
    }

    setUp(() async {
      final session = sessionWithBothInks();
      // The board the player is resuming is already in the store, so what the
      // action writes is the difference and not the whole board.
      await sink.writeNotes(_puzzleId, <int, NoteSet>{
        for (final cell in const <int>[2, 11, 40])
          cell: session.board.notesAt(cell),
      });

      counting = _CountingSink(sink);
      controller = PuzzleController(
        puzzle: const StoredPuzzle(
          id: _puzzleId,
          clues: _clues,
          solution: _solution,
          rank: Rank.greenhorn,
          seed: 1,
        ),
        sink: counting,
        initial: session,
      );
    });

    test('the clearance commits once and the rows follow', () async {
      controller.clearProvisional();
      await pumpEventQueue();

      expect(counting.noteCommits, 1);
      final stored = await notes.notesFor(_puzzleId);
      expect(
        stored.every((note) => note.kind == NoteKind.settled),
        isTrue,
        reason: 'nothing provisional survives the clearance',
      );
      expect(
        (await storedIn(2, puzzleId: _puzzleId)).keys.toList()..sort(),
        <int>[4],
      );
      expect(
        (await storedIn(40, puzzleId: _puzzleId)).keys.toList()..sort(),
        <int>[9],
      );
      expect(
        (await storedIn(11, puzzleId: _puzzleId)).keys.toList()..sort(),
        <int>[3],
      );
    });

    test('the promotion commits once and the rows follow', () async {
      controller.promoteProvisional();
      await pumpEventQueue();

      expect(counting.noteCommits, 1);
      final stored = await notes.notesFor(_puzzleId);
      expect(stored, hasLength(5));
      expect(
        stored.every((note) => note.kind == NoteKind.settled),
        isTrue,
        reason: 'promote changes the ink and removes nothing',
      );
    });
  });

  test('the board and its notes are written together', () async {
    final board = boardWith(<int, List<int>>{
      2: <int>[3, 6],
    });
    await sink.write('q1', board, mistakes: 0);
    await sink.writeNotes('q1', <int, NoteSet>{2: board.notesAt(2)});

    final saves = await PuzzleSaveRepository(db).all();
    expect(saves.single.puzzleId, 'q1');
    expect(await notes.notesInCell('q1', 2), hasLength(2));
  });
}
