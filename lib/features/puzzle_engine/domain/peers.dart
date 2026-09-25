import 'cage.dart';
import 'grid_geometry.dart';

/// Which cells a cell may not share a digit with, for one puzzle.
///
/// On a classic puzzle this is [GridGeometry.peersOf] and nothing else. On a
/// **killer** puzzle every other cell of a cell's **cage** joins them (D-130),
/// because "no digit repeats in a **cage**" is the relation a **peer** already
/// expresses — so every system that asks this question is right on a **killer**
/// board without learning a second rule.
///
/// The **cage sum** is deliberately absent. Ruling a digit out by arithmetic is
/// a deduction, not a legality check.
final class Peers {
  const Peers._(this._table);

  /// The unit table, shared by every classic puzzle.
  static const Peers classic = Peers._(null);

  /// The peers of a puzzle with [cages], or [classic] when there are none.
  factory Peers.of(CageSet? cages) =>
      cages == null ? classic : Peers._(_build(cages));

  final List<List<int>>? _table;

  /// Every peer of [cell], each listed once, never [cell] itself.
  List<int> of(int cell) => _table?[cell] ?? GridGeometry.peersOf(cell);

  static List<List<int>> _build(CageSet cages) =>
      List<List<int>>.unmodifiable(<List<int>>[
        for (var cell = 0; cell < GridGeometry.cellCount; cell++)
          List<int>.unmodifiable(
            (<int>{
              ...GridGeometry.peersOf(cell),
              ...cages.cageOf(cell).cells,
            }..remove(cell)).toList()..sort(),
          ),
      ]);
}
