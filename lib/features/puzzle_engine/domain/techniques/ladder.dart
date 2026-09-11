import '../technique.dart';
import 'chains.dart';
import 'fish.dart';
import 'intersections.dart';
import 'singles.dart';
import 'solving_technique.dart';
import 'subsets.dart';
import 'wings.dart';

/// Every technique in the D-57 ladder, easiest first.
///
/// The order is [Technique.values], and the solver tries them in it: the easiest
/// applicable technique wins, or every puzzle grades harder than it is. A
/// technique missing from this list would be a technique the grader can never
/// charge a puzzle for, and one outside D-57 would be a rank nobody can explain.
const List<SolvingTechnique> techniqueLadder = <SolvingTechnique>[
  FullHouse(),
  NakedSingle(),
  HiddenSingle(),
  NakedPair(),
  PointingPair(),
  BoxLineReduction(),
  NakedTriple(),
  HiddenPair(),
  XWing(),
  Swordfish(),
  XyWing(),
  SimpleChain(),
];

/// The implementation of one named technique, for running it on its own.
SolvingTechnique techniqueFor(Technique technique) =>
    techniqueLadder.firstWhere((entry) => entry.technique == technique);
