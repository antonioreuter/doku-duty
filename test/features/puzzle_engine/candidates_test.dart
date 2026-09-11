import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/candidates.dart';

void main() {
  test('a full set holds the digits one to nine', () {
    expect(Candidates.all.digits, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(Candidates.all.length, 9);
    expect(Candidates.none.digits, isEmpty);
    expect(Candidates.none.isEmpty, isTrue);
  });

  test('a nine-bit mask, one bit per digit', () {
    expect(Candidates.all.mask, 0x1FF);
    expect(Candidates.none.mask, 0);
    expect(Candidates.of(const <int>[1]).mask, 1);
    expect(Candidates.of(const <int>[9]).mask, 1 << 8);
  });

  // Notes are positional and never reflow (constraint 3). The engine's own
  // candidate set has the same property for the same reason: removing one
  // digit must not disturb where the others sit.
  test('eliminating a digit leaves every other digit untouched', () {
    for (var digit = 1; digit <= 9; digit++) {
      final reduced = Candidates.all.without(digit);
      expect(reduced.contains(digit), isFalse);
      expect(reduced.length, 8);
      for (var other = 1; other <= 9; other++) {
        if (other == digit) continue;
        expect(reduced.contains(other), isTrue);
      }
      expect(reduced.digits, <int>[
        for (var d = 1; d <= 9; d++)
          if (d != digit) d,
      ]);
    }
  });

  test('eliminating a digit that is not there changes nothing', () {
    final without5 = Candidates.all.without(5);
    expect(without5.without(5), without5);
  });

  test('adding a digit back restores it and nothing else', () {
    final restored = Candidates.all.without(3).with_(3);
    expect(restored, Candidates.all);
    expect(Candidates.none.with_(7).digits, <int>[7]);
  });

  test('single reports the only digit left, and nothing otherwise', () {
    expect(Candidates.of(const <int>[4]).single, 4);
    expect(Candidates.all.single, isNull);
    expect(Candidates.none.single, isNull);
  });

  test('sets combine and subtract as masks', () {
    final a = Candidates.of(const <int>[1, 2, 3]);
    final b = Candidates.of(const <int>[3, 4]);
    expect(a.union(b).digits, <int>[1, 2, 3, 4]);
    expect(a.intersection(b).digits, <int>[3]);
    expect(a.difference(b).digits, <int>[1, 2]);
    expect(a.containsAll(Candidates.of(const <int>[1, 3])), isTrue);
    expect(a.containsAll(b), isFalse);
  });

  test('equal sets are equal values', () {
    expect(Candidates.of(const <int>[2, 1]), Candidates.of(const <int>[1, 2]));
    expect(
      Candidates.of(const <int>[2, 1]).hashCode,
      Candidates.of(const <int>[1, 2]).hashCode,
    );
  });
}
