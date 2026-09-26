import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../design_system/domain/haptics.dart';
import '../../design_system/domain/motion.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';
import '../domain/completion_schedule.dart';
import '../domain/completion_sequence.dart';
import '../domain/effect_event.dart';
import '../domain/effect_frame.dart';
import '../domain/particle_pool.dart';

/// Turns what completed into what is on screen.
///
/// Subscribes to the controller's effect events and produces an [EffectFrame]
/// per tick. **It never touches the board.** Everything it needs it is told —
/// which cells hold a value, whether motion is reduced — so an effect cannot
/// change the game, only decorate it.
///
/// **Nothing here can delay a tap** (constraint 2). The ticker drives painting
/// and painting alone; input goes straight to the puzzle controller and arrives
/// whether or not anything is celebrating. A placement made mid-**cascade**
/// lands on the frame it would have landed on anyway.
class CompletionEffectsController extends ChangeNotifier {
  CompletionEffectsController({
    required TickerProvider vsync,
    required bool Function(int cell) cellIsFilled,
    this.fireHaptic,
    bool reduceMotion = false,
    // Both assigned in the initialiser list rather than as initialising
    // formals: these are named parameters, and Dart does not allow a named
    // parameter to start with an underscore, so `this._field` is not available
    // here. The lint asks for something the language refuses.
    // ignore: prefer_initializing_formals
  }) : _cellIsFilled = cellIsFilled,
       // ignore: prefer_initializing_formals
       _reduceMotion = reduceMotion {
    _ticker = vsync.createTicker(_tick);
  }

  final bool Function(int cell) _cellIsFilled;

  /// Named rather than called on the platform directly, so the vocabulary in
  /// `docs/DESIGN.md` §5 stays the only way a haptic happens.
  final void Function(DokuHaptic haptic)? fireHaptic;

  late final Ticker _ticker;
  final ParticlePool _pool = ParticlePool();

  bool _reduceMotion;

