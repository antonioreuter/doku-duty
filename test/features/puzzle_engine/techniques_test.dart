import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/deduction.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/techniques/ladder.dart';

import 'support/positions.dart';

Deduction? run(Technique technique, SolverState state) =>
    techniqueFor(technique).deduce(state);

/// The empty grid: every digit is possible everywhere, so nothing at all is
/// deducible from a pattern. A technique that fires here is firing on nothing.
SolverState get blankGrid => stateOf('.' * 81);

void main() {
  group('full house', () {
    test('fills the last cell of a unit', () {
      final state = SolverState.fromGrid(gridOf(referenceSolution).cleared(0));
      final deduction = run(Technique.fullHouse, state)!;

      expect(deduction.technique, Technique.fullHouse);
      expect(deduction.placements, <CellDigit>[const CellDigit(0, 5)]);
      expect(deduction.eliminations, isEmpty);
      expect(deduction.affectedCells, <int>[0]);
    });

    test('makes no deduction where no unit is one cell short', () {
      expect(run(Technique.fullHouse, stateOf(referenceClues)), isNull);
      expect(run(Technique.fullHouse, blankGrid), isNull);
    });
  });

  group('naked single', () {
    test('fills a cell with one candidate left', () {
      final deduction = run(Technique.nakedSingle, stateOf(referenceClues))!;

      expect(deduction.technique, Technique.nakedSingle);
      expect(deduction.placements, <CellDigit>[const CellDigit(40, 5)]);
    });

    test('makes no deduction where every cell has a choice', () {
      expect(run(Technique.nakedSingle, blankGrid), isNull);
    });
  });

  group('hidden single', () {
    test('fills the only cell in a unit that admits a digit', () {
      final deduction = run(Technique.hiddenSingle, stateOf(referenceClues))!;

      expect(deduction.technique, Technique.hiddenSingle);
      // Row 3 holds no 5 anywhere but cell 24, though that cell still looks
      // like it could take four other digits.
      expect(deduction.placements, <CellDigit>[const CellDigit(24, 5)]);
      expect(stateOf(referenceClues).candidatesAt(24).length, greaterThan(1));
    });

    test('makes no deduction where every digit has nine homes', () {
      expect(run(Technique.hiddenSingle, blankGrid), isNull);
    });
  });

  group('naked pair', () {
    test('strikes the pair out of the rest of the unit', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 2],
        at(0, 1): <int>[1, 2],
        at(0, 2): <int>[1, 3],
      });
      final deduction = run(Technique.nakedPair, state)!;

      expect(deduction.technique, Technique.nakedPair);
      expect(deduction.placements, isEmpty);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(0, 2), 1)]);
      expect(deduction.witnesses, <int>[at(0, 0), at(0, 1)]);
    });

    test('makes no deduction on three cells that share three digits', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 2],
        at(0, 1): <int>[1, 3],
        at(0, 2): <int>[2, 3],
      });
      expect(run(Technique.nakedPair, state), isNull);
      expect(run(Technique.nakedPair, blankGrid), isNull);
    });
  });

  group('pointing pair', () {
    test('strikes a block-confined digit off the rest of its line', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[3],
        at(0, 1): <int>[3],
        at(0, 5): <int>[3],
      });
      final deduction = run(Technique.pointingPair, state)!;

      expect(deduction.technique, Technique.pointingPair);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(0, 5), 3)]);
      expect(deduction.witnesses, <int>[at(0, 0), at(0, 1)]);
    });

    test(
      'makes no deduction when the digit straddles two lines of the block',
      () {
        final state = position(<int, List<int>>{
          at(0, 0): <int>[3],
          at(1, 1): <int>[3],
          at(0, 5): <int>[3],
        });
        expect(run(Technique.pointingPair, state), isNull);
        expect(run(Technique.pointingPair, blankGrid), isNull);
      },
    );
  });

  group('box-line reduction', () {
    test('strikes a line-confined digit off the rest of its block', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[4],
        at(0, 1): <int>[4],
        at(1, 2): <int>[4],
      });
      final deduction = run(Technique.boxLineReduction, state)!;

      expect(deduction.technique, Technique.boxLineReduction);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(1, 2), 4)]);
      expect(deduction.witnesses, <int>[at(0, 0), at(0, 1)]);
    });

    test('makes no deduction when the line spans two blocks', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[4],
        at(0, 4): <int>[4],
        at(1, 2): <int>[4],
      });
      expect(run(Technique.boxLineReduction, state), isNull);
      expect(run(Technique.boxLineReduction, blankGrid), isNull);
    });
  });

  group('naked triple', () {
    test('strikes three shared digits out of the rest of the unit', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 2],
        at(0, 1): <int>[2, 3],
        at(0, 2): <int>[1, 3],
        at(0, 4): <int>[1, 5],
      });
      final deduction = run(Technique.nakedTriple, state)!;

      expect(deduction.technique, Technique.nakedTriple);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(0, 4), 1)]);
      expect(deduction.witnesses, <int>[at(0, 0), at(0, 1), at(0, 2)]);
    });

    test('makes no deduction on three cells spanning four digits', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 2],
        at(0, 1): <int>[2, 3],
        at(0, 2): <int>[1, 4],
        at(0, 4): <int>[1, 5],
      });
      expect(run(Technique.nakedTriple, state), isNull);
      expect(run(Technique.nakedTriple, blankGrid), isNull);
    });
  });

  group('hidden pair', () {
    test(
      'clears everything else out of the two cells the pair is confined to',
      () {
        final state = position(<int, List<int>>{
          at(0, 0): <int>[1, 2, 5],
          at(0, 1): <int>[1, 2, 6],
          at(0, 2): <int>[5, 6, 7],
          at(0, 3): <int>[5, 6, 7],
        });
        final deduction = run(Technique.hiddenPair, state)!;

        expect(deduction.technique, Technique.hiddenPair);
        expect(deduction.eliminations, <CellDigit>[
          CellDigit(at(0, 0), 5),
          CellDigit(at(0, 1), 6),
        ]);
        expect(deduction.witnesses, <int>[at(0, 0), at(0, 1)]);
      },
    );

    test('makes no deduction when the two digits sit in different cells', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 5],
        at(0, 1): <int>[1, 5],
        at(0, 2): <int>[2, 6],
        at(0, 3): <int>[2, 6],
      });
      expect(run(Technique.hiddenPair, state), isNull);
      expect(run(Technique.hiddenPair, blankGrid), isNull);
    });
  });

  group('x-wing', () {
    test('strikes the digit off the two columns it is locked into', () {
      final state = position(<int, List<int>>{
        at(0, 1): <int>[5],
        at(0, 5): <int>[5],
        at(3, 1): <int>[5],
        at(3, 5): <int>[5],
        at(6, 1): <int>[5],
      });
      final deduction = run(Technique.xWing, state)!;

      expect(deduction.technique, Technique.xWing);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(6, 1), 5)]);
      expect(deduction.witnesses, <int>[
        at(0, 1),
        at(0, 5),
        at(3, 1),
        at(3, 5),
      ]);
    });

    test('makes no deduction when the two rows do not share their columns', () {
      final state = position(<int, List<int>>{
        at(0, 1): <int>[5],
        at(0, 5): <int>[5],
        at(3, 1): <int>[5],
        at(3, 6): <int>[5],
        at(6, 1): <int>[5],
      });
      expect(run(Technique.xWing, state), isNull);
      expect(run(Technique.xWing, blankGrid), isNull);
    });
  });

  group('swordfish', () {
    test('strikes the digit off the three columns it is locked into', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[7],
        at(0, 4): <int>[7],
        at(3, 4): <int>[7],
        at(3, 8): <int>[7],
        at(6, 0): <int>[7],
        at(6, 8): <int>[7],
        at(1, 0): <int>[7],
      });
      final deduction = run(Technique.swordfish, state)!;

      expect(deduction.technique, Technique.swordfish);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(1, 0), 7)]);
    });

    test('makes no deduction when the three rows span four columns', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[7],
        at(0, 4): <int>[7],
        at(3, 4): <int>[7],
        at(3, 8): <int>[7],
        at(6, 0): <int>[7],
        at(6, 7): <int>[7],
        at(1, 0): <int>[7],
      });
      expect(run(Technique.swordfish, state), isNull);
      expect(run(Technique.swordfish, blankGrid), isNull);
    });
  });

  group('xy-wing', () {
    test('strikes the third digit off every cell that sees both pincers', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 2],
        at(0, 1): <int>[1, 3],
        at(1, 0): <int>[2, 3],
        at(1, 1): <int>[3],
      });
      final deduction = run(Technique.xyWing, state)!;

      expect(deduction.technique, Technique.xyWing);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(1, 1), 3)]);
      expect(deduction.witnesses, <int>[at(0, 0), at(0, 1), at(1, 0)]);
    });

    test('makes no deduction when the pincers share no third digit', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[1, 2],
        at(0, 1): <int>[1, 3],
        at(1, 0): <int>[2, 4],
        at(1, 1): <int>[3],
      });
      expect(run(Technique.xyWing, state), isNull);
      expect(run(Technique.xyWing, blankGrid), isNull);
    });
  });

  group('simple chain', () {
    // Four cells, three conjugate links: r1c1 - r5c1 (column 1), r5c1 - r5c8
    // (row 5), r5c8 - r1c8 (column 8). Colouring alternates along it, so r1c1
    // and r1c8 carry opposite colours — and r1c4, which sees both, cannot hold
    // the digit whichever colour turns out to be true.
    test('strikes a digit off a cell that sees both colours of a chain', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[4],
        at(4, 0): <int>[4],
        at(4, 7): <int>[4],
        at(0, 7): <int>[4],
        at(0, 3): <int>[4],
      });
      final deduction = run(Technique.simpleChain, state)!;

      expect(deduction.technique, Technique.simpleChain);
      expect(deduction.eliminations, <CellDigit>[CellDigit(at(0, 3), 4)]);
      expect(deduction.witnesses, <int>[
        at(0, 0),
        at(0, 7),
        at(4, 0),
        at(4, 7),
      ]);
    });

    test('makes no deduction from a lone conjugate link', () {
      final state = position(<int, List<int>>{
        at(0, 0): <int>[4],
        at(4, 0): <int>[4],
      });
      expect(run(Technique.simpleChain, state), isNull);
      expect(run(Technique.simpleChain, blankGrid), isNull);
    });
  });

  group('the ladder', () {
    // Read from Technique rather than restated here. This is the test that
    // fails when the ladder and the solver drift apart — a technique in D-57
    // with no implementation is a rank the grader can never charge for, and an
    // implementation outside D-57 is a rank nobody can explain.
    test('implements every technique D-57 names, and nothing else', () {
      expect(
        techniqueLadder.map((entry) => entry.technique).toList(),
        Technique.values,
      );
    });

    test('every technique is reachable by name', () {
      for (final technique in Technique.values) {
        expect(techniqueFor(technique).technique, technique);
      }
    });

    test('the ladder runs easiest first', () {
      for (var i = 1; i < techniqueLadder.length; i++) {
        expect(
          techniqueLadder[i].technique.introducedAt.index,
          greaterThanOrEqualTo(
            techniqueLadder[i - 1].technique.introducedAt.index,
          ),
        );
      }
    });

    test('no technique ever reports a deduction that changes nothing', () {
      final states = <SolverState>[
        stateOf(referenceClues),
        SolverState.fromGrid(gridOf(referenceSolution).cleared(0)),
        blankGrid,
      ];
      for (final entry in techniqueLadder) {
        for (final state in states) {
          final deduction = entry.deduce(state.copy());
          if (deduction == null) continue;
          expect(deduction.changesNothing, isFalse);
          expect(deduction.technique, entry.technique);
        }
      }
    });
  });
}
