import '../../persistence/data/pack_repository.dart';
import '../data/pack_source.dart';
import '../domain/pack.dart';

/// What one install attempt did.
enum PackInstallOutcome {
  /// The **pack** was written.
  installed,

  /// This version, or a newer one, was already stored. Nothing was rewritten.
  alreadyInstalled,

  /// The **pack** could not be read. Nothing was written.
  unreadable,

  /// The write itself failed. Nothing was left half-installed.
  failed,
}

/// Puts the bundled **pack** into the database.
///
/// **Runs after the first frame, never before it.** Nothing a player does waits
/// on it, and the shell's cold-start budget has no slack for three hundred
/// inserts. Every outcome is a value: a missing or corrupt **pack** is reported
/// and swallowed, because there is no useful thing to show a player about it and
/// this product has no failure states (D-03).
final class PackInstaller {
  const PackInstaller({
    required this.source,
    required this.packs,
    required this.report,
  });

  final PackSource source;
  final PackRepository packs;

  /// Where an unusable **pack** goes. Never to the player: this product has no
  /// failure states (D-03), and a missing asset is a developer's problem.
  final void Function(Object error, StackTrace stack) report;

  Future<PackInstallOutcome> install() async {
    final result = await source.read();
    if (result is! ParsedPack) {
      final invalid = result as InvalidPack;
      report(
        StateError('bundled pack unusable: ${invalid.description}'),
        StackTrace.current,
      );
      return PackInstallOutcome.unreadable;
    }

    final pack = result.pack;
    final stored = await packs.packVersion(pack.packId);
    if (stored != null && stored >= pack.version) {
      return PackInstallOutcome.alreadyInstalled;
    }

    try {
      // One transaction, so a kill part-way leaves the version unrecorded and
      // the next launch installs it again rather than trusting a half-written
      // pack.
      await packs.installPack(
        packId: pack.packId,
        version: pack.version,
        puzzles: <StoredPuzzle>[
          for (final puzzle in pack.puzzles)
            StoredPuzzle(
              id: puzzle.id,
              clues: puzzle.clues,
              solution: puzzle.solution,
              rank: puzzle.rank,
              seed: puzzle.seed,
            ),
        ],
      );
    } on Object catch (error, stack) {
      report(error, stack);
      return PackInstallOutcome.failed;
    }
    return PackInstallOutcome.installed;
  }
}
