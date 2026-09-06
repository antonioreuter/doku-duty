import 'palette.dart';

/// How each kind of note is drawn.
///
/// Two attributes, not one. The ink alone cannot carry the distinction: once
/// `turquoise` is dark enough to be legible at 11px (D-72), the two inks sit
/// 1.34:1 apart in normal vision and 1.14:1 under deuteranopia, at which point
/// they are the same mark. Constraint 5 forbids resting a state on colour, so
/// provisional notes carry an underline as well (D-73).
///
/// The token layer decides the treatment; `add-grid-and-input` and the notes
/// changes draw it.
enum NoteInk {
  /// A candidate the player has derived.
  settled(PaletteToken.nightIndigo, isUnderlined: false),

  /// A hypothesis under test, clearable in one action (D-11).
  provisional(PaletteToken.turquoise, isUnderlined: true);

  const NoteInk(this.token, {required this.isUnderlined});

  final PaletteToken token;

  /// The non-colour signal. The underline sits below the digit's baseline so the
  /// digit keeps the fixed positional slot it would occupy either way (D-10).
  final bool isUnderlined;

  int get value => token.value;
}

/// Stroke weight of the provisional underline, in logical pixels.
///
/// One pixel, matching the grid cell hairline in `docs/DESIGN.md` §3 — heavy
/// enough to read at 11px, light enough not to compete with the digit.
const double provisionalUnderlineWeight = 1.0;

/// Gap between the note's baseline and the underline, in logical pixels.
///
/// Small enough to stay inside the note's own third of the cell, so the rule
/// never reads as belonging to the candidate in the slot below.
const double provisionalUnderlineOffset = 1.5;
