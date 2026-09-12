import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/note_ink.dart';
import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/persistence/domain/note_enums.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';

import 'support/recording_canvas.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

Board _applied(BoardEdit edit) => (edit as EditApplied).board;

Board _withNotes(Map<int, List<int>> notes) {
  var board = _board();
  for (final entry in notes.entries) {
    for (final digit in entry.value) {
      board = _applied(board.toggleNote(entry.key, digit));
    }
  }
  return board;
}

/// A board carrying both inks, so the rule is drawn beside candidates without
/// one.
Board _withInks(Map<int, List<int>> settled, Map<int, List<int>> provisional) {
  var board = _withNotes(settled);
  for (final entry in provisional.entries) {
    for (final digit in entry.value) {
      board = _applied(
        board.toggleNote(entry.key, digit, ink: NoteKind.provisional),
      );
    }
  }
  return board;
}

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Widget _host(
  Board board, {
  int? highlighted,
  int? selected,
  GridColours? colours,
  Color background = const Color(0xFFE4D4AE),
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: background,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 360,
          height: 360,
          child: PuzzleGrid(
            board: board,
            selectedCell: selected,
            highlightedDigit: highlighted,
            colours: colours,
            onCellTapped: (_) {},
          ),
        ),
      ),
    ),
  ),
);

/// A season that repaints both surfaces, to prove the state colours do not
/// move with it (D-55).
const SeasonTheme _otherSeason = SeasonTheme(
  id: 'test-season',
  name: 'Test Season',
  bone: 0xE8F1E0,
  sand: 0xCBDCC0,
);

/// Rasterises just the painter, so two boards can be compared pixel for pixel.
Future<ui.Image> _render(Board board) {
  final recorder = ui.PictureRecorder();
  GridPainter(
    board: board,
    selectedCell: null,
    textScale: 1,
    colours: GridColours.standard(),
  ).paint(Canvas(recorder), const Size(360, 360));
  return recorder.endRecording().toImage(360, 360);
}

Future<List<int>> _pixels(Board board) async {
  final image = await _render(board);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List().toList();
}

