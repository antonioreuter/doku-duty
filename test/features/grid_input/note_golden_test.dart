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
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
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

    test('the provisional ink is not used by this change', () {
      final source = File(
        'lib/features/grid_input/presentation/grid_painter.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('provisional')));
      expect(source, isNot(contains('turquoise')));
    });
  });

  testWidgets('notes stay inside their cell at the largest type', (
    tester,
  ) async {
    for (final scale in <double>[1, 2, 3]) {
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
}
