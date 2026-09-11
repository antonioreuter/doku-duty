import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';

import 'support/corpus.dart';

/// What the solver costs, measured rather than hoped at.
///
/// Nothing here sits on a frame path yet, so these are not the latency budget of
/// constraint 2 — they are the number `add-perks` starts from when it has to
/// decide whether a hint can answer while a player waits. The ceilings are
/// deliberately loose: they catch a hundredfold regression and nothing subtler,
/// because a tight bound on a shared CI machine is a flaky test, not a budget.
void main() {
  const solver = Solver();
  final legend = corpus.where((entry) => entry.rank == Rank.legend).toList();

  Duration median(List<Duration> samples) {
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  test('a single step at Legend', () {
    final samples = <Duration>[];
    for (final entry in legend) {
      final state = SolverState.fromGrid(entry.grid);
      for (var run = 0; run < 20; run++) {
        final stopwatch = Stopwatch()..start();
        solver.stepFrom(state);
        stopwatch.stop();
        samples.add(stopwatch.elapsed);
      }
    }
    final result = median(samples);
    // ignore: avoid_print
    print(
      'single step, Legend: median ${result.inMicroseconds}us, '
      'worst ${samples.last.inMicroseconds}us',
    );
    expect(result, lessThan(const Duration(milliseconds: 100)));
  });

  test('the hardest step of a full Legend solve', () {
    var worst = Duration.zero;
    for (final entry in legend) {
      final state = SolverState.fromGrid(entry.grid);
      while (true) {
        final stopwatch = Stopwatch()..start();
        final step = solver.stepFrom(state);
        stopwatch.stop();
        if (stopwatch.elapsed > worst) worst = stopwatch.elapsed;
        if (step is! DeducedStep) break;
        state.apply(step.deduction);
      }
    }
    // ignore: avoid_print
    print(
      'worst single step across a full Legend solve: '
      '${worst.inMicroseconds}us',
    );
    expect(worst, lessThan(const Duration(milliseconds: 250)));
  });

  test('a full solve at Legend', () {
    final samples = <Duration>[];
    for (final entry in legend) {
      for (var run = 0; run < 5; run++) {
        final stopwatch = Stopwatch()..start();
        final outcome = solver.solve(entry.grid);
        stopwatch.stop();
        expect(outcome.solved, isTrue);
        samples.add(stopwatch.elapsed);
      }
    }
    final result = median(samples);
    // ignore: avoid_print
    print(
      'full solve, Legend: median ${result.inMilliseconds}ms, '
      'worst ${samples.last.inMilliseconds}ms',
    );
    expect(result, lessThan(const Duration(seconds: 2)));
  });

  test('a full solve at Greenhorn, for the other end of the ladder', () {
    final greenhorn = corpus
        .where((entry) => entry.rank == Rank.greenhorn)
        .toList();
    final samples = <Duration>[];
    for (final entry in greenhorn) {
      for (var run = 0; run < 5; run++) {
        final stopwatch = Stopwatch()..start();
        solver.solve(entry.grid);
        stopwatch.stop();
        samples.add(stopwatch.elapsed);
      }
    }
    // ignore: avoid_print
    print(
      'full solve, Greenhorn: median '
      '${median(samples).inMicroseconds}us',
    );
    expect(median(samples), lessThan(const Duration(seconds: 1)));
  });
}
