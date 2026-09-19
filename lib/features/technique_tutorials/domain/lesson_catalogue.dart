import '../../puzzle_engine/domain/technique.dart';
import 'lesson.dart';

/// The eleven **lesson**s, keyed by id.
///
/// **Generated content, checked by test.** Every grid here is a real position
/// lifted from a puzzle in the shipped **pack** — walked to the state where the
/// technique actually fires, by `tool/find_lesson_positions.dart`. None of them
/// was invented, which matters more than it sounds: a lesson demonstrating a
/// naked pair on a grid holding no naked pair would read perfectly and teach
/// nothing, and no test but `lesson_catalogue_test.dart` would notice.
///
/// The placement each **lesson** ends on is a cell the technique's own
/// eliminations reduced to one candidate — it held more than one before and
/// exactly one after. That is why the last sentence of each lesson is true
/// rather than merely plausible.
///
/// The copy is checked too, and for a reason: the first draft of three of these
/// named the *eliminated* digit where it meant the one being placed, so the
/// lesson said "only the 2 left" over a cell whose answer was 5. It read
/// perfectly. `lesson_catalogue_test.dart` now asserts the last step names the
/// digit the player is actually asked for.
const List<Lesson> lessonCatalogue = <Lesson>[
  Lesson.notes,
  Lesson(
    id: 'hiddenSingle',
    title: 'Hidden single',
    technique: Technique.hiddenSingle,
    grid:
        '.6.4.....83..19..2942.....7.....6.896..8..17..87.91.452.8.....4..........1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text:
            'Look at the 4s already placed. They cover every cell of this box but one.',
        cells: <int>[9, 10, 11, 12, 13, 14, 16, 17],
      ),
      LessonStep(
        text:
            'So although this cell could hold several digits, it is the only place left in the box for a 4.',
        cells: <int>[9, 10, 11, 12, 13, 14, 16, 17],
      ),
      LessonStep(text: 'Place the 4.', cells: <int>[15]),
    ],
    placement: LessonPlacement(cell: 15, digit: 4),
  ),
  Lesson(
    id: 'nakedPair',
    title: 'Naked pair',
    technique: Technique.nakedPair,
    grid:
        '7614.....835719.62942.....7.....6.896..8..17..87.91.452.8.....4..........1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text: 'These two cells can hold nothing but 2 and 3.',
        cells: <int>[30, 33],
      ),
      LessonStep(
        text:
            'Between them they will use both digits, so no other cell in the unit can be 2 and 3.',
        cells: <int>[27, 28, 29, 31],
      ),
      LessonStep(
        text:
            'Take 2 and 3 out of the rest, and this cell has only the 5 left. Place it.',
        cells: <int>[28],
      ),
    ],
    placement: LessonPlacement(cell: 28, digit: 5),
  ),
  Lesson(
    id: 'pointingPair',
    title: 'Pointing pair',
    technique: Technique.pointingPair,
    grid:
        '.6.4.....83..19..2942.....71....6.896..8..17..87.91.452.8.....4..........1.5..896',
    steps: <LessonStep>[
      LessonStep(
        text:
            'Inside this box, the 4s can only go in these cells — and they share a line.',
        cells: <int>[29, 38],
      ),
      LessonStep(
        text:
            'Wherever the 4 lands in the box, it is on that line, so the 4 is ruled out of the rest of the line.',
        cells: <int>[65, 74],
      ),
      LessonStep(
        text: 'That leaves this cell with only the 3. Place it.',
        cells: <int>[74],
      ),
    ],
    placement: LessonPlacement(cell: 74, digit: 3),
  ),
  Lesson(
    id: 'boxLineReduction',
    title: 'Box-line reduction',
    technique: Technique.boxLineReduction,
    grid:
        '7614....88357194629426....71543762896298..1733872916452.81....4.7.9....1.1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text:
            'On this line, the 5s can only go in cells that all sit inside one box.',
        cells: <int>[60, 61],
      ),
      LessonStep(
        text:
            'The line needs its 5, so the 5 must be in that box — and is ruled out of the box\'s other cells.',
        cells: <int>[69, 70],
      ),
      LessonStep(
        text: 'This cell is left with only the 3. Place it.',
        cells: <int>[69],
      ),
    ],
    placement: LessonPlacement(cell: 69, digit: 3),
  ),
  Lesson(
    id: 'nakedTriple',
    title: 'Naked triple',
    technique: Technique.nakedTriple,
    grid:
        '.614.....835.19..2942.....7.....6.896..8..17..87.91.452.8.....4..........1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text: 'These three cells hold nothing outside 3 and 4 and 9.',
        cells: <int>[29, 38, 74],
      ),
      LessonStep(
        text:
            'Three cells, three digits: between them they use all of it, so none of the three can appear elsewhere in the unit.',
        cells: <int>[65],
      ),
      LessonStep(
        text: 'That clears this cell down to the 6. Place it.',
        cells: <int>[65],
      ),
    ],
    placement: LessonPlacement(cell: 65, digit: 6),
  ),
  Lesson(
    id: 'hiddenPair',
    title: 'Hidden pair',
    technique: Technique.hiddenPair,
    grid:
        '7614....8835719462942.....7.....6.896..8..173.87.91.452.8.....4..........1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text: 'In this unit, 2 and 3 and 6 can only go in these two cells.',
        cells: <int>[57, 66],
      ),
      LessonStep(
        text:
            'So these two cells hold that pair and nothing else — every other candidate comes out of them.',
        cells: <int>[57, 66],
      ),
      LessonStep(
        text:
            'That settles the unit far enough to leave this cell with only the 9. Place it.',
        cells: <int>[66],
      ),
    ],
    placement: LessonPlacement(cell: 66, digit: 9),
  ),
  Lesson(
    id: 'xWing',
    title: 'X-wing',
    technique: Technique.xWing,
    grid:
        '.614.....835.19..2942.....7.....6.896..8..17..87.91.452.8.....4..........1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text:
            'Look at the 7s on these two lines: each has only two places, and they line up.',
        cells: <int>[55, 60, 64, 69],
      ),
      LessonStep(
        text:
            'Whichever way the two 7s fall, they take both of those columns — so the 7 is out everywhere else in them.',
        cells: <int>[57, 58, 59, 63, 66, 67, 68],
      ),
      LessonStep(
        text: 'This cell is left with only the 3. Place it.',
        cells: <int>[59],
      ),
    ],
    placement: LessonPlacement(cell: 59, digit: 3),
  ),
  Lesson(
    id: 'swordfish',
    title: 'Swordfish',
    technique: Technique.swordfish,
    grid:
        '7614....88357194629426....71543762896298..173.87.916452.8.....4........1.1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text:
            'The same shape as an X-wing, one size larger: three lines, and the 2s in them share three columns.',
        cells: <int>[4, 5, 67, 68, 70, 76, 77, 79],
      ),
      LessonStep(
        text:
            'Three 2s must fill those three columns, so no other cell in them can be a 2.',
        cells: <int>[66],
      ),
      LessonStep(
        text: 'That leaves this cell holding only the 9. Place it.',
        cells: <int>[66],
      ),
    ],
    placement: LessonPlacement(cell: 66, digit: 9),
  ),
  Lesson(
    id: 'xyWing',
    title: 'XY-wing',
    technique: Technique.xyWing,
    grid:
        '7614..9388357194629426.85171543762896298..1733872916452981.37.457.9..3.141.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text:
            'Three cells of two candidates each: a pivot, and two others it shares a digit with.',
        cells: <int>[5, 41, 68],
      ),
      LessonStep(
        text:
            'Whichever the pivot takes, one of the wings is forced to 2 — so any cell seeing both wings cannot be 2.',
        cells: <int>[77],
      ),
      LessonStep(
        text: 'This cell loses its 2 and is left with the 7. Place it.',
        cells: <int>[77],
      ),
    ],
    placement: LessonPlacement(cell: 77, digit: 7),
  ),
  Lesson(
    id: 'simpleChain',
    title: 'Simple chain',
    technique: Technique.simpleChain,
    grid:
        '7614....8835719462942.....71....62896..8..173.87.91.452.8.....4........1.1.5..896',
    steps: <LessonStep>[
      LessonStep(
        text:
            'Follow the 4s: each of these cells has only two places for it, linked end to end.',
        cells: <int>[29, 31, 38],
      ),
      LessonStep(
        text:
            'The links alternate, so both ends cannot be 4 — and a cell seeing both ends cannot be 4 either.',
        cells: <int>[65, 74],
      ),
      LessonStep(
        text: 'That leaves this cell with only the 3. Place it.',
        cells: <int>[74],
      ),
    ],
    placement: LessonPlacement(cell: 74, digit: 3),
  ),
];
