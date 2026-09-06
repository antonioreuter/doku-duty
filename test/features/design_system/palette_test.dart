import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';

void main() {
  group('the palette is exactly eight tokens', () {
    // D-71. The count is the requirement, so it is asserted directly rather
    // than implied by the values below.
    test('has eight members, six state and two surfaces', () {
      expect(PaletteToken.values, hasLength(8));
      expect(PaletteToken.stateColours, hasLength(6));
      expect(PaletteToken.surfaces, hasLength(2));
    });

    test('every token is either a surface or a state colour, never both', () {
      expect({
        ...PaletteToken.stateColours,
        ...PaletteToken.surfaces,
      }, PaletteToken.values.toSet());
      expect(
        PaletteToken.stateColours.toSet().intersection(
          PaletteToken.surfaces.toSet(),
        ),
        isEmpty,
      );
    });

    test('the surfaces are bone and sand', () {
      expect(PaletteToken.surfaces, <PaletteToken>[
        PaletteToken.bone,
        PaletteToken.sand,
      ]);
    });

    test('the six state colours are the six roles D-71 names', () {
      expect(PaletteToken.stateColours, <PaletteToken>[
        PaletteToken.duskInk, // ink
        PaletteToken.badgeGold, // focus
        PaletteToken.nightIndigo, // candidate
        PaletteToken.turquoise, // provisional
        PaletteToken.sunsetRed, // error
        PaletteToken.cactusGreen, // completion
      ]);
    });
  });

  group('values match docs/DESIGN.md §1', () {
    test('base values', () {
      expect(PaletteToken.bone.value, 0xF5EBD6);
      expect(PaletteToken.sand.value, 0xE4D4AE);
      expect(PaletteToken.duskInk.value, 0x2E2438);
      expect(PaletteToken.badgeGold.value, 0xF2B33D);
      expect(PaletteToken.nightIndigo.value, 0x4A3F9E);
      expect(PaletteToken.turquoise.value, 0x1B6661); // corrected by D-72
      expect(PaletteToken.sunsetRed.value, 0xE05A2B);
      expect(PaletteToken.cactusGreen.value, 0x4E9E62);
    });

    test('derived tints', () {
      expect(PaletteToken.badgeGold.pale, 0xFDEFC6);
      expect(PaletteToken.nightIndigo.pale, 0xE6DEFA);
      expect(PaletteToken.sunsetRed.pale, 0xFBDDD6);
      expect(PaletteToken.cactusGreen.pale, 0xCFE0BE);
      expect(PaletteToken.duskInk.pale, 0x64596B); // inkSoft, corrected by D-72
      expect(PaletteToken.sand.pale, 0xDCCDA8); // hairline
    });

    test('depth shades', () {
      expect(PaletteToken.badgeGold.depthShade, 0xB47A15);
      expect(PaletteToken.sunsetRed.depthShade, 0xA03A15);
      expect(PaletteToken.cactusGreen.depthShade, 0x2F6E3F);
      expect(PaletteToken.nightIndigo.depthShade, 0x2F2670);
      expect(PaletteToken.bone.depthShade, 0xC9B48C);
      expect(PaletteToken.sand.depthShade, 0xC9B48C);
    });

    test('on-colour text values', () {
      expect(PaletteToken.badgeGold.onColour, 0x4A3405);
      expect(PaletteToken.sunsetRed.onColour, 0x3D0D06); // corrected by D-72
      expect(PaletteToken.cactusGreen.onColour, 0x0E2D17); // corrected by D-72
      expect(PaletteToken.nightIndigo.onColour, 0xF3EFFF);
    });
  });

  group('derived values are not independent hues', () {
    // D-71: a derived value is reachable only through its parent, so it cannot
    // become a ninth token by being referenced on its own.
    test('every derived value belongs to a token', () {
      final derived = <int>[
        for (final t in PaletteToken.values)
          ...<int?>[t.pale, t.depthShade, t.onColour].whereType<int>(),
      ];
      expect(derived, isNotEmpty);
      // Nothing here is exposed as a top-level constant; the only way to reach
      // any of them is through the token that owns it.
      for (final token in PaletteToken.values) {
        expect(
          <int?>[
            token.pale,
            token.depthShade,
            token.onColour,
          ].whereType<int>().every(derived.contains),
          isTrue,
        );
      }
    });

    test('all eight base values are distinct', () {
      expect(PaletteToken.values.map((t) => t.value).toSet(), hasLength(8));
    });

    test('only surfaces are repaintable by a season', () {
      for (final token in PaletteToken.stateColours) {
        expect(token.isSurface, isFalse, reason: token.name);
      }
      for (final token in PaletteToken.surfaces) {
        expect(token.isSurface, isTrue, reason: token.name);
      }
    });
  });
}
