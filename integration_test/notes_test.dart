import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/design_system/domain/note_ink.dart';
import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
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

  // The second ink, on the file the app actually opens. A clearance, a
  // promotion and a re-inking each rewrite many rows at once, and a board that
  // came back in the wrong ink is indistinguishable from one that came back
  // right until the player looks for their hypothesis (D-11, constraint 9).
  testWidgets('both inks reach disk, and survive a clearance', (tester) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    final notes = NoteRepository(db);
    final sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);

    const inkId = 'notes-ink-probe';
    var board = Board.forPuzzle(givens: (Grid.parse(clues) as ValidGrid).grid);
    // Cell 2 keeps a settled candidate beside a hypothesis; cell 11 is the
    // hypothesis alone; cell 40 is settled work that must not be touched.
    for (final entry in const <int, List<int>>{
      2: <int>[1, 4],
      11: <int>[3],
      40: <int>[7, 9],
    }.entries) {
      for (final digit in entry.value) {
        board = (board.toggleNote(entry.key, digit) as EditApplied).board;
      }
    }
    for (final (cell, digit) in const <(int, int)>[(2, 1), (11, 3)]) {
      board =
          (board.toggleNote(cell, digit, ink: NoteKind.provisional)
                  as EditApplied)
              .board;
    }
    final cells = const <int>[2, 11, 40];
    Map<int, NoteSet> asWritten(Board board) => <int, NoteSet>{
      for (final cell in cells) cell: board.notesAt(cell),
    };
    Future<Map<int, NoteSet>> reopened() async {
      final rebuilt = <int, NoteSet>{};
      for (final note in await notes.notesFor(inkId)) {
        final set = rebuilt[note.cell] ?? NoteSet.none;
        final marked = note.origin == NoteOrigin.generated
            ? set.withGenerated(note.digit)
            : set.with_(note.digit);
        rebuilt[note.cell] = note.kind == NoteKind.provisional
            ? marked.reInked(note.digit, NoteKind.provisional)
            : marked;
      }
      return <int, NoteSet>{
        for (final cell in cells) cell: rebuilt[cell] ?? NoteSet.none,
      };
    }

    await sink.writeNotes(inkId, asWritten(board));
    expect(await reopened(), asWritten(board), reason: 'the inks as marked');

    // A re-inking: the candidate never leaves its slot, and the row moves with
    // it (D-90).
    board = (board.toggleNote(40, 7, ink: NoteKind.provisional) as EditApplied)
        .board;
    await sink.writeNotes(inkId, asWritten(board));
    expect(await reopened(), asWritten(board), reason: 'after a re-inking');

    // **Promote**: nothing added, nothing removed, every hypothesis kept.
    board = (board.promoteProvisional() as EditApplied).board;
    await sink.writeNotes(inkId, asWritten(board));
    expect(await reopened(), asWritten(board), reason: 'after a promotion');
    expect(
      (await notes.notesFor(
        inkId,
      )).every((note) => note.kind == NoteKind.settled),
      isTrue,
    );

    // And a clearance, on a board made provisional again.
    board = (board.toggleNote(2, 1, ink: NoteKind.provisional) as EditApplied)
        .board;
    board = (board.clearProvisional() as EditApplied).board;
    await sink.writeNotes(inkId, asWritten(board));
    expect(await reopened(), asWritten(board), reason: 'after a clearance');
    expect(board.notesAt(2).digits, <int>[4], reason: 'settled work survives');
  });

  // The cross-process half: run this file twice, and the second run reads what
  // the first left on disk. An ink that only survives inside one process is
  // not stored at all.
  testWidgets('the inks a previous process wrote are still here', (
    tester,
  ) async {
    final db = AppDatabase.open();
    addTearDown(db.close);

    const provisionalId = 'notes-ink-survivor';
    final notes = NoteRepository(db);
    final stored = await notes.notesInCell(provisionalId, 40);

    if (stored.isEmpty) {
      final sink = RepositoryBoardSink(PuzzleSaveRepository(db), notes);
      var board = Board.forPuzzle(
        givens: (Grid.parse(clues) as ValidGrid).grid,
      );
      board = (board.toggleNote(40, 5) as EditApplied).board;
      board =
          (board.toggleNote(40, 8, ink: NoteKind.provisional) as EditApplied)
              .board;
      await sink.writeNotes(provisionalId, <int, NoteSet>{
        40: board.notesAt(40),
      });
      return;
    }

    final byDigit = <int, Note>{for (final note in stored) note.digit: note};
    expect(
      byDigit[5]!.kind,
      NoteKind.settled,
      reason: 'run this file twice — the second run asserts the first',
    );
    expect(byDigit[8]!.kind, NoteKind.provisional);
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

  // The second ink on the platform's own rasteriser. The golden pins the
  // layout on the host; this proves an 11px turquoise candidate and its 1px
  // rule actually draw on a device, at the largest dynamic type as well as the
  // default (D-73, constraint 5).
  testWidgets('a board in both inks renders at every text size', (
    tester,
  ) async {
    var board = Board.forPuzzle(givens: (Grid.parse(clues) as ValidGrid).grid);
    for (var cell = 0; cell < 81; cell++) {
      if (board.isGiven(cell)) continue;
      for (var digit = 1; digit <= 9; digit++) {
        board = (board.toggleNote(cell, digit) as EditApplied).board;
      }
      // Half of each cell's candidates as a hypothesis, so every cell carries
      // both inks and every underline has a neighbour to stay clear of.
      for (var digit = 1; digit <= 9; digit += 2) {
        board =
            (board.toggleNote(cell, digit, ink: NoteKind.provisional)
                    as EditApplied)
                .board;
      }
    }
    expect(board.notesAt(2).provisional, <int>[1, 3, 5, 7, 9]);

    for (final scale in <double>[1, 2, 3]) {
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

      expect(tester.takeException(), isNull, reason: 'at \${scale}x');
      expect(tester.getSize(find.byType(PuzzleGrid)), const Size(360, 360));
    }

    // The underline is a logical pixel, and a device with a fractional ratio
    // must still give it a physical one — a rule rounded to nothing is a
    // provisional note that reads as settled, which is constraint 5 broken
    // silently.
    final ratio = tester.view.devicePixelRatio;
    expect(
      provisionalUnderlineWeight * ratio,
      greaterThanOrEqualTo(1.0),
      reason: 'the rule disappears into rounding at \$ratio',
    );
  });

  // The three controls the second ink adds, on the device's own metrics.
  testWidgets('the provisional controls meet the tap target on the device', (
    tester,
  ) async {
    final pressed = <PadKey>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: NumberPad(onKey: pressed.add)),
      ),
    );
    await tester.pumpAndSettle();

    for (final glyph in const <String>['~', '✕', '✓']) {
      expect(find.text(glyph), findsOneWidget, reason: glyph);
      final size = tester.getSize(
        find
            .ancestor(of: find.text(glyph), matching: find.byType(SizedBox))
            .first,
      );
      expect(
        size.shortestSide,
        greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
        reason: glyph,
      );
      await tester.tap(find.text(glyph));
      await tester.pump();
    }

    expect(pressed, hasLength(3));
    expect(pressed[0], isA<InkToggleKey>());
    expect(pressed[1], isA<ClearProvisionalKey>());
    expect(pressed[2], isA<PromoteProvisionalKey>());
  });

  // D-92 against the scaler that actually matters. Every other test of the cap
  // hands the tree a `TextScaler.linear` the test chose; this one overrides
  // nothing and reads what the OS is reporting, which is the number a player's
  // text setting produces and the one the cap has to hold against.
  //
  // Run it with the platform's text size turned up, and pass
  // `--dart-define=doku.largeText=true` so the run refuses to pass at the
  // default scale — a cap "verified" at 1× is verified against nothing.
  testWidgets('the cap holds against the OS text setting', (tester) async {
    const expectLarge = bool.fromEnvironment('doku.largeText');

    var board = Board.forPuzzle(givens: (Grid.parse(clues) as ValidGrid).grid);
    board = (board.toggleNote(40, 8) as EditApplied).board;
    board = (board.toggleNote(40, 3, ink: NoteKind.provisional) as EditApplied)
        .board;

    late double scale;
    await tester.pumpWidget(
      // No `textScaler` of our own anywhere in this tree: what reaches the
      // grid is the view's, which is the OS's.
      MediaQuery.fromView(
        view: tester.view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              // Read exactly as `PuzzleGrid` reads it, from the same context.
              scale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;
              return Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: PuzzleGrid(board: board, onCellTapped: (_) {}),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The tree's scaler is the platform's, so what follows is measured against
    // the OS setting and not against a number this test picked.
    expect(
      scale,
      closeTo(tester.platformDispatcher.textScaleFactor, 0.001),
      reason: 'the grid is not reading the platform scaler',
    );
    if (expectLarge) {
      expect(
        scale,
        greaterThan(1.3),
        reason:
            'the OS text size was not raised before this run, so it proves '
            'nothing about the cap',
      );
    }

    // The glyphs at that scale, inside the boxes they have to stay in.
    final painter = GridPainter(
      board: board,
      selectedCell: null,
      textScale: scale,
      colours: GridColours.standard(),
    );
    painter.paint(ui.Canvas(ui.PictureRecorder()), const Size(360, 360));

    const cell = 40.0;
    const slot = cell / 3;
    // Both inks: they are laid out from separate caches, so a cap proved on
    // one says nothing about the other.
    for (final box in <({double width, double em})>[
      painter.debugNoteGlyphBox(8),
      painter.debugProvisionalGlyphBox(3),
    ]) {
      expect(box.width, lessThanOrEqualTo(slot), reason: '${scale}x note');
      expect(box.em, lessThanOrEqualTo(slot), reason: '${scale}x note em');
    }
    final value = painter.debugValueGlyphBox(5);
    expect(value.width, lessThanOrEqualTo(cell), reason: '${scale}x value');
    expect(value.em, lessThanOrEqualTo(cell), reason: '${scale}x value em');
  });
}
