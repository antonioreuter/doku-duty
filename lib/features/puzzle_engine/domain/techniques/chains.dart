import '../deduction.dart';
import '../grid_geometry.dart';
import '../solver_state.dart';
import '../technique.dart';
import 'solving_technique.dart';

/// Simple colouring on one digit.
///
/// Where a digit has exactly two places left in a **unit**, one of them is true
/// and the other false — a conjugate link. Following those links two-colours a
/// chain, and then two things follow. If one colour appears twice in a **unit**
/// it must be the false one, so the digit leaves every cell of that colour. And
/// any cell outside the chain that sees both colours cannot hold the digit,
/// because one of the two colours is true whichever way the chain falls.
final class SimpleChain extends SolvingTechnique {
  const SimpleChain();

  @override
  Technique get technique => Technique.simpleChain;

  @override
  Deduction? deduce(SolverState state) {
    for (var digit = 1; digit <= 9; digit++) {
      final links = _conjugateLinks(state, digit);
      if (links.isEmpty) continue;

      for (final chain in _chains(links)) {
        final deduction =
            _colourTrap(state, digit, chain) ?? _seesBoth(state, digit, chain);
        if (deduction != null) return deduction;
      }
    }
    return null;
  }

  /// A colour that appears twice in one **unit** is false throughout.
  Deduction? _colourTrap(SolverState state, int digit, _Chain chain) {
    for (var colour = 0; colour < 2; colour++) {
      final wearing = chain.wearing(colour);
      for (final unit in GridGeometry.allUnits) {
        var seen = 0;
        for (final cell in unit.cells) {
          if (wearing.contains(cell)) seen++;
        }
        if (seen < 2) continue;
        return Deduction(
          technique: Technique.simpleChain,
          eliminations: <CellDigit>[
            for (final cell in wearing) CellDigit(cell, digit),
          ],
          witnesses: chain.cells,
        );
      }
    }
    return null;
  }

  /// A cell outside the chain that sees both colours cannot hold the digit.
  Deduction? _seesBoth(SolverState state, int digit, _Chain chain) {
    final eliminations = <CellDigit>[];
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (chain.colourOf.containsKey(cell)) continue;
      if (!state.isEmptyAt(cell) || !state.hasCandidate(cell, digit)) continue;

      var sees = 0;
      for (final peer in GridGeometry.peersOf(cell)) {
        final colour = chain.colourOf[peer];
        if (colour != null) sees |= 1 << colour;
      }
      if (sees == 3) eliminations.add(CellDigit(cell, digit));
    }
    if (eliminations.isEmpty) return null;
    return Deduction(
      technique: Technique.simpleChain,
      eliminations: eliminations,
      witnesses: chain.cells,
    );
  }
}

/// Pairs of cells that are the only two places a digit can go in some **unit**.
Map<int, Set<int>> _conjugateLinks(SolverState state, int digit) {
  final links = <int, Set<int>>{};
  for (final unit in GridGeometry.allUnits) {
    if (state.unitHolds(unit, digit)) continue;
    final cells = state.cellsAdmitting(digit, unit.cells);
    if (cells.length != 2) continue;
    links.putIfAbsent(cells[0], () => <int>{}).add(cells[1]);
    links.putIfAbsent(cells[1], () => <int>{}).add(cells[0]);
  }
  return links;
}

/// The connected components of the link graph, two-coloured, lowest cell first.
List<_Chain> _chains(Map<int, Set<int>> links) {
  final colours = <int, int>{};
  final chains = <_Chain>[];
  for (final start in links.keys.toList()..sort()) {
    if (colours.containsKey(start)) continue;
    final member = <int, int>{start: 0};
    final queue = <int>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final next in links[cell]!) {
        if (member.containsKey(next)) continue;
        member[next] = 1 - member[cell]!;
        queue.add(next);
      }
    }
    colours.addAll(member);
    if (member.length > 2) chains.add(_Chain(member));
  }
  return chains;
}

/// One two-coloured component. A component of two cells is a single conjugate
/// link and says nothing beyond it, so it is not carried.
final class _Chain {
  _Chain(this.colourOf);

  final Map<int, int> colourOf;

  List<int> get cells => colourOf.keys.toList()..sort();

  List<int> wearing(int colour) => <int>[
    for (final entry in colourOf.entries)
      if (entry.value == colour) entry.key,
  ]..sort();
}
