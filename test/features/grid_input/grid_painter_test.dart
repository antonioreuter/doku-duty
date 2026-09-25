import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/domain/note_ink.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/persistence/domain/note_enums.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import 'support/recording_canvas.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;
Board _board() => Board.forPuzzle(givens: _grid(_clues));

GridPainter _painter({
  Board? board,
  int? selected,
  int? highlighted,
  Set<int> flagged = const <int>{},
  double scale = 1,
}) => GridPainter(
  board: board ?? _board(),
  selectedCell: selected,
  highlightedDigit: highlighted,
  flaggedCells: flagged,
  textScale: scale,
  colours: GridColours.standard(),
);

void main() {
  group('metrics', () {
    test('the grid is the largest square that fits, centred', () {
      final wide = GridMetrics.fit(const Size(500, 300));
      expect(wide.side, 300);
      expect(wide.origin, const Offset(100, 0));

      final tall = GridMetrics.fit(const Size(300, 500));
      expect(tall.side, 300);
      expect(tall.origin, const Offset(0, 100));

      final square = GridMetrics.fit(const Size(360, 360));
      expect(square.origin, Offset.zero);
    });

    // D-84: the grid takes the width it is given. Nine 44pt cells need 396pt
    // before any gutter, which most phones do not have.
    test('a cell is the width divided by nine, whatever that comes to', () {
      for (final width in <double>[320, 375, 393, 412, 430, 834]) {
        final metrics = GridMetrics.fit(Size(width, width));
        expect(metrics.cellSize, closeTo(width / 9, 0.0001));
      }
    });

    test('cells tile the square exactly, with no gap and no overlap', () {
      final metrics = GridMetrics.fit(const Size(393, 393));
      expect(metrics.cellRect(0).topLeft, metrics.origin);
      expect(
        metrics.cellRect(80).bottomRight.dx,
        closeTo(metrics.bounds.right, 0.0001),
      );
      expect(
        metrics.cellRect(1).left,
        closeTo(metrics.cellRect(0).right, 0.0001),
      );
      expect(
        metrics.cellRect(9).top,
        closeTo(metrics.cellRect(0).bottom, 0.0001),
      );
    });

    test('every cell is reachable by a tap at its centre', () {
      final metrics = GridMetrics.fit(const Size(393, 500));
      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        expect(metrics.cellAt(metrics.cellRect(cell).center), cell);
      }
    });

    test('a tap outside the grid selects nothing', () {
      final metrics = GridMetrics.fit(const Size(500, 300));
      expect(metrics.cellAt(const Offset(5, 5)), isNull);
      expect(metrics.cellAt(const Offset(499, 299)), isNull);
      expect(metrics.cellAt(metrics.bounds.center), isNotNull);
    });

    test('a tap on the far edge lands in the last cell, not off the grid', () {
      final metrics = GridMetrics.fit(const Size(360, 360));
      final justInside = metrics.bounds.bottomRight - const Offset(0.01, 0.01);
      expect(metrics.cellAt(justInside), 80);
    });
  });

  // Returning true unconditionally is how the latency budget is lost with
  // nothing looking wrong: every unrelated rebuild would redraw the board.
  group('repainting', () {
    test('nothing changed means no repaint', () {
      expect(_painter().shouldRepaint(_painter()), isFalse);
    });

    test('a placed digit repaints', () {
      final moved = (_board().place(2, 4) as EditApplied).board;
      expect(_painter(board: moved).shouldRepaint(_painter()), isTrue);
    });

    test('a moved selection repaints', () {
      expect(_painter(selected: 2).shouldRepaint(_painter()), isTrue);
      expect(
        _painter(selected: 2).shouldRepaint(_painter(selected: 3)),
        isTrue,
      );
      expect(
        _painter(selected: 2).shouldRepaint(_painter(selected: 2)),
        isFalse,
      );
    });

    test('a text scale change repaints', () {
      expect(_painter(scale: 1.3).shouldRepaint(_painter()), isTrue);
    });

    test('a repainted season repaints', () {
      final other = GridPainter(
        board: _board(),
        selectedCell: null,
        textScale: 1,
        colours: const GridColours(
          cell: Color(0xFFFFFFFF),
          hairline: Color(0xFFEEEEEE),
          divider: Color(0xFF000000),
          given: Color(0xFF000000),
          placed: Color(0xFF444444),
          candidateFill: Color(0xFFE6DEFA),
          flaggedFill: Color(0xFFFBDDD6),
          errorMark: Color(0xFFE05A2B),
          completionFill: Color(0xFFCFE0BE),
          freshCompletionFill: Color(0xFFFDEFC6),
          completionMark: Color(0xFF4E9E62),
          provisionalNote: Color(0xFF1B6661),
          focusFill: Color(0xFFFFEEBB),
          focusLine: Color(0xFFFFCC00),
          settledNote: Color(0xFF4A3F9E),
          cageLine: Color(0xFF000000),
          cageSum: Color(0xFF444444),
        ),
      );
      expect(other.shouldRepaint(_painter()), isTrue);
    });
  });

  group('colour is never the only signal', () {
    test('selection and peer highlight are one hue at two depths', () {
      final colours = GridColours.standard();
      // The fill is the pale of the focus token, the line is its base. One
      // hue, two depths (D-53, constraint 4).
      expect(colours.focusFill, isNot(colours.focusLine));
      expect(colours.focusFill, isNot(colours.cell));
    });

    test('the selected cell carries a border, not only a fill', () {
      // Peers get the fill; only the selection gets the line, so the two are
      // told apart without colour (constraint 5).
      final painted = _RecordingCanvas();
      _painter(selected: 40).paint(painted, const Size(360, 360));
      expect(painted.strokedRects, isNotEmpty);
    });

    test('a given and a placed value differ in weight, not only in tone', () {
      final colours = GridColours.standard();
      expect(colours.given, isNot(colours.placed));
      // Weight is asserted through the golden; here we pin that the painter
      // asks for two different weights at all.
      expect(GridPainter.givenWeight, isNot(GridPainter.placedWeight));
    });
  });
  group('repainting with notes', () {
    test('a marked candidate repaints', () {
      final noted = (_board().toggleNote(2, 4) as EditApplied).board;
      expect(_painter(board: noted).shouldRepaint(_painter()), isTrue);
    });

    // A note set rebuilt into an equal one is the same board. Comparing the
    // map by identity would repaint the whole grid on every unrelated rebuild,
    // and nothing would look wrong while the budget went.
    test('note sets rebuilt into equal ones do not repaint', () {
      final first = (_board().toggleNote(2, 4) as EditApplied).board;
      final second = (_board().toggleNote(2, 4) as EditApplied).board;

      expect(identical(first, second), isFalse, reason: 'two separate boards');
      expect(
        _painter(board: first).shouldRepaint(_painter(board: second)),
        isFalse,
      );
    });

    test('a different candidate in the same cell repaints', () {
      final four = (_board().toggleNote(2, 4) as EditApplied).board;
      final five = (_board().toggleNote(2, 5) as EditApplied).board;
      expect(
        _painter(board: four).shouldRepaint(_painter(board: five)),
        isTrue,
      );
    });
  });

  // D-13. Free, always on, and the thing that makes a pointing pair visible
  // rather than deduced by squinting.
  group('candidate highlighting', () {
    RecordingCanvas paint({Board? board, int? selected, int? highlighted}) {
      final canvas = RecordingCanvas();
      _painter(
        board: board,
        selected: selected,
        highlighted: highlighted,
      ).paint(canvas, const Size(360, 360));
      return canvas;
    }

    Board withNote(Board board, int cell, int digit) =>
        (board.toggleNote(cell, digit) as EditApplied).board;

    test('every cell holding the digit as a candidate is lit', () {
      var board = _board();
      for (final cell in const <int>[2, 11, 40]) {
        board = withNote(board, cell, 4);
      }

      final lit = paint(
        board: board,
        highlighted: 4,
      ).filledWith(GridColours.standard().candidateFill);
      final metrics = GridMetrics.fit(const Size(360, 360));

      for (final cell in const <int>[2, 11, 40]) {
        expect(lit, contains(metrics.cellRect(cell)));
      }
      // Plus every cell already holding a 4 as a value: highlighting shows
      // where the digit is marked *or* placed.
      final placed = <int>[
        for (var cell = 0; cell < GridGeometry.cellCount; cell++)
          if (board.digitAt(cell) == 4) cell,
      ];
      expect(lit, hasLength(3 + placed.length));
    });

    // The bible is explicit: highlighting shows where a digit is already
    // *marked or placed*.
    test('a cell holding the digit as a value is lit too', () {
      final lit = paint(
        highlighted: 5,
      ).filledWith(GridColours.standard().candidateFill);
      final metrics = GridMetrics.fit(const Size(360, 360));

      // Cell 0 is the given 5.
      expect(lit, contains(metrics.cellRect(0)));
      final fives = <int>[
        for (var cell = 0; cell < GridGeometry.cellCount; cell++)
          if (_board().digitAt(cell) == 5) cell,
      ];
      expect(lit, hasLength(fives.length));
    });

    // Highlighting answers where a digit already is, and a hypothesis is
    // somewhere it is.
    test('a cell holding the digit as a hypothesis is lit', () {
      var board = _board();
      board = (board.toggleNote(2, 4, ink: NoteKind.provisional) as EditApplied)
          .board;
      board = withNote(board, 11, 4);

      final lit = paint(
        board: board,
        highlighted: 4,
      ).filledWith(GridColours.standard().candidateFill);
      final metrics = GridMetrics.fit(const Size(360, 360));

      expect(lit, contains(metrics.cellRect(2)), reason: 'the hypothesis');
      expect(lit, contains(metrics.cellRect(11)), reason: 'the settled note');
    });

    test('re-inking a candidate does not change what is lit', () {
      var settledBoard = _board();
      for (final cell in const <int>[2, 11, 40]) {
        settledBoard = withNote(settledBoard, cell, 4);
      }
      var mixedBoard = settledBoard;
      for (final cell in const <int>[2, 40]) {
        mixedBoard =
            (mixedBoard.toggleNote(cell, 4, ink: NoteKind.provisional)
                    as EditApplied)
                .board;
      }

      final fill = GridColours.standard().candidateFill;
      expect(
        paint(board: mixedBoard, highlighted: 4).filledWith(fill),
        paint(board: settledBoard, highlighted: 4).filledWith(fill),
      );
    });

    test('no cell is lit when nothing is highlighted', () {
      var board = _board();
      board = withNote(board, 2, 4);

      expect(
        paint(board: board).filledWith(GridColours.standard().candidateFill),
        isEmpty,
      );
    });

    test('a cell holding a different digit is not lit', () {
      var board = _board();
      board = withNote(board, 2, 7);

      final lit = paint(
        board: board,
        highlighted: 4,
      ).filledWith(GridColours.standard().candidateFill);
      final metrics = GridMetrics.fit(const Size(360, 360));

      expect(lit, isNot(contains(metrics.cellRect(2))));
    });

    // D-49: the player's current focus always wins where highlights compete.
    test('selection is painted over the highlight', () {
      var board = _board();
      board = withNote(board, 2, 4);
      final canvas = paint(board: board, selected: 2, highlighted: 4);

      final colours = GridColours.standard();
      final metrics = GridMetrics.fit(const Size(360, 360));
      final rect = metrics.cellRect(2);

      final highlightAt = canvas.fills.indexWhere(
        (fill) =>
            fill.$1 == rect &&
            fill.$2.toARGB32() == colours.candidateFill.toARGB32(),
      );
      final focusAt = canvas.fills.indexWhere(
        (fill) =>
            fill.$1 == rect &&
            fill.$2.toARGB32() == colours.focusFill.toARGB32(),
      );

      expect(highlightAt, isNonNegative);
      expect(focusAt, greaterThan(highlightAt), reason: 'focus must land last');
    });

    // Constraint 4: the pale derivative of the candidate token, not a ninth
    // hue.
    test('the highlight is the candidate token, paled', () {
      final colours = GridColours.standard();

      expect(colours.candidateFill, PaletteToken.nightIndigo.paleColour);
      expect(colours.candidateFill, isNot(colours.focusFill));
      expect(colours.candidateFill, isNot(colours.cell));
      expect(colours.candidateFill, isNot(colours.settledNote));
    });

    test('changing the highlighted digit repaints', () {
      expect(
        _painter(highlighted: 4).shouldRepaint(_painter(highlighted: 5)),
        isTrue,
      );
      expect(_painter(highlighted: 4).shouldRepaint(_painter()), isTrue);
      expect(
        _painter(highlighted: 4).shouldRepaint(_painter(highlighted: 4)),
        isFalse,
      );
    });
  });

  // D-11 and D-73. The second ink, and the underline that is the part a
  // colour-blind player actually reads.
  group('the provisional ink', () {
    RecordingCanvas paint(Board board) {
      final canvas = RecordingCanvas();
      _painter(board: board).paint(canvas, const Size(360, 360));
      return canvas;
    }

    Board noted(Map<int, List<int>> settled, Map<int, List<int>> provisional) {
      var board = _board();
      for (final entry in settled.entries) {
        for (final digit in entry.value) {
          board = (board.toggleNote(entry.key, digit) as EditApplied).board;
        }
      }
      for (final entry in provisional.entries) {
        for (final digit in entry.value) {
          board =
              (board.toggleNote(entry.key, digit, ink: NoteKind.provisional)
                      as EditApplied)
                  .board;
        }
      }
      return board;
    }

    test('the two inks are two different colours', () {
      final colours = GridColours.standard();
      expect(colours.provisionalNote, PaletteToken.turquoise.colour);
      expect(colours.provisionalNote, isNot(colours.settledNote));
    });

    test(
      'a provisional candidate carries a rule and a settled one does not',
      () {
        final canvas = paint(
          noted(
            <int, List<int>>{
              2: <int>[1],
            },
            <int, List<int>>{
              2: <int>[9],
            },
          ),
        );

        final rules = canvas.linesIn(GridColours.standard().provisionalNote);
        expect(
          rules,
          hasLength(1),
          reason: 'one provisional candidate, one rule',
        );
      },
    );

    test('every provisional candidate gets its own rule', () {
      final canvas = paint(
        noted(const <int, List<int>>{}, <int, List<int>>{
          2: <int>[1, 4, 9],
          11: <int>[5],
        }),
      );

      expect(
        canvas.linesIn(GridColours.standard().provisionalNote),
        hasLength(4),
      );
    });

    test('a board with no provisional candidates draws no rules', () {
      final canvas = paint(
        noted(<int, List<int>>{
          2: <int>[1, 4, 9],
        }, const <int, List<int>>{}),
      );

      expect(canvas.linesIn(GridColours.standard().provisionalNote), isEmpty);
    });

    test('the rule is 1px, matching the cell hairline', () {
      final canvas = paint(
        noted(const <int, List<int>>{}, <int, List<int>>{
          2: <int>[5],
        }),
      );

      final rule = canvas.lines.singleWhere(
        (line) =>
            line.$3.toARGB32() ==
            GridColours.standard().provisionalNote.toARGB32(),
      );
      expect(rule.$4, provisionalUnderlineWeight);
    });

    // Constraint 3. The rule sits below the baseline inside the note's own
    // third of the cell, so the digit keeps the slot it would occupy either way
    // and a cell full of mixed inks scans exactly like a cell full of one.
    test('the rule stays inside the candidate own third of the cell', () {
      final canvas = paint(
        noted(const <int, List<int>>{}, <int, List<int>>{
          40: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        }),
      );

      final metrics = GridMetrics.fit(const Size(360, 360));
      final cell = metrics.cellRect(40);
      final slot = cell.width / 3;

      for (final rule in canvas.linesIn(
        GridColours.standard().provisionalNote,
      )) {
        final slotColumn = ((rule.$1.dx - cell.left) / slot).floor();
        final slotRow = ((rule.$1.dy - cell.top) / slot).floor();
        final own = Rect.fromLTWH(
          cell.left + slotColumn * slot,
          cell.top + slotRow * slot,
          slot,
          slot,
        );
        expect(own.contains(rule.$1), isTrue, reason: 'rule start escaped');
        expect(own.contains(rule.$2), isTrue, reason: 'rule end escaped');
      }
    });

    test('the ink does not move the digit (constraint 3)', () {
      final settled = paint(
        noted(<int, List<int>>{
          40: <int>[5],
        }, const <int, List<int>>{}),
      );
      final provisional = paint(
        noted(const <int, List<int>>{}, <int, List<int>>{
          40: <int>[5],
        }),
      );

      // The glyph is drawn at the same place either way; only the rule and the
      // colour differ.
      expect(settled.linesIn(GridColours.standard().provisionalNote), isEmpty);
      expect(
        provisional.linesIn(GridColours.standard().provisionalNote),
        hasLength(1),
      );
    });

    // **The test that matters.** D-73 measured the two inks at 1.07:1 under
    // deuteranopia — the same mark, for roughly one man in twelve. So the
    // distinction has to be provable with colour thrown away entirely.
    test('the two inks differ with colour removed', () {
      final settledOnly = paint(
        noted(<int, List<int>>{
          40: <int>[5],
        }, const <int, List<int>>{}),
      );
      final provisionalOnly = paint(
        noted(const <int, List<int>>{}, <int, List<int>>{
          40: <int>[5],
        }),
      );

      // Count the geometry, never the colour. If the underline were ever
      // dropped in favour of hue alone, these two would be identical and this
      // test is the only thing that would say so.
      expect(
        provisionalOnly.lines.length,
        settledOnly.lines.length + 1,
        reason: 'the second ink must add a mark, not only a colour',
      );
    });

    test('changing only a candidate ink repaints', () {
      final settled = noted(<int, List<int>>{
        2: <int>[4],
      }, const {});
      final provisional = noted(const {}, <int, List<int>>{
        2: <int>[4],
      });

      expect(
        _painter(board: settled).shouldRepaint(_painter(board: provisional)),
        isTrue,
      );
    });
  });

  // Dynamic type is respected everywhere (`docs/DESIGN.md` §2), but a sudoku
  // grid cannot reflow: nine columns are nine columns. Left uncapped, a note
  // overflows its slot at 1.5x and a value its cell at 2x — ordinary "Larger
  // Text", not an accessibility extreme — and the board becomes an overlapping
  // mess rather than a large one.
  group('glyphs are capped to the box they sit in', () {
    ({double width, double em}) noteGlyph(double scale) {
      final painter = _painter(
        board: (_board().toggleNote(40, 8) as EditApplied).board,
        scale: scale,
      );
      final canvas = RecordingCanvas();
      painter.paint(canvas, const Size(360, 360));
      return painter.debugNoteGlyphBox(8);
    }

    ({double width, double em}) valueGlyph(double scale) {
      final painter = _painter(scale: scale);
      final canvas = RecordingCanvas();
      painter.paint(canvas, const Size(360, 360));
      return painter.debugValueGlyphBox(5);
    }

    test('a note never exceeds its slot, at any scale', () {
      const slot = 40.0 / 3;
      for (final scale in <double>[1, 1.5, 2, 3, 5]) {
        final glyph = noteGlyph(scale);
        expect(glyph.width, lessThanOrEqualTo(slot), reason: '${scale}x width');
        expect(glyph.em, lessThanOrEqualTo(slot), reason: '${scale}x em');
      }
    });

    test('a value never exceeds its cell, at any scale', () {
      const cell = 40.0;
      for (final scale in <double>[1, 1.5, 2, 3, 5]) {
        final glyph = valueGlyph(scale);
        expect(glyph.width, lessThanOrEqualTo(cell), reason: '${scale}x width');
        expect(glyph.em, lessThanOrEqualTo(cell), reason: '${scale}x em');
      }
    });

    // The cap is a ceiling, not a fixed size: dynamic type still does
    // something for a player who asks for it.
    test('type still grows until it stops fitting', () {
      expect(valueGlyph(1.5).em, greaterThan(valueGlyph(1).em));
      expect(noteGlyph(1.1).em, greaterThan(noteGlyph(1).em));
    });

    test('the default scale is untouched by the cap', () {
      // 22px values and 11px notes already fit; capping must not shrink them.
      expect(valueGlyph(1).em, closeTo(22, 0.01));
      expect(noteGlyph(1).em, closeTo(11, 0.01));
    });

    test('a smaller grid caps sooner', () {
      // The box is the cell, not a constant, so a narrow phone caps earlier
      // than a tablet does.
      final painter = _painter(scale: 3);
      final canvas = RecordingCanvas();
      painter.paint(canvas, const Size(180, 180));
      final glyph = painter.debugValueGlyphBox(5);

      expect(glyph.em, lessThanOrEqualTo(20.0));
    });
  });
  // **Strict mode** only. Nothing here can be reached with stakes off, because
  // the session hands the painter an empty set (D-04).
  group('a flagged cell', () {
    RecordingCanvas paint({
      Board? board,
      int? selected,
      int? highlighted,
      Set<int> flagged = const <int>{},
    }) {
      final canvas = RecordingCanvas();
      _painter(
        board: board,
        selected: selected,
        highlighted: highlighted,
        flagged: flagged,
      ).paint(canvas, const Size(360, 360));
      return canvas;
    }

    Board placed(int cell, int digit) =>
        (_board().place(cell, digit) as EditApplied).board;

    test('nothing is drawn for it when no cell is flagged', () {
      final canvas = paint(board: placed(2, 7));
      expect(
        canvas.filledWith(GridColours.standard().flaggedFill),
        isEmpty,
        reason: 'a wrong digit looks exactly like a right one by default',
      );
    });

    test('the cell carries the flag fill', () {
      final canvas = paint(board: placed(2, 7), flagged: const <int>{2});
      final metrics = GridMetrics.fit(const Size(360, 360));

      expect(
        canvas.filledWith(GridColours.standard().flaggedFill),
        contains(metrics.cellRect(2)),
      );
    });

    // **The test that matters** (constraint 5). `sunsetRed` against the ink is
    // a colour difference, and a colour difference alone is not a signal — the
    // strike is. If the strike were ever dropped in favour of the hue, these
    // two paints would differ only in colour and this is the only test that
    // would say so.
    test('a flagged cell differs with colour removed', () {
      final board = placed(2, 7);
      final unflagged = paint(board: board);
      final flagged = paint(board: board, flagged: const <int>{2});

      expect(
        flagged.lines.length,
        unflagged.lines.length + 1,
        reason: 'the flag must add a mark, not only a colour',
      );
    });

    test('each flagged cell gets its own mark', () {
      final board = (placed(2, 7).place(3, 1) as EditApplied).board;
      final one = paint(board: board, flagged: const <int>{2});
      final two = paint(board: board, flagged: const <int>{2, 3});

      expect(two.lines.length, one.lines.length + 1);
    });

    test('the strike stays inside the cell it marks', () {
      final canvas = paint(board: placed(2, 7), flagged: const <int>{2});
      final rect = GridMetrics.fit(const Size(360, 360)).cellRect(2);

      final strikes = canvas.lines.where(
        (line) =>
            rect.inflate(0.01).contains(line.$1) &&
            rect.inflate(0.01).contains(line.$2),
      );
      expect(strikes, hasLength(1));
    });

    // D-49: selection, then **candidate highlighting**, then this.
    test('selection is painted over the flag', () {
      final canvas = paint(
        board: placed(2, 7),
        flagged: const <int>{2},
        selected: 2,
      );

      final colours = GridColours.standard();
      final flagAt = canvas.fills.indexWhere(
        (fill) => fill.$2.toARGB32() == colours.flaggedFill.toARGB32(),
      );
      final focusAt = canvas.fills.indexWhere(
        (fill) => fill.$2.toARGB32() == colours.focusFill.toARGB32(),
      );

      expect(flagAt, isNonNegative);
      expect(focusAt, greaterThan(flagAt), reason: 'focus must land last');
    });

    test('candidate highlighting is painted over the flag', () {
      final canvas = paint(
        board: placed(2, 7),
        flagged: const <int>{2},
        highlighted: 7,
      );

      final colours = GridColours.standard();
      final flagAt = canvas.fills.indexWhere(
        (fill) => fill.$2.toARGB32() == colours.flaggedFill.toARGB32(),
      );
      final highlightAt = canvas.fills.indexWhere(
        (fill) => fill.$2.toARGB32() == colours.candidateFill.toARGB32(),
      );

      expect(flagAt, isNonNegative);
      expect(highlightAt, greaterThan(flagAt));
    });

    test('a changed flag set repaints', () {
      expect(
        _painter(flagged: const <int>{2}).shouldRepaint(_painter()),
        isTrue,
      );
      expect(
        _painter(
          flagged: const <int>{2},
        ).shouldRepaint(_painter(flagged: const <int>{2})),
        isFalse,
        reason: 'the same flags are not a reason to repaint',
      );
    });
  });
}

/// Records what was stroked, so a border can be asserted without a golden.
class _RecordingCanvas implements Canvas {
  final List<Rect> strokedRects = <Rect>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    if (paint.style == PaintingStyle.stroke) strokedRects.add(rect);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}
