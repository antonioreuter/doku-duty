import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/due_lesson.dart';

/// A stand-in catalogue, so the rule's tests do not depend on lesson content.
Lesson _for(Technique technique) => Lesson(
  id: technique.name,
  title: technique.name,
  technique: technique,
  steps: const <LessonStep>[],
  grid: '',
  placement: const LessonPlacement(cell: 0, digit: 1),
);

final List<Lesson> _catalogue = <Lesson>[
  for (final technique in Technique.values)
    if (technique.introducedAt.isHarderThan(Rank.greenhorn) ||
        technique.killerOnly)
      _for(technique),
  Lesson.notes,
];

Lesson? _due({
  required Rank rank,
  Set<Technique> required = const <Technique>{},
  Set<Technique> unlocked = const <Technique>{},
  Set<String> seen = const <String>{},
}) => dueLesson(
  puzzleRank: rank,
  techniquesRequired: required,
  unlocked: unlocked,
  seen: seen,
  catalogue: _catalogue,
);

void main() {
  group('a technique with no lesson is never due', () {
    test('full house and naked single, at every rank', () {
      for (final rank in Rank.values) {
        expect(
          _due(
            rank: rank,
            required: <Technique>{Technique.fullHouse, Technique.nakedSingle},
            seen: <String>{Lesson.notes.id},
          ),
          isNull,
          reason: 'a Greenhorn technique was taught at $rank',
        );
      }
    });
  });

  group('a technique already solved is never due', () {
    test('an unlocked technique is not taught, even unseen', () {
      expect(
        _due(
          rank: Rank.ranger,
          required: <Technique>{Technique.xWing},
          unlocked: <Technique>{Technique.xWing},
          seen: <String>{Lesson.notes.id},
        ),
        isNull,
      );
    });

    test('an unlocked one is skipped and a due one is still found', () {
      final lesson = _due(
        rank: Rank.ranger,
        required: <Technique>{Technique.xWing, Technique.hiddenPair},
        unlocked: <Technique>{Technique.xWing},
        seen: <String>{Lesson.notes.id},
      );
      expect(lesson?.technique, Technique.hiddenPair);
    });
  });

  group('a lesson already seen is never due', () {
    test('seen suppresses it however it was seen', () {
      expect(
        _due(
          rank: Rank.sheriff,
          required: <Technique>{Technique.nakedPair},
          seen: <String>{Technique.nakedPair.name, Lesson.notes.id},
        ),
        isNull,
      );
    });
  });

  group('at most one, the hardest', () {
    test('several due yields the hardest by the ladder', () {
      final lesson = _due(
        rank: Rank.legend,
        required: <Technique>{
          Technique.hiddenSingle,
          Technique.nakedPair,
          Technique.xWing,
          Technique.swordfish,
        },
        seen: <String>{Lesson.notes.id},
      );
      expect(lesson?.technique, Technique.swordfish);
    });

    test('the others stay due for a later opening', () {
      const required = <Technique>{Technique.hiddenSingle, Technique.xWing};
      final first = _due(
        rank: Rank.ranger,
        required: required,
        seen: <String>{Lesson.notes.id},
      );
      expect(first?.technique, Technique.xWing);

      final second = _due(
        rank: Rank.ranger,
        required: required,
        seen: <String>{Lesson.notes.id, first!.id},
      );
      expect(second?.technique, Technique.hiddenSingle);
    });
  });

  group('nothing due', () {
    test('an empty answer, not an error and not a filler lesson', () {
      expect(
        _due(rank: Rank.greenhorn, seen: <String>{Lesson.notes.id}),
        isNull,
      );
    });

    test('everything seen', () {
      expect(
        _due(
          rank: Rank.legend,
          required: Technique.values.toSet(),
          seen: <String>{
            Lesson.notes.id,
            for (final t in Technique.values) t.name,
          },
        ),
        isNull,
      );
    });
  });

  group('the notes lesson', () {
    test('is due on a Sheriff-rank puzzle when unseen', () {
      expect(_due(rank: Rank.sheriff)?.id, Lesson.notes.id);
    });

    test('is not due below Sheriff', () {
      for (final rank in <Rank>[Rank.greenhorn, Rank.deputy]) {
        expect(_due(rank: rank)?.id, isNot(Lesson.notes.id));
      }
    });

    test('is still due above Sheriff, for a player who jumped', () {
      // The soft **rank** gate (D-103) lets a Deputy open a Marshal puzzle, so
      // "the first Sheriff-rank puzzle" cannot be the only door — a player who
      // never opened one would otherwise never be taught notes at all.
      for (final rank in <Rank>[Rank.marshal, Rank.ranger, Rank.legend]) {
        expect(_due(rank: rank)?.id, Lesson.notes.id, reason: 'at $rank');
      }
    });

    test('comes before a technique lesson due on the same opening', () {
      // Notes are the prerequisite for every technique above Deputy, so a
      // player taught naked pair first would be taught to use a tool they have
      // not met.
      expect(
        _due(
          rank: Rank.sheriff,
          required: <Technique>{Technique.nakedPair},
        )?.id,
        Lesson.notes.id,
      );
    });

    test('once seen, the technique lesson follows', () {
      expect(
        _due(
          rank: Rank.sheriff,
          required: <Technique>{Technique.nakedPair},
          seen: <String>{Lesson.notes.id},
        )?.technique,
        Technique.nakedPair,
      );
    });

    test('cannot be suppressed by a technique unlock', () {
      // It teaches no technique, so no counter can stand for it.
      expect(
        _due(rank: Rank.sheriff, unlocked: Technique.values.toSet())?.id,
        Lesson.notes.id,
      );
    });

    test('does not return once seen', () {
      expect(_due(rank: Rank.sheriff, seen: <String>{Lesson.notes.id}), isNull);
    });
  });

  // Cage combination is the one **lesson** that says what a **cage** is. The
  // hardest-first rule (D-106) would show a Sheriff **killer** puzzle's 45 rule
  // instead — and solving it unlocks cage combination, so the introduction
  // would never be due again. It is owed first, the way notes are.
  group('the cage lesson is owed before any other killer lesson', () {
    final killerSheriff = <Technique>{
      Technique.nakedSingle,
      Technique.cageCombination,
      Technique.fortyFiveRule,
    };

    test('it comes before the 45 rule, though the 45 rule is harder', () {
      expect(
        _due(
          rank: Rank.sheriff,
          required: killerSheriff,
          seen: <String>{Lesson.notes.id},
        )?.id,
        Technique.cageCombination.name,
      );
    });

    test('it comes before a harder classic lesson on a killer board', () {
      expect(
        _due(
          rank: Rank.ranger,
          required: <Technique>{Technique.cageCombination, Technique.xWing},
          seen: <String>{Lesson.notes.id},
        )?.id,
        Technique.cageCombination.name,
      );
    });

    test('once seen, the hardest killer lesson follows as usual', () {
      expect(
        _due(
          rank: Rank.sheriff,
          required: killerSheriff,
          seen: <String>{Lesson.notes.id, Technique.cageCombination.name},
        )?.id,
        Technique.fortyFiveRule.name,
      );
    });

    test('notes still come first when they are owed', () {
      expect(
        _due(rank: Rank.sheriff, required: killerSheriff)?.id,
        Lesson.notes.id,
      );
    });

    test('a player who has solved a killer puzzle is not taught it', () {
      expect(
        _due(
          rank: Rank.sheriff,
          required: killerSheriff,
          unlocked: <Technique>{Technique.cageCombination},
          seen: <String>{Lesson.notes.id},
        )?.id,
        Technique.fortyFiveRule.name,
      );
    });

    test('it is owed when the puzzle needs only the 45 rule', () {
      // A grade can reach the 45 rule without ever needing cage combination,
      // and that player still has not been told what a **cage** is.
      expect(
        _due(
          rank: Rank.sheriff,
          required: <Technique>{Technique.fortyFiveRule},
          seen: <String>{Lesson.notes.id},
        )?.id,
        Technique.cageCombination.name,
      );
    });

    test('a classic puzzle never owes it', () {
      expect(
        _due(
          rank: Rank.ranger,
          required: <Technique>{Technique.xWing},
          seen: <String>{Lesson.notes.id},
        )?.id,
        Technique.xWing.name,
      );
    });
  });
}
