import 'dart:convert';

import 'grid.dart';
import 'grid_geometry.dart';

/// A group of orthogonally connected cells on a **killer** board whose digits
/// are distinct and add up to its **cage sum** (D-127).
///
/// Not a **unit** (D-130): it holds anywhere from one to nine cells, and it is
/// satisfied by arithmetic rather than by holding every digit once.
final class Cage {
  Cage({required List<int> cells, required this.sum})
    : cells = List<int>.unmodifiable(List<int>.of(cells)..sort());

  /// The cells, ascending — which is reading order.
  final List<int> cells;

  /// The **cage sum**.
  final int sum;

  /// The cell the **cage sum** is printed in: the first in reading order
  /// (D-129).
  int get head => cells.first;

  int get size => cells.length;

  /// The smallest sum [size] distinct digits can make: 1 + 2 + … + size.
  static int leastSum(int size) => size * (size + 1) ~/ 2;

  /// The largest sum [size] distinct digits can make: 9 + 8 + … downward.
  static int greatestSum(int size) => size * (19 - size) ~/ 2;

  /// Every set of [size] distinct digits adding up to [sum], each as a nine-bit
  /// mask. Empty when there is none.
  ///
  /// A table rather than a search: the uniqueness check asks this on every
  /// placement, and there are only 512 digit sets to file.
  static List<int> combinations(int size, int sum) {
    if (size < 0 || size > 9 || sum < 0 || sum > 45) return const <int>[];
    return _combinations[size * 46 + sum];
  }

  static final List<List<int>> _combinations = () {
    final table = List<List<int>>.generate(10 * 46, (_) => <int>[]);
    for (var mask = 0; mask < 1 << 9; mask++) {
      var size = 0;
      var sum = 0;
      for (var digit = 1; digit <= 9; digit++) {
        if (mask & (1 << (digit - 1)) == 0) continue;
        size++;
        sum += digit;
      }
      table[size * 46 + sum].add(mask);
    }
    return List<List<int>>.unmodifiable(<List<int>>[
      for (final entry in table) List<int>.unmodifiable(entry),
    ]);
  }();

