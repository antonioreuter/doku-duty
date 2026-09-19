import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/rank_progression/domain/player_rank.dart';

void main() {
  group('a player with nothing solved', () {
    test('starts at Greenhorn', () {
      expect(PlayerRank.from(const <Rank>[]), Rank.greenhorn);
    });

    test('is at a starting position, not an absence', () {
      // The rule answers with a **rank**, never null and never a throw. A
      // caller forced to handle "no rank yet" would invent its own answer, and
      // the two would disagree the first time one of them changed.
      expect(PlayerRank.from(const <Rank>[]), isA<Rank>());
    });
  });

  group('the hardest solved rank wins', () {
    test('one solve sets the rank to that rank', () {
      expect(PlayerRank.from(const <Rank>[Rank.sheriff]), Rank.sheriff);
    });

    test('a harder solve raises it', () {
      expect(
        PlayerRank.from(const <Rank>[Rank.deputy, Rank.marshal]),
        Rank.marshal,
      );
    });

    test('an easier solve leaves it alone', () {
      expect(
        PlayerRank.from(const <Rank>[Rank.marshal, Rank.greenhorn]),
        Rank.marshal,
      );
    });

    test('order of arrival does not matter', () {
      const ranks = <Rank>[Rank.ranger, Rank.greenhorn, Rank.sheriff];
      expect(PlayerRank.from(ranks), PlayerRank.from(ranks.reversed));
    });

    test('every rank is reachable by solving one of its puzzles', () {
      for (final rank in Rank.values) {
        expect(PlayerRank.from(<Rank>[rank]), rank);
      }
    });

    test('repeats change nothing', () {
      expect(
        PlayerRank.from(const <Rank>[Rank.deputy, Rank.deputy, Rank.deputy]),
        Rank.deputy,
      );
    });
  });

  group('a rank never falls', () {
    // The rule cannot be told about a **mistake**, an **attempt** that ended in
    // **strict mode**, an abandoned puzzle, or a **season** rotating — none of
    // them is a solved **rank**, and a solved **rank** is the only input there
    // is. That is the ratchet made structural rather than remembered (D-102).
    test('adding any further solve never lowers the answer', () {
      for (final first in Rank.values) {
        for (final second in Rank.values) {
          final before = PlayerRank.from(<Rank>[first]);
          final after = PlayerRank.from(<Rank>[first, second]);
          expect(
            after.isHarderThan(before) || after == before,
            isTrue,
            reason: 'solving $second after $first lowered the rank',
          );
        }
      }
    });

    test('no sequence of solves ever drops below the peak', () {
      const solves = <Rank>[
        Rank.deputy,
        Rank.legend,
        Rank.greenhorn,
        Rank.sheriff,
        Rank.greenhorn,
      ];
      var peak = PlayerRank.starting;
      for (var i = 1; i <= solves.length; i++) {
        final now = PlayerRank.from(solves.take(i));
        expect(now.isHarderThan(peak) || now == peak, isTrue);
        peak = now;
      }
      expect(peak, Rank.legend);
    });
  });

  group('which ranks are above a player', () {
    // Asked of the capability so the picker's mark, and anything later that
    // wants the same question answered, cannot drift by comparing enum indices
    // at the call site.
    test('a new player has five ranks above them', () {
      expect(PlayerRank.above(Rank.greenhorn), <Rank>{
        Rank.deputy,
        Rank.sheriff,
        Rank.marshal,
        Rank.ranger,
        Rank.legend,
      });
    });

    test('the top rank has nothing above it', () {
      expect(PlayerRank.above(Rank.legend), isEmpty);
    });

    test('a rank is never above itself', () {
      for (final rank in Rank.values) {
        expect(PlayerRank.above(rank).contains(rank), isFalse);
      }
    });

    test('nothing at or below the player is marked', () {
      final above = PlayerRank.above(Rank.marshal);
      expect(above, <Rank>{Rank.ranger, Rank.legend});
      for (final rank in <Rank>[
        Rank.greenhorn,
        Rank.deputy,
        Rank.sheriff,
        Rank.marshal,
      ]) {
        expect(above.contains(rank), isFalse, reason: '$rank should be clear');
      }
    });

    test('solving above your rank clears that rank and every one below', () {
      final before = PlayerRank.above(PlayerRank.from(const <Rank>[]));
      expect(before.contains(Rank.ranger), isTrue);

      final after = PlayerRank.above(
        PlayerRank.from(const <Rank>[Rank.ranger]),
      );
      expect(after.contains(Rank.ranger), isFalse);
      for (final rank in Rank.values) {
        if (!rank.isHarderThan(Rank.ranger)) {
          expect(after.contains(rank), isFalse);
        }
      }
    });
  });
}
