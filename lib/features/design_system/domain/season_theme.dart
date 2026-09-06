import 'palette.dart';

/// What a season is allowed to repaint.
///
/// The guarantee in D-55 is structural, not conventional: this type has a field
/// for each of the two surfaces and a map of props, and **no field of any kind**
/// through which one of the six state colours could arrive. A season that wanted
/// to change the error colour would have to change this class first, which is a
/// review anyone would notice.
///
/// Seasons rotate every six weeks. If completion or error colour moved with the
/// theme, the grid would be relearned nine times a year and the muscle memory an
/// expert board depends on would never form.
class SeasonTheme {
  const SeasonTheme({
    required this.id,
    required this.name,
    required this.bone,
    required this.sand,
    int? hairline,
    int? surfaceDepth,
    this.props = const <String, PaletteToken>{},
  }) : hairline = hairline ?? _defaultHairline,
       surfaceDepth = surfaceDepth ?? _defaultSurfaceDepth;

  // Resolved at construction so a theme always answers, and callers never have
  // to know which season bothered to supply them.
  static const int _defaultHairline = 0xDCCDA8;
  static const int _defaultSurfaceDepth = 0xC9B48C;

  /// The theme every build falls back to. Real territories are data and arrive
  /// with `add-season-map`; this one exists so there is always a resolved
  /// palette with no network and no configuration.
  static const SeasonTheme defaultTheme = SeasonTheme(
    id: 'default',
    name: 'Default',
    bone: 0xF5EBD6,
    sand: 0xE4D4AE,
  );

  final String id;
  final String name;

  /// Repaints [PaletteToken.bone] — grid cells and cards.
  final int bone;

  /// Repaints [PaletteToken.sand] — page background and ground shadows.
  final int sand;

  /// Interior grid lines. Derived from [sand], and repainted with it — a season
  /// that changes the paper and leaves the ruling behind looks like a bug.
  /// Falls back to the default surface's value when a season does not say.
  final int hairline;

  /// The shade both surfaces cast as a solid offset shadow (`docs/DESIGN.md` §4).
  final int surfaceDepth;

  /// Prop tints, each chosen from the eight tokens rather than supplied as a
  /// free colour. Props are decoration, and decoration draws from the token set
  /// and never adds to it (D-71), so the value type here is the enum itself.
  final Map<String, PaletteToken> props;
}

/// The palette as a given season paints it.
///
/// Surfaces come from the theme; the six state colours and every value derived
/// from them come from [PaletteToken] and are the same in every season.
class SeasonPalette {
  const SeasonPalette(this.theme);

  final SeasonTheme theme;

  /// The base value of [token] under this season.
  int valueOf(PaletteToken token) => switch (token) {
    PaletteToken.bone => theme.bone,
    PaletteToken.sand => theme.sand,
    _ => token.value,
  };

  /// Derived values follow their parent: a state colour's tint is as fixed as
  /// the state colour itself, and a surface's tint repaints with the surface.
  int? paleOf(PaletteToken token) => switch (token) {
    PaletteToken.sand => theme.hairline,
    _ => token.pale,
  };

  int? depthShadeOf(PaletteToken token) => switch (token) {
    PaletteToken.bone || PaletteToken.sand => theme.surfaceDepth,
    _ => token.depthShade,
  };

  int? onColourOf(PaletteToken token) => token.onColour;

  /// The token a prop takes its tint from, or null if this season does not
  /// paint that prop.
  PaletteToken? propToken(String prop) => theme.props[prop];
}
