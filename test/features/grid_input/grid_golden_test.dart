import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
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

Board _partFilled() {
  var board = Board.forPuzzle(givens: _grid(_clues));
  for (final (cell, digit) in const <(int, int)>[
    (2, 4),
    (3, 6),
    (5, 8),
    (11, 7),
    (21, 1),
  ]) {
    board = (board.place(cell, digit) as EditApplied).board;
  }
  return board;
}

Board _solved() {
  var board = Board.forPuzzle(givens: _grid(_clues));
  final solution = _grid(_solution);
  for (var cell = 0; cell < 81; cell++) {
    if (board.isGiven(cell)) continue;
    board = (board.place(cell, solution.digitAt(cell)) as EditApplied).board;
  }
  return board;
}

Widget _host(Board board, {int? selected, GridColours? colours}) =>
    Directionality(
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
              selectedCell: selected,
              colours: colours,
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

  testWidgets('an untouched puzzle', (tester) async {
    await pumpAndMatch(
      tester,
      _host(Board.forPuzzle(givens: _grid(_clues))),
      'grid_untouched',
    );
  });

  // Givens and placed values in the same picture: the weight difference is what
  // this golden exists to pin (constraint 5).
  testWidgets('a part-filled puzzle', (tester) async {
    await pumpAndMatch(tester, _host(_partFilled()), 'grid_part_filled');
  });

  testWidgets('a solved puzzle', (tester) async {
    await pumpAndMatch(tester, _host(_solved()), 'grid_solved');
  });

  testWidgets('a selected cell with its peers marked', (tester) async {
    await pumpAndMatch(
      tester,
      _host(_partFilled(), selected: 40),
      'grid_selected',
    );
  });

  testWidgets('a selected cell in a corner', (tester) async {
    await pumpAndMatch(
      tester,
      _host(_partFilled(), selected: 0),
      'grid_selected_corner',
    );
  });

  // A season repaints surfaces and nothing else (D-55). The focus colour and
  // both inks must be identical to the default season's.
  testWidgets('the same board under a repainted season', (tester) async {
    const season = SeasonTheme(
      id: 'test-territory',
      name: 'Test Territory',
      bone: 0xEFE7F0,
      sand: 0xD6C7DC,
      hairline: 0xC7B4CE,
    );
    await pumpAndMatch(
      tester,
      _host(
        _partFilled(),
        selected: 40,
        colours: GridColours.forSeason(const SeasonPalette(season)),
      ),
      'grid_repainted_season',
    );
  });

  test('a season repaints surfaces and never the focus or the ink', () {
    const season = SeasonTheme(
      id: 'test-territory',
      name: 'Test Territory',
      bone: 0xEFE7F0,
      sand: 0xD6C7DC,
      hairline: 0xC7B4CE,
    );
    final repainted = GridColours.forSeason(const SeasonPalette(season));
    final standard = GridColours.standard();

    expect(repainted.cell, isNot(standard.cell));
    expect(repainted.hairline, isNot(standard.hairline));
    expect(repainted.focusFill, standard.focusFill);
    expect(repainted.focusLine, standard.focusLine);
    expect(repainted.given, standard.given);
    expect(repainted.placed, standard.placed);
  });
}