  /// Whether the player has asked for less.
  ///
  /// Either switch alone is enough, and turning it on mid-effect ends what is
  /// running rather than letting it finish — a player who asked for less asked
  /// for less now.
  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    if (value) _settleEverything();
  }

  List<ScheduledEffect> _steps = const <ScheduledEffect>[];
  Duration _elapsed = Duration.zero;
  Duration _lastTick = Duration.zero;

  /// Which step has already fired its haptic. One per step, never one per
  /// **cascade** and never one per frame.
  final Set<int> _hapticsFired = <int>{};

  /// When each **unit** completed, for the fresh hold.
  ///
  /// Keyed by **unit** rather than by cell so a **unit** re-completing restarts
  /// its own hold and leaves its neighbours' alone.
  final Map<Unit, Duration> _completedAt = <Unit, Duration>{};
  Duration _clock = Duration.zero;

  EffectFrame _frame = EffectFrame.empty;

  /// What to draw this frame.
  EffectFrame get frame => _frame;

  /// The cells of every **unit** still inside its fresh hold.
  ///
  /// The hold is a *state duration*, not an animation: two seconds of a colour
  /// that is already correct, blocking nothing and delaying nothing. That is
  /// why [DokuMotion.completionTintHold] is marked as not in-puzzle motion
  /// rather than declared a third exception to the 400ms ceiling — there is no
  /// motion here to exceed it.
  Set<int> get freshCells => <int>{
    for (final entry in _completedAt.entries)
      if (_clock - entry.value < DokuMotion.completionTintHold.duration)
        ...entry.key.cells,
  };

  /// A completion happened.
  void handle(EffectEvent event) {
    switch (event) {
      case UnitsCompleted(:final steps):
        // Each step already carries the cell the placement landed in, so the
        // event's own origin is not needed a second time here.
        _start(steps);
      case BoardCompleted(:final origin):
        _startSequence(origin);
    }
  }

  /// The board is finished. Play the four beats.
  ///
  /// Nothing waits on this. The puzzle is recorded as solved by the controller
  /// that wrote the board, on its own path, so a player who taps straight
  /// through the celebration loses none of it.
  void _startSequence(int origin) {
    if (_reduceMotion) {
      notifyListeners();
      return;
    }
    _sequenceOrigin = origin;
    _sequenceElapsed = Duration.zero;
    _sequenceHapticFired = false;
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
    notifyListeners();
  }

  int _sequenceOrigin = 0;
  Duration? _sequenceElapsed;

  /// Whether the four beats are still playing.
  ///
  /// False once the last beat ends, when the player taps through it, and
  /// always under reduce-motion — which plays no sequence. What waits for the
  /// celebration reads this rather than a timer of its own, so a skipped
  /// celebration ends for everyone at once (D-46).
  bool get isSequenceRunning => _sequenceElapsed != null;

  /// Whether the sequence's success pattern has already been felt.
  ///
  /// A flag rather than "elapsed is still zero": the first frame after a start
  /// can arrive with a zero delta, which leaves elapsed at zero for two ticks
  /// and would buzz the player twice for one finished puzzle.
  bool _sequenceHapticFired = false;

  void _start(List<ScheduledEffect> steps) {
    for (final step in steps) {
      _completedAt[step.unit] = _clock;
    }

    if (_reduceMotion) {
      // Straight to the end state. The tint and the **corner mark** say
      // everything the animation would have, so nothing is lost — and the fresh
      // hold is skipped too, because a flash the player asked not to see is
      // still a flash.
      _completedAt.clear();
      notifyListeners();
      return;
    }

    _steps = steps;
    _elapsed = Duration.zero;
    _hapticsFired.clear();
    _pool.clear();
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
    notifyListeners();
  }

  /// The player tapped. End whatever is running and let the tap be the tap.
  ///
  /// Every effect is skippable (D-46). The state the effect was announcing
  /// survives — the **completion tint** and the **corner mark** are derived
  /// from the board, so skipping the celebration cannot skip the record.
  void skip() {
    // The fresh hold counts as outstanding, not just the moving parts. A tap
    // during the hold settles the tint to its record colour there and then:
    // the player has moved on, and holding the celebration over a board they
    // are already playing is the effect outstaying its welcome.
    if (_steps.isEmpty && _frame.isEmpty && _completedAt.isEmpty) return;
    _settleEverything();
  }

  void _settleEverything() {
    _steps = const <ScheduledEffect>[];
    _hapticsFired.clear();
    _pool.clear();
    _completedAt.clear();
    _sequenceElapsed = null;
    _frame = EffectFrame.empty;
    _ticker.stop();
    notifyListeners();
  }

  void _tick(Duration since) {
    final delta = since - _lastTick;
    _lastTick = since;
    _elapsed += delta;
    _clock += delta;
    _pool.advance(delta);

    final active = <ActiveEffect>[];
    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      if (_elapsed < step.startsAt) continue;
      if (_elapsed > step.endsAt) continue;

      // One haptic per step, fired as the step begins — which is what makes a
      // three-step **cascade** feel like three rewards rather than one long
      // one.
      if (_hapticsFired.add(i)) {
        final haptic = step.haptic;
        if (haptic != null) fireHaptic?.call(haptic);
        _emitFor(step);
      }

      final into = _elapsed - step.startsAt;
      active.add(
        ActiveEffect(
          unit: step.unit,
          origin: step.origin,
          progress: (into.inMicroseconds / step.duration.inMicroseconds).clamp(
            0.0,
            1.0,
          ),
        ),
      );
    }

    SequenceFrame? sequence;
    final sequenceElapsed = _sequenceElapsed;
    if (sequenceElapsed != null) {
      // The success pattern, once, as the sequence opens.
      if (!_sequenceHapticFired) {
        _sequenceHapticFired = true;
        final haptic = DokuMotion.puzzleComplete.haptic;
        if (haptic != null) fireHaptic?.call(haptic);
      }
      final advanced = sequenceElapsed + delta;
      if (advanced >= CompletionSequence.duration) {
        _sequenceElapsed = null;
      } else {
        _sequenceElapsed = advanced;
        sequence = SequenceFrame(origin: _sequenceOrigin, elapsed: advanced);
      }
    }

    final particles = _pool.alive.toList(growable: false);
    _frame = EffectFrame(
      effects: active,
      particles: particles,
      sequence: sequence,
    );

    final done =
        _steps.isEmpty || _elapsed > CompletionSchedule.totalOf(_steps);
    if (done && particles.isEmpty) {
      _steps = const <ScheduledEffect>[];
      // Kept running only while a fresh hold or the sequence is outstanding,
      // so the frame that settles the tint still arrives.
      if (freshCells.isEmpty && _sequenceElapsed == null) _ticker.stop();
    }
    notifyListeners();
  }

  /// Throw up this step's share of the dust.
  ///
  /// Placed deterministically from the cell index rather than at random: a
  /// golden has to be reproducible, and a puff's exact position is not what
  /// anyone is looking at.
  void _emitFor(ScheduledEffect step) {
    final budget = ParticlePool.budgetFor(step.unit.kind);
    final cells = step.unit.cells;
    for (var i = 0; i < budget; i++) {
      final cell = cells[i % cells.length];
      _pool.emit(
        Particle(
          cell: cell,
          offset: (_scatter(cell * 7 + i), _scatter(cell * 13 + i * 3)),
          age: Duration.zero,
          lifetime: step.duration,
        ),
        cellIsFilled: _cellIsFilled,
      );
    }
  }

  /// A stable 0.2..0.8 from an integer. Not random, just scattered.
  static double _scatter(int seed) => 0.2 + ((seed * 37) % 60) / 100;

  @override
  void dispose() {
    // Stopped before it is disposed. A ticker left running outlives the screen
    // that owned it — harmless on a phone, and an immediate failure in a
    // widget test, which is the useful place to find out.
    _ticker
      ..stop()
      ..dispose();
    super.dispose();
  }
}

/// Subscribes [controller] to [events] for as long as it is alive.
StreamSubscription<EffectEvent> driveEffects(
  Stream<EffectEvent> events,
  CompletionEffectsController controller,
) => events.listen(controller.handle);
