import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';

void main() {
  // A throwaway theme with obviously different surfaces. Not a real territory —
  // seasons are data and arrive with add-season-map (change 15).
  const testTheme = SeasonTheme(
    id: 'test',
    name: 'Test territory',
    bone: 0x123456,
    sand: 0x654321,
  );

  group('a season repaints surfaces', () {
    test('the default theme resolves to the documented values', () {
      const palette = SeasonPalette(SeasonTheme.defaultTheme);
      for (final token in PaletteToken.values) {
        expect(palette.valueOf(token), token.value, reason: token.name);
      }
    });

    test('a season theme changes both surfaces', () {
      const palette = SeasonPalette(testTheme);
      expect(palette.valueOf(PaletteToken.bone), 0x123456);
      expect(palette.valueOf(PaletteToken.sand), 0x654321);
    });

    // D-55. The muscle memory that makes an expert board readable never forms
    // if completion or error colour moves with the season.
    test('every state colour is identical under any season', () {
      const defaultPalette = SeasonPalette(SeasonTheme.defaultTheme);
      const seasonPalette = SeasonPalette(testTheme);
      for (final token in PaletteToken.stateColours) {
        expect(
          seasonPalette.valueOf(token),
          defaultPalette.valueOf(token),
          reason: '${token.name} moved with the season',
        );
        expect(seasonPalette.valueOf(token), token.value);
      }
    });

    test('derived values of a state colour are also fixed', () {
      const palette = SeasonPalette(testTheme);
      for (final token in PaletteToken.stateColours) {
        expect(palette.paleOf(token), token.pale, reason: token.name);
        expect(
          palette.depthShadeOf(token),
          token.depthShade,
          reason: token.name,
        );
        expect(palette.onColourOf(token), token.onColour, reason: token.name);
      }
    });
  });

  group('a season theme has nowhere to put a state colour', () {
    // The structural half of D-55: the guarantee is the absence of a field, so
    // this asserts the shape of the type rather than a value it produced.
    test('it carries exactly the two surfaces and its props', () {
      const theme = testTheme;
      // Surfaces are named individually — there is no map, no index, and no
      // token-keyed setter through which a state colour could arrive.
      expect(theme.bone, 0x123456);
      expect(theme.sand, 0x654321);
      expect(theme.props, isEmpty);
    });

    test('surface-derived values repaint with their surface', () {
      const repainted = SeasonTheme(
        id: 'dusk',
        name: 'Dusk',
        bone: 0x123456,
        sand: 0x654321,
        hairline: 0x445566,
        surfaceDepth: 0x112233,
      );
      const palette = SeasonPalette(repainted);
      expect(palette.paleOf(PaletteToken.sand), 0x445566);
      expect(palette.depthShadeOf(PaletteToken.sand), 0x112233);
      expect(palette.depthShadeOf(PaletteToken.bone), 0x112233);
    });

    test('a season that omits them keeps the default surface values', () {
      const palette = SeasonPalette(testTheme);
      expect(palette.paleOf(PaletteToken.sand), PaletteToken.sand.pale);
      expect(
        palette.depthShadeOf(PaletteToken.bone),
        PaletteToken.bone.depthShade,
      );
    });

    test('props choose from the eight tokens rather than free colours', () {
      const themed = SeasonTheme(
        id: 'props',
        name: 'Props',
        bone: 0xF5EBD6,
        sand: 0xE4D4AE,
        props: <String, PaletteToken>{'cactus': PaletteToken.cactusGreen},
      );
      expect(themed.props['cactus'], PaletteToken.cactusGreen);
      // The value type is the token enum, so a prop cannot introduce a hue.
      expect(themed.props.values.every(PaletteToken.values.contains), isTrue);
    });
  });
}
