import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
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
  double scale = 1,
}) => GridPainter(
  board: board ?? _board(),
  selectedCell: selected,
  highlightedDigit: highlighted,
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
          focusFill: Color(0xFFFFEEBB),
          focusLine: Color(0xFFFFCC00),
          settledNote: Color(0xFF4A3F9E),
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
