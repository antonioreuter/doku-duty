import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/palette.dart';
import '../domain/season_theme.dart';
import '../domain/shape.dart';
import 'doku_colours.dart';
import 'doku_type.dart';

/// The season currently painting the app.
///
/// One default for now. Real territories are data and arrive with
/// `add-season-map`; this provider is the seam they will be supplied through,
/// so nothing downstream has to change when they do.
final seasonThemeProvider = Provider<SeasonTheme>(
  (ref) => SeasonTheme.defaultTheme,
);

/// The resolved palette for the active season.
final seasonPaletteProvider = Provider<SeasonPalette>(
  (ref) => SeasonPalette(ref.watch(seasonThemeProvider)),
);

/// The Flutter theme built from the tokens.
///
/// Capabilities read tokens from here rather than importing the token file, so
/// a season repaint reaches every screen without any of them knowing a season
/// exists.
final appThemeProvider = Provider<ThemeData>((ref) {
  return DokuTheme.from(ref.watch(seasonPaletteProvider));
});

abstract final class DokuTheme {
  /// Builds a [ThemeData] from [palette].
  ///
  /// Every colour comes from a token. There is no literal here, which is what
  /// the stray-colour test checks — a theme is exactly where an off-palette
  /// grey would otherwise creep in as a "sensible default".
  static ThemeData from(SeasonPalette palette) {
    final surface = palette.colourOf(PaletteToken.bone);
    final background = palette.colourOf(PaletteToken.sand);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: DokuColours.badgeGold,
        onPrimary: PaletteToken.badgeGold.onColourText!,
        secondary: DokuColours.nightIndigo,
        onSecondary: PaletteToken.nightIndigo.onColourText!,
        error: DokuColours.sunsetRed,
        onError: PaletteToken.sunsetRed.onColourText!,
        surface: surface,
        onSurface: DokuColours.duskInk,
      ),
      textTheme: TextTheme(
        titleLarge: TypeRole.screenTitle.style,
        bodyMedium: TypeRole.body.style,
        labelMedium: TypeRole.label.style,
      ),
      fontFamily: DokuType.family,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DokuRadius.card),
        ),
      ),
      // Elevation is Material's blurred shadow. The design uses solid offset
      // depth instead (docs/DESIGN.md §4), painted by the primitives.
      splashFactory: NoSplash.splashFactory,
    );
  }
}
