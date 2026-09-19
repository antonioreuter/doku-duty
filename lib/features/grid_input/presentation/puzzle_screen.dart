import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../completion_effects/application/completion_effects_controller.dart';
import '../../completion_effects/application/completion_settings.dart';
import '../../completion_effects/domain/unit_completion.dart';
import '../../design_system/domain/haptics.dart';
import '../../design_system/application/motion_settings.dart';
import '../../design_system/presentation/haptic_service.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../persistence/domain/note_enums.dart';
import '../../mistake_model/application/strict_mode.dart';
import '../../completion_effects/domain/effect_event.dart';
import '../../technique_tutorials/application/lesson_providers.dart';
import '../../technique_tutorials/domain/lesson.dart';
import '../../technique_tutorials/presentation/lesson_view.dart';
import '../application/grid_providers.dart';
import '../application/puzzle_controller.dart';
import '../domain/puzzle_session.dart';
import 'number_pad.dart';
import 'pad_tools.dart';
import 'puzzle_grid.dart';

/// The grid and the pad.
///
/// No timer — that belongs to a later change and is easy to add "while we are
/// here", which is exactly why it is not here.
///
/// Completion effects arrived with `add-completion-effects`. They are drawn
/// from the board and never write to it: the **completion tint** is derived,
/// the celebration is a snapshot the painter consumes, and neither can delay a
/// tap (constraint 2).
///
/// The **mistake** count and the error colour arrived with `add-mistake-model`,
/// and both are invisible unless the player turned **strict mode** on: a wrong
/// digit looks exactly like a right one by default, because finding it is the
/// game (D-04).
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({required this.puzzleId, super.key});

  final String puzzleId;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  /// Whether the **lesson** that was due has been dealt with this visit.
  ///
  /// Held here rather than derived, because the answer changes underneath us:
  /// finishing or skipping marks the **lesson** seen, which makes it no longer
  /// due — and without this the screen would simply have rebuilt into the
  /// puzzle, which is right, but a second **lesson** due on the same opening
  /// would then appear. At most one per opening (D-106).
  bool _lessonDone = false;

  @override
  Widget build(BuildContext context) {
    final opening = ref.watch(puzzleOpeningProvider(widget.puzzleId));

    if (!_lessonDone) {
      final due = opening.value == null
          ? const AsyncValue<Lesson?>.loading()
          : ref.watch(
              dueLessonProvider(
                LessonRequest(
                  rank: opening.value!.puzzle.rank,
                  techniquesRequired: opening.value!.techniquesRequired,
                ),
              ),
            );
      final lesson = due.value;
      if (lesson != null) {
        return LessonView(
          lesson: lesson,
          // The same answer the puzzle gets: a player who asked for less
          // motion asked for less of all of it, tutorial included.
          reduceMotion: MotionSettings(
            osReduceMotion: MediaQuery.disableAnimationsOf(context),
            reduceEffects: ref.watch(reduceEffectsProvider),
          ).isMotionReduced,
          onDone: ({required bool skipped}) async {
            // Seen either way, and written before the puzzle opens: a
            // **lesson** that returned after being declined would be nagging
            // rather than teaching (constraint 9 for the write).
            await ref.read(lessonRepositoryProvider).markSeen(lesson.id);
            ref.invalidate(seenLessonsProvider);
            if (mounted) setState(() => _lessonDone = true);
          },
        );
      }
    }

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
                  // Watched, so the stored choice arriving after the first
                  // frame (D-85) and a mid-puzzle toggle both rebuild this and
                  // reach `didUpdateWidget`. The session is what carries the
                  // mode from there on, so the flagging and the cap move
                  // together through one path rather than two.
                  isStrict: ref.watch(strictModeProvider),
                  // Hides the tint and nothing else — the **corner mark**s are
                  // drawn either way, so completion stays readable (D-50).
                  hideCompletionTints: ref.watch(hideCompletionTintsProvider),
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
    required this.hideCompletionTints,
  });

  final PuzzleOpening opening;
  final BoardSink sink;
  final bool reduceMotion;
  final bool isStrict;
  final bool hideCompletionTints;

  @override
  State<_PuzzleBody> createState() => _PuzzleBodyState();
}

