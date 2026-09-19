import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

/// What one grade costs on the path that opens a puzzle.
///
/// Not on the path of a tap — that is asserted structurally in
/// `solve_wiring_test.dart`. This is the other half: a cost paid once, on open,
/// has to be small enough that opening a puzzle does not feel slower for it.
void main() {
  test('grading a puzzle costs a fraction of a frame', () {
    final grid = (Grid.parse(_clues) as ValidGrid).grid;

    // Warm the JIT: the first run is not the one a player pays for, and
    // reporting it would overstate the cost by an order of magnitude.
    for (var i = 0; i < 20; i++) {
      grade(grid);
    }

    const runs = 200;
    final watch = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      grade(grid);
    }
    watch.stop();

    final perGrade = watch.elapsedMicroseconds / runs;
    // ignore: avoid_print
    print('grade(): ${perGrade.toStringAsFixed(1)} µs per call');

    // A 60fps frame is 16,600 µs. A grade that cannot fit several times over
    // in one frame does not belong on the open path, and the task that added
    // this said to move it rather than accept it.
    expect(
      perGrade,
      lessThan(16600 / 4),
      reason: 'grading is too slow to sit on the path that opens a puzzle',
    );
  });
}
