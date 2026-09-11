import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

PuzzleSession _session() => PuzzleSession.start(
  board: Board.forPuzzle(givens: _grid(_clues)),
  entryKind: EntryKind.note,
);

void main() {
  // Notes are thinking out loud. Punishing exploration undermines the technique
  // learning the whole progression depends on (D-14).
  group('a candidate that cannot be right', () {
    test('is marked exactly as any other', () {
      // Cell 2 is 4 in the only solution.
      expect(_grid(_solution).digitAt(2), 4);

      final wrong = _session().tapCell(2).tapDigit(1);
      final right = _session().tapCell(2).tapDigit(4);

      expect(wrong.board.notesAt(2), NoteSet.of(const <int>[1]));
      expect(right.board.notesAt(2), NoteSet.of(const <int>[4]));
      expect(wrong.lastEdit.runtimeType, right.lastEdit.runtimeType);
    });

    test('all nine can be marked at once, eight of them impossible', () {
      var session = _session().tapCell(2);
      for (var digit = 1; digit <= 9; digit++) {
        session = session.tapDigit(digit);
      }
      expect(session.board.notesAt(2).length, 9);
    });
  });

  group('a candidate contradicting a peer', () {
    test('is still marked', () {
      // Cell 0 is a given 5, and cell 2 shares row 0 with it.
      expect(GridGeometry.peersOf(2), contains(0));

      final session = _session().tapCell(2).tapDigit(5);
      expect(session.board.notesAt(2), NoteSet.of(const <int>[5]));
    });

    test('nothing about the board reports it', () {
      final session = _session().tapCell(2).tapDigit(5);
      // The board answers what the cell holds and nothing about whether it
      // should. There is no "is this note wrong" to ask.
      expect(session.board.notesAt(2).contains(5), isTrue);
      expect(session.lastEdit, isA<EditApplied>());
    });
  });

  // Auto-check and strict mode arrive with `add-mistake-model`. Notes sit
  // outside them in any case (D-14), and this change must not be where any of
  // it quietly begins.
  test('nothing in the feature reads auto-check or strict mode', () {
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/grid_input',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The settings screen lists them as rows; it does not act on them.
      if (entity.path.endsWith('settings_screen.dart')) continue;

      final source = entity.readAsStringSync();
      for (final forbidden in const <String>[
        'AppSetting.autoCheck',
        'AppSetting.strictMode',
      ]) {
        if (source.contains(forbidden)) {
          offenders.add('${entity.path}: $forbidden');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('nothing in the feature compares a note to the solution', () {
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/grid_input',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      // The controller compares the finished *board* to the solution to know
      // when a puzzle is solved. Nothing may do so for a candidate.
      for (final line in source.split('\n')) {
        final code = line.split('//').first;
        if (code.contains('solution') && code.contains('note')) {
          offenders.add('${entity.path}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
