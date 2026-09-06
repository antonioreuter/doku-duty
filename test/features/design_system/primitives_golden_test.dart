import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/presentation/doku_card.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/design_system/presentation/paper_grain.dart';
import 'package:doku_duty/features/design_system/presentation/pressable.dart';

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: DokuColours.sand,
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

void main() {
  setUpAll(_loadFont);

  testWidgets('the pressable at rest and pressed', (tester) async {
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final token in <PaletteToken>[
                PaletteToken.badgeGold,
                PaletteToken.cactusGreen,
                PaletteToken.sunsetRed,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Pressable(
                    onPressed: () {},
                    token: token,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Deputy 147',
                        style: TypeRole.label.style.copyWith(
                          color: token.onColourText,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/pressable_rest.png'),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable).first),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/pressable_pressed.png'),
    );
    await gesture.up();
  });

  testWidgets('the card, tilted, on grain', (tester) async {
    await tester.pumpWidget(
      _host(
        PaperGrain(
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var seed = 0; seed < 3; seed++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DokuCard(
                      tiltSeed: seed,
                      child: SizedBox(
                        width: 200,
                        child: Text(
                          'Filed under seed $seed',
                          style: TypeRole.body.style.copyWith(
                            color: DokuColours.duskInk,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(PaperGrain),
      matchesGoldenFile('goldens/card.png'),
    );
  });
}
