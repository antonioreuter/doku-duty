import 'season.dart';

/// What a **node** is showing.
///
/// Three states and no fourth. A **node** is behind the player, under them, or
/// ahead of them — there is no "available but not current", because the
/// **trail** is walked in order and nothing opens out of turn.
enum NodeState {
  completed,
  current,

  /// Ahead of where the player has walked.
  ///
  /// **The name is the requirement.** D-108 records why: a **node** ahead is
  /// not something earned and withheld, it is somewhere not yet gone, and
  /// "locked" describes the game keeping something from the player when it is
  /// only describing what they have done so far. A test asserts no
  /// player-facing string says otherwise.
  notYetReached;

  /// What a screen reader says, and what the label reads.
  ///
  /// Here rather than in the widget so there is one place the words live and
  /// one place the test checks (constraint 5 — the state must be readable
  /// without colour, and these are what carry it).
  String get label => switch (this) {
    NodeState.completed => 'Completed',
    NodeState.current => 'Current',
    NodeState.notYetReached => 'Not yet reached',
  };
}

/// Where the player stands on a **season**'s **trail**.
///
/// Immutable, and the only operation is [completing]. **There is deliberately
/// no way to uncomplete a node** — no decay, no expiry, no reset, and no
/// `DateTime` anywhere in the class. D-20 and constraint 1 are enforced by the
/// rule having no input that could withdraw progress, rather than by every
/// caller remembering not to.
class TrailProgress {
  const TrailProgress({required this.completed});

  /// A **season** not yet started: **node** 1 is current, and that is a
  /// starting position rather than an absence.
  static const TrailProgress fresh = TrailProgress(completed: <int>{});

  /// The 1-based positions completed, in no particular order.
  final Set<int> completed;

  bool get isEmpty => completed.isEmpty;

  int get completedCount => completed.length;

  int get total => SeasonDefinition.nodeCount;

  bool get isSeasonComplete => completed.length >= total;

  /// The **node** the player is at: the first not yet completed.
  ///
  /// Null once every **node** is done — nowhere further to walk, which is an
  /// ending rather than an error.
  ///
  /// Derived from the completed set rather than stored beside it, for D-104's
  /// reason: two answers to one question can only disagree, and a stored
  /// "current" that drifted from the completions is a player standing somewhere
  /// they have already been.
  int? get currentPosition {
    for (var position = 1; position <= total; position++) {
      if (!completed.contains(position)) return position;
    }
    return null;
  }

  NodeState stateOf(int position) {
    if (completed.contains(position)) return NodeState.completed;
    return position == currentPosition
        ? NodeState.current
        : NodeState.notYetReached;
  }

  /// Whether the player may open this **node** now.
  ///
  /// The **current node** and anything already completed. A completed **node**
  /// reopens freely and completing it again changes nothing — replaying is not
  /// a thing the game has an opinion about.
  bool isOpenable(int position) {
    if (position < 1 || position > total) return false;
    return stateOf(position) != NodeState.notYetReached;
  }

  /// The player finished [position].
  ///
  /// Completing a **node** already completed returns an equal progress rather
  /// than advancing — the same idempotence the **solve record** has, and for
  /// the same reason: a second completion of one board must not be worth a
  /// second **node**.
  TrailProgress completing(int position) {
    if (position < 1 || position > total) return this;
    if (completed.contains(position)) return this;
    return TrailProgress(completed: <int>{...completed, position});
  }
}
