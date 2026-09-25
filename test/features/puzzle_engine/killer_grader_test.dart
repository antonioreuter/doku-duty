import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/uniqueness.dart';

import 'support/killer.dart';
import 'support/positions.dart';

// Dug from the reference killer board and graded by the engine; each is kept
// for the grade it reached, which the tests below assert rather than trust.
const String _greenhornByCombination =
    '.34...9.......53.8..8.........7......268..7917.3.2.8...6....2..2.....63.3.5.8....';
const String _deputy =
    '.3....9........3.8............7........8....1....2.8....................3........';
const String _sheriffByFortyFive =
    '..............................7........8.........2...............................';
const String _marshal =
    '.....8...........................................................................';

void main() {
  test('a killer puzzle no technique finishes is ungradable, not Legend', () {
    // Dominoes over an empty grid admit more than one completion, so nothing
    // that only deduces can finish them.
    final result = grade(Grid.empty, cages: dominoCages(referenceSolution));

    expect(result, isA<Ungradable>());
    expect((result as Ungradable).cellsRemaining, greaterThan(0));
  });

  test('a classic grid grades exactly as before when given no cages', () {
    for (final source in <String>[referenceClues, referenceSolution]) {
      final classic = grade(gridOf(source)) as Graded;
      final none = grade(gridOf(source), cages: null) as Graded;
      expect(none.rank, classic.rank);
      expect(none.hardest, classic.hardest);
      expect(none.techniquesUsed, classic.techniquesUsed);
    }
  });

  test('the cages are what makes a killer grid gradable', () {
    // With no givens the grid alone is hopeless; its cages pin it.
    final cages = referenceKillerCages(referenceSolution);
    expect(grade(Grid.empty), isA<Ungradable>());
    final outcome = const Solver().solve(Grid.empty, cages: cages);
    expect(outcome.deductions, isNotEmpty);
    expect(
      outcome.techniquesUsed,
      anyOf(
        contains(Technique.cageCombination),
        contains(Technique.fortyFiveRule),
      ),
    );
  });

  group('on the same ladder', () {
    final cages = referenceKillerCages(referenceSolution);

    test('one finishable only by cage combination grades Greenhorn', () {
      final grid = gridOf(_greenhornByCombination);
      // Classic singles stall on it, even with its cages as peers.
      expect(
        const Solver(
          allowed: <Technique>{Technique.fullHouse, Technique.nakedSingle},
        ).solve(grid, cages: cages).solved,
        isFalse,
      );

      final result = grade(grid, cages: cages) as Graded;
      expect(result.rank, Rank.greenhorn);
      expect(result.hardest, Technique.cageCombination);
    });

    test('a classic technique above the killer ones sets the rank', () {
      final result = grade(gridOf(_deputy), cages: cages) as Graded;
      expect(result.rank, Rank.deputy);
      expect(result.hardest, Technique.hiddenSingle);
      expect(result.techniquesUsed, contains(Technique.cageCombination));
    });

    test('the 45 rule sets the rank when it is the hardest step', () {
      final result = grade(gridOf(_sheriffByFortyFive), cages: cages) as Graded;
      expect(result.rank, Rank.sheriff);
      expect(result.hardest, Technique.fortyFiveRule);
    });

    test('its rank is the hardest technique across both sets', () {
      final result = grade(gridOf(_marshal), cages: cages) as Graded;
      expect(result.rank, Rank.marshal);
      expect(result.techniquesUsed, contains(Technique.fortyFiveRule));
      expect(result.hardest!.introducedAt, Rank.marshal);
      for (final technique in result.techniquesUsed) {
        expect(
          technique.index,
          lessThanOrEqualTo(result.hardest!.index),
          reason: technique.name,
        );
      }
    });

    test('every fixture is unique under its cages', () {
      for (final source in <String>[
        _greenhornByCombination,
        _deputy,
        _sheriffByFortyFive,
        _marshal,
      ]) {
        final result = checkUniqueness(gridOf(source), cages: cages);
        expect(result, isA<UniqueSolution>(), reason: source);
      }
    });
  });
}
