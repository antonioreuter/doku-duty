import 'dart:ui' show Color;

import '../domain/palette.dart';
import '../domain/season_theme.dart';

/// The only place in `lib/` where a [Color] is constructed.
///
/// A test walks every file under `lib/` and fails on a colour literal or a
/// framework colour constant found anywhere else. That test, not this comment,
/// is what makes "one colour, one job" enforceable — D-71 fixes the palette at
/// eight tokens, and a rule that is only written down is a rule that gets an
/// exception the first time someone is in a hurry.
extension PaletteTokenColour on PaletteToken {
  /// This token's base colour.
  Color get colour => Color(0xFF000000 | value);

  /// The pale tint derived from this token, or null where the design defines
  /// none. Reachable only through the token that owns it (D-71).
  Color? get paleColour => _opaque(pale);

  /// The shade for this token's solid offset shadow (`docs/DESIGN.md` §4).
  Color? get depthColour => _opaque(depthShade);

  /// Text drawn on this token used as a background.
  Color? get onColourText => _opaque(onColour);
}

Color? _opaque(int? rgb) => rgb == null ? null : Color(0xFF000000 | rgb);

/// The eight tokens as colours, for code that wants them by name.
///
/// There is deliberately no way to add a member: the accessors delegate to
/// [PaletteToken], which is an enum, so a ninth hue would have to be added to
/// the enum — where the count test would catch it.
abstract final class DokuColours {
  static Color get bone => PaletteToken.bone.colour;
  static Color get sand => PaletteToken.sand.colour;
  static Color get duskInk => PaletteToken.duskInk.colour;
  static Color get badgeGold => PaletteToken.badgeGold.colour;
  static Color get nightIndigo => PaletteToken.nightIndigo.colour;
  static Color get turquoise => PaletteToken.turquoise.colour;
  static Color get sunsetRed => PaletteToken.sunsetRed.colour;
  static Color get cactusGreen => PaletteToken.cactusGreen.colour;

  /// Secondary text. Derived from [PaletteToken.duskInk], not a token of its own.
  static Color get inkSoft => PaletteToken.duskInk.paleColour!;

  /// Interior grid lines. Derived from [PaletteToken.sand].
  static Color get hairline => PaletteToken.sand.paleColour!;
}

/// Season-resolved values as colours.
///
/// Exists so that nothing outside this file has to turn an `0xRRGGBB` into a
/// [Color] — including the theme builder, which is exactly where an off-palette
/// grey would otherwise arrive as a sensible-looking default.
extension SeasonPaletteColour on SeasonPalette {
  Color colourOf(PaletteToken token) => Color(0xFF000000 | valueOf(token));

  Color? paleColourOf(PaletteToken token) => _opaque(paleOf(token));

  Color? depthColourOf(PaletteToken token) => _opaque(depthShadeOf(token));

  Color? onColourOf(PaletteToken token) => _opaque(token.onColour);
}
