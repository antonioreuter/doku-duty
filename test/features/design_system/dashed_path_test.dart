import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/dashed_path.dart';

List<double> _dashLengths(Path path) => <double>[
  for (final metric in path.computeMetrics()) metric.length,
];

void main() {
  test(
    'a line becomes dashes of the on length, with the off length between',
    () {
      final line = Path()
        ..moveTo(0, 0)
        ..lineTo(20, 0);
      final dashed = dashedPath(line, on: 3, off: 2);

      // 20 = four whole periods of 5: four dashes of 3.
      expect(_dashLengths(dashed), <double>[3, 3, 3, 3]);
      final starts = <double>[
        for (final metric in dashed.computeMetrics())
          metric.getTangentForOffset(0)!.position.dx,
      ];
      expect(starts, <double>[0, 5, 10, 15]);
    },
  );

  test('a line that ends mid-dash ends with a shorter dash', () {
    final line = Path()
      ..moveTo(0, 0)
      ..lineTo(7, 0);
    expect(_dashLengths(dashedPath(line, on: 3, off: 2)), <double>[3, 2]);
  });

  test('every contour is dashed from its own start', () {
    final two = Path()
      ..moveTo(0, 0)
      ..lineTo(4, 0)
      ..moveTo(0, 10)
      ..lineTo(4, 10);
    expect(_dashLengths(dashedPath(two, on: 3, off: 2)), <double>[3, 3]);
  });

  test('an empty path stays empty', () {
    expect(_dashLengths(dashedPath(Path(), on: 3, off: 2)), isEmpty);
  });
}