void main() {
  setUpAll(_loadFont);

  testWidgets('a cell with one candidate and a cell with nine', (tester) async {
    await tester.pumpWidget(
      _host(
        _withNotes(<int, List<int>>{
          2: <int>[5],
          3: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        }),
      ),
    );
    await expectLater(
      find.byType(PuzzleGrid),
      matchesGoldenFile('goldens/notes_one_and_nine.png'),
    );
  });

  testWidgets('a board carrying both notes and values', (tester) async {
    var board = _withNotes(<int, List<int>>{
      2: <int>[1, 4, 7],
      5: <int>[2, 5, 8],
      11: <int>[3, 6, 9],
      21: <int>[1, 5, 9],
    });
    board = _applied(board.place(23, 2));
    board = _applied(board.place(24, 7));

    await tester.pumpWidget(_host(board));
    await expectLater(
      find.byType(PuzzleGrid),
      matchesGoldenFile('goldens/notes_and_values.png'),
    );
  });

  // **The reflow test.** Constraint 3, and the defect the backlog names as the
  // hidden cause of an app feeling bad. Nobody reports it, because a player
  // cannot say why the board is hard to read — only a pixel comparison catches
  // it.
  group('removing a candidate moves nothing', () {
    test('every other glyph is at the pixel it was at', () async {
      final all = _withNotes(<int, List<int>>{
        40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      });
      final without5 = _applied(all.toggleNote(40, 5));

      // The reference: the same eight candidates, marked directly, never
      // having held a fifth. If removal reflowed, these two would differ.
      final never5 = _withNotes(<int, List<int>>{
        40: <int>[1, 2, 3, 4, 6, 7, 8, 9],
      });

      expect(without5.notesAt(40), never5.notesAt(40));
      expect(await _pixels(without5), await _pixels(never5));
    });

    test('whichever candidate goes, the rest hold their pixels', () async {
      for (final removed in <int>[1, 3, 5, 7, 9]) {
        final all = _withNotes(<int, List<int>>{
          40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        });
        final after = _applied(all.toggleNote(40, removed));
        final direct = _withNotes(<int, List<int>>{
          40: <int>[
            for (var digit = 1; digit <= 9; digit++)
              if (digit != removed) digit,
          ],
        });

        expect(
          await _pixels(after),
          await _pixels(direct),
          reason: 'removing $removed moved something',
        );
      }
    });

    test('the order candidates were marked in leaves no trace', () async {
      final ascending = _withNotes(<int, List<int>>{
        40: <int>[2, 4, 6, 8],
      });
      final descending = _withNotes(<int, List<int>>{
        40: <int>[8, 6, 4, 2],
      });

      expect(await _pixels(ascending), await _pixels(descending));
    });

    test(
      'a candidate sits in the same place however full the cell is',
      () async {
        final lonely = _withNotes(<int, List<int>>{
          40: <int>[5],
        });
        final crowded = _withNotes(<int, List<int>>{
          40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        });

        // Strip the crowded cell back to just the 5 and it must match exactly.
        var stripped = crowded;
        for (final digit in <int>[1, 2, 3, 4, 6, 7, 8, 9]) {
          stripped = _applied(stripped.toggleNote(40, digit));
        }
        expect(await _pixels(stripped), await _pixels(lonely));
      },
    );
  });

  group('the ink', () {
    test('notes use the settled token and nothing else', () {
      expect(GridColours.standard().settledNote, NoteInk.settled.token.colour);
      expect(NoteInk.settled.token, PaletteToken.nightIndigo);
    });

    // Retired guard. Until `add-provisional-notes` this asserted the painter
    // never touched the second ink, so that change would inherit a renderer
    // with one. It now asserts the opposite half — both inks, both from
    // tokens, and no third.
    test('the provisional ink comes from its token', () {
      expect(
        GridColours.standard().provisionalNote,
        NoteInk.provisional.token.colour,
      );
      expect(NoteInk.provisional.token, PaletteToken.turquoise);
    });

    test('there are two note inks and no third', () {
      expect(NoteInk.values, hasLength(2));
      final colours = GridColours.standard();
      expect(colours.settledNote, isNot(colours.provisionalNote));
    });

    // Constraint 5, stated where the tokens are chosen rather than only where
    // they are drawn: the underline is not decoration, it is the distinction.
    test('only the provisional ink carries a rule', () {
      expect(NoteInk.settled.isUnderlined, isFalse);
      expect(NoteInk.provisional.isUnderlined, isTrue);
    });
  });

  // This test is named for a guarantee it did not make. It asserted no
  // exception and the *widget's* own size, both of which held while every
  // glyph inside overflowed its slot from 1.5x — which is how that shipped.
  // It now measures the glyphs (D-92).
  testWidgets('notes stay inside their cell at the largest type', (
    tester,
  ) async {
    for (final scale in <double>[1, 1.5, 2, 3]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: _host(
            _withNotes(<int, List<int>>{
              40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
            }),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'at ${scale}x');
      expect(tester.getSize(find.byType(PuzzleGrid)), const Size(360, 360));

      final painter = GridPainter(
        board: _withNotes(<int, List<int>>{
          40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        }),
        selectedCell: null,
        textScale: scale,
        colours: GridColours.standard(),
      );
      painter.paint(RecordingCanvas(), const Size(360, 360));

      const slot = 40.0 / 3;
      for (var digit = 1; digit <= 9; digit++) {
        final glyph = painter.debugNoteGlyphBox(digit);
        expect(
          glyph.width,
          lessThanOrEqualTo(slot),
          reason: 'digit $digit at ${scale}x',
        );
        expect(
          glyph.em,
          lessThanOrEqualTo(slot),
          reason: 'digit $digit at ${scale}x',
        );
      }
    }
  });

  // D-13 rendered. The tint is `nightIndigo` paled — the candidate token's own
  // derivative, never a ninth hue (constraint 4).
  group('candidate highlighting', () {
    testWidgets('a highlighted digit across candidates and values', (
      tester,
    ) async {
      final board = _withNotes(<int, List<int>>{
        2: <int>[1, 4, 7],
        11: <int>[4, 9],
        40: <int>[2, 4, 6, 8],
        21: <int>[3, 5],
      });

      await tester.pumpWidget(_host(board, highlighted: 4));
      await expectLater(
        find.byType(PuzzleGrid),
        matchesGoldenFile('goldens/highlight_four.png'),
      );
    });

    // D-49: the player's current focus always wins where highlights compete.
    testWidgets('selection sits on top of the highlight', (tester) async {
      final board = _withNotes(<int, List<int>>{
        2: <int>[1, 4, 7],
        11: <int>[4, 9],
        40: <int>[2, 4, 6, 8],
      });

      await tester.pumpWidget(_host(board, highlighted: 4, selected: 11));
      await expectLater(
        find.byType(PuzzleGrid),
        matchesGoldenFile('goldens/highlight_under_selection.png'),
      );
    });

    testWidgets('a season repaints the paper and not the highlight', (
      tester,
    ) async {
      final board = _withNotes(<int, List<int>>{
        2: <int>[1, 4, 7],
        11: <int>[4, 9],
        40: <int>[2, 4, 6, 8],
        21: <int>[3, 5],
      });

      await tester.pumpWidget(
        _host(
          board,
          highlighted: 4,
          colours: GridColours.forSeason(const SeasonPalette(_otherSeason)),
          background: const Color(0xFFCBDCC0),
        ),
      );
      await expectLater(
        find.byType(PuzzleGrid),
        matchesGoldenFile('goldens/highlight_other_season.png'),
      );
    });

    test('the tint is the same in every season', () {
      final standard = GridColours.standard();
      final seasonal = GridColours.forSeason(const SeasonPalette(_otherSeason));

      expect(seasonal.candidateFill, standard.candidateFill);
      expect(seasonal.settledNote, standard.settledNote);
      // The paper did move, or the test proves nothing.
      expect(seasonal.cell, isNot(standard.cell));
    });

    test('the tint is the candidate token and not a ninth hue', () {
      final colours = GridColours.standard();
      expect(colours.candidateFill, PaletteToken.nightIndigo.paleColour);
      expect(colours.candidateFill, isNot(NoteInk.provisional.token.colour));
    });
  });

  // D-11 and D-73 rendered. The rule is 1px, 1.5px below the baseline, inside
  // the candidate's own third of the cell.
  group('the provisional ink', () {
    testWidgets('a cell holding all nine in mixed inks', (tester) async {
      final board = _withInks(
        <int, List<int>>{
          40: <int>[1, 3, 5, 7, 9],
        },
        <int, List<int>>{
          40: <int>[2, 4, 6, 8],
        },
      );

      await tester.pumpWidget(_host(board));
      await expectLater(
        find.byType(PuzzleGrid),
        matchesGoldenFile('goldens/inks_mixed_full_cell.png'),
      );
    });

    testWidgets('a board carrying both inks beside values', (tester) async {
      var board = _withInks(
        <int, List<int>>{
          2: <int>[1, 4, 7],
          11: <int>[3, 6],
        },
        <int, List<int>>{
          21: <int>[2, 5, 8],
          40: <int>[9],
        },
      );
      board = _applied(board.place(23, 2));

      await tester.pumpWidget(_host(board));
      await expectLater(
        find.byType(PuzzleGrid),
        matchesGoldenFile('goldens/inks_board.png'),
      );
    });

    // Deliberately not a golden. At 3x the whole grid overflows its cells —
    // givens included — which predates this change and is untested for: the
    // large-type test below only asserts no exception and the widget's own
    // size, despite its name. A golden here would enshrine that as correct.
    // What matters for *this* change is that the rule is still drawn, and
    // still inside the candidate's own third.
    test('the rule survives the largest dynamic type', () {
      for (final scale in <double>[1, 2, 3]) {
        final canvas = RecordingCanvas();
        GridPainter(
          board: _withInks(const <int, List<int>>{}, <int, List<int>>{
            40: <int>[1, 5, 9],
          }),
          selectedCell: null,
          textScale: scale,
          colours: GridColours.standard(),
        ).paint(canvas, const Size(360, 360));

        final rules = canvas.linesIn(GridColours.standard().provisionalNote);
        expect(rules, hasLength(3), reason: 'at ${scale}x');

        final metrics = GridMetrics.fit(const Size(360, 360));
        final cell = metrics.cellRect(40);
        final slot = cell.width / 3;

        // The guarantee is that a rule never *crosses* a slot boundary — if it
        // did it would start reading as belonging to the candidate next door.
        // Asserted as "both ends fall in the same third", which holds however
        // wide the glyph above it has grown.
        //
        // Both ends are inset by a hair first. A rule exactly one slot wide
        // sits *on* two boundaries, and which side of one it lands on is
        // floating-point noise — 186.66666666666666 against the slot's own
        // 186.66666666666669. Without the inset the test reports a crossing
        // that is not there.
        const nudge = 0.01;
        int thirdOf(double offset) =>
            ((offset - cell.left) / slot).clamp(0, 2.999).floor();

        for (final rule in rules) {
          expect(
            rule.$1.dx,
            greaterThanOrEqualTo(cell.left),
            reason: '${scale}x',
          );
          expect(
            rule.$2.dx,
            lessThanOrEqualTo(cell.right),
            reason: '${scale}x',
          );
          expect(
            rule.$1.dy,
            greaterThanOrEqualTo(cell.top),
            reason: '${scale}x',
          );
          expect(
            rule.$1.dy,
            lessThanOrEqualTo(cell.bottom),
            reason: '${scale}x',
          );
          expect(
            thirdOf(rule.$2.dx - nudge),
            thirdOf(rule.$1.dx + nudge),
            reason: 'a rule crossed a slot boundary at ${scale}x',
          );
          expect(
            rule.$2.dx - rule.$1.dx,
            lessThanOrEqualTo(slot + 0.001),
            reason: 'a rule is wider than its slot at ${scale}x',
          );
        }
      }
    });

    // **The reflow test, re-run with the rule present.** `add-notes` proved a
    // candidate does not move when another is removed. This proves it does not
    // move when another is *re-inked* — the new way constraint 3 could break.
    test('re-inking a candidate moves no other glyph', () async {
      final before = _withInks(<int, List<int>>{
        40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      }, const <int, List<int>>{});
      final after = _applied(
        before.toggleNote(40, 5, ink: NoteKind.provisional),
      );

      // The reference: the same nine candidates with the 5 marked provisional
      // from the start. If re-inking reflowed, these two would differ.
      final never = _withInks(
        <int, List<int>>{
          40: <int>[1, 2, 3, 4, 6, 7, 8, 9],
        },
        <int, List<int>>{
          40: <int>[5],
        },
      );

      expect(after.notesAt(40).digits, never.notesAt(40).digits);
      expect(after.notesAt(40).provisional, never.notesAt(40).provisional);
      expect(after.notesAt(40).settled, never.notesAt(40).settled);
    });

    testWidgets('re-inking draws the same board as marking it that way', (
      tester,
    ) async {
      final reInked = _applied(
        _withInks(
          <int, List<int>>{
            40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
          },
          const <int, List<int>>{},
        ).toggleNote(40, 5, ink: NoteKind.provisional),
      );

      await tester.pumpWidget(_host(reInked));
      await expectLater(
        find.byType(PuzzleGrid),
        matchesGoldenFile('goldens/inks_reinked.png'),
      );
    });
  });
}
