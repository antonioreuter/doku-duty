import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/domain/haptics.dart';
import '../../design_system/application/motion_settings.dart';
import '../../design_system/presentation/haptic_service.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../persistence/domain/note_enums.dart';
import '../../mistake_model/application/strict_mode.dart';
import '../application/grid_providers.dart';
import '../application/puzzle_controller.dart';
import '../domain/puzzle_session.dart';
import 'number_pad.dart';
import 'puzzle_grid.dart';

/// The grid and the pad.
///
/// No timer and no completion effect — both belong to a later change and both
/// are easy to add "while we are here", which is exactly why neither is here.
///
/// The **mistake** count and the error colour arrived with `add-mistake-model`,
/// and both are invisible unless the player turned **strict mode** on: a wrong
/// digit looks exactly like a right one by default, because finding it is the
/// game (D-04).
class PuzzleScreen extends ConsumerWidget {
  const PuzzleScreen({required this.puzzleId, super.key});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opening = ref.watch(puzzleOpeningProvider(puzzleId));

    return Scaffold(
      appBar: AppBar(),
      body: PaperGrain(
        child: opening.when(
          // A blank surface, not a spinner: there is nothing to wait for that
          // takes long enough to be worth announcing.
          loading: () => const SizedBox.expand(),
          error: (error, stack) => const SizedBox.expand(),
          data: (data) => data == null
              ? const SizedBox.expand()
              : _PuzzleBody(
                  opening: data,
                  sink: ref.watch(boardSinkProvider),
                  // Read rather than watched: the session carries the mode
                  // from here on, so that turning it off mid-puzzle goes
                  // through one path and not two.
                  isStrict: ref.watch(strictModeProvider),
                  // A player who asked for less motion asked for less of all
                  // of it — the pad stops animating and the haptic goes quiet.
                  reduceMotion: MotionSettings(
                    osReduceMotion: MediaQuery.disableAnimationsOf(context),
                    reduceEffects: ref.watch(reduceEffectsProvider),
                  ).isMotionReduced,
                ),
        ),
      ),
    );
  }
}

class _PuzzleBody extends StatefulWidget {
  const _PuzzleBody({
    required this.opening,
    required this.sink,
    required this.reduceMotion,
    required this.isStrict,
  });

  final PuzzleOpening opening;
  final BoardSink sink;
  final bool reduceMotion;
  final bool isStrict;

  @override
  State<_PuzzleBody> createState() => _PuzzleBodyState();
}

class _PuzzleBodyState extends State<_PuzzleBody> {
  late final PuzzleController _controller = PuzzleController(
    puzzle: widget.opening.puzzle,
    sink: widget.sink,
    initial: sessionFor(
      puzzle: widget.opening.puzzle,
      placedValues: widget.opening.placedValues,
      notes: widget.opening.notes,
      mode: widget.opening.mode,
      isStrict: widget.isStrict,
      mistakes: widget.opening.mistakes,
    ),
    fireHaptic: (haptic) => unawaited(_haptics.fire(haptic)),
  );

  /// The stored choice arrives after the first frame (D-85), and the player
  /// can change it mid-puzzle. Either way the session is told, so the mode
  /// lives in exactly one place.
  @override
  void didUpdateWidget(_PuzzleBody old) {
    super.didUpdateWidget(old);
    if (old.isStrict != widget.isStrict) {
      _controller.setStrictMode(widget.isStrict);
    }
  }

  HapticService get _haptics => HapticService(isEnabled: !widget.reduceMotion);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final session = _controller.state;
        final remaining = session.mistakesRemaining;
        return SafeArea(
          child: Column(
            children: <Widget>[
              // Stated as a number, never as a colour that deepens: how much
              // of an **attempt** is left is exactly what a hue cannot carry
              // (constraint 5). Absent entirely when stakes are off, because
              // there is nothing to count down to.
              if (remaining != null)
                Padding(
                  key: const ValueKey<String>('mistakes-remaining'),
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    remaining == 1
                        ? '1 mistake left'
                        : '$remaining mistakes left',
                    style: TypeRole.body.style,
                  ),
                ),
              if (session.isOver)
                _AttemptEnded(
                  onRestart: _controller.restart,
                  onLeave: () => Navigator.of(context).maybePop(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PuzzleGrid(
                    board: session.board,
                    selectedCell: session.selectedCell,
                    highlightedDigit: session.highlightedDigit,
                    flaggedCells: session.flaggedCells,
                    onCellTapped: _controller.tapCell,
                  ),
                ),
              ),
              // The pad goes when the **attempt** does. It accepts nothing at
              // that point, and a pad that looks live and swallows every tap
              // is a set of disabled controls wearing a working pad's clothes
              // — which is the thing constraint 1 objects to. Removing it also
              // gives the two choices the room they need at the reader's
              // largest text size, where a board, a count, a dead pad and a
              // panel do not fit on a phone together.
              if (!session.isOver)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NumberPad(
                    lockedDigit: session.mode == InputMode.digitFirst
                        ? session.lockedDigit
                        : null,
                    notesMode: session.entryKind == EntryKind.note,
                    provisionalInk: session.noteInk == NoteKind.provisional,
                    reduceMotion: widget.reduceMotion,
                    onKey: _controller.tapKey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Kept so the haptic vocabulary is reachable from here without a raw platform
/// call appearing in a widget.
const DokuHaptic placementHaptic = DokuHaptic.selectionTick;

/// What the player is offered when a **strict mode** **attempt** ends (D-95).
///
/// Two choices and no third. Nothing here sells a way back into the attempt:
/// the stakes are the reason the player turned the mode on, and monetising the
/// only failure state in the product would make it a funnel.
///
/// The board stays on screen behind this, locked but kept, so the player can
/// look at what they did before deciding.
class _AttemptEnded extends StatelessWidget {
  const _AttemptEnded({required this.onRestart, required this.onLeave});

  final VoidCallback onRestart;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('attempt-ended'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Three mistakes. That is the deal you made.',
            style: TypeRole.body.style,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              // Neither is ever disabled: a disabled control is a small
              // failure state, and this product does not have those beyond the
              // one the player opted into (constraint 1).
              Expanded(
                child: _EndedChoice(
                  key: const ValueKey<String>('attempt-restart'),
                  label: 'Start again',
                  onPressed: onRestart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EndedChoice(
                  key: const ValueKey<String>('attempt-leave'),
                  label: 'Back to the map',
                  onPressed: onLeave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the two choices, named for a screen reader and holding the 44pt
/// minimum whatever the text size (D-84, D-93).
class _EndedChoice extends StatelessWidget {
  const _EndedChoice({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: DokuLayout.minimumTapTarget * (scale < 1 ? 1 : scale),
        ),
        child: TextButton(
          onPressed: onPressed,
          child: Text(label, style: TypeRole.body.style),
        ),
      ),
    );
  }
}
