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
class NumberPad extends StatelessWidget {
  const NumberPad({
    required this.onKey,
    this.lockedDigit,
    this.notesMode = false,
    this.reduceMotion = false,
    super.key,
  });

  final ValueChanged<PadKey> onKey;

  /// The digit held for digit-first input, or null in cell-first mode.
  final int? lockedDigit;

  /// Whether a digit press writes a **settled note** rather than a value.
  final bool notesMode;

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _row(<PadKey>[for (var d = 1; d <= 5; d++) DigitKey(d)]),
        _row(<PadKey>[
          for (var d = 6; d <= 9; d++) DigitKey(d),
          const EraseKey(),
        ]),
        _row(const <PadKey>[
          NotesToggleKey(),
          AutoNotesKey(),
          UndoKey(),
        ], fill: false),
      ],
    );
  }

  Widget _row(List<PadKey> keys, {bool fill = true}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final key in keys)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _PadButton(
              padKey: key,
              onPressed: () => onKey(key),
              // Long-press a digit for one entry in the other mode, so a
              // single note during a run of values costs no trip to the
              // toggle (`docs/SPEC.md` §3.4).
              onLongPressed: key is DigitKey
                  ? () => onKey(DigitLongPressKey(key.digit))
                  : null,
              isLocked:
                  (key is DigitKey && key.digit == lockedDigit) ||
                  (key is NotesToggleKey && notesMode),
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
    required this.onPressed,
    required this.onLongPressed,
    required this.isLocked,
    required this.reduceMotion,
  });

  final PadKey padKey;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;

  /// Digit-first mode holds a digit; the held key says so.
  final bool isLocked;

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;
    // The target grows with type but never shrinks below the floor.
    final side = DokuLayout.minimumTapTarget * (scale < 1 ? 1 : scale);

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
  };

  String get _label => switch (padKey) {
    DigitKey(:final digit) => '$digit',
    DigitLongPressKey(:final digit) => '$digit',
    EraseKey() => 'Erase',
    UndoKey() => 'Undo',
    NotesToggleKey() => 'Notes',
    AutoNotesKey() => 'Fill notes',
  };
}
