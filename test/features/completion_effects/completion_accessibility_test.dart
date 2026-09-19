import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/design_system/domain/contrast.dart';
import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import '../grid_input/support/recording_canvas.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

Board _boardOf(String source) => Board.forPuzzle(givens: _grid(source));

/// Row 0 filled, nothing else: exactly one complete **unit**.
Board _oneUnit() => _boardOf(_solution.substring(0, 9) + '.' * 72);

Widget _host(Board board, {bool showTints = true, double textScale = 1}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Center(
          child: SizedBox(
            width: 360,
            height: 360,
            child: PuzzleGrid(
              board: board,
              completedCells: UnitCompletion.tintedCells(board),
              showCompletionTints: showTints,
              onCellTapped: (_) {},
            ),
          ),
        ),
      ),
    );

/// The simple deuteranopia simulation the design system's own checks use:
/// red and green collapse toward a shared channel.
int _deuteranope(int rgb) {
  final r = (rgb >> 16) & 0xFF;
  final g = (rgb >> 8) & 0xFF;
  final b = rgb & 0xFF;
  final merged = ((r * 0.625) + (g * 0.375)).round().clamp(0, 255);
  final merged2 = ((r * 0.7) + (g * 0.3)).round().clamp(0, 255);
  return (merged << 16) | (merged2 << 8) | b;
}

void main() {
  group('completion is readable without colour', () {
    testWidgets('the grid tells a screen reader how much is settled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(_oneUnit()));
      expect(
        find.bySemanticsLabel('Sudoku grid, 1 of 27 groups complete'),
        findsOneWidget,
      );

      await tester.pumpWidget(_host(_boardOf(_solution)));
      expect(
        find.bySemanticsLabel('Sudoku grid, 27 of 27 groups complete'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('an untouched grid announces no completion', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(_boardOf('.' * 81)));
      expect(find.bySemanticsLabel('Sudoku grid'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a unit that disagrees with the solution is counted too', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      // Row 0 is 534678912. Swapping two of its digits leaves nine distinct
      // digits and two wrong ones: still complete, still announced (D-99).
      final digits = _solution.split('');
      digits[6] = '1';
      digits[7] = '9';
      digits[8] = '2';
      final board = _boardOf(digits.join().substring(0, 9) + '.' * 72);

      await tester.pumpWidget(_host(board));
      expect(
        find.bySemanticsLabel('Sudoku grid, 1 of 27 groups complete'),
        findsOneWidget,
        reason:
            'silence where a celebration was expected would tell the '
            'player they are wrong — auto-check by omission (constraint 1)',
      );

      handle.dispose();
    });

    testWidgets('the announcement survives the tints being hidden', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(_oneUnit(), showTints: false));
      expect(
        find.bySemanticsLabel('Sudoku grid, 1 of 27 groups complete'),
        findsOneWidget,
        reason: 'hiding a tint hides a convenience, never a state',
      );

      handle.dispose();
    });

    test('the tint alone would not carry it under deuteranopia', () {
      final tinted = PaletteToken.cactusGreen.pale!;
      const surface = 0xF5EBD6; // bone

      final normal = contrastRatio(tinted, surface);
      final simulated = contrastRatio(
        _deuteranope(tinted),
        _deuteranope(surface),
      );

      // Not a failure — the tint is not asked to carry this alone. The number
      // is here so that anyone tempted to drop the corner mark can see what
      // they would be leaving the state to.
      expect(normal, greaterThan(1.0));
      expect(
        simulated,
        lessThan(2.0),
        reason: 'which is exactly why the corner mark exists (D-50)',
      );
    });

    test('the corner mark is geometry, so it is unaffected by the hue', () {
      final board = _oneUnit();
      final canvas = RecordingCanvas();
      GridPainter(
        board: board,
        selectedCell: null,
        completedCells: UnitCompletion.tintedCells(board),
        showCompletionTints: false,
        textScale: 1,
        colours: GridColours.standard(),
      ).paint(canvas, const Size(360, 360));

      expect(
        canvas.pathBoundsIn(GridColours.standard().completionMark).length,
        GridGeometry.side,
        reason: 'nine marks with no tint underneath any of them',
      );
    });
  });

  group('dynamic type does not displace the corner mark', () {
    for (final scale in <double>[0.85, 1.0, 1.3, 2.0, 3.0]) {
      test('at a text scale of $scale the mark stays in its cell', () {
        final board = _oneUnit();
        final canvas = RecordingCanvas();
        GridPainter(
          board: board,
          selectedCell: null,
          completedCells: UnitCompletion.tintedCells(board),
          textScale: scale,
          colours: GridColours.standard(),
        ).paint(canvas, const Size(360, 360));

        final metrics = GridMetrics.fit(const Size(360, 360));
        final marks = canvas.pathBoundsIn(
          GridColours.standard().completionMark,
        );

        expect(marks.length, GridGeometry.side);
        for (final bounds in marks) {
          final owner = GridGeometry.unitsOfKind(UnitKind.row)[0].cells
              .map(metrics.cellRect)
              .firstWhere((rect) => rect.contains(bounds.center));
          expect(
            owner.contains(bounds.topLeft) &&
                owner.contains(bounds.bottomRight),
            isTrue,
            reason:
                'the mark is sized from the cell, never from the type '
                'scale, so it cannot grow out of its corner (D-92)',
          );
        }
      });
    }
  });
}
