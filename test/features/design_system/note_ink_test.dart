import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/contrast.dart';
import 'package:doku_duty/features/design_system/domain/note_ink.dart';
import 'package:doku_duty/features/design_system/domain/palette.dart';

import 'support/colour_vision.dart';

void main() {
  group('the two note kinds', () {
    test('use the inks their roles reserve', () {
      expect(NoteInk.settled.token, PaletteToken.nightIndigo);
      expect(NoteInk.provisional.token, PaletteToken.turquoise);
    });

    // D-73. Asserted on the tokens rather than on a rendering, so it holds
    // before anything draws a grid.
    test('differ in at least one attribute that is not colour', () {
      const settled = NoteInk.settled;
      const provisional = NoteInk.provisional;
      expect(
        settled.value == provisional.value,
        isFalse,
        reason: 'the inks differ, but that is not enough on its own',
      );
      expect(
        settled.isUnderlined != provisional.isUnderlined,
        isTrue,
        reason: 'the two note kinds must differ without relying on hue',
      );
    });

    test('only the provisional note carries the rule', () {
      expect(NoteInk.provisional.isUnderlined, isTrue);
      expect(NoteInk.settled.isUnderlined, isFalse);
    });
  });

  group('colour vision deficiency', () {
    // The measurement that produced D-73: under every simulated deficiency the
    // two inks fall far below the 3:1 that would let hue carry the distinction.
    // The test asserts the failure is real, so nobody later removes the
    // underline believing the colours were enough.
    test('hue alone does not separate the inks under any deficiency', () {
      for (final vision in ColourVision.values) {
        final settled = vision.simulate(NoteInk.settled.value);
        final provisional = vision.simulate(NoteInk.provisional.value);
        final ratio = contrastRatio(settled, provisional);
        expect(
          ratio,
          lessThan(3.0),
          reason:
              'under ${vision.name} the inks are ${ratio.toStringAsFixed(2)} '
              'apart — if this ever exceeds 3.0, re-read D-73 before acting on it',
        );
      }
    });

    test('the underline separates them where hue does not', () {
      for (final vision in ColourVision.values) {
        // Whatever the simulated hues collapse to, the non-colour signal is
        // untouched by the simulation — that is the whole point of it.
        expect(
          NoteInk.settled.isUnderlined != NoteInk.provisional.isUnderlined,
          isTrue,
          reason: 'under ${vision.name}',
        );
      }
    });

    test('both inks stay legible on every cell background under deficiency', () {
      final budget = ContrastBudget.forText(sizePx: 11, weight: 400);
      for (final vision in ColourVision.values) {
        for (final ink in NoteInk.values) {
          for (final background in cellBackgrounds) {
            final ratio = contrastRatio(
              vision.simulate(ink.value),
              vision.simulate(background),
            );
            expect(
              ratio >= budget.minimumRatio,
              isTrue,
              reason:
                  '${ink.name} under ${vision.name} on '
                  '${background.toRadixString(16)} is ${ratio.toStringAsFixed(2)}',
            );
          }
        }
      }
    });
  });

  group('the underline geometry', () {
    test('is light enough not to compete with the digit', () {
      expect(provisionalUnderlineWeight, 1.0);
    });

    test('sits close enough to stay in the note\'s own slot', () {
      // A note slot is a third of a cell; the minimum cell is 44pt, so the
      // smallest slot is about 14.7pt. Weight plus offset must stay well inside.
      expect(
        provisionalUnderlineOffset + provisionalUnderlineWeight,
        lessThan(14.7 / 3),
      );
    });
  });
}
