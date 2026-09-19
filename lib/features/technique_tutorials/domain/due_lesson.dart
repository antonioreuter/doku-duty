import '../../puzzle_engine/domain/rank.dart';
import '../../puzzle_engine/domain/technique.dart';
import 'lesson.dart';

/// The one **lesson** to show when this puzzle is opened, or null for none.
///
/// Pure Dart, and the whole rule in one place. Null is the ordinary answer —
/// most openings teach nothing — and never an error, and never a **lesson**
/// chosen to fill the gap.
///
/// A **lesson** is due when the puzzle needs it, the player has not seen it,
/// and they have not already demonstrated the technique. That last clause is
/// why `unlocked` is here: a player who has solved a puzzle requiring an X-wing
/// does not need teaching, whatever their seen record says (D-104).
Lesson? dueLesson({
  required Rank puzzleRank,
  required Set<Technique> techniquesRequired,
  required Set<Technique> unlocked,
  required Set<String> seen,
  required Iterable<Lesson> catalogue,
}) {
  // Notes first when it is owed. It is the prerequisite for every technique
  // above Deputy rather than a peer of them, and a player taught naked pair
  // first would be taught to use a tool they have not met.
  //
  // Due at Sheriff *or harder*, not at Sheriff alone: the soft **rank** gate
  // (D-103) lets a Deputy open a Marshal puzzle, and a player who never opened
  // a Sheriff one would otherwise never be taught notes at all.
  final notesDue =
      !seen.contains(Lesson.notes.id) &&
      !puzzleRank.isEasierThan(Lesson.notesRank);
  if (notesDue) {
    return catalogue.firstWhere(
      (lesson) => lesson.id == Lesson.notes.id,
      orElse: () => Lesson.notes,
    );
  }

  Lesson? hardest;
  for (final lesson in catalogue) {
    final technique = lesson.technique;
    // The **notes lesson** is handled above; a technique lesson needs the
    // puzzle to actually require it.
    if (technique == null) continue;
    if (!techniquesRequired.contains(technique)) continue;
    if (seen.contains(lesson.id)) continue;
    if (unlocked.contains(technique)) continue;

    // At most one, and the hardest of them (D-106): it is the technique the
    // puzzle is graded on and the likeliest thing stopping the player.
    if (hardest == null ||
        lesson.introducedAt.isHarderThan(hardest.introducedAt)) {
      hardest = lesson;
    }
  }
  return hardest;
}

extension on Rank {
  bool isEasierThan(Rank other) => other.isHarderThan(this);
}
