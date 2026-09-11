// Generates a shipped pack. Run by a developer, never on a device (D-32,
// docs/TECH_STACK.md §4).
//
//   dart run tool/generate_pack.dart --seed 20260909 --out assets/packs/frontier-1.json
//
// Every puzzle it writes was verified unique by the engine's exhaustive search
// and graded by the engine's grader, so the rank on the row is what the grader
// said about that grid — never what this tool was asked for.
import 'dart:io';

import 'package:doku_duty/features/puzzle_engine/domain/generator.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

/// The split the first pack ships with: weighted to where players spend time
/// rather than spread evenly across six ranks.
const Map<Rank, int> defaultSplit = <Rank, int>{
  Rank.greenhorn: 70,
  Rank.deputy: 70,
  Rank.sheriff: 60,
  Rank.marshal: 50,
  Rank.ranger: 35,
  Rank.legend: 20,
};

void main(List<String> arguments) {
  final options = _parse(arguments);
  final wanted = <Rank, int>{
    for (final entry in defaultSplit.entries)
      entry.key: options.counts[entry.key] ?? entry.value,
  };

  stdout.writeln(
    'Generating ${wanted.values.reduce((a, b) => a + b)} puzzles '
    'from seed ${options.seed}, at most ${options.maxClues} clues each.',
  );

  final stopwatch = Stopwatch()..start();
  var lastReported = 0;
  final report = const PuzzleGenerator().generate(
    wanted: wanted,
    firstGridSeed: options.seed,
    maxGridSeeds: options.maxGridSeeds,
    maxClues: options.maxClues,
    onGridSeed: (progress) {
      if (progress.gridSeedsTried - lastReported < 250) return;
      lastReported = progress.gridSeedsTried;
      stdout.writeln(
        '  ${progress.gridSeedsTried} grids: '
        '${_counts(progress.found)}',
      );
    },
  );
  stopwatch.stop();

  stdout.writeln('');
  stdout.writeln('Grid seeds tried:      ${report.gridSeedsTried}');
  stdout.writeln('Candidates considered: ${report.candidatesConsidered}');
  stdout.writeln('Discarded:             ${report.discarded}');
  stdout.writeln('Kept:                  ${report.puzzles.length}');
  stdout.writeln('Found:                 ${_counts(report.found)}');
  stdout.writeln('Elapsed:               ${stopwatch.elapsed}');

  if (!report.complete) {
    stdout.writeln('');
    stdout.writeln(
      'SHORT by ${_counts(report.shortfall)} — '
      'raise --max-grid-seeds or lower the split.',
    );
    exitCode = 1;
    return;
  }

  // Ordered by rank, then by seed: a diff of a regenerated pack then reads as
  // content moving rather than as the whole file churning.
  final ordered = report.puzzles.toList()
    ..sort((a, b) {
      final byRank = a.rank.index.compareTo(b.rank.index);
      return byRank != 0 ? byRank : a.seed.compareTo(b.seed);
    });

  final pack = Pack(
    packId: options.packId,
    version: options.version,
    puzzles: <PackPuzzle>[
      for (final puzzle in ordered)
        PackPuzzle(
          id: 'q${puzzle.seed}',
          clues: puzzle.clues.toStorageString(),
          solution: puzzle.solution.toStorageString(),
          rank: puzzle.rank,
          seed: puzzle.seed,
        ),
    ],
  );

  final file = File(options.out)..createSync(recursive: true);
  file.writeAsStringSync('${pack.encode()}\n');
  stdout.writeln('');
  stdout.writeln(
    'Wrote ${options.out} '
    '(${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)',
  );
}

String _counts(Map<Rank, int> counts) => <String>[
  for (final rank in Rank.values)
    if ((counts[rank] ?? 0) > 0) '${rank.name}=${counts[rank]}',
].join(' ');

final class _Options {
  const _Options({
    required this.seed,
    required this.out,
    required this.packId,
    required this.version,
    required this.maxClues,
    required this.maxGridSeeds,
    required this.counts,
  });

  final int seed;
  final String out;
  final String packId;
  final int version;
  final int maxClues;
  final int maxGridSeeds;
  final Map<Rank, int> counts;
}

_Options _parse(List<String> arguments) {
  var seed = 20260909;
  var out = 'assets/packs/frontier-1.json';
  var packId = 'frontier-1';
  var version = 1;
  var maxClues = PuzzleGenerator.defaultMaxClues;
  var maxGridSeeds = 20000;
  final counts = <Rank, int>{};

  for (var i = 0; i < arguments.length; i++) {
    final name = arguments[i];
    String next() {
      if (i + 1 >= arguments.length) {
        stderr.writeln('$name needs a value');
        exit(2);
      }
      return arguments[++i];
    }

    switch (name) {
      case '--seed':
        seed = int.parse(next());
      case '--out':
        out = next();
      case '--pack-id':
        packId = next();
      case '--version':
        version = int.parse(next());
      case '--max-clues':
        maxClues = int.parse(next());
      case '--max-grid-seeds':
        maxGridSeeds = int.parse(next());
      case '--help':
        stdout.writeln(
          'usage: dart run tool/generate_pack.dart '
          '[--seed N] [--out PATH] [--pack-id ID] [--version N] '
          '[--max-clues N] [--max-grid-seeds N] [--<rank> N]',
        );
        exit(0);
      default:
        final rank = Rank.values.where((r) => '--${r.name}' == name);
        if (rank.isEmpty) {
          stderr.writeln('unknown option $name');
          exit(2);
        }
        counts[rank.single] = int.parse(next());
    }
  }

  return _Options(
    seed: seed,
    out: out,
    packId: packId,
    version: version,
    maxClues: maxClues,
    maxGridSeeds: maxGridSeeds,
    counts: counts,
  );
}
