import 'dart:convert';

import 'cage.dart';
import 'grid.dart';
import 'rank.dart';

/// One puzzle as a **pack** carries it (D-32).
///
/// The solution, the **rank**, and the seed are all stored rather than derived.
/// Recomputing any of them at load time would be a second answer to what the
/// puzzle is, and the grade is the one a player is told — it has to be the one
/// that was checked, not one this device worked out again.
final class PackPuzzle {
  const PackPuzzle({
    required this.id,
    required this.clues,
    required this.solution,
    required this.rank,
    required this.seed,
    this.cages,
  });

  final String id;

  /// The givens, eighty-one characters, `.` for empty.
  final String clues;

  /// The one solution. Every puzzle has exactly one (D-08).
  final String solution;

  /// The hardest technique the puzzle requires, as a **rank** (D-07).
  final Rank rank;

  /// The value that reproduces this puzzle from the generator — a **killer**
  /// generator when [cages] is set.
  final int seed;

  /// The **cage**s of a **killer** puzzle, or null for a classic one (D-127).
  final CageSet? cages;

  bool get isKiller => cages != null;

  @override
  bool operator ==(Object other) =>
      other is PackPuzzle &&
      other.id == id &&
      other.clues == clues &&
      other.solution == solution &&
      other.rank == rank &&
      other.seed == seed &&
      other.cages == cages;

  @override
  int get hashCode => Object.hash(id, clues, solution, rank, seed, cages);
}

/// A versioned, immutable shipment of pre-generated puzzles.
///
/// One reader and one writer, in this file. Seasons arrive on a six-week cadence
/// (D-18), so a second place that decided what a **pack** is on disk would
/// become a second answer the first time the two drifted.
///
/// **Name collision.** Drift generates a `Pack` row class for the persistence
/// layer's `Packs` table. A file importing both needs
/// `import '.../app_database.dart' hide Pack;` — this type is the **pack** the
/// glossary names, and drift's is a two-column row that happens to share the
/// word.
final class Pack {
  const Pack({
    required this.packId,
    required this.version,
    required this.puzzles,
  });

  final String packId;

  /// Immutable once shipped: `add-persistence-layer` refuses to install a
  /// version at or below the stored one, so a changed pack needs a new number.
  final int version;

  final List<PackPuzzle> puzzles;

