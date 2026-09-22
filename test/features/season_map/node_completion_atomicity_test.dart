import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../persistence/support/fixture_pack.dart';

/// A **node** completion and its **solve record** are one write.
///
/// The failure this guards against has no symptom at the moment it happens. A
/// **node** marked complete over a puzzle with no **solve record** means the
/// player's **rank** never rose for a board they finished; the reverse means
/// they walked a **node** the **trail** still shows as current. Either survives
/// every restart, because both are written state.
void main() {
  late AppDatabase db;
  late SeasonRepository seasons;
  late ProgressionRepository progression;
  late PackRepository packs;

  const seasonId = SeasonOne.id;
  const puzzleId = 'fixture-sheriff';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seasons = SeasonRepository(db);
    progression = ProgressionRepository(db);
    packs = PackRepository(db);
    await installFixturePack(packs);
  });
  tearDown(() => db.close());

  test('both are written together', () async {
    await progression.record(
      puzzleId: puzzleId,
      techniquesRequired: <Technique>{Technique.nakedPair},
      timeTaken: const Duration(minutes: 3),
      attempt: Attempt.fresh,
      alsoInTransaction: () =>
          seasons.completeNode(seasonId: seasonId, position: 1),
    );

    expect(await packs.isSolved(puzzleId), isTrue);
    final progress = await seasons.progressFor(seasonId);
    expect(progress.stateOf(1), NodeState.completed);
    expect(progress.currentPosition, 2);
  });

  test('a failure part way leaves neither, and the node stays current', () async {
    await expectLater(
      progression.record(
        // No such puzzle, so `record` throws after the node write has run.
        puzzleId: 'no-such-puzzle',
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
        alsoInTransaction: () =>
            seasons.completeNode(seasonId: seasonId, position: 1),
      ),
      throwsStateError,
    );

    // The node write happened first and was rolled back with the rest. Without
    // the shared transaction this is the case that leaves a completed **node**
    // standing over a puzzle nothing recorded.
    final progress = await seasons.progressFor(seasonId);
    expect(progress.stateOf(1), NodeState.current);
    expect(progress.isEmpty, isTrue);
  });

  test('a failure in the node write leaves no solve record', () async {
    await expectLater(
      progression.record(
        puzzleId: puzzleId,
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
        // Position 0 violates the CHECK constraint on the column.
        alsoInTransaction: () =>
            seasons.completeNode(seasonId: seasonId, position: 0),
      ),
      throwsA(anything),
    );

    expect(await packs.isSolved(puzzleId), isFalse);
    expect((await seasons.progressFor(seasonId)).isEmpty, isTrue);
  });

  test('a replayed board still completes the node it was opened from', () async {
    // The two are different facts. A puzzle carries a **solve record** once
    // ever; a **node** is completed by the player finishing it. Returning early
    // on the already-solved guard would leave this **node** current forever.
    await progression.record(
      puzzleId: puzzleId,
      techniquesRequired: <Technique>{Technique.nakedPair},
      timeTaken: const Duration(minutes: 3),
      attempt: Attempt.fresh,
    );
    expect(await packs.isSolved(puzzleId), isTrue);

    await progression.record(
      puzzleId: puzzleId,
      techniquesRequired: <Technique>{Technique.nakedPair},
      timeTaken: const Duration(minutes: 3),
      attempt: Attempt.fresh,
      alsoInTransaction: () =>
          seasons.completeNode(seasonId: seasonId, position: 1),
    );

    final progress = await seasons.progressFor(seasonId);
    expect(progress.stateOf(1), NodeState.completed);
  });

  test('completing a node twice does not raise the counters twice', () async {
    Future<void> finish() => progression.record(
      puzzleId: puzzleId,
      techniquesRequired: <Technique>{Technique.nakedPair},
      timeTaken: const Duration(minutes: 3),
      attempt: Attempt.fresh,
      alsoInTransaction: () =>
          seasons.completeNode(seasonId: seasonId, position: 1),
    );

    await finish();
    await finish();

    final progress = await seasons.progressFor(seasonId);
    expect(progress.completedCount, 1);
    expect(await progression.playerRank(), Rank.sheriff);
  });

  test('the app killed right after completion relaunches walked on', () async {
    await progression.record(
      puzzleId: puzzleId,
      techniquesRequired: <Technique>{Technique.nakedPair},
      timeTaken: const Duration(minutes: 3),
      attempt: Attempt.fresh,
      alsoInTransaction: () =>
          seasons.completeNode(seasonId: seasonId, position: 1),
    );

    // Relaunch reads the rows and nothing else — there is no in-memory state to
    // lose, which is what makes the kill case boring (constraint 9).
    final afterRelaunch = SeasonRepository(db);
    final progress = await afterRelaunch.progressFor(seasonId);
    expect(progress.stateOf(1), NodeState.completed);
    expect(progress.currentPosition, 2);
  });
}
