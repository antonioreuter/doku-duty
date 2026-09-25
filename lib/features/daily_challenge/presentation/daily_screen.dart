import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../platform_shell/routing/app_router.dart';
import '../../grid_input/application/puzzle_origin.dart';
import '../application/daily_providers.dart';
import '../application/daily_service.dart';
import '../domain/daily_date.dart';
import 'calendar_grid.dart';

/// The **daily challenge**: today's board, the **streak**, and the month.
///
/// **Nothing here is read before the first frame.** The shell keeps all three
/// destinations built at once so switching back does not lose a scroll
/// position, which means this screen builds on launch whether or not the player
/// ever taps Daily — and its state all lives in the database. Reading it
/// eagerly would open the database on the path to the first frame, which
/// `lazy_open_test.dart` forbids and which costs cold-start time every launch
/// for a screen most sessions never visit. The **trail** solves it the same
/// way, for the same reason.
class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen>
    with WidgetsBindingObserver {
  bool _pastFirstFrame = false;

  /// The day the screen last built for, so a rollover can be noticed.
  DailyDate? _shownFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pastFirstFrame = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-read when the app comes back, if the day has moved.
  ///
  /// **A real device found this.** The status is a cached read, so a phone
  /// left open across midnight — or carried into another timezone — came back
  /// showing yesterday: yesterday's board, at yesterday's **rank**, with
  /// today's square still blank. Changing the device's timezone on the
  /// emulator reproduced it exactly, which is the check
  /// `openspec/changes/.../tasks.md` asked for and the reason it asked on
  /// hardware rather than in a widget test, where rebuilding the tree hides it.
  ///
  /// Guarded on the date rather than firing on every resume: re-reading the
  /// database each time the player switches apps would be a cost with nothing
  /// to show for it on the overwhelming majority of resumes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final today = ref.read(dailyClockProvider).today().date;
    if (_shownFor != null && _shownFor != today) {
      ref.invalidate(dailyStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _pastFirstFrame
        ? ref.watch(dailyStatusProvider)
        : const AsyncValue<DailyStatus>.loading();

    _shownFor = status.value?.date ?? _shownFor;

    return Scaffold(
      // No `AppBar` here, so nothing is keeping the title out from under the
      // status bar — on the emulator it drew straight through the clock. The
      // **trail** gets this for free from its own app bar; this screen has to
      // ask.
      body: SafeArea(
        child: PaperGrain(
          child: status.when(
            // Nothing is announced while it loads. An empty moment is not a
            // state worth naming, and a spinner over a habit screen reads as a
            // failure that has not finished happening yet.
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (data) => _Daily(status: data),
          ),
        ),
      ),
    );
  }
}

class _Daily extends ConsumerWidget {
  const _Daily({required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: const ValueKey<String>('daily-screen'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        Text('Daily challenge', style: TypeRole.screenTitle.style),
        const SizedBox(height: 8),
        _StreakLine(status: status),
        const SizedBox(height: 16),
        _TodayCard(status: status),
        const SizedBox(height: 24),
        CalendarGrid(
          month: status.date,
          calendar: status.calendar,
          today: status.date,
        ),
      ],
    );
  }
}

class _StreakLine extends StatelessWidget {
  const _StreakLine({required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    final streak = status.streak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          // Zero is stated plainly rather than hidden. A player with no
          // **streak** has not failed at anything — they have not started one,
          // and those read very differently.
          streak == 0
              ? 'No streak yet'
              : '$streak day${streak == 1 ? '' : 's'} in a row',
          key: const ValueKey<String>('daily-streak'),
          style: TypeRole.body.style,
        ),
        const SizedBox(height: 2),
        Text(
          status.freezeIsHeld
              ? 'Streak freeze ready'
              : 'Streak freeze used — back in a few days',
          key: const ValueKey<String>('daily-freeze'),
          style: TypeRole.label.style.copyWith(color: DokuColours.inkSoft),
        ),
      ],
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = status.board;

    if (board == null) {
      // No **pack** at all. An absence, never a wall (constraint 1).
      return Text(
        'No puzzle installed yet',
        key: const ValueKey<String>('daily-absent'),
        style: TypeRole.body.style,
      );
    }

    final done = status.isCompleted;

    return Semantics(
      button: true,
      label: done
          ? 'Today, ${board.rank.name}, completed'
          : 'Play today, ${board.rank.name}',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey<String>('daily-open'),
        onTap: () {
          // Opened as the day this card shows, not the day it is solved on: a
          // daily started before midnight credits the day the player opened
          // (D-132). Replacing the origin also means a **node** opened earlier
          // is not completed by this board (D-111).
          ref
              .read(puzzleOriginProvider.notifier)
              .openDaily(
                DatedDay(date: status.date, isVerified: status.isVerified),
              );
          Routes.goPuzzle(context, board.id);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: done
                ? PaletteToken.cactusGreen.paleColour
                : PaletteToken.bone.colour,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DokuColours.duskInk, width: 3),
          ),
          child: Row(
            children: <Widget>[
              // The state twice over: the glyph as well as the fill
              // (constraint 5).
              Icon(
                done ? Icons.check : Icons.today,
                color: DokuColours.duskInk,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      done ? 'Completed today' : 'Play today',
                      style: TypeRole.body.style,
                    ),
                    Text(
                      // The **rank** is stated because it is not the player's
                      // own and they cannot infer it — every player gets this
                      // board at this rank, whatever ladder they are on
                      // (D-116).
                      '${board.rank.name[0].toUpperCase()}'
                      '${board.rank.name.substring(1)} rank',
                      style: TypeRole.label.style.copyWith(
                        color: DokuColours.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
