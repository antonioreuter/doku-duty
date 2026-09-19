import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import '../grid_input/support/recording_canvas.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

const Size _size = Size(360, 360);

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

String _withHoles(Iterable<int> cells) {
  final digits = _solution.split('');
  for (final cell in cells) {
    digits[cell] = '.';
  }
  return digits.join();
}

Board _boardOf(String source) => Board.forPuzzle(givens: _grid(source));

/// A board where row 0 is filled and every other cell is empty.
///
/// Exactly one **unit** is complete on it — the row. Every column and every
/// block still has eight or six holes, so a test that counts tints or marks is
/// counting that one row and nothing it has to reason about.
Board _onlyRowComplete() => _boardOf(_solution.substring(0, 9) + '.' * 72);

RecordingCanvas _paint(
  Board board, {
  int? selected,
  int? highlighted,
  Set<int> flagged = const <int>{},
  Set<int> fresh = const <int>{},
  bool showTints = true,
}) {
  final canvas = RecordingCanvas();
  GridPainter(
    board: board,
    selectedCell: selected,
    highlightedDigit: highlighted,
    flaggedCells: flagged,
    completedCells: UnitCompletion.tintedCells(board),
    freshCells: fresh,
    showCompletionTints: showTints,
    textScale: 1,
    colours: GridColours.standard(),
  ).paint(canvas, _size);
  return canvas;
}

Rect _cell(int cell) => GridMetrics.fit(_size).cellRect(cell);

