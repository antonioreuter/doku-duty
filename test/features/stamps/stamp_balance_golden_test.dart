import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/stamps/presentation/earn_notice_view.dart';
import 'package:doku_duty/features/stamps/presentation/stamp_balance.dart';

/// The balance line on the smallest phone the app targets (D-84), at 1x and
/// at the largest text size the app supports.
///
/// No colour of its own: it is ink on the surface, so no ninth hue can creep
/// in here (constraint 4), and the number is the whole of its meaning
/// (constraint 5).
void main() {
  setUpAll(_loadFonts);

  Future<void> pump(WidgetTester tester, {required double scale}) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DokuTheme.from(SeasonPalette(SeasonTheme.defaultTheme)),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 568),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            backgroundColor: PaletteToken.sand.colour,
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: <Widget>[StampBalance(balance: 1234)]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('at 1x', (tester) async {
    await pump(tester, scale: 1);

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(StampBalance),
      matchesGoldenFile('goldens/stamp_balance_1x.png'),
    );
  });

  testWidgets('at 5x it stacks and does not clip', (tester) async {
    await pump(tester, scale: 5);

    expect(tester.takeException(), isNull, reason: 'the balance overflowed');
    await expectLater(
      find.byType(StampBalance),
      matchesGoldenFile('goldens/stamp_balance_5x.png'),
    );
  });

  testWidgets('the earn notice at 5x wraps rather than clips', (tester) async {
    // The largest total one completion can earn: a perfect boss, 23.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DokuTheme.from(SeasonPalette(SeasonTheme.defaultTheme)),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(5),
          ),
          child: Scaffold(
            backgroundColor: PaletteToken.sand.colour,
            body: const Align(
              alignment: Alignment.topCenter,
              child: EarnNoticeView(total: 23, reduceMotion: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'the notice overflowed');
    expect(find.text('+23 Stamps'), findsOneWidget);
    await expectLater(
      find.byType(EarnNoticeView),
      matchesGoldenFile('goldens/earn_notice_5x.png'),
    );
  });
}

Future<void> _loadFonts() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
