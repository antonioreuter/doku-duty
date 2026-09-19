import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../grid_input/application/grid_providers.dart';
import '../../persistence/application/database_provider.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../../puzzle_engine/domain/technique.dart';
import '../data/lesson_repository.dart';
import '../domain/due_lesson.dart';
import '../domain/lesson.dart';
import '../domain/lesson_catalogue.dart';

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(ref.watch(appDatabaseProvider)),
);

/// Every **lesson** the player has been shown.
final seenLessonsProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(lessonRepositoryProvider).seen(),
);

/// What a puzzle needs to know before deciding whether to teach something.
final class LessonRequest {
  const LessonRequest({required this.rank, required this.techniquesRequired});

  final Rank rank;
  final Set<Technique> techniquesRequired;

  @override
  bool operator ==(Object other) =>
      other is LessonRequest &&
      other.rank == rank &&
      other.techniquesRequired.length == techniquesRequired.length &&
      other.techniquesRequired.containsAll(techniquesRequired);

  @override
  int get hashCode =>
      Object.hash(rank, Object.hashAllUnordered(techniquesRequired));
}

/// The **lesson** to show before this puzzle, or null for none.
///
/// Null is the ordinary answer — most openings teach nothing. The technique set
/// comes from the grade the open already took (`add-rank-progression`), so no
/// solver run is added here and nothing is computed on a tap.
final dueLessonProvider = FutureProvider.family<Lesson?, LessonRequest>((
  ref,
  request,
) async {
  final seen = await ref.watch(seenLessonsProvider.future);
  final unlocked = await ref
      .watch(progressionRepositoryProvider)
      .unlockedTechniques();

  return dueLesson(
    puzzleRank: request.rank,
    techniquesRequired: request.techniquesRequired,
    unlocked: unlocked,
    seen: seen,
    catalogue: lessonCatalogue,
  );
});