  @override
  bool operator ==(Object other) {
    if (other is! Cage || other.sum != sum || other.size != size) return false;
    for (var i = 0; i < size; i++) {
      if (other.cells[i] != cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(sum, Object.hashAll(cells));

  @override
  String toString() => 'Cage($sum: $cells)';
}

/// Why a list of cages could not be a **killer** board.
enum CageProblem {
  /// Stored cages that are not a list of sums and cells at all.
  malformed,

  /// A cage with no cells.
  empty,

  /// A cell index outside 0..80.
  cellOffGrid,

  /// More than nine cells, which cannot hold distinct digits.
  tooLarge,

  /// A cell no cage holds.
  cellUncovered,

  /// A cell two cages hold.
  cellInTwoCages,

  /// A cage whose cells do not all join edge to edge.
  notConnected,

  /// A sum no set of that many distinct digits can make.
  sumOutOfRange,
}

/// The outcome of building a cage set.
///
/// A malformed set is a value, never an exception, for the reason [Grid.parse]
/// gives: a corrupt pack row must not need catching.
sealed class CageSetResult {
  const CageSetResult();
}

final class ValidCageSet extends CageSetResult {
  const ValidCageSet(this.cages);

  final CageSet cages;
}

final class InvalidCageSet extends CageSetResult {
  const InvalidCageSet({
    required this.problem,
    required this.description,
    this.cell,
  });

  final CageProblem problem;

  /// Plain description for a log or a developer tool. Not player-facing copy.
  final String description;

  /// The offending cell, when there is one.
  final int? cell;
}

/// Every **cage** of one **killer** puzzle, covering the grid exactly once.
final class CageSet {
  CageSet._(this.cages, this._cageByCell);

  /// Check [cages] cover the grid exactly once, each connected and each with a
  /// sum its size can make.
  static CageSetResult build(List<Cage> cages) {
    final owner = List<Cage?>.filled(GridGeometry.cellCount, null);
    for (final cage in cages) {
      if (cage.cells.isEmpty) {
        return const InvalidCageSet(
          problem: CageProblem.empty,
          description: 'a cage has no cells',
        );
      }
      for (final cell in cage.cells) {
        if (cell < 0 || cell >= GridGeometry.cellCount) {
          return InvalidCageSet(
            problem: CageProblem.cellOffGrid,
            description: 'cell $cell is not on the grid',
            cell: cell,
          );
        }
      }
      if (cage.size > GridGeometry.maxDigit) {
        return InvalidCageSet(
          problem: CageProblem.tooLarge,
          description: '$cage has more cells than there are digits',
        );
      }
      if (cage.sum < Cage.leastSum(cage.size) ||
          cage.sum > Cage.greatestSum(cage.size)) {
        return InvalidCageSet(
          problem: CageProblem.sumOutOfRange,
          description:
              '${cage.size} distinct digits cannot add up to ${cage.sum}',
        );
      }
      if (!_isConnected(cage.cells)) {
        return InvalidCageSet(
          problem: CageProblem.notConnected,
          description: '$cage does not join edge to edge',
        );
      }
      for (final cell in cage.cells) {
        if (owner[cell] != null) {
          return InvalidCageSet(
            problem: CageProblem.cellInTwoCages,
            description: 'cell $cell is in ${owner[cell]} and $cage',
            cell: cell,
          );
        }
        owner[cell] = cage;
      }
    }
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (owner[cell] == null) {
        return InvalidCageSet(
          problem: CageProblem.cellUncovered,
          description: 'cell $cell is in no cage',
          cell: cell,
        );
      }
    }
    return ValidCageSet(
      CageSet._(
        List<Cage>.unmodifiable(cages),
        List<Cage>.unmodifiable(owner.cast<Cage>()),
      ),
    );
  }

  /// Read cages from their stored form: a list of `{"sum": n, "cells": [..]}`,
  /// the shape a **pack** row and the `puzzles` table both carry.
  static CageSetResult fromJson(Object? source) {
    if (source is! List<dynamic>) {
      return InvalidCageSet(
        problem: CageProblem.malformed,
        description: 'cages are a list, not a ${source.runtimeType}',
      );
    }
    final cages = <Cage>[];
    for (final entry in source) {
      if (entry is! Map<String, dynamic>) {
        return InvalidCageSet(
          problem: CageProblem.malformed,
          description: 'a cage is an object, not a ${entry.runtimeType}',
        );
      }
      final sum = entry['sum'];
      final cells = entry['cells'];
      if (sum is! int ||
          cells is! List<dynamic> ||
          cells.any((c) => c is! int)) {
        return InvalidCageSet(
          problem: CageProblem.malformed,
          description: 'a cage needs an integer sum and integer cells: $entry',
        );
      }
      cages.add(Cage(cells: cells.cast<int>(), sum: sum));
    }
    return build(cages);
  }

  /// Read cages from the text a `puzzles` row stores, or null when the row
  /// carries none — which is what a classic puzzle is.
  static CageSetResult? fromStoredText(String? text) {
    if (text == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (error) {
      return InvalidCageSet(
        problem: CageProblem.malformed,
        description: 'stored cages are not JSON: ${error.message}',
      );
    }
    return fromJson(decoded);
  }

  /// The stored form [fromJson] reads.
  List<Map<String, Object>> toJson() => <Map<String, Object>>[
    for (final cage in cages)
      <String, Object>{'sum': cage.sum, 'cells': cage.cells},
  ];

  final List<Cage> cages;
  final List<Cage> _cageByCell;

  Cage cageOf(int cell) => _cageByCell[cell];

  @override
  bool operator ==(Object other) {
    if (other is! CageSet || other.cages.length != cages.length) return false;
    for (var i = 0; i < cages.length; i++) {
      if (other.cages[i] != cages[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(cages);

  /// Every cage adds up to its sum and repeats no digit in [grid].
  bool isSatisfiedBy(Grid grid) {
    for (final cage in cages) {
      var seen = 0;
      var total = 0;
      for (final cell in cage.cells) {
        final digit = grid.digitAt(cell);
        if (digit == Grid.blank) return false;
        final bit = 1 << (digit - 1);
        if (seen & bit != 0) return false;
        seen |= bit;
        total += digit;
      }
      if (total != cage.sum) return false;
    }
    return true;
  }

  static bool _isConnected(List<int> cells) {
    final members = cells.toSet();
    final reached = <int>{cells.first};
    final queue = <int>[cells.first];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      for (final next in _edgeNeighbours(cell)) {
        if (members.contains(next) && reached.add(next)) queue.add(next);
      }
    }
    return reached.length == members.length;
  }

  static Iterable<int> _edgeNeighbours(int cell) sync* {
    final row = GridGeometry.rowOf(cell);
    final column = GridGeometry.columnOf(cell);
    if (row > 0) yield cell - GridGeometry.side;
    if (row < GridGeometry.side - 1) yield cell + GridGeometry.side;
    if (column > 0) yield cell - 1;
    if (column < GridGeometry.side - 1) yield cell + 1;
  }
}
