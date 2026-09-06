import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/contrast.dart';
import 'package:doku_duty/features/design_system/domain/palette.dart';

/// Every foreground/background pair the design actually uses, with the budget
/// set by the size it is used at. This is the enforcement for D-72: a value that
/// drifts below its budget fails the build rather than shipping.
void main() {
  group('text on cell backgrounds', () {
    // Grid value: 22px, so the large-text budget applies.
    test('a grid value is legible on every cell background', () {
      final budget = ContrastBudget.forText(sizePx: 22, weight: 600);
      for (final background in cellBackgrounds) {
        expect(
          budget.isMetBy(PaletteToken.duskInk.value, background),
          isTrue,
          reason:
              'duskInk on ${_hex(background)} is '
              '${contrastRatio(PaletteToken.duskInk.value, background).toStringAsFixed(2)}',
        );
      }
    });

    // Grid note: 11px, so the small-text budget applies. This is the pair that
    // failed — turquoise was 2.21–2.70 across these five backgrounds.
    test('both note inks are legible on every cell background', () {
      final budget = ContrastBudget.forText(sizePx: 11, weight: 400);
      for (final ink in <PaletteToken>[
        PaletteToken.nightIndigo,
        PaletteToken.turquoise,
      ]) {
        for (final background in cellBackgrounds) {
          expect(
            budget.isMetBy(ink.value, background),
            isTrue,
            reason:
                '${ink.name} on ${_hex(background)} is '
                '${contrastRatio(ink.value, background).toStringAsFixed(2)}',
          );
        }
      }
    });
  });

  group('text on surfaces', () {
    test('primary text is legible on both surfaces', () {
      final budget = ContrastBudget.forText(sizePx: 15, weight: 400);
      for (final surface in PaletteToken.surfaces) {
        expect(
          budget.isMetBy(PaletteToken.duskInk.value, surface.value),
          isTrue,
          reason: 'duskInk on ${surface.name}',
        );
      }
    });

    test('secondary text is legible on both surfaces', () {
      final budget = ContrastBudget.forText(sizePx: 12, weight: 500);
      final inkSoft = PaletteToken.duskInk.pale!;
      for (final surface in PaletteToken.surfaces) {
        expect(
          budget.isMetBy(inkSoft, surface.value),
          isTrue,
          reason:
              'inkSoft on ${surface.name} is '
              '${contrastRatio(inkSoft, surface.value).toStringAsFixed(2)}',
        );
      }
    });
  });

  group('on-colour text', () {
    test('every token defining an on-colour meets the label budget', () {
      final budget = ContrastBudget.forText(sizePx: 12, weight: 500);
      for (final token in PaletteToken.values) {
        final onColour = token.onColour;
        if (onColour == null) continue;
        expect(
          budget.isMetBy(onColour, token.value),
          isTrue,
          reason:
              'on-colour for ${token.name} is '
              '${contrastRatio(onColour, token.value).toStringAsFixed(2)}',
        );
      }
    });
  });

  group('deliberate exemptions', () {
    // Recorded in D-72 so the next person to measure it does not "fix" it.
    // The hairline is not text, and unit structure is carried by the 2.5px
    // duskInk box dividers at 12.44:1, not by cell separators.
    test('the interior hairline is exempt and still measured', () {
      final hairline = PaletteToken.sand.pale!;
      expect(hairline, 0xDCCDA8);
      expect(
        contrastRatio(hairline, PaletteToken.bone.value),
        closeTo(1.33, 0.01),
      );
    });
  });
}

String _hex(int rgb) =>
    '#${rgb.toRadixString(16).toUpperCase().padLeft(6, '0')}';
