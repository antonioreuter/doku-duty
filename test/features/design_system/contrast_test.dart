import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/contrast.dart';

void main() {
  group('relativeLuminance', () {
    test('is 1.0 for white and 0.0 for black', () {
      expect(relativeLuminance(0xFFFFFF), closeTo(1.0, 1e-9));
      expect(relativeLuminance(0x000000), closeTo(0.0, 1e-9));
    });
  });

  group('contrastRatio', () {
    test('white against black is the 21:1 maximum', () {
      expect(contrastRatio(0xFFFFFF, 0x000000), closeTo(21.0, 1e-6));
    });

    test('is symmetric — order of the pair does not matter', () {
      expect(
        contrastRatio(0x2E2438, 0xF5EBD6),
        closeTo(contrastRatio(0xF5EBD6, 0x2E2438), 1e-12),
      );
    });

    test('a colour against itself is 1:1', () {
      expect(contrastRatio(0x4A3F9E, 0x4A3F9E), closeTo(1.0, 1e-9));
    });

    test('duskInk on bone is 12.44:1', () {
      expect(contrastRatio(0x2E2438, 0xF5EBD6), closeTo(12.44, 0.01));
    });

    test('nightIndigo on bone is 7.11:1', () {
      expect(contrastRatio(0x4A3F9E, 0xF5EBD6), closeTo(7.11, 0.01));
    });
  });

  group('ContrastBudget', () {
    test('small text needs 4.5:1', () {
      expect(ContrastBudget.smallText.minimumRatio, 4.5);
    });

    test('large text and non-text need 3:1', () {
      expect(ContrastBudget.largeText.minimumRatio, 3.0);
      expect(ContrastBudget.nonText.minimumRatio, 3.0);
    });

    test('budget for a type role follows size and weight', () {
      // Below 18px is small text regardless of weight.
      expect(
        ContrastBudget.forText(sizePx: 15, weight: 400),
        ContrastBudget.smallText,
      );
      // 18px or above is large text.
      expect(
        ContrastBudget.forText(sizePx: 18, weight: 400),
        ContrastBudget.largeText,
      );
      // 14px or above counts as large only when bold.
      expect(
        ContrastBudget.forText(sizePx: 14, weight: 700),
        ContrastBudget.largeText,
      );
      expect(
        ContrastBudget.forText(sizePx: 14, weight: 600),
        ContrastBudget.smallText,
      );
    });
  });
}
