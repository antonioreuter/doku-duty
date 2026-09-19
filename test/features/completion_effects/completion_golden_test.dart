import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/domain/effect_frame.dart';
import 'package:doku_duty/features/completion_effects/domain/particle_pool.dart';
import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Board _boardOf(String source) => Board.forPuzzle(givens: _grid(source));

/// Row 0 filled, nothing else: exactly one complete **unit**.
Board _oneUnit() => _boardOf(_solution.substring(0, 9) + '.' * 72);

/// Row 0, column 0 and block 0 all complete, so cell 0 is in three of them.
///
/// The top-left block, the first row and the first column filled and nothing
/// else — the smallest board on which D-48 can be seen rather than reasoned
/// about.
Board _threeUnits() {
  final digits = List<String>.filled(81, '.');
  for (var cell = 0; cell < 81; cell++) {
    final row = cell ~/ 9;
    final column = cell % 9;
    final inBlockZero = row < 3 && column < 3;
    if (row == 0 || column == 0 || inBlockZero) {
      digits[cell] = _solution[cell];
    }
  }
  return _boardOf(digits.join());
}

Widget _host(
  Board board, {
  bool showTints = true,
  Set<int> fresh = const <int>{},
  EffectFrame effects = EffectFrame.empty,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: DokuColours.sand,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 360,
        height: 360,
        child: PuzzleGrid(
          board: board,
          completedCells: UnitCompletion.tintedCells(board),
          freshCells: fresh,
          showCompletionTints: showTints,
          effects: effects,
          onCellTapped: (_) {},
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadFont);

  Future<void> pumpAndMatch(
    WidgetTester tester,
    Widget widget,
    String name,
  ) async {
    await tester.pumpWidget(widget);
    await expectLater(
      find.byType(PuzzleGrid),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('one completed unit', (tester) async {
    await pumpAndMatch(tester, _host(_oneUnit()), 'completion_one_unit');
  });

  // The pair that pins D-48. Cell 0 belongs to one completed unit in the golden
  // above and to three in this one, and the two pictures must agree about what
  // colour it is. A tint that stacked would darken it here and nowhere else.
  testWidgets('three overlapping completed units', (tester) async {
    await pumpAndMatch(tester, _host(_threeUnits()), 'completion_three_units');
  });

  testWidgets('a completed unit with the tints hidden', (tester) async {
    await pumpAndMatch(
      tester,
      _host(_oneUnit(), showTints: false),
      'completion_tints_hidden',
    );
  });

  // The effect runs across nine placed values. Every digit under it has to
  // stay fully legible — the effect goes behind the glyph, never over it.
  testWidgets('a lasso running across placed values', (tester) async {
    await pumpAndMatch(
      tester,
      _host(
        _oneUnit(),
        effects: EffectFrame(
          effects: <ActiveEffect>[
            ActiveEffect(
              unit: GridGeometry.unitsOfKind(UnitKind.row)[0],
              origin: 4,
              progress: 0.6,
            ),
          ],
          particles: <Particle>[
            for (var cell = 0; cell < 9; cell++)
              Particle(
                cell: cell,
                offset: (0.3, 0.7),
                age: const Duration(milliseconds: 80),
                lifetime: const Duration(milliseconds: 260),
              ),
          ],
        ),
      ),
      'completion_lasso',
    );
  });

  testWidgets('a unit still holding the fresh flash', (tester) async {
    await pumpAndMatch(
      tester,
      _host(_oneUnit(), fresh: const <int>{0, 1, 2, 3, 4, 5, 6, 7, 8}),
      'completion_fresh',
    );
  });
}