  /// Read a **pack** from its file form.
  ///
  /// Every failure is a value. A corrupt or unreadable pack is something an
  /// installer has to cope with, not an exception for it to catch.
  static PackParseResult parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      return InvalidPack(
        problem: PackProblem.notJson,
        description: 'not JSON: ${error.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return InvalidPack(
        problem: PackProblem.notAnObject,
        description: 'a pack is a JSON object, not a ${decoded.runtimeType}',
      );
    }

    for (final field in const <String>['packId', 'version', 'puzzles']) {
      if (!decoded.containsKey(field)) {
        return InvalidPack(
          problem: PackProblem.missingField,
          description: "the pack has no '$field'",
        );
      }
    }

    final packId = decoded['packId'];
    final version = decoded['version'];
    final rows = decoded['puzzles'];
    if (packId is! String) {
      return _wrongType('packId', 'a string', packId);
    }
    if (version is! int) {
      return _wrongType('version', 'an integer', version);
    }
    if (rows is! List<dynamic>) {
      return _wrongType('puzzles', 'a list', rows);
    }
    if (rows.isEmpty) {
      return const InvalidPack(
        problem: PackProblem.emptyPack,
        description: 'a pack with no puzzles is not content, it is a mistake',
      );
    }

    final puzzles = <PackPuzzle>[];
    final seen = <String>{};
    for (final row in rows) {
      final parsed = _parsePuzzle(row);
      if (parsed is InvalidPack) return parsed;
      final puzzle = (parsed as ParsedPuzzle).puzzle;
      if (!seen.add(puzzle.id)) {
        return InvalidPack(
          problem: PackProblem.duplicateId,
          description: "two puzzles share the id '${puzzle.id}'",
        );
      }
      puzzles.add(puzzle);
    }

    return ParsedPack(Pack(packId: packId, version: version, puzzles: puzzles));
  }

  static PackParseResult _parsePuzzle(Object? row) {
    if (row is! Map<String, dynamic>) {
      return _wrongType('a puzzle', 'an object', row);
    }
    for (final field in const <String>[
      'id',
      'clues',
      'solution',
      'rank',
      'seed',
    ]) {
      if (!row.containsKey(field)) {
        return InvalidPack(
          problem: PackProblem.missingField,
          description: "a puzzle has no '$field'",
        );
      }
    }

    final id = row['id'];
    final clues = row['clues'];
    final solution = row['solution'];
    final rank = row['rank'];
    final seed = row['seed'];
    if (id is! String) return _wrongType('id', 'a string', id);
    if (clues is! String) return _wrongType("$id's clues", 'a string', clues);
    if (solution is! String) {
      return _wrongType("$id's solution", 'a string', solution);
    }
    if (rank is! String) return _wrongType("$id's rank", 'a string', rank);
    if (seed is! int) return _wrongType("$id's seed", 'an integer', seed);

    for (final (name, grid) in <(String, String)>[
      ('clues', clues),
      ('solution', solution),
    ]) {
      final result = Grid.parse(grid);
      if (result is InvalidGrid) {
        return InvalidPack(
          problem: PackProblem.invalidGrid,
          description: "$id's $name is not a grid: ${result.description}",
        );
      }
    }

    final named = Rank.values.where((value) => value.name == rank);
    if (named.isEmpty) {
      return InvalidPack(
        problem: PackProblem.unknownRank,
        description: "$id has rank '$rank', which is not one of the six",
      );
    }

    // Optional: its absence is what a classic puzzle is. Present, it must be a
    // valid set the stored solution satisfies — a **cage** that disagrees with
    // the solution is a board nobody can finish.
    CageSet? cages;
    if (row.containsKey('cages')) {
      final read = CageSet.fromJson(row['cages']);
      switch (read) {
        case InvalidCageSet(:final description):
          return InvalidPack(
            problem: PackProblem.invalidCages,
            description: "$id's cages are not a killer board: $description",
          );
        case ValidCageSet(cages: final valid):
          if (!valid.isSatisfiedBy((Grid.parse(solution) as ValidGrid).grid)) {
            return InvalidPack(
              problem: PackProblem.invalidCages,
              description: "$id's solution does not satisfy its cages",
            );
          }
          cages = valid;
      }
    }

    return ParsedPuzzle(
      PackPuzzle(
        id: id,
        clues: clues,
        solution: solution,
        rank: named.single,
        seed: seed,
        cages: cages,
      ),
    );
  }

  static InvalidPack _wrongType(String field, String wanted, Object? found) =>
      InvalidPack(
        problem: PackProblem.wrongType,
        description: '$field must be $wanted, not ${found.runtimeType}',
      );

  /// The file form. Only the fields this reader knows survive a re-encode, so a
  /// pack written here is exactly what this version of the format means.
  String encode() =>
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'packId': packId,
        'version': version,
        'puzzles': <Map<String, Object>>[
          for (final puzzle in puzzles)
            <String, Object>{
              'id': puzzle.id,
              'clues': puzzle.clues,
              'solution': puzzle.solution,
              'rank': puzzle.rank.name,
              'seed': puzzle.seed,
              if (puzzle.cages case final cages?) 'cages': cages.toJson(),
            },
        ],
      });

  @override
  bool operator ==(Object other) {
    if (other is! Pack) return false;
    if (other.packId != packId || other.version != version) return false;
    if (other.puzzles.length != puzzles.length) return false;
    for (var i = 0; i < puzzles.length; i++) {
      if (other.puzzles[i] != puzzles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(packId, version, Object.hashAll(puzzles));
}

/// Why a file could not be read as a **pack**.
enum PackProblem {
  notJson,
  notAnObject,
  missingField,
  wrongType,
  invalidGrid,
  unknownRank,
  duplicateId,
  emptyPack,

  /// A **killer** puzzle's **cage**s are malformed, or its solution does not
  /// satisfy them.
  invalidCages,

  /// The file could not be read at all — most often an asset that never
  /// reached the binary.
  unreadable,
}

/// The outcome of reading a **pack** file.
sealed class PackParseResult {
  const PackParseResult();
}

final class ParsedPack extends PackParseResult {
  const ParsedPack(this.pack);

  final Pack pack;
}

/// Internal to parsing: one puzzle read successfully.
final class ParsedPuzzle extends PackParseResult {
  const ParsedPuzzle(this.puzzle);

  final PackPuzzle puzzle;
}

final class InvalidPack extends PackParseResult {
  const InvalidPack({required this.problem, required this.description});

  final PackProblem problem;

  /// Plain description naming what was wrong and, where it applies, which
  /// puzzle. For a log or a developer tool, not player-facing copy.
  final String description;
}
