import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';

/// One puzzle that provably requires one technique, with the reasoning that
/// makes "provably" mean something.
///
/// "Provably" is not a claim in a comment here: `corpus_test.dart` solves each
/// entry with the ladder cut to its **rank** and again with the technique
/// withheld, and the second must fail. The comment above each entry says *which*
/// deduction is the one that cannot be reached otherwise, so that a test failing
/// two years from now can be re-verified against the grid rather than re-derived
/// from nothing.
///
/// Every entry is unique by the exhaustive check in `uniqueness.dart`, which is
/// the one judgement here that does not come from the technique solver.
class CorpusEntry {
  const CorpusEntry({
    required this.technique,
    required this.clues,
    required this.solution,
    required this.alternate,
  });

  /// The hardest technique this puzzle requires.
  final Technique technique;

  /// The givens, eighty-one characters.
  final String clues;

  /// The one solution.
  final String solution;

  /// A second puzzle needing the same hardest technique but a different number
  /// of clues, so the grader can be shown not to be counting them (D-07).
  final String alternate;

  /// The **rank** this puzzle grades to.
  Rank get rank => technique.introducedAt;

  Grid get grid => (Grid.parse(clues) as ValidGrid).grid;

  Grid get alternateGrid => (Grid.parse(alternate) as ValidGrid).grid;

  Grid get solutionGrid => (Grid.parse(solution) as ValidGrid).grid;
}