class _PuzzleBodyState extends State<_PuzzleBody>
    with SingleTickerProviderStateMixin {
  late final PuzzleController _controller = PuzzleController(
    puzzle: widget.opening.puzzle,
    sink: widget.sink,
    // Graded when the puzzle was opened, so the **solve record** has the
    // technique set without a solver run on the frame that completes the board.
    techniquesRequired: widget.opening.techniquesRequired,
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

  late final CompletionEffectsController _effects = CompletionEffectsController(
    vsync: this,
    // Told which cells hold a value rather than handed the board: the
    // effect layer has no business reading the game, only decorating it.
    cellIsFilled: (cell) => !_controller.state.board.isEmptyAt(cell),
    fireHaptic: (haptic) => unawaited(_haptics.fire(haptic)),
    reduceMotion: widget.reduceMotion,
  );

  late final StreamSubscription<EffectEvent> _subscription = driveEffects(
    _controller.effects,
    _effects,
  );

  @override
  void initState() {
    super.initState();
    // Touch the subscription so it is live from the first frame. A completion
    // in the first second of a resumed puzzle is an ordinary thing.
    _subscription;
  }

  /// The stored choice arrives after the first frame (D-85), and the player
  /// can change it mid-puzzle. Either way the session is told, so the mode
  /// lives in exactly one place.
  @override
  void didUpdateWidget(_PuzzleBody old) {
    super.didUpdateWidget(old);
    if (old.isStrict != widget.isStrict) {
      _controller.setStrictMode(widget.isStrict);
    }
    // Either switch alone is enough, and it takes effect on whatever is running
    // rather than at the next completion: a player who asked for less asked for
    // less now.
    if (old.reduceMotion != widget.reduceMotion) {
      _effects.reduceMotion = widget.reduceMotion;
    }
  }

  HapticService get _haptics => HapticService(isEnabled: !widget.reduceMotion);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _effects.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// A key or a tool was pressed.
  ///
  /// The celebration is skipped first: a player who reaches for the pad
  /// mid-**cascade** has moved on, and the effect should not still be running
  /// over the board they are working (D-46).
  void _onPadKey(PadKey key) {
    _effects.skip();
    _controller.tapKey(key);
  }

  /// A tap anywhere on the grid ends whatever is celebrating, and is still the
  /// tap it was.
  ///
  /// Both happen, in this order, on the same gesture: the effect is skipped and
  /// the cell is selected (D-46). Nothing is swallowed — a tap that only
  /// dismissed a celebration would make the player tap twice, which is exactly
  /// the obstacle the skippability rule exists to prevent.
  void _onCellTapped(int cell) {
    _effects.skip();
    _controller.tapCell(cell);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Both, so a frame of the celebration and a change to the board each
      // repaint on their own. The effect layer never causes a board change, so
      // listening to it cannot cause a write (constraint 9).
      listenable: Listenable.merge(<Listenable>[_controller, _effects]),
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
                    // Derived from the board every frame rather than stored.
                    // Nothing is written when a **unit** completes, so nothing
                    // can be written wrongly (D-48).
                    completedCells: UnitCompletion.tintedCells(session.board),
                    freshCells: _effects.freshCells,
                    showCompletionTints: !widget.hideCompletionTints,
                    effects: _effects.frame,
                    onCellTapped: _onCellTapped,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      NumberPad(
                        lockedDigit: session.mode == InputMode.digitFirst
                            ? session.lockedDigit
                            : null,
                        reduceMotion: widget.reduceMotion,
                        onKey: _onPadKey,
                      ),
                      // The named controls, below the digits and visibly not
                      // more of them. Which ones are here is derived from the
                      // board and the mode, so nothing is stored and nothing
                      // can fall out of step.
                      PadTools(
                        notesMode: session.entryKind == EntryKind.note,
                        provisionalInk: session.noteInk == NoteKind.provisional,
                        hasProvisionalNotes: session.board.hasProvisionalNotes,
                        reduceMotion: widget.reduceMotion,
                        onKey: _onPadKey,
                      ),
                    ],
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
