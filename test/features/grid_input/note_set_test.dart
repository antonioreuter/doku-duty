import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/note_set.dart';

void main() {
  group('marking', () {
    test('an empty set holds nothing', () {
      expect(NoteSet.none.digits, isEmpty);
      expect(NoteSet.none.isEmpty, isTrue);
      expect(NoteSet.none.contains(5), isFalse);
    });

    test('a marked digit is in the set', () {
      final marked = NoteSet.none.toggle(4);
      expect(marked.contains(4), isTrue);
      expect(marked.digits, <int>[4]);
    });

    // One control both marks and unmarks: a second control to remove a
    // candidate is a second thing to find on a crowded pad.
    test('marking a digit already there removes it', () {
      final once = NoteSet.none.toggle(4);
      final twice = once.toggle(4);

      expect(twice.contains(4), isFalse);
      expect(twice, NoteSet.none);
    });

    test('a set holds all nine at once (D-09)', () {
      var set = NoteSet.none;
      for (var digit = 1; digit <= 9; digit++) {
        set = set.toggle(digit);
      }
      expect(set.digits, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(set.length, 9);
    });

    test('the set it was marked on is unchanged', () {
      final before = NoteSet.of(const <int>[1, 2]);
      before.toggle(3);
      expect(before.digits, <int>[1, 2]);
    });
  });

  // Constraint 3. Removing a candidate must not disturb the others, and the
  // data model is what makes that structural rather than careful.
  group('removing leaves the rest alone', () {
    test('every other digit survives, whichever one goes', () {
      final all = NoteSet.of(const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]);

      for (var digit = 1; digit <= 9; digit++) {
        final reduced = all.toggle(digit);
        expect(reduced.contains(digit), isFalse, reason: 'removed $digit');
        expect(reduced.length, 8);
        for (var other = 1; other <= 9; other++) {
          if (other == digit) continue;
          expect(reduced.contains(other), isTrue, reason: '$other survives');
        }
      }
    });

    test('removing from the middle does not renumber anything', () {
      final before = NoteSet.of(const <int>[2, 5, 8]);
      final after = before.toggle(5);
      expect(after.digits, <int>[2, 8]);
    });
  });

  // A slot is a function of the digit and nothing else — not insertion order,
  // not how many candidates the cell holds. This is the property that stops a
  // board reflowing, and it is asserted rather than assumed.
  group('slots', () {
    test('the documented three-by-three arrangement (D-10)', () {
      expect(NoteSet.slotOf(1), (row: 0, column: 0));
      expect(NoteSet.slotOf(5), (row: 1, column: 1));
      expect(NoteSet.slotOf(9), (row: 2, column: 2));
      expect(NoteSet.slotOf(3), (row: 0, column: 2));
      expect(NoteSet.slotOf(7), (row: 2, column: 0));
    });

    test('every digit owns a distinct slot', () {
      final slots = <({int row, int column})>{
        for (var digit = 1; digit <= 9; digit++) NoteSet.slotOf(digit),
      };
      expect(slots, hasLength(9));
    });

    test('a slot does not depend on what else the cell holds', () {
      final lonely = NoteSet.of(const <int>[5]);
      final crowded = NoteSet.of(const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]);

      expect(lonely.contains(5), isTrue);
      expect(crowded.contains(5), isTrue);
      // The slot is asked of the digit, never of the set, so there is no way
      // for the two to disagree.
      expect(NoteSet.slotOf(5), NoteSet.slotOf(5));
    });

    test('a slot does not depend on the order digits were marked', () {
      final ascending = NoteSet.none.toggle(2).toggle(7);
      final descending = NoteSet.none.toggle(7).toggle(2);
      expect(ascending, descending);
      expect(ascending.digits, descending.digits);
    });
  });

  test('sets are compared by value', () {
    expect(NoteSet.of(const <int>[3, 1]), NoteSet.of(const <int>[1, 3]));
    expect(
      NoteSet.of(const <int>[3, 1]).hashCode,
      NoteSet.of(const <int>[1, 3]).hashCode,
    );
    expect(NoteSet.of(const <int>[1]), isNot(NoteSet.of(const <int>[2])));
  });

  // D-15. Undo, **auto-cleanup**, and clearing all need to know which
  // candidates the player marked and which **auto-notes** did, so the
  // distinction lives in the model rather than being inferred later. It is
  // invisible on screen: both are drawn in the **settled note** ink.
  group('origin', () {
    test('a digit the player marks is theirs', () {
      final marked = NoteSet.none.toggle(4);
      expect(marked.contains(4), isTrue);
      expect(marked.isGenerated(4), isFalse);
    });

    test('a digit marked as generated says so', () {
      final filled = NoteSet.none.withGenerated(4);
      expect(filled.contains(4), isTrue);
      expect(filled.isGenerated(4), isTrue);
    });

    test('a digit that is absent is not generated', () {
      expect(NoteSet.none.isGenerated(4), isFalse);
      expect(NoteSet.of(const <int>[1]).isGenerated(4), isFalse);
    });

    test('the two kinds sit in one cell', () {
      final mixed = NoteSet.of(const <int>[1]).withGenerated(4);
      expect(mixed.digits, <int>[1, 4]);
      expect(mixed.isGenerated(1), isFalse);
      expect(mixed.isGenerated(4), isTrue);
      expect(mixed.generated, <int>[4]);
      expect(mixed.manual, <int>[1]);
    });

    // The player has now made that call themselves, so it is theirs.
    test('toggling a generated candidate off and on makes it manual', () {
      final filled = NoteSet.none.withGenerated(4);
      final removed = filled.toggle(4);
      expect(removed.contains(4), isFalse);

      final remarked = removed.toggle(4);
      expect(remarked.contains(4), isTrue);
      expect(remarked.isGenerated(4), isFalse);
    });

    test('marking a generated candidate by hand takes it over', () {
      final taken = NoteSet.none.withGenerated(4).with_(4);
      expect(taken.contains(4), isTrue);
      expect(taken.isGenerated(4), isFalse);
    });

    test('removing a generated candidate leaves nothing behind', () {
      final gone = NoteSet.none.withGenerated(4).without(4);
      expect(gone, NoteSet.none);
      expect(gone.isGenerated(4), isFalse);
    });

    test('origin does not disturb the slot a digit owns (constraint 3)', () {
      for (var digit = 1; digit <= 9; digit++) {
        expect(
          NoteSet.slotOf(digit),
          NoteSet.slotOf(digit),
          reason: 'the slot is a function of the digit and nothing else',
        );
      }
      // Asked of the digit, never of the set — so a set holding generated
      // candidates cannot place one anywhere different.
      final mixed = NoteSet.of(const <int>[1, 5, 9]).withGenerated(4);
      expect(mixed.digits, <int>[1, 4, 5, 9]);
      expect(NoteSet.slotOf(5), (row: 1, column: 1));
    });

    test('two sets differing only in origin are not the same fact', () {
      expect(NoteSet.none.withGenerated(4), isNot(NoteSet.of(const <int>[4])));
    });

    test('length and isEmpty count candidates, not origins', () {
      final mixed = NoteSet.of(const <int>[1]).withGenerated(4);
      expect(mixed.length, 2);
      expect(mixed.isEmpty, isFalse);
      expect(NoteSet.none.isEmpty, isTrue);
    });
  });
}
