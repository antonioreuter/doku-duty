import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/domain/effect_event.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';

import '../puzzle_engine/support/killer.dart';
import '../puzzle_engine/support/positions.dart';

class _NullSink implements BoardSink {
  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async {}

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {}

  @override
  Future<int> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async => 0;
}

/// A **killer** puzzle over the reference solution with [holes] empty.
PuzzleController _controllerWithHoles(Iterable<int> holes) {
  final digits = referenceSolution.split('');
  for (final cell in holes) {
    digits[cell] = '.';
  }
  final puzzle = StoredPuzzle(
    id: 'k1',
    clues: digits.join(),
    solution: referenceSolution,
    rank: Rank.sheriff,
    seed: 1,
    cages: jsonEncode(referenceKillerCages(referenceSolution).toJson()),
  );
  return PuzzleController(
    puzzle: puzzle,
    sink: _NullSink(),
    initial: sessionFor(
      puzzle: puzzle,
      placedValues: null,
      mode: InputMode.cellFirst,
    ),
  );
}

void place(PuzzleController controller, int cell) {
  controller.tapCell(cell);
  controller.tapKey(DigitKey(int.parse(referenceSolution[cell])));
}

void main() {
  // Cage 'i' of the reference shape: r3c2, r4c1, r4c2, r5c1. r5c1 goes in
  // last, and its row, column and block each keep another hole.
  final cage = <int>[at(2, 1), at(3, 0), at(3, 1), at(4, 0)];
  final last = at(4, 0);
  final elsewhere = <int>[at(4, 4), at(8, 0), at(5, 2)];

  test('the fixture is the cage the test means', () {
    final cages = referenceKillerCages(referenceSolution);
    expect(cages.cageOf(last).cells, cage);
    for (final unit in GridGeometry.unitsOf(last)) {
      expect(unit.cells.any(elsewhere.contains), isTrue, reason: '$unit');
    }
  });

  test(
    'filling a cage with no unit completing announces nothing (D-130)',
    () async {
      final controller = _controllerWithHoles(<int>[...cage, ...elsewhere]);
      for (final cell in cage.where((c) => c != last)) {
        place(controller, cell);
      }
      final events = <EffectEvent>[];
      controller.effects.listen(events.add);

      place(controller, last);
      await Future<void>.delayed(Duration.zero);

      // Every effect and haptic is downstream of an event; there is none.
      expect(events, isEmpty);
      controller.dispose();
    },
  );

  test('a row on a killer board still completes', () async {
    final controller = _controllerWithHoles(<int>[at(4, 4), at(4, 5)]);
    place(controller, at(4, 5));
    final events = <EffectEvent>[];
    controller.effects.listen(events.add);

    place(controller, at(4, 4));
    await Future<void>.delayed(Duration.zero);

    final completed = events.whereType<UnitsCompleted>().single;
    expect(
      completed.steps.map((step) => step.unit.kind),
      contains(UnitKind.row),
    );
    controller.dispose();
  });
}
