import 'package:flutter/widgets.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/pressable.dart';
import 'number_pad.dart';

/// A control on the pad that is not a digit.
///
/// **Named in words, and that is the whole point of the type.** A symbol on a
/// control the player meets once is a guess: `~` for which ink a note is written
/// in, and `⁙` for filling every empty cell with its candidates, are not
/// guessable by anyone who has not read the source. This capability already
/// insists a screen reader hear the name rather than the symbol — the symbol is
/// decoration and the name is the state — and a player looking at the screen is
/// owed the same thing.
///
/// The digits and **Erase** stay on the pad as keys. There the face and the name
/// are the same word, so a label would only repeat the glyph.
enum PadTool {
  notes('Notes', NotesToggleKey()),

  /// Which ink note entry writes (D-89).
  ///
  /// Named for the thing the player is doing rather than for the mechanism: a
  /// **provisional note** is a hypothesis under test (D-11), and "Test" is what
  /// the player would call it. "Provisional ink" describes the implementation.
  ink('Test', InkToggleKey()),

  fillNotes('Fill notes', AutoNotesKey()),

  undo('Undo', UndoKey()),

  /// The hypothesis failed: throw the whole test away (D-11).
  ///
  /// Named for what it does to the board. It used to be a bare `✕` beside a
  /// bare `✓`, which reads as cancel beside confirm — and confirm reads as
  /// "check my answer", the one thing this product does not do (D-04).
  discardTest('Discard test', ClearProvisionalKey()),

  /// The hypothesis held: keep it as ordinary working (D-91, **promote**).
  keepTest('Keep test', PromoteProvisionalKey());

  const PadTool(this.label, this.key);

  /// The word the player reads, and the word a screen reader says. One string,
  /// so the two cannot drift into describing the same control differently.
  final String label;

  /// What pressing it asks the controller to do.
  final PadKey key;
}

/// The controls below the digits, and the rule for which of them are there.
///
/// **A control with no work to do is absent, never greyed out.** That is the
/// treatment `add-mistake-model` already established when it took the whole pad
/// off screen at the end of an **attempt** rather than leaving it live and
/// unresponsive: a disabled control is a small failure state, and an empty space
/// is not (constraint 1). The two chain-test controls are the case that matters
/// — on a board with no hypothesis on it there is nothing to discard and nothing
/// to keep, and they were the two most easily misread controls on the pad.
class PadTools extends StatelessWidget {
  const PadTools({
    required this.onKey,
    required this.notesMode,
    required this.provisionalInk,
    required this.hasProvisionalNotes,
    this.reduceMotion = false,
    super.key,
  });

  final ValueChanged<PadKey> onKey;

  /// Whether a digit press writes a note rather than a value.
  final bool notesMode;

  /// Whether note entry writes a **provisional note**.
  final bool provisionalInk;

  /// Whether the board holds at least one **provisional note**.
  ///
  /// Derived from the board by the caller rather than tracked here, so there is
  /// nothing to keep in step and nothing to get wrong after an undo.
  final bool hasProvisionalNotes;

  final bool reduceMotion;

  /// The tools on the first line.
  ///
  /// The ink control joins only while notes mode is on, because that is the only
  /// time it changes anything: it decides what the *next* note is written in,
  /// and in value mode there is no next note.
  List<PadTool> get primary => <PadTool>[
    PadTool.notes,
    if (notesMode) PadTool.ink,
    PadTool.fillNotes,
    PadTool.undo,
  ];

  /// The two ways a chain test ends (D-11, D-91), present only while there is
  /// a test to end.
  List<PadTool> get chainTest => hasProvisionalNotes
      ? const <PadTool>[PadTool.discardTest, PadTool.keepTest]
      : const <PadTool>[];

  bool _isOn(PadTool tool) => switch (tool) {
    PadTool.notes => notesMode,
    PadTool.ink => provisionalInk,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The same width as the digit keys above, so the pad reads as one
        // block rather than as a narrow keypad with a full-width tray bolted
        // under it. Taken from the pad's own key arithmetic rather than
        // guessed, so the two cannot drift apart at a text size neither was
        // checked at.
        final side = NumberPad.keySide(textScale, constraints.maxWidth);
        final width = NumberPad.columns * (side + NumberPad.gutter * 2);

        return SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _line(primary),
              if (chainTest.isNotEmpty) _line(chainTest),
            ],
          ),
        );
      },
    );
  }

  Widget _line(List<PadTool> tools) => Padding(
    padding: const EdgeInsets.only(top: 8),
    // Every chip on a line is as tall as the tallest, so a label that wraps to
    // two lines does not leave its neighbours looking short. Cheap here — a
    // line is four chips at most, and none of this is on the grid's paint path.
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final tool in tools)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NumberPad.gutter,
                ),
                child: _ToolChip(
                  tool: tool,
                  isOn: _isOn(tool),
                  onPressed: () => onKey(tool.key),
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// One named control.
///
/// Wider than it is tall and filled with a word, so it does not read as another
/// digit key. The 44pt floor still applies — this is a control whose mis-tap
/// costs the player their working out (D-84).
class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.tool,
    required this.isOn,
    required this.onPressed,
    required this.reduceMotion,
  });

  final PadTool tool;

  /// Whether this control is the one currently in force.
  final bool isOn;

  final VoidCallback onPressed;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;

    // The label carries the whole announcement, and it is the same string the
    // player reads. `selected` carries the on state, so the mode is readable
    // without seeing which chip is painted differently (constraint 5).
    return Semantics(
      button: true,
      label: tool.label,
      selected: isOn,
      child: Pressable(
        onPressed: onPressed,
        token: isOn ? PaletteToken.badgeGold : PaletteToken.bone,
        radius: DokuRadius.button,
        reduceMotion: reduceMotion,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: DokuLayout.minimumTapTarget * (scale < 1 ? 1 : scale),
          ),
          child: Center(
            // The Semantics label above is the announcement. Without this the
            // word is read twice — once as the button's name and once as its
            // content.
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  tool.label,
                  textAlign: TextAlign.center,
                  // The label is the control, so it wraps rather than
                  // truncating: "Discard te…" and "Discard" would be the same
                  // control saying two different things, and one of them is
                  // the opposite of what it does.
                  // The colour is set here rather than inherited. Without it
                  // the label takes whatever the ambient text style carries,
                  // which on this surface is near-invisible — and a control
                  // whose name cannot be read is the bug this change exists to
                  // fix, reintroduced one layer down.
                  style: TypeRole.label
                      .scaled(scale)
                      .copyWith(
                        color: isOn
                            ? PaletteToken.badgeGold.onColourText
                            : DokuColours.duskInk,
                      ),
                  // The scale is already in the style above. Left on, the
                  // ambient scaler would apply it a second time and a chip at
                  // the largest text size would hold type at nine times the
                  // documented size.
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
