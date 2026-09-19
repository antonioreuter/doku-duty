import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/domain/effect_frame.dart';
import 'package:doku_duty/features/completion_effects/domain/particle_pool.dart';
import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import '../grid_input/support/recording_canvas.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

const Size _size = Size(360, 360);

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

Board _rowComplete() =>
    Board.forPuzzle(givens: _grid(_solution.substring(0, 9) + '.' * 72));

Unit _row(int index) => GridGeometry.unitsOfKind(UnitKind.row)[index];

EffectFrame _lassoMidway() => EffectFrame(
  effects: <ActiveEffect>[
    ActiveEffect(unit: _row(0), origin: 4, progress: 0.5),
  ],
  particles: const <Particle>[
    Particle(
      cell: 0,
      offset: (0.5, 0.5),
      age: Duration(milliseconds: 100),
      lifetime: Duration(milliseconds: 260),
    ),
  ],
);

RecordingCanvas _paint({EffectFrame effects = EffectFrame.empty}) {
  final board = _rowComplete();
  final canvas = RecordingCanvas();
  GridPainter(
    board: board,
    selectedCell: null,
    completedCells: UnitCompletion.tintedCells(board),
    effects: effects,
    textScale: 1,
    colours: GridColours.standard(),
  ).paint(canvas, _size);
  return canvas;
}

void main() {
  group('effects draw above the cells and behind the glyphs', () {
    test('every effect mark goes down before the first glyph', () {
      final canvas = _paint(effects: _lassoMidway());

      final firstGlyph = canvas.order.indexOf('glyph');
      final lastCircle = canvas.order.lastIndexOf('circle');

      expect(firstGlyph, isNot(-1), reason: 'the row holds nine values');
      expect(lastCircle, isNot(-1), reason: 'the frame carries a particle');
      expect(
        lastCircle,
        lessThan(firstGlyph),
        reason:
            'a puff drawn after a digit would sit on top of it — the glyph '
            'is the content and the effect is the decoration',
      );
    });

    test('an effect draws nothing when there is nothing celebrating', () {
      final quiet = _paint();
      final celebrating = _paint(effects: _lassoMidway());

      expect(quiet.circles, isEmpty);
      expect(celebrating.circles, isNotEmpty);
    });

    test('the painter repaints when the frame moves and not otherwise', () {
      GridPainter at(EffectFrame frame) => GridPainter(
        board: _rowComplete(),
        selectedCell: null,
        effects: frame,
        textScale: 1,
        colours: GridColours.standard(),
      );

      final midway = _lassoMidway();
      final later = EffectFrame(
        effects: <ActiveEffect>[
          ActiveEffect(unit: _row(0), origin: 4, progress: 0.9),
        ],
        particles: midway.particles,
      );

      expect(at(later).shouldRepaint(at(midway)), isTrue);
      expect(at(midway).shouldRepaint(at(_lassoMidway())), isFalse);
    });
  });

  group('the lasso and the dynamite read differently', () {
    test('a row effect is linear', () {
      final canvas = _paint(effects: _lassoMidway());

      expect(
        canvas.linesIn(GridColours.standard().freshCompletionFill),
        isNotEmpty,
        reason: 'the rope runs the length of the unit',
      );
    });

    test('a block effect is radial, not linear', () {
      final block = GridGeometry.unitsOfKind(UnitKind.block)[0];
      final canvas = _paint(
        effects: EffectFrame(
          effects: <ActiveEffect>[
            ActiveEffect(unit: block, origin: 0, progress: 0.5),
          ],
          particles: const <Particle>[],
        ),
      );

      expect(
        canvas.circles,
        isNotEmpty,
        reason: 'the charge goes off outward, so a block never reads as a row',
      );
      expect(
        canvas.linesIn(GridColours.standard().freshCompletionFill),
        isEmpty,
      );
    });

    test('the rope reaches further as the effect runs', () {
      int ropes(double progress) => _paint(
        effects: EffectFrame(
          effects: <ActiveEffect>[
            ActiveEffect(unit: _row(0), origin: 4, progress: progress),
          ],
          particles: const <Particle>[],
        ),
      ).linesIn(GridColours.standard().freshCompletionFill).length;

      expect(
        ropes(0.9),
        greaterThan(ropes(0.2)),
        reason: 'staggered, so the eye reads direction rather than a flash',
      );
    });
  });
}
