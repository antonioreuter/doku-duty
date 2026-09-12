import 'dart:ui';

/// Records what a painter drew, so a test can assert on shapes rather than on
/// pixels.
///
/// Goldens catch a layout that moved; this catches "how many cells were
/// filled", which is what peer highlighting actually is.
class RecordingCanvas implements Canvas {
  final List<(Rect, Color)> fills = <(Rect, Color)>[];
  final List<(Rect, Color)> strokes = <(Rect, Color)>[];

  /// The rectangles filled with [colour].
  ///
  /// Compared as packed ARGB rather than by `==`: a colour assigned to a
  /// [Paint] and read back is reconstructed from float components, so two
  /// values that name the same colour are not necessarily the same object.
  List<Rect> filledWith(Color colour) => <Rect>[
    for (final fill in fills)
      if (fill.$2.toARGB32() == colour.toARGB32()) fill.$1,
  ];

  /// The rectangles stroked with [colour].
  List<Rect> strokedWith(Color colour) => <Rect>[
    for (final stroke in strokes)
      if (stroke.$2.toARGB32() == colour.toARGB32()) stroke.$1,
  ];

  /// The lines drawn, with their colour and stroke width.
  ///
  /// The provisional underline is a line, not a rect — and it is the signal
  /// that survives when colour does not (D-73), so a test has to be able to
  /// count them.
  final List<(Offset, Offset, Color, double)> lines =
      <(Offset, Offset, Color, double)>[];

  /// The lines drawn in [colour].
  List<(Offset, Offset)> linesIn(Color colour) => <(Offset, Offset)>[
    for (final line in lines)
      if (line.$3.toARGB32() == colour.toARGB32()) (line.$1, line.$2),
  ];

  @override
  void drawRect(Rect rect, Paint paint) {
    final entry = (rect, paint.color);
    (paint.style == PaintingStyle.stroke ? strokes : fills).add(entry);
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    lines.add((from, to, paint.color, paint.strokeWidth));
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}
