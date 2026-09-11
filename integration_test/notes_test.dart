import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';

/// The half of constraint 9 a host test cannot reach.
///
/// Host tests prove a candidate reaches *a* sqlite file. These prove it reaches
/// the real one, on a real OS, through the sqlite the app bundles — and that it
/// is still there in a new process. The process that died has to be a real one.
///
/// Run twice. The first run writes; the second asserts what the first left
/// behind.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const puzzleId = 'notes-probe';
  const cell = 40;
  const clues =
      '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

  testWidgets('a candidate written through the sink reaches disk', (
    tester,
  ) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final notes = NoteRepository(db);
    final sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);

    await sink.writeNotes(puzzleId, <int, NoteSet>{
      cell: NoteSet.of(const <int>[1, 5, 9]),
    });

    final stored = await notes.notesInCell(puzzleId, cell);
    expect(stored, hasLength(3));
    for (final note in stored) {
      expect(note.kind, NoteKind.settled);
      expect(note.origin, NoteOrigin.manual);
    }
  });

  testWidgets('what a previous process wrote is still here', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);

    final stored = await NoteRepository(db).notesInCell(puzzleId, cell);
    expect(
      stored.map((note) => note.digit).toList()..sort(),
      <int>[1, 5, 9],
      reason: 'run this file twice — the second run asserts the first',
    );
  });

  // Constraint 3 on a real device: removing one candidate deletes one row and
  // the other two never referred to it.
  testWidgets('removing one candidate leaves the others', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final notes = NoteRepository(db);
    final sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);

    await sink.writeNotes(puzzleId, <int, NoteSet>{
      cell: NoteSet.of(const <int>[1, 9]),
    });

    final stored = await notes.notesInCell(puzzleId, cell);
    expect(stored.map((note) => note.digit).toList()..sort(), <int>[1, 9]);
  });

  // **Auto-notes** and **auto-cleanup** against the real database. Host tests
  // prove the transaction commits; these prove it commits to the file the app
  // actually opens, on the OS the player is holding (constraint 9).
  testWidgets('a fill reaches disk whole, with its origins', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final notes = NoteRepository(db);
    final sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);

    const fillId = 'notes-fill-probe';
    final board = Board.forPuzzle(
      givens: (Grid.parse(clues) as ValidGrid).grid,
    );
    final filled = (board.fillNotes() as EditApplied).board;

    final changed = <int, NoteSet>{
      for (var cell = 0; cell < 81; cell++)
        if (filled.notesAt(cell).isNotEmpty) cell: filled.notesAt(cell),
    };
    await sink.writeNotes(fillId, changed);

    final stored = await notes.notesFor(fillId);
    final expected = changed.values.fold<int>(
      0,
      (sum, set) => sum + set.length,
    );
    expect(stored, hasLength(expected), reason: 'the fill landed part-way');
    for (final note in stored) {
      expect(note.kind, NoteKind.settled);
      expect(note.origin, NoteOrigin.generated);
    }

    // What the app rebuilds on reopen is the board that was on screen.
    final rebuilt = <int, NoteSet>{};
    for (final note in stored) {
      final set = rebuilt[note.cell] ?? NoteSet.none;
      rebuilt[note.cell] = note.origin == NoteOrigin.generated
          ? set.withGenerated(note.digit)
          : set.with_(note.digit);
    }
    expect(rebuilt, changed);
  });

  // The cross-process half, as the single-candidate probe above does it: run
  // this file twice and the second run asserts what the first left behind.
  // Same-process reads prove the transaction committed; only a second process
  // proves it reached the file the app reopens (D-33, constraint 9).
  testWidgets('a fill a previous process wrote is still here', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);

    final stored = await NoteRepository(db).notesFor('notes-fill-probe');
    expect(
      stored,
      isNotEmpty,
      reason: 'run this file twice — the second run asserts the first',
    );
    expect(
      stored.every((note) => note.origin == NoteOrigin.generated),
      isTrue,
      reason: 'the fill wrote these, and the origin has to survive with them',
    );
  });

  testWidgets('a cleanup reaches disk with the placement', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final notes = NoteRepository(db);
    final sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);

    const cleanupId = 'notes-cleanup-probe';
    var board = Board.forPuzzle(givens: (Grid.parse(clues) as ValidGrid).grid);
    final peers = <int>[
      for (final peer in GridGeometry.peersOf(2))
        if (board.isEmptyAt(peer)) peer,
    ];
    for (final peer in peers) {
      board = (board.toggleNote(peer, 4) as EditApplied).board;
    }
    await sink.writeNotes(cleanupId, <int, NoteSet>{
      for (final peer in peers) peer: board.notesAt(peer),
    });

    final before = board;
    board = (board.place(2, 4) as EditApplied).board;
    await sink.writeNotes(cleanupId, <int, NoteSet>{
      for (var cell = 0; cell < 81; cell++)
        if (before.notesAt(cell) != board.notesAt(cell))
          cell: board.notesAt(cell),
    });

    // Not one row anywhere carries the 4 a peer's value now contradicts.
    final stored = await notes.notesFor(cleanupId);
    expect(stored.where((note) => note.digit == 4), isEmpty);
  });

  // Rendering, on the platform's own rasteriser and text shaper. The golden
  // pins the layout on the host; this proves 11px candidates actually draw on
  // a device, at the largest dynamic type as well as the default.
  testWidgets('a dense board of candidates renders on the device', (
    tester,
  ) async {
    var board = Board.forPuzzle(givens: (Grid.parse(clues) as ValidGrid).grid);
    for (var cell = 0; cell < 81; cell++) {
      if (board.isGiven(cell)) continue;
      for (var digit = 1; digit <= 9; digit++) {
        board = (board.toggleNote(cell, digit) as EditApplied).board;
      }
    }

    for (final scale in <double>[1, 2]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: PuzzleGrid(board: board, onCellTapped: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'at ${scale}x');
      expect(tester.getSize(find.byType(PuzzleGrid)), const Size(360, 360));
    }
  });
}
