import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/pressable.dart';

/// What a key on the pad does.
sealed class PadKey {
  const PadKey();
}

final class DigitKey extends PadKey {
  const DigitKey(this.digit);

  final int digit;
}

final class EraseKey extends PadKey {
  const EraseKey();
}

final class UndoKey extends PadKey {
  const UndoKey();
}

/// Switch between writing values and writing **settled note**s.
final class NotesToggleKey extends PadKey {
  const NotesToggleKey();
}

/// Run **auto-notes**: mark every empty cell with its legal candidates.
///
/// One press, one action, one undo. Unmetered here — the charge and the Stamp
/// price are `add-perks`, and a free control that later grows a price is a
/// worse surprise than one that arrives priced.
final class AutoNotesKey extends PadKey {
  const AutoNotesKey();
}

/// Switch which ink note entry writes (D-89).
///
/// A second axis rather than a third value on [NotesToggleKey]: the two are
/// independent, and folding them into one control would leave a long-press —
/// "one entry in the opposite mode" — with no defined meaning, because the
/// opposite of provisional is two things.
final class InkToggleKey extends PadKey {
  const InkToggleKey();
}

/// Remove every **provisional note** on the board (D-11).
final class ClearProvisionalKey extends PadKey {
  const ClearProvisionalKey();
}

/// Turn every **provisional note** settled (D-91, **promote**).
final class PromoteProvisionalKey extends PadKey {
  const PromoteProvisionalKey();
}

/// A digit pressed and held: one entry in the other mode.
final class DigitLongPressKey extends PadKey {
  const DigitLongPressKey(this.digit);

  final int digit;
}

/// The nine digits, erase, and undo.
///
/// Five columns, not nine (`docs/DESIGN.md` §8): nine keys in a row cannot carry
/// the depth treatment and are worse for thumbs regardless. Every key holds the
/// 44pt minimum — this is where a miss costs a placed digit, which is why the
/// floor stayed here when D-84 lifted it off grid cells.
///
/// Nothing is ever disabled, including a digit already placed nine times. A
/// disabled control is a small failure state, and this product does not have
/// those (constraint 1).
///
/// Four rows, not three. The second ink brought the chrome controls to six,
/// and a row is five wide: crowding them into one would put **clear** beside
/// undo, where a mis-tap discards the hypothesis the player meant to keep.
/// Clear and **promote** share the bottom row instead — together, because they
/// are the two ways one chain test ends, and furthest from the digits, because
/// those are what a thumb is already near.
class NumberPad extends StatelessWidget {
  const NumberPad({
    required this.onKey,
    this.lockedDigit,
    this.notesMode = false,
    this.provisionalInk = false,
    this.reduceMotion = false,
    super.key,
  });

  final ValueChanged<PadKey> onKey;

  /// The digit held for digit-first input, or null in cell-first mode.
  final int? lockedDigit;

  /// Whether a digit press writes a note rather than a value.
  final bool notesMode;

  /// Whether note entry writes a **provisional note** rather than a settled
  /// one. Independent of [notesMode] — they are two axes, not one (D-89).
  final bool provisionalInk;

  final bool reduceMotion;

  /// The pad is five columns wide (`docs/DESIGN.md` §8), so the widest row
  /// holds five keys and a key is the pad's width divided by five.
  static const int columns = 5;

  /// Horizontal padding each side of a key.
  static const double _gutter = 4;

