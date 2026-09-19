// One-off: derive real lesson positions from the shipped pack.
//
// Not shipped and not a test. Run with:
//   flutter test tool/find_lesson_positions.dart
//
// For each technique it walks every puzzle's solve, asking that technique alone
// at every state. It keeps the first position where the technique fires *and*
// the resulting eliminations immediately leave some cell with one candidate —
// because a lesson has to end in a placement the player makes, and an
// elimination technique has no placement of its own.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/deduction.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/techniques/ladder.dart';

/// A cell the technique's eliminations *newly* reduced to one candidate.
///
/// "Newly" is the whole point. Any mid-solve board has cells sitting at one
/// candidate already, and picking one of those would let a lesson claim the
/// technique caused something it did not — teaching a false link in a lesson
/// about reasoning. The cell must have held more than one candidate before and
/// exactly one after, so the sentence "and that leaves only the 5" is true.
({int cell, int digit})? _newSingle(SolverState before, SolverState after) {
  for (final cell in after.emptyCells) {
    final was = before.candidateMask(cell);
    final now = after.candidateMask(cell);
    if (now == 0) continue;
    if (now & (now - 1) != 0) continue; // still more than one
    if (was & (was - 1) == 0) continue; // was already a single
    for (var digit = 1; digit <= 9; digit++) {
      if (now == 1 << (digit - 1)) return (cell: cell, digit: digit);
    }
  }
  return null;
}

void main() {
  test('find a position for every technique above Greenhorn', () {
    final pack =
        jsonDecode(File('assets/packs/frontier-1.json').readAsStringSync())
            as Map<String, dynamic>;
    final puzzles = (pack['puzzles'] as List<dynamic>).cast<Map<String, dynamic>>();

    final wanted = <Technique>[
      for (final t in Technique.values)
        if (t != Technique.fullHouse && t != Technique.nakedSingle) t,
    ];
    final found = <Technique, String>{};

    for (final technique in wanted) {
      final impl = techniqueFor(technique);

      outer:
      for (final puzzle in puzzles) {
        final parsed = Grid.parse(puzzle['clues'] as String);
        if (parsed is! ValidGrid) continue;
        final state = SolverState.fromGrid(parsed.grid);

        for (var step = 0; step < 200; step++) {
          if (state.isSolved) break;

          final candidate = impl.deduce(state);
          if (candidate != null) {
            final trial = state.copy()..apply(candidate);
            var single = candidate.placements.isNotEmpty
                ? (
                    cell: candidate.placements.first.cell,
                    digit: candidate.placements.first.digit,
                  )
                : _newSingle(state, trial);

            // Some techniques cannot create a single on their own. A hidden
            // pair reduces its two cells to exactly the pair — two candidates
            // each, never one — so the placement it earns is always one step
            // further on, where the pair it exposed eliminates elsewhere. Take
            // that step, and only keep it if the technique was actually needed
            // for it: if the same cell falls out without the technique, the
            // lesson would be claiming credit for someone else's work.
            Deduction? follow;
            if (single == null) {
              for (final entry in techniqueLadder) {
                follow = entry.deduce(trial);
                if (follow != null) break;
              }
              if (follow != null) {
                final second = trial.copy()..apply(follow);
                final after = _newSingle(state, second);
                if (after != null) {
                  Deduction? without;
                  for (final entry in techniqueLadder) {
                    if (entry.technique == technique) continue;
                    without = entry.deduce(state);
                    if (without != null) break;
                  }
                  final control = state.copy();
                  if (without != null) control.apply(without);
                  final sameWithout = _newSingle(state, control);
                  if (sameWithout?.cell != after.cell) single = after;
                }
              }
            }

            if (single != null) {
              found[technique] = jsonEncode(<String, Object?>{
                'technique': technique.name,
                'puzzleId': puzzle['id'],
                'grid': state.toGrid().toStorageString(),
                'witnesses': candidate.witnesses,
                'placements': <Map<String, int>>[
                  for (final p in candidate.placements)
                    <String, int>{'cell': p.cell, 'digit': p.digit},
                ],
                'eliminations': <Map<String, int>>[
                  for (final e in candidate.eliminations)
                    <String, int>{'cell': e.cell, 'digit': e.digit},
                ],
                'answerCell': single.cell,
                'answerDigit': single.digit,
                'followTechnique': follow?.technique.name,
                'followEliminations': <Map<String, int>>[
                  for (final e in follow?.eliminations ?? const <CellDigit>[])
                    <String, int>{'cell': e.cell, 'digit': e.digit},
                ],
                'followWitnesses': follow?.witnesses ?? const <int>[],
                'filled': 81 - state.emptyCells.length,
              });
              break outer;
            }
          }

          // Advance the solve by the ordinary ladder.
          Deduction? next;
          for (final entry in techniqueLadder) {
            next = entry.deduce(state);
            if (next != null) break;
          }
          if (next == null) break;
          state.apply(next);
        }
      }
    }

    final out = File('tool/lesson_positions.json');
    out.writeAsStringSync(
      '[\n${wanted.where(found.containsKey).map((t) => '  ${found[t]}').join(',\n')}\n]\n',
    );

    for (final technique in wanted) {
      // ignore: avoid_print
      print('${technique.name}: ${found.containsKey(technique) ? "found" : "MISSING"}');
    }
  });
}
