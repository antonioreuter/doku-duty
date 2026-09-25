import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

import '../puzzle_engine/support/killer.dart';
import '../puzzle_engine/support/positions.dart';

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

final _cages = referenceKillerCages(referenceSolution);

Board _empty() => Board.forPuzzle(givens: Grid.empty, cages: _cages);

/// Every head cell carrying all nine candidates: the worst case for a sum
/// meeting slot 1, and the case D-129's board-wide inset exists for.
Board _notesInEveryHead() {
  var board = _empty();
  for (final cage in _cages.cages) {
    for (var digit = 1; digit <= 9; digit++) {
      board = (board.toggleNote(cage.head, digit) as EditApplied).board;
    }
  }
  // And one cell that heads nothing, to show the slots line up with it.
  for (var digit = 1; digit <= 9; digit++) {
    board = (board.toggleNote(at(4, 4), digit) as EditApplied).board;
  }
  return board;
}

Board _solved() {
  var board = _empty();
  final solution = gridOf(referenceSolution);
  for (var cell = 0; cell < 81; cell++) {
    board = (board.place(cell, solution.digitAt(cell)) as EditApplied).board;
  }
  return board;
}

Widget _host(Board board, {int? selected, double width = 360}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: DokuColours.sand,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: width,
            height: width,
            child: PuzzleGrid(
              board: board,
              selectedCell: selected,
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

  testWidgets('an empty killer board', (tester) async {
    await pumpAndMatch(tester, _host(_empty()), 'killer_empty');
  });

  testWidgets('notes in every head cell', (tester) async {
    await pumpAndMatch(tester, _host(_notesInEveryHead()), 'killer_head_notes');
  });

  // D-84's smallest phone, where notes fall to 8.3px (D-129).
  testWidgets('notes in every head cell, on the smallest phone', (
    tester,
  ) async {
    await pumpAndMatch(
      tester,
      _host(_notesInEveryHead(), width: 296),
      'killer_head_notes_smallest',
    );
  });

  testWidgets('a solved killer board with a cage selected', (tester) async {
    await pumpAndMatch(
      tester,
      _host(_solved(), selected: at(2, 1)),
      'killer_solved',
    );
  });
}