void main() {
  final colours = GridColours.standard();

  group('the completion tint is one flat level', () {
    test('a completed row tints its nine cells', () {
      final canvas = _paint(_onlyRowComplete());

      final tinted = canvas.filledWith(colours.completionFill);
      for (final cell in GridGeometry.unitsOfKind(UnitKind.row)[0].cells) {
        expect(
          tinted,
          contains(_cell(cell)),
          reason: 'cell $cell is in the completed row',
        );
      }
    });

    test('a cell in three completed units is filled exactly once', () {
      // Cell 0 is in row 0, column 0, and block 0 — all three complete on a
      // finished board.
      final canvas = _paint(_boardOf(_solution));

      final atCellZero = canvas
          .filledWith(colours.completionFill)
          .where((rect) => rect == _cell(0))
          .toList();

      expect(
        atCellZero.length,
        1,
        reason:
            'three completed units, one fill — the tint cannot stack '
            '(D-48)',
      );
    });

    test('a cell in one completed unit and a cell in three look identical', () {
      // One unit: row 0 complete, every column and block still holed.
      final oneUnit = _paint(_onlyRowComplete());
      // Three units: everything complete.
      final threeUnits = _paint(_boardOf(_solution));

      Color fillAt(RecordingCanvas canvas, int cell) {
        final rect = _cell(cell);
        return canvas.fills
            .where((fill) => fill.$1 == rect)
            .map((fill) => fill.$2)
            .last;
      }

      expect(
        fillAt(oneUnit, 0).toARGB32(),
        fillAt(threeUnits, 0).toARGB32(),
        reason:
            'a cell in three completed units looks identical to a cell in '
            'one (D-48)',
      );
    });

    test('an uncompleted board tints nothing', () {
      final canvas = _paint(
        _boardOf(_withHoles(<int>[0, 12, 24, 28, 40, 52, 56, 68, 80])),
      );

      expect(canvas.filledWith(colours.completionFill), isEmpty);
    });
  });

  group('the corner mark carries completion without colour', () {
    test('every tinted cell carries a mark', () {
      final canvas = _paint(_onlyRowComplete());

      final marks = canvas.pathBoundsIn(colours.completionMark);
      expect(marks.length, 9, reason: 'nine cells in the completed row');
    });

    test('the mark sits inside its own cell', () {
      final canvas = _paint(_onlyRowComplete());

      for (final bounds in canvas.pathBoundsIn(colours.completionMark)) {
        final owner = GridGeometry.unitsOfKind(UnitKind.row)[0].cells
            .map(_cell)
            .firstWhere((rect) => rect.contains(bounds.center));
        expect(
          owner.contains(bounds.topLeft) && owner.contains(bounds.bottomRight),
          isTrue,
          reason: 'a mark that left its cell would read as the next cell\'s',
        );
      }
    });

    test('hiding the tints leaves the marks', () {
      final canvas = _paint(_onlyRowComplete(), showTints: false);

      expect(
        canvas.filledWith(colours.completionFill),
        isEmpty,
        reason: 'the player asked for no tint',
      );
      expect(
        canvas.pathBoundsIn(colours.completionMark).length,
        9,
        reason:
            'completion is still readable — the mark is the signal and the '
            'tint was the convenience (D-50, constraint 5)',
      );
    });

    test('a mark never lands on a candidate, because it cannot', () {
      // A complete unit holds nine values, and a cell holds a value or notes
      // and never both — so no tinted cell has a candidate to collide with.
      final board = _onlyRowComplete();

      for (final cell in UnitCompletion.tintedCells(board)) {
        expect(
          board.notesAt(cell).isEmpty,
          isTrue,
          reason: 'cell $cell is tinted and holds candidates',
        );
      }
    });
  });

  group('the player\'s focus outranks the tint (D-49)', () {
    // The painter draws back to front, so the fill applied last is the one the
    // player sees. Each of these asserts that ordering rather than a pixel.
    Color topFillAt(RecordingCanvas canvas, int cell) {
      final rect = _cell(cell);
      return canvas.fills
          .where((fill) => fill.$1 == rect)
          .map((fill) => fill.$2)
          .last;
    }

    test('selection wins over the completion tint', () {
      final canvas = _paint(_onlyRowComplete(), selected: 0);

      expect(topFillAt(canvas, 0).toARGB32(), colours.focusFill.toARGB32());
    });

    test('candidate highlighting wins over the completion tint', () {
      final board = _onlyRowComplete();
      final canvas = _paint(board, highlighted: board.digitAt(0));

      expect(topFillAt(canvas, 0).toARGB32(), colours.candidateFill.toARGB32());
    });

    test('a flag wins over the completion tint', () {
      final canvas = _paint(_onlyRowComplete(), flagged: <int>{0});

      expect(topFillAt(canvas, 0).toARGB32(), colours.flaggedFill.toARGB32());
    });

    test('selection still wins with all four competing', () {
      final board = _onlyRowComplete();
      final canvas = _paint(
        board,
        selected: 0,
        highlighted: board.digitAt(0),
        flagged: <int>{0},
      );

      expect(
        topFillAt(canvas, 0).toARGB32(),
        colours.focusFill.toARGB32(),
        reason:
            'selection, then candidate highlighting, then the flag, then '
            'the completion tint (D-49)',
      );
    });

    test('the fresh flash still yields to selection', () {
      final canvas = _paint(_onlyRowComplete(), selected: 0, fresh: <int>{0});

      expect(topFillAt(canvas, 0).toARGB32(), colours.focusFill.toARGB32());
    });
  });

  group('the fresh flash is a different state from the record', () {
    test('a fresh cell takes the warmer colour over the settled tint', () {
      final canvas = _paint(_onlyRowComplete(), fresh: <int>{0});

      final atCellZero = canvas.fills
          .where((fill) => fill.$1 == _cell(0))
          .map((fill) => fill.$2.toARGB32())
          .toList();

      expect(atCellZero.last, colours.freshCompletionFill.toARGB32());
      expect(
        atCellZero,
        contains(colours.completionFill.toARGB32()),
        reason: 'the record is underneath the celebration, not replaced by it',
      );
    });

    test('a cell with no fresh flash takes the settled tint', () {
      final canvas = _paint(_onlyRowComplete());

      expect(
        canvas.filledWith(colours.freshCompletionFill),
        isEmpty,
        reason: 'nothing completed just now',
      );
    });
  });
}
