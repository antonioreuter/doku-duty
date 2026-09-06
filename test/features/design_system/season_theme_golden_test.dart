import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';

/// A throwaway territory with obviously different surfaces, so the golden shows
/// at a glance which half of the palette moved. Not a real season — those are
/// data and arrive with add-season-map.
const SeasonTheme _duskTheme = SeasonTheme(
  id: 'dusk-test',
  name: 'Dusk (test)',
  bone: 0xD9C7B0,
  sand: 0xA89275,
  hairline: 0xC4AF95,
  surfaceDepth: 0x7A664D,
);

/// The same sheet under whichever season is passed in. Two surfaces move; the
/// six state colours do not (D-55).
class _ThemedSheet extends StatelessWidget {
  const _ThemedSheet(this.theme);

  final SeasonTheme theme;

  @override
  Widget build(BuildContext context) {
    final palette = SeasonPalette(theme);
    return ColoredBox(
      color: Color(0xFF000000 | palette.valueOf(PaletteToken.sand)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final token in PaletteToken.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Chip(palette.valueOf(token)),
                    _Chip(palette.paleOf(token)),
                    _Chip(palette.depthShadeOf(token)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.value);

  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 28,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: value == null ? null : Color(0xFF000000 | value!),
        border: value == null ? Border.all(color: DokuColours.hairline) : null,
      ),
    );
  }
}

void main() {
  for (final (label, theme) in <(String, SeasonTheme)>[
    ('default', SeasonTheme.defaultTheme),
    ('dusk', _duskTheme),
  ]) {
    testWidgets('the palette under the $label season', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: _ThemedSheet(theme),
          ),
        ),
      );
      await expectLater(
        find.byType(_ThemedSheet),
        matchesGoldenFile('goldens/season_$label.png'),
      );
    });
  }
}
