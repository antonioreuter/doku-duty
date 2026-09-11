/// Shape, depth, and layout constants from `docs/DESIGN.md` §3, §4, and §8.
///
/// Pure Dart, no Flutter import, so the relationships between them can be
/// asserted without a widget test. The relationships matter as much as the
/// numbers: a thick outer contour with thinner interior lines is what reads as
/// cartoon rather than diagram, and uniform stroke weight is the most common
/// tell of lifeless vector art.
library;

abstract final class DokuRadius {
  static const double card = 20.0;
  static const double button = 18.0;
  static const double gridOuter = 14.0;
}

abstract final class DokuStroke {
  static const double outerContour = 3.0;
  static const double interiorDetail = 2.0;
  static const double gridBoxDivider = 2.5;
  static const double gridCellHairline = 1.0;
}

/// Solid offset shadows, never blurred (`docs/DESIGN.md` §4).
///
/// Blur reads corporate; solid offset reads toy. Applies to interactive chrome
/// only — never to grid cells, where thick borders and shadows on nine columns
/// destroy readability.
abstract final class DokuDepth {
  /// Resting depth for a button.
  ///
  /// `docs/DESIGN.md` §4 gives the range as 4–5px and the total travel as 8px.
  /// Only 5 satisfies both — 4 down plus the 4 of depth it loses — so 5 is the
  /// value and [restMinimum] is the floor of the range, not an alternative.
  static const double rest = 5.0;

  /// The shallow end of the documented range, for chrome that should sit
  /// flatter than a button.
  static const double restMinimum = 4.0;

  /// Depth while held.
  static const double pressed = 1.0;

  /// How far the element moves down when pressed.
  ///
  /// Press travel is this plus the depth it loses, which is the 8px the design
  /// specifies. This single technique is most of why a casual game feels good
  /// to tap.
  static const double pressTranslation = 4.0;
}

/// Cards and speech bubbles rotate slightly. Perfect alignment reads
/// machine-made.
abstract final class DokuTilt {
  static const double minimumDegrees = 0.5;
  static const double maximumDegrees = 2.0;

  /// A stable tilt for [seed], in degrees, positive or negative.
  ///
  /// Deterministic on purpose. A tilt re-rolled on every rebuild makes cards
  /// twitch as unrelated state changes — the seed is usually something durable
  /// about the element, such as its index or id hash.
  static double forSeed(int seed) {
    // Mix the seed so adjacent values do not produce adjacent angles; two cards
    // side by side leaning identically looks like a layout bug, not a style.
    final mixed = (seed * 2654435761) & 0x7FFFFFFF;
    final magnitude =
        minimumDegrees +
        (mixed % 1000) / 999 * (maximumDegrees - minimumDegrees);
    return mixed.isEven ? magnitude : -magnitude;
  }
}

abstract final class DokuLayout {
  /// `docs/DESIGN.md` §8. The floor for **controls** — buttons, number-pad
  /// keys, anything where a miss costs an action the player did not intend.
  ///
  /// Not a floor for grid cells (D-84): nine 44pt cells need 396pt of width,
  /// which most phones do not have, and a mis-tapped cell costs a second tap
  /// rather than a placed digit.
  static const double minimumTapTarget = 44.0;

  /// Five, not nine. Nine keys in a row cannot carry the depth treatment and
  /// are worse for thumbs regardless.
  static const int numberPadColumns = 5;
}
