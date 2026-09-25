import 'dart:ui';

/// [source] redrawn as dashes of [on] separated by gaps of [off].
///
/// Each contour starts its own pattern at a dash, so a shape made of separate
/// runs reads the same wherever each run begins. Flutter has no dashed stroke,
/// and this is the one place that makes one.
Path dashedPath(Path source, {required double on, required double off}) {
  assert(on > 0 && off >= 0);
  final dashed = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = distance + on < metric.length ? distance + on : metric.length;
      dashed.addPath(metric.extractPath(distance, end), Offset.zero);
      distance += on + off;
    }
  }
  return dashed;
}
