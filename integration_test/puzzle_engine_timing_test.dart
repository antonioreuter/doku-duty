import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';

/// The solver's cost on a real device, in release-mode arithmetic rather than
/// the host's.
///
/// Not a gate. Nothing calls the solver on a frame path yet; change 19 is where
/// a hint has to answer while a player waits, and this is the measurement that
/// change starts from instead of a hope. The host suite records the same numbers
/// on a desktop CPU — the interesting comparison is the ratio.
///
/// The three grids are the Legend entries from the host corpus, inlined because
/// an integration test cannot reach the test tree's support files.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const legend = <String>[
    // swordfish
    '9....7....7..6.39.....4...12..6.5.39..62..1..49...1.2..8...9..5.5.7..6...4.15..8.',
    // xy-wing
    '7..8.......1.3..58.6.......17..2.....2.14.8..8...93..26.....1744..9.....38...42.9',
    // simple chain
    '4..6.3.7.935..8....27.5...8..35.294775.....3...9..1....14...7..89.3..6......4.18.',
  ];

  Grid gridOf(String clues) => (Grid.parse(clues) as ValidGrid).grid;

  testWidgets('a single step and a full solve at Legend', (tester) async {
    const solver = Solver();

    final steps = <int>[];
    for (final clues in legend) {
      final state = SolverState.fromGrid(gridOf(clues));
      for (var run = 0; run < 20; run++) {
        final stopwatch = Stopwatch()..start();
        solver.stepFrom(state);
        stopwatch.stop();
        steps.add(stopwatch.elapsedMicroseconds);
      }
    }
    steps.sort();

    final solves = <int>[];
    var worstStep = 0;
    for (final clues in legend) {
      final stopwatch = Stopwatch()..start();
      final outcome = solver.solve(gridOf(clues));
      stopwatch.stop();
      expect(outcome.solved, isTrue);
      solves.add(stopwatch.elapsedMicroseconds);

      final state = SolverState.fromGrid(gridOf(clues));
      while (true) {
        final inner = Stopwatch()..start();
        final step = solver.stepFrom(state);
        inner.stop();
        if (inner.elapsedMicroseconds > worstStep) {
          worstStep = inner.elapsedMicroseconds;
        }
        if (step is! DeducedStep) break;
        state.apply(step.deduction);
      }
    }
    solves.sort();

    // ignore: avoid_print
    print(
      'SOLVER TIMING — single step median ${steps[steps.length ~/ 2]}us, '
      'worst step in a full solve ${worstStep}us, '
      'full solve median ${solves[solves.length ~/ 2]}us',
    );

    // Loose enough not to be flaky on a shared machine, tight enough to catch a
    // hundredfold regression.
    expect(steps[steps.length ~/ 2], lessThan(500000));
    expect(solves[solves.length ~/ 2], lessThan(10000000));
  });
}
