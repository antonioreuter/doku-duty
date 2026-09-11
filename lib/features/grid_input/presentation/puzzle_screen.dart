import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/domain/haptics.dart';
import '../../design_system/application/motion_settings.dart';
import '../../design_system/presentation/haptic_service.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../application/grid_providers.dart';
import '../application/puzzle_controller.dart';
import '../domain/puzzle_session.dart';
import 'number_pad.dart';
import 'puzzle_grid.dart';

/// The grid and the pad.
///
/// No timer, no mistake count, no error colour, no completion effect. Each of
/// those belongs to a later change and each is easy to add "while we are here",
/// which is exactly why none of them is here.
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
  });

  final PuzzleOpening opening;
  final BoardSink sink;
  final bool reduceMotion;

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
    ),
    fireHaptic: (haptic) => unawaited(_haptics.fire(haptic)),
  );

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
        return SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PuzzleGrid(
                    board: session.board,
                    selectedCell: session.selectedCell,
                    highlightedDigit: session.highlightedDigit,
                    onCellTapped: _controller.tapCell,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NumberPad(
                  lockedDigit: session.mode == InputMode.digitFirst
                      ? session.lockedDigit
                      : null,
                  notesMode: session.entryKind == EntryKind.note,
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
