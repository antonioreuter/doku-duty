import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_type.dart';

void main() {
  group('the six roles', () {
    test('there are exactly six, and no more', () {
      expect(TypeRole.values, hasLength(6));
    });

    // docs/DESIGN.md §2. Sizes and weights are the contract; the grid's
    // hit-testing and the note slots are laid out against them.
    test('each role has the documented size and weight', () {
      const expected = <TypeRole, (double, FontWeight)>{
        TypeRole.gridValue: (22, FontWeight.w600),
        TypeRole.gridNote: (11, FontWeight.w400),
        TypeRole.screenTitle: (24, FontWeight.w600),
        TypeRole.body: (15, FontWeight.w400),
        TypeRole.label: (12, FontWeight.w500),
        TypeRole.characterLine: (15, FontWeight.w400),
      };
      for (final role in TypeRole.values) {
        final (size, weight) = expected[role]!;
        expect(role.style.fontSize, size, reason: role.name);
        expect(role.style.fontWeight, weight, reason: role.name);
      }
    });

    test('every role uses the bundled family', () {
      for (final role in TypeRole.values) {
        expect(role.style.fontFamily, DokuType.family, reason: role.name);
      }
    });

    test('the family is the one bundled in pubspec, not a system face', () {
      expect(DokuType.family, 'Nunito');
    });

    // Only the three weights declared in pubspec are available; asking for a
    // fourth gets a synthesised approximation, which looks wrong at 11px.
    test('no role asks for a weight that is not bundled', () {
      const bundled = <FontWeight>[
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
      ];
      for (final role in TypeRole.values) {
        expect(bundled, contains(role.style.fontWeight), reason: role.name);
      }
    });
  });

  group('digits do not shift as values change', () {
    // A proportional 1 makes a column of grid values jitter as digits are
    // placed. Tabular figures are what stop the board twitching.
    test('the grid roles ask for tabular figures', () {
      for (final role in <TypeRole>[TypeRole.gridValue, TypeRole.gridNote]) {
        expect(
          role.style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: role.name,
        );
      }
    });
  });

  group('scaling', () {
    test(
      'a role can be resolved at a text scale without losing its family',
      () {
        final scaled = TypeRole.body.scaled(1.5);
        expect(scaled.fontSize, 15 * 1.5);
        expect(scaled.fontFamily, DokuType.family);
        expect(scaled.fontWeight, FontWeight.w400);
      },
    );
  });
}
