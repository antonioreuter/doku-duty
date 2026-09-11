import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

void main() {
  // D-57 fixes both the names and the order. The order is what the progression
  // ladder and every "is this harder than" comparison rest on.
  test('there are six ranks, in the order D-57 fixes', () {
    expect(Rank.values, <Rank>[
      Rank.greenhorn,
      Rank.deputy,
      Rank.sheriff,
      Rank.marshal,
      Rank.ranger,
      Rank.legend,
    ]);
  });

  test('the ladder is strictly increasing', () {
    for (var i = 1; i < Rank.values.length; i++) {
      expect(Rank.values[i].isHarderThan(Rank.values[i - 1]), isTrue);
    }
    expect(Rank.greenhorn.isHarderThan(Rank.legend), isFalse);
  });

  test('easier ranks are the ones below', () {
    expect(Rank.sheriff.easier, <Rank>[Rank.greenhorn, Rank.deputy]);
    expect(Rank.greenhorn.easier, isEmpty);
    expect(Rank.legend.easier, hasLength(5));
  });
}
