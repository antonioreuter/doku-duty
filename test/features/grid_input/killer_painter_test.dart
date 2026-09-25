import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import '../puzzle_engine/support/killer.dart';
import '../puzzle_engine/support/positions.dart';
import 'support/recording_canvas.dart';

final CageSet _cages = referenceKillerCages(referenceSolution);

Board _killer() => Board.forPuzzle(givens: Grid.empty, cages: _cages);

GridPainter _painter(Board board, {int? selected, double scale = 1}) =>
    GridPainter(
      board: board,
      selectedCell: selected,
      textScale: scale,
      colours: GridColours.standard(),
    );

/// The smallest phone the app targets (D-84), grid at full width.
const Size _smallest = Size(320, 320);

void main() {
  group('the cage layer', () {
    test('a killer board draws dashed outlines in the cage colour', () {
      final canvas = RecordingCanvas();
      _painter(_killer()).paint(canvas, const Size(360, 360));

      final colours = GridColours.standard();
      final outlines = canvas.pathBoundsIn(colours.cageLine);
      expect(outlines, isNotEmpty);
      // Inside the grid, never on its frame.
      expect(
        outlines.single.left,
        greaterThanOrEqualTo(DokuStroke.cageInset - DokuStroke.cageOutline),
      );
    });

    test('a classic board draws no cage layer at all', () {
      final canvas = RecordingCanvas();
      _painter(
        Board.forPuzzle(givens: Grid.empty),
      ).paint(canvas, const Size(360, 360));
      // The cage colour is duskInk, which the frame also uses — so the
      // assertion is on the frame being the only path in it.
      final colours = GridColours.standard();
      expect(canvas.pathBoundsIn(colours.cageLine), isEmpty);
      expect(
        _painter(
          Board.forPuzzle(givens: Grid.empty),
        ).debugCageSumBoxes(const Size(360, 360)),
        isEmpty,
      );
    });

    test('the cage layer is built once per puzzle, not per painter', () {
      _painter(_killer()).paint(RecordingCanvas(), const Size(360, 360));
      final first = GridPainter.debugCageOutlineFor(_cages);
      _painter(
        _killer(),
        selected: 3,
      ).paint(RecordingCanvas(), const Size(360, 360));
      expect(identical(GridPainter.debugCageOutlineFor(_cages), first), isTrue);
    });

    // The cache is keyed per puzzle, and a box that grows along its long side
    // moves the grid without resizing it — a tools row or a banner changing
    // height does exactly that. The outline has to move with the cells.
    test('the outline follows the grid when the box moves it', () {
      final colours = GridColours.standard();
      Rect outlineIn(Size size) {
        final canvas = RecordingCanvas();
        _painter(_killer()).paint(canvas, size);
        return canvas.pathBoundsIn(colours.cageLine).single;
      }

      final square = outlineIn(const Size(360, 360));
      final tall = outlineIn(const Size(360, 480));
      final offset = GridMetrics.fit(const Size(360, 480)).origin;
      expect(offset.dy, 60);
      expect(tall.top, closeTo(square.top + offset.dy, 1e-6));
      expect(tall.left, closeTo(square.left, 1e-6));
    });

    test('one sum per cage, printed in its head cell', () {
      final boxes = _painter(_killer()).debugCageSumBoxes(_smallest);
      expect(boxes.keys.toSet(), <int>{
        for (final cage in _cages.cages) cage.head,
      });
    });
  });

  group('the sum never clips and never meets a note (D-129)', () {
    test('at every text scale on the smallest phone, a sum fits its band', () {
      final cell = GridMetrics.fit(_smallest).cellSize;
      for (final scale in <double>[1, 1.5, 2, 3, 5]) {
        final boxes = _painter(
          _killer(),
          scale: scale,
        ).debugCageSumBoxes(_smallest);
        for (final entry in boxes.entries) {
          expect(
            entry.value.height,
            lessThanOrEqualTo(GridPainter.cageSumBand),
            reason: 'scale $scale, cage at ${entry.key}',
          );
          expect(
            entry.value.width,
            lessThan(cell / 2),
            reason: 'scale $scale, cage at ${entry.key}',
          );
        }
      }
    });

    test('slot 1 starts below the sum band', () {
      final cell = GridMetrics.fit(_smallest).cellRect(0);
      final area = GridPainter.noteArea(cell, isKiller: true);
      expect(area.top, cell.top + GridPainter.cageSumBand);
      expect(area.bottom, lessThanOrEqualTo(cell.bottom));
    });
  });

  group('the note inset (constraint 3)', () {
    test('is the same for every cell of a killer board', () {
      final metrics = GridMetrics.fit(_smallest);
      final first = GridPainter.noteArea(metrics.cellRect(0), isKiller: true);
      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        final rect = metrics.cellRect(cell);
        final area = GridPainter.noteArea(rect, isKiller: true);
        final offset = area.topLeft - rect.topLeft;
        final firstOffset = first.topLeft - metrics.cellRect(0).topLeft;
        expect(offset.dx, closeTo(firstOffset.dx, 1e-9));
        expect(offset.dy, closeTo(firstOffset.dy, 1e-9));
        expect(area.width, closeTo(first.width, 1e-9));
      }
    });

    test('never applies to a classic board', () {
      final rect = GridMetrics.fit(_smallest).cellRect(40);
      expect(GridPainter.noteArea(rect, isKiller: false), rect);
    });

    test('gives D-129\'s note sizes', () {
      for (final (width, slot) in <(double, double)>[(296, 8.3), (351, 10.3)]) {
        final rect = GridMetrics.fit(Size(width, width)).cellRect(0);
        expect(
          GridPainter.noteArea(rect, isKiller: true).width / 3,
          closeTo(slot, 0.1),
          reason: '$width',
        );
      }
    });
  });

  test('selecting a cell marks its cage mates with its peers (D-130)', () {
    final canvas = RecordingCanvas();
    final selected = at(2, 1);
    final mate = at(3, 0);
    _painter(_killer(), selected: selected).paint(canvas, const Size(360, 360));
    final metrics = GridMetrics.fit(const Size(360, 360));
    expect(
      canvas.filledWith(GridColours.standard().focusFill),
      contains(metrics.cellRect(mate)),
    );
  });
}