  /// How large a key may be drawn: it grows with the reader's text size until
  /// the row it sits in is full, and then it stops (D-93).
  ///
  /// The same shape as D-92's glyph cap, one layer out, and for the same
  /// reason: a row of five keys cannot reflow any more than a row of nine
  /// cells can. Uncapped, five keys need 480pt at 2× against a 393pt phone —
  /// ordinary "Larger Text" — and the row runs off the screen.
  ///
  /// The 44pt floor outranks the cap. A pad too narrow to hold five keys at
  /// 44pt keeps the 44pt keys: a key that cannot be hit is worse than a row
  /// that has to be cut (D-84), and this is where a miss costs a placed digit.
  static double keySide(double textScale, double maxWidth) {
    final grown = DokuLayout.minimumTapTarget * (textScale < 1 ? 1 : textScale);
    // An unbounded width caps nothing — there is no row to fill.
    if (!maxWidth.isFinite) return grown;
    final fits = maxWidth / columns - _gutter * 2;
    return math.max(DokuLayout.minimumTapTarget, math.min(grown, fits));
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = keySide(textScale, constraints.maxWidth);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _row(<PadKey>[for (var d = 1; d <= 5; d++) DigitKey(d)], side),
            _row(<PadKey>[
              for (var d = 6; d <= 9; d++) DigitKey(d),
              const EraseKey(),
            ], side),
            _row(
              const <PadKey>[
                NotesToggleKey(),
                InkToggleKey(),
                AutoNotesKey(),
                UndoKey(),
              ],
              side,
              fill: false,
            ),
            _row(
              const <PadKey>[ClearProvisionalKey(), PromoteProvisionalKey()],
              side,
              fill: false,
            ),
          ],
        );
      },
    );
  }

  Widget _row(List<PadKey> keys, double side, {bool fill = true}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final key in keys)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gutter),
            child: _PadButton(
              padKey: key,
              side: side,
              onPressed: () => onKey(key),
              // Long-press a digit for one entry in the other mode, so a
              // single note during a run of values costs no trip to the
              // toggle (`docs/SPEC.md` §3.4).
              onLongPressed: key is DigitKey
                  ? () => onKey(DigitLongPressKey(key.digit))
                  : null,
              isLocked:
                  (key is DigitKey && key.digit == lockedDigit) ||
                  (key is NotesToggleKey && notesMode) ||
                  (key is InkToggleKey && provisionalInk),
              reduceMotion: reduceMotion,
            ),
          ),
        if (fill) const SizedBox.shrink(),
      ],
    ),
  );
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.padKey,
    required this.side,
    required this.onPressed,
    required this.onLongPressed,
    required this.isLocked,
    required this.reduceMotion,
  });

  final PadKey padKey;

  /// The key's side, already capped to the row it sits in (D-93).
  final double side;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;

  /// Digit-first mode holds a digit; the held key says so.
  final bool isLocked;

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    // The glyph scales with the key rather than with the text size directly,
    // so a capped key never holds an uncapped glyph and the key keeps the
    // proportions it has at the default size.
    final scale = side / DokuLayout.minimumTapTarget;

    // The label is the whole announcement. `excludeSemantics` on this node
    // would also drop the tap action [Pressable] contributes, leaving a button
    // a screen reader can name but not press — so the glyph is excluded at the
    // glyph instead.
    return Semantics(
      button: true,
      label: _label,
      selected: isLocked,
      child: GestureDetector(
        onLongPress: onLongPressed,
        child: Pressable(
          onPressed: onPressed,
          token: isLocked ? PaletteToken.badgeGold : PaletteToken.bone,
          radius: DokuRadius.button,
          reduceMotion: reduceMotion,
          child: SizedBox(
            width: side,
            height: side,
            child: Center(
              // Decoration. Without this the glyph merges into the label and a
              // screen reader reads "Fill notes ⁙" — the symbol spoken aloud,
              // which is noise at best and unreadable at worst.
              child: ExcludeSemantics(
                child: Text(
                  _glyph,
                  style: TypeRole.gridValue
                      .scaled(scale)
                      .copyWith(color: DokuColours.duskInk),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _glyph => switch (padKey) {
    DigitKey(:final digit) => '$digit',
    DigitLongPressKey(:final digit) => '$digit',
    EraseKey() => '⌫',
    UndoKey() => '↶',
    NotesToggleKey() => '✎',
    AutoNotesKey() => '⁙',
    InkToggleKey() => '~',
    ClearProvisionalKey() => '✕',
    PromoteProvisionalKey() => '✓',
  };

  String get _label => switch (padKey) {
    DigitKey(:final digit) => '$digit',
    DigitLongPressKey(:final digit) => '$digit',
    EraseKey() => 'Erase',
    UndoKey() => 'Undo',
    NotesToggleKey() => 'Notes',
    AutoNotesKey() => 'Fill notes',
    InkToggleKey() => 'Provisional ink',
    // Named for what they do to the board, and named apart at the first word:
    // a screen reader user hears which one they are on before the shared
    // "provisional notes" arrives (constraint 5, D-91).
    ClearProvisionalKey() => 'Clear provisional notes',
    PromoteProvisionalKey() => 'Promote provisional notes',
  };
}
