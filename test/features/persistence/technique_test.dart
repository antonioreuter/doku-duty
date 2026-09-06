import 'package:test/test.dart';

import 'package:doku_duty/features/persistence/domain/rank.dart';
import 'package:doku_duty/features/persistence/domain/technique.dart';

void main() {
  // Transcribed from D-57. A puzzle graded Marshal that only needs a hidden
  // single destroys trust in the whole progression, so the mapping is asserted
  // rather than trusted.
  test('each rank introduces exactly the techniques D-57 lists', () {
    Set<Technique> introducedAt(Rank rank) =>
        Technique.values.where((t) => t.introducedAt == rank).toSet();

    expect(introducedAt(Rank.greenhorn), <Technique>{
      Technique.fullHouse,
      Technique.nakedSingle,
    });
    expect(introducedAt(Rank.deputy), <Technique>{Technique.hiddenSingle});
    expect(introducedAt(Rank.sheriff), <Technique>{
      Technique.nakedPair,
      Technique.pointingPair,
    });
    expect(introducedAt(Rank.marshal), <Technique>{
      Technique.boxLineReduction,
      Technique.nakedTriple,
    });
    expect(introducedAt(Rank.ranger), <Technique>{
      Technique.hiddenPair,
      Technique.xWing,
    });
    expect(introducedAt(Rank.legend), <Technique>{
      Technique.swordfish,
      Technique.xyWing,
      Technique.simpleChain,
    });
  });

  test('the ladder is cumulative', () {
    expect(Technique.upTo(Rank.greenhorn), hasLength(2));
    expect(Technique.upTo(Rank.deputy), hasLength(3));
    expect(Technique.upTo(Rank.legend), Technique.values);
    expect(Technique.upTo(Rank.ranger), contains(Technique.nakedSingle));
    expect(Technique.upTo(Rank.ranger), isNot(contains(Technique.swordfish)));
  });

  test('every technique belongs to a rank', () {
    for (final technique in Technique.values) {
      expect(Rank.values, contains(technique.introducedAt));
    }
  });
}
