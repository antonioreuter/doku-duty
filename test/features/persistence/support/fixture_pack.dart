import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

/// A tiny pack for tests.
///
/// **Not content.** Real packs are generated and graded offline
/// (`docs/TECH_STACK.md` §4) and arrive with `add-puzzle-engine`. These grids
/// are here so storage can be exercised; nothing asserts they are solvable, and
/// nothing in this layer is entitled to an opinion about that.
const String fixturePackId = 'fixture';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

StoredPuzzle fixturePuzzle(String id, Rank rank, {int seed = 1}) =>
    StoredPuzzle(
      id: id,
      clues: _clues,
      solution: _solution,
      rank: rank,
      seed: seed,
    );

/// One puzzle at each of the six ranks (D-57).
List<StoredPuzzle> fixturePuzzles() => <StoredPuzzle>[
  for (final (index, rank) in Rank.values.indexed)
    fixturePuzzle('fixture-${rank.name}', rank, seed: index),
];

Future<void> installFixturePack(PackRepository packs, {int version = 1}) =>
    packs.installPack(
      packId: fixturePackId,
      version: version,
      puzzles: fixturePuzzles(),
    );
