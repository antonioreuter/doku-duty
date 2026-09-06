import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';

/// A swatch sheet of every token and every derived value.
///
/// Deliberately text-free: a golden that renders type is really a test of the
/// font, and this one exists to catch a value changing. Type has its own tests.
class _SwatchSheet extends StatelessWidget {
  const _SwatchSheet();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DokuColours.sand,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final token in PaletteToken.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Chip(token.colour),
                    _Chip(token.paleColour),
                    _Chip(token.depthColour),
                    _Chip(token.onColourText),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One swatch. An absent derived value leaves a gap rather than a substitute,
/// so the sheet shows which tokens define what.
class _Chip extends StatelessWidget {
  const _Chip(this.colour);

  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 32,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: colour,
        border: colour == null ? Border.all(color: DokuColours.hairline) : null,
      ),
    );
  }
}

void main() {
  testWidgets('the palette renders every token and derived value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topLeft, child: _SwatchSheet()),
      ),
    );

    await expectLater(
      find.byType(_SwatchSheet),
      matchesGoldenFile('goldens/palette.png'),
    );
  });
}
