import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../daily_challenge/domain/daily_date.dart';

/// Where the board on screen was opened from, which decides what solving it
/// completes.
///
/// **One value, not a flag per place.** Before `wire-completion-events` the
/// **trail** had a flag and the **daily challenge** had none; adding a second
/// flag beside the first would leave every screen responsible for clearing the
/// other's, and a daily marker left standing would credit a later **free play**
/// solve to the **calendar**. Opening a board from anywhere replaces the whole
/// value, so no origin can outlive the board it described.
///
/// A provider rather than a route parameter because the thing that needs it is
/// the board sink, which is global and has no route.
sealed class PuzzleOrigin {
  const PuzzleOrigin();
}

/// Opened from a **node** on the **trail**: solving it completes that **node**.
final class TrailOrigin extends PuzzleOrigin {
  const TrailOrigin(this.position);

  final int position;

  @override
  bool operator ==(Object other) =>
      other is TrailOrigin && other.position == position;

  @override
  int get hashCode => position.hashCode;
}

/// Opened as the **daily challenge**: solving it marks [day] on the
/// **calendar**.
///
/// The day is captured when the board is opened, not read when it is solved,
/// so a daily started before midnight and finished after it credits the day
/// the player opened (D-132).
final class DailyOrigin extends PuzzleOrigin {
  const DailyOrigin(this.day);

  final DatedDay day;

  @override
  bool operator ==(Object other) =>
      other is DailyOrigin &&
      other.day.date == day.date &&
      other.day.isVerified == day.isVerified;

  @override
  int get hashCode => Object.hash(day.date, day.isVerified);
}

/// Opened from **free play**: solving it completes no **node** and no day
/// (D-111).
final class FreePlayOrigin extends PuzzleOrigin {
  const FreePlayOrigin();

  @override
  bool operator ==(Object other) => other is FreePlayOrigin;

  @override
  int get hashCode => 0;
}

class PuzzleOriginNotifier extends Notifier<PuzzleOrigin> {
  @override
  PuzzleOrigin build() => const FreePlayOrigin();

  void openNode(int position) => state = TrailOrigin(position);

  void openDaily(DatedDay day) => state = DailyOrigin(day);

  void openFreePlay() => state = const FreePlayOrigin();
}

final puzzleOriginProvider =
    NotifierProvider<PuzzleOriginNotifier, PuzzleOrigin>(
      PuzzleOriginNotifier.new,
    );
