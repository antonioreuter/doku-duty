import 'dart:math' as math;

/// WCAG 2.1 contrast arithmetic over 24-bit RGB values.
///
/// Pure Dart with no Flutter import, so the palette can be checked by the plain
/// test runner rather than only inside a widget test. The token layer runs this
/// over every foreground/background pair the design uses, and a pair below its
/// budget fails the build — measuring is what keeps `docs/DESIGN.md` honest.

/// Channel-wise inverse companding, per WCAG's definition of relative luminance.
double _linearise(int channel) {
  final c = channel / 255.0;
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4) as double;
}

/// Relative luminance of an `0xRRGGBB` value, 0.0 for black and 1.0 for white.
double relativeLuminance(int rgb) {
  final r = _linearise((rgb >> 16) & 0xFF);
  final g = _linearise((rgb >> 8) & 0xFF);
  final b = _linearise(rgb & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Contrast ratio between two `0xRRGGBB` values, from 1.0 to 21.0.
///
/// Symmetric: the order of the pair does not matter.
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// The minimum ratio a pair must reach, chosen by what the pair is used for.
enum ContrastBudget {
  /// Body-sized text: below 18px, or below 14px bold.
  smallText(4.5),

  /// 18px and above, or 14px and above at bold weight.
  largeText(3.0),

  /// Interface boundaries and graphical objects that carry meaning.
  nonText(3.0);

  const ContrastBudget(this.minimumRatio);

  final double minimumRatio;

  /// The budget for text at [sizePx] and [weight], per WCAG's large-text rule.
  static ContrastBudget forText({required double sizePx, required int weight}) {
    final isBold = weight >= 700;
    if (sizePx >= 18 || (isBold && sizePx >= 14)) return largeText;
    return smallText;
  }

  /// Whether [foreground] on [background] meets this budget.
  bool isMetBy(int foreground, int background) =>
      contrastRatio(foreground, background) >= minimumRatio;
}
