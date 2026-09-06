import 'package:flutter/painting.dart';

/// The type scale — six roles, no more.
///
/// Sizes and weights are canonical in `docs/DESIGN.md` §2. They are a contract
/// rather than a suggestion: the grid's note slots and hit targets are laid out
/// against these numbers, so a role that quietly grows moves the board.
enum TypeRole {
  /// The digit a player has placed. 22px, so the large-text contrast budget
  /// applies to it.
  gridValue(22, FontWeight.w600, isTabular: true),

  /// A candidate in one of the nine fixed positional slots (D-10). The smallest
  /// type in the app, and the reason the face was chosen on its 11px aperture.
  gridNote(11, FontWeight.w400, isTabular: true),

  screenTitle(24, FontWeight.w600),
  body(15, FontWeight.w400),
  label(12, FontWeight.w500),

  /// A character's line. Short — under six words (D-02).
  characterLine(15, FontWeight.w400);

  const TypeRole(this._size, this._weight, {this.isTabular = false});

  final double _size;
  final FontWeight _weight;

  /// Whether this role uses tabular figures.
  final bool isTabular;

  /// This role at its documented size, before any text scaling.
  TextStyle get style => TextStyle(
    fontFamily: DokuType.family,
    fontSize: _size,
    fontWeight: _weight,
    // Tabular figures on the grid roles only. A proportional `1` is
    // narrower than the other digits, so a column of values shifts sideways
    // as the board fills — a twitch the player notices without being able
    // to name it.
    fontFeatures: isTabular
        ? const <FontFeature>[FontFeature.tabularFigures()]
        : null,
  );

  /// This role at [textScale]. Dynamic type is respected everywhere
  /// (`docs/DESIGN.md` §2), so nothing in the app pins a size.
  TextStyle scaled(double textScale) =>
      style.copyWith(fontSize: _size * textScale);
}

abstract final class DokuType {
  /// The bundled family. Declared in `pubspec.yaml` with three static weights
  /// and shipped as an asset — never fetched, because the first frame has to
  /// render in airplane mode on a fresh install.
  ///
  /// Nunito, over Fredoka and Baloo 2 (D-74): it holds the widest counters at
  /// 11px, which is the size that decides a sudoku face.
  static const String family = 'Nunito';
}
