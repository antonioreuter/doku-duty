import 'package:flutter/material.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../design_system/presentation/pressable.dart';
import '../domain/lesson.dart';
import 'lesson_grid.dart';

/// One **lesson**, start to finish.
///
/// Steps through its own fixed grid and ends by asking the player to make the
/// placement themselves. It reads nothing about the player's puzzle and writes
/// nothing anywhere: [onDone] is the only way out, and what happens after is
/// the caller's business.
///
/// **Nothing here can be failed.** A wrong digit says so and waits; there is no
/// score, no limit, and no route out except finishing or skipping (constraint
/// 1). Skip is present on every step, never hidden and never disabled — a
/// **lesson** the player cannot leave is a gate.
class LessonView extends StatefulWidget {
  const LessonView({
    required this.lesson,
    required this.onDone,
    this.reduceMotion = false,
    super.key,
  });

  final Lesson lesson;

  /// Called when the **lesson** is finished or skipped, with which it was.
  ///
  /// Both mark it seen: a **lesson** that returned after being declined would
  /// be nagging rather than teaching. The caller is what knows how to record
  /// that, so it is told rather than doing it here.
  final void Function({required bool skipped}) onDone;

  final bool reduceMotion;

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> {
  int _step = 0;
  bool _placed = false;
  int? _wrong;

  Lesson get _lesson => widget.lesson;

  bool get _isFinalStep => _step == _lesson.steps.length - 1;

  void _next() {
    if (_isFinalStep) return;
    setState(() => _step++);
  }

  void _tryDigit(int digit) {
    setState(() {
      if (digit == _lesson.placement.digit) {
        _placed = true;
        _wrong = null;
      } else {
        // Said plainly, and that is all that happens. Nothing is recorded, the
        // lesson does not end, and the player may try as often as they like.
        _wrong = digit;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _lesson.steps[_step];

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title, style: TypeRole.screenTitle.style),
      ),
      body: PaperGrain(
        child: SafeArea(
          // The controls are pinned below the scrolling part, not appended to
          // the end of it. Skip is the one action a player always has
          // (constraint 1), and a way out you have to scroll to find is not
          // one — on a tall lesson it sat below the fold, which a test caught
          // only because it could not reach it either.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: LessonGrid(
                          grid: _lesson.grid,
                          marked: step.cells,
                          answerCell: _isFinalStep
                              ? _lesson.placement.cell
                              : null,
                          answerDigit: _placed ? _lesson.placement.digit : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.text,
                        key: const ValueKey<String>('lesson-step-text'),
                        style: TypeRole.body.style,
                      ),
                      const SizedBox(height: 16),
                      if (_isFinalStep && !_placed) _digits(),
                      if (_wrong != null && !_placed) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Not $_wrong — try another.',
                          key: const ValueKey<String>('lesson-wrong'),
                          style: TypeRole.label.style,
                        ),
                      ],
                      if (_placed) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'That is the one.',
                          key: const ValueKey<String>('lesson-right'),
                          style: TypeRole.body.style,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _chip(
                        key: const ValueKey<String>('lesson-skip'),
                        label: _placed ? 'Done' : 'Skip',
                        token: PaletteToken.sand,
                        onPressed: () => widget.onDone(skipped: !_placed),
                      ),
                    ),
                    if (!_isFinalStep) ...<Widget>[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _chip(
                          key: const ValueKey<String>('lesson-next'),
                          label: 'Next',
                          token: PaletteToken.badgeGold,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digits() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var digit = 1; digit <= 9; digit++)
          SizedBox(
            width: 44,
            height: 44,
            child: _chip(
              key: ValueKey<String>('lesson-digit-$digit'),
              label: '$digit',
              token: PaletteToken.bone,
              onPressed: () => _tryDigit(digit),
            ),
          ),
      ],
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required PaletteToken token,
    required VoidCallback onPressed,
  }) {
    return Pressable(
      key: key,
      token: token,
      reduceMotion: widget.reduceMotion,
      onPressed: onPressed,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TypeRole.body.style,
          ),
        ),
      ),
    );
  }
}