/// One entry per technique in the D-57 ladder, in ladder order.
const List<CorpusEntry> corpus = <CorpusEntry>[
  // fullHouse. The step nothing easier reaches: r9c1, r9c2, r9c3, r9c4, r9c6,
  // r9c7, r9c8, r9c9 — places 2 in r9c5. It is deduction 1 of 1, and every one
  // before it comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.fullHouse,
    clues:
        '7614529388357194629426385171543762896298451733872916452981637545769843214135.7896',
    solution:
        '761452938835719462942638517154376289629845173387291645298163754576984321413527896',
    alternate:
        '14978625372854361.65391.874385471962274659138916238547462395781897164325531827496',
  ),
  // nakedSingle. The step nothing easier reaches: places 4 in r1c4. It is
  // deduction 9 of 12, and every one before it comes from a technique lower in
  // the ladder.
  CorpusEntry(
    technique: Technique.nakedSingle,
    clues:
        '761.5.93883.719462942638.1715437.289.29.4.17.3872916452.81637545769843214135.789.',
    solution:
        '761452938835719462942638517154376289629845173387291645298163754576984321413527896',
    alternate:
        '14.78625.72854.61.653...8743.54.1..2.74.5.138916238.474623957.189.1643.553182.496',
  ),
  // hiddenSingle. The step nothing easier reaches: r1c1, r1c2, r1c4, r1c5, r1c6,
  // r1c7, r1c8, r1c9 — places 1 in r1c3. It is deduction 17 of 49, and every one
  // before it comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.hiddenSingle,
    clues:
        '.6.....38.3..1946.9.2.....715.3....9....4....3..2....52.816.7545..98.3.1...5.....',
    solution:
        '761452938835719462942638517154376289629845173387291645298163754576984321413527896',
    alternate:
        '....86.5..28....1..........3.54....2......1..9.6..8..7..239.7.1.9..64...5.1.2..9.',
  ),
  // nakedPair. The step nothing easier reaches: r6c1, r7c1 — rules out 5 from
  // r2c1, 5 from r3c1, 2 from r4c1. It is deduction 26 of 52, and every one
  // before it comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.nakedPair,
    clues:
        '.2.6.5.......9.......1.86.......1.74..783......9..7.18.8.91..4.6.375....4...865.3',
    solution:
        '924675831816392457735148629368521974147839265259467318582913746693754182471286593',
    alternate:
        '.7.9..2....34....1....3.4.61...58...49..................96.1....15..9.8.64....1.7',
  ),
  // pointingPair. The step nothing easier reaches: r1c1, r2c1, r3c1 — rules out 9
  // from r4c1. It is deduction 16 of 61, and every one before it comes from a
  // technique lower in the ladder.
  CorpusEntry(
    technique: Technique.pointingPair,
    clues:
        '.6...3....3...7.5........81..1........5.19...7...42.6...98....651.9.4..8.....1..2',
    solution:
        '168453927932187654457296381691738245245619873783542169329875416516924738874361592',
    alternate:
        '.....6.5..28....1..........3..4....2......1..9....8..7..239.7.1.9..64...5.1.2..9.',
  ),
  // boxLineReduction. The step nothing easier reaches: r4c7, r4c8 — rules out 5
  // from r5c8, 5 from r6c8. It is deduction 18 of 59, and every one before it
  // comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.boxLineReduction,
    clues:
        '...1.3748.9...83.5....5..96..69.....87...........37..1..13.5.8..68........98..2..',
    solution:
        '652193748197468325483752196316984572875621934924537861241375689768219453539846217',
    alternate:
        '.2...4...6..8.3...1.....4..7.....9.8....9..46.1...65..............15..97.6...93.2',
  ),
  // nakedTriple. The step nothing easier reaches: r7c1, r7c3, r8c1 — rules out 3
  // from r9c2, 7 from r9c2, 1 from r9c3, 3 from r9c3. It is deduction 15 of 61,
  // and every one before it comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.nakedTriple,
    clues:
        '..71....26.9.....8.1.9...5.....3..........37.......9.6.2...5.....48.9.2.9...6.4..',
    solution:
        '837154692659273148412986753196537284248691375573428916721345869364819527985762431',
    alternate:
        '..5...4..6.8.5.9....38.1..........4..4...3.513..59......7..........6.2.8.3.94....',
  ),
  // hiddenPair. The step nothing easier reaches: r3c8, r3c9 — rules out 1 from
  // r3c8, 3 from r3c8, 1 from r3c9. It is deduction 15 of 69, and every one
  // before it comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.hiddenPair,
    clues:
        '3....4.874.59......6............7...1.......88....5742.23...1..6...9......1.4.5..',
    solution:
        '319654287475982316268713495542867931137429658896135742923578164654291873781346529',
    alternate:
        '63.147.........31....3.2.6...4...8.2.5...3..1....7.9...958..........14..4.29.....',
  ),
  // xWing. The step nothing easier reaches: r1c2, r1c4, r5c2, r5c4 — rules out 4
  // from r3c2, 4 from r2c4. It is deduction 27 of 59, and every one before it
  // comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.xWing,
    clues:
        '3.7.59....5..2.37....8.........82.611.5..78.3.28......4.6.....8.73.4..........24.',
    solution:
        '347659182859124376612873594734582961165497823928361457496215738273948615581736249',
    alternate:
        '.4..15.9.97..63.....5...4.65...4728.......5.........697..29..5...6.7....13.......',
  ),
  // swordfish. The step nothing easier reaches: r1c3, r1c4, r6c4, r6c5, r7c3,
  // r7c5 — rules out 3 from r3c3, 3 from r9c3, 3 from r8c5. It is deduction 19 of
  // 55, and every one before it comes from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.swordfish,
    clues:
        '9....7....7..6.39.....4...12..6.5.39..62..1..49...1.2..8...9..5.5.7..6...4.15..8.',
    solution:
        '963817542174562398528943761217685439836294157495371826681439275359728614742156983',
    alternate:
        '..79....553214........2513...9.1..6776....2..2...7..4.6..4.9..1..1...4.....2...96',
  ),
  // xyWing. The step nothing easier reaches: r1c3, r2c2, r7c2 — rules out 5 from
  // r7c3, 5 from r9c3. It is deduction 21 of 62, and every one before it comes
  // from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.xyWing,
    clues:
        '7..8.......1.3..58.6.......17..2.....2.14.8..8...93..26.....1744..9.....38...42.9',
    solution:
        '734851926291436758568279341173628495926145837845793612659382174412967583387514269',
    alternate:
        '7.89.......912.8.6....8.9..2....8.93..6.....18...4...........7..2.4.6...4..35..6.',
  ),
  // simpleChain. The step nothing easier reaches: r1c5, r1c9, r2c4, r2c8, r7c5,
  // r7c8, r9c4, r9c9 — rules out 2 from r1c9, 2 from r2c4, 2 from r7c5, 2 from
  // r7c8, 2 from r9c9. It is deduction 30 of 49, and every one before it comes
  // from a technique lower in the ladder.
  CorpusEntry(
    technique: Technique.simpleChain,
    clues:
        '4..6.3.7.935..8....27.5...8..35.294775.....3...9..1....14...7..89.3..6......4.18.',
    solution:
        '481623579935178426627954318163582947758496231249731865314865792892317654576249183',
    alternate:
        '..2.7....8........3.7.85..1..854...9.54.32.78.........93...415.......8...8.7...9.',
  ),
];

/// A puzzle with exactly one solution that no implemented technique can finish.
///
/// It stalls after 32 deductions with 32 cells still empty, and the exhaustive
/// check still calls it unique — which is the whole reason those two questions
/// are answered by different code. Grading must call this ungradable rather than
/// Legend: filing it under the top **rank** is what would put a guess-and-check
/// puzzle in front of a player, and constraint 8 forbids that.
const String puzzleBeyondTheLadder =
    '.6.....3.....1946...2.....715.3....9....4....3..2....52..16.7..5...8...1...5.....';

const String puzzleBeyondTheLadderSolution =
    '761452938835719462942638517154376289629845173387291645298163754576984321413527896';

/// Reads one of the strings above. They are checked into the suite, so a parse
/// failure here is a typo in this file, not input from anywhere.
Grid corpusGrid(String clues) => (Grid.parse(clues) as ValidGrid).grid;
