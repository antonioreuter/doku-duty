/// The palette as raw `0xRRGGBB` values, with no Flutter import.
///
/// Kept pure so the contrast budget can be enforced by the plain test runner
/// rather than only inside a widget test. `DokuColors` in the presentation layer
/// is the only place these become `Color` objects, which is what makes the
/// "no colour literal outside the token file" rule enforceable.
///
/// Values are canonical in `docs/DESIGN.md` §1. Eight tokens: six carry state,
/// two are surfaces (D-71). Four were corrected for measured contrast (D-72).
library;

/// One of the eight tokens. There is no ninth, and no way to add one (D-71).
enum PaletteToken {
  // Surfaces. Season themes repaint these two and nothing else (D-55).
  bone(0xF5EBD6, isSurface: true),
  sand(0xE4D4AE, isSurface: true),

  // The six that carry state. Fixed across every season.
  duskInk(0x2E2438),
  badgeGold(0xF2B33D),
  nightIndigo(0x4A3F9E),
  turquoise(0x1B6661),
  sunsetRed(0xE05A2B),
  cactusGreen(0x4E9E62);

  const PaletteToken(this.value, {this.isSurface = false});

  /// The base `0xRRGGBB` value.
  final int value;

  /// Whether a season theme may repaint this token (D-55).
  final bool isSurface;

  /// The six tokens that carry state.
  static List<PaletteToken> get stateColours =>
      values.where((t) => !t.isSurface).toList(growable: false);

  /// The two surface tokens.
  static List<PaletteToken> get surfaces =>
      values.where((t) => t.isSurface).toList(growable: false);

  /// The pale tint derived from this token, where the design defines one.
  ///
  /// Derived values are reachable only through their parent so that they cannot
  /// be mistaken for, or grow into, a ninth hue (D-71).
  int? get pale => switch (this) {
    PaletteToken.badgeGold => 0xFDEFC6,
    PaletteToken.nightIndigo => 0xE6DEFA,
    PaletteToken.sunsetRed => 0xFBDDD6,
    PaletteToken.cactusGreen => 0xCFE0BE,
    PaletteToken.duskInk => 0x64596B, // inkSoft — secondary text
    PaletteToken.sand => 0xDCCDA8, // hairline — interior grid lines
    _ => null,
  };

  /// The shade used for this token's solid offset shadow (`docs/DESIGN.md` §4).
  int? get depthShade => switch (this) {
    PaletteToken.badgeGold => 0xB47A15,
    PaletteToken.sunsetRed => 0xA03A15,
    PaletteToken.cactusGreen => 0x2F6E3F,
    PaletteToken.nightIndigo => 0x2F2670,
    PaletteToken.bone || PaletteToken.sand => 0xC9B48C,
    _ => null,
  };

  /// Text drawn on top of this token as a background, where the design defines
  /// one. Always the darkest shade of the same family, never black or grey.
  int? get onColour => switch (this) {
    PaletteToken.badgeGold => 0x4A3405,
    PaletteToken.sunsetRed => 0x3D0D06,
    PaletteToken.cactusGreen => 0x0E2D17,
    PaletteToken.nightIndigo => 0xF3EFFF,
    _ => null,
  };
}

/// The backgrounds a grid cell can take, and therefore the backgrounds any
/// value or note must stay legible against.
const List<int> cellBackgrounds = <int>[
  0xF5EBD6, // bone
  0xFDEFC6, // goldPale — fresh-completion flash
  0xE6DEFA, // indigoPale — candidate highlight
  0xFBDDD6, // redPale — duplicate
  0xCFE0BE, // greenPale — settled completion tint
];
