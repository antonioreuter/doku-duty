import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/pad_tools.dart';

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Widget _host({
  bool notesMode = false,
  bool provisionalInk = false,
  bool hasProvisionalNotes = false,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: DokuColours.sand,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NumberPad(onKey: (_) {}),
            PadTools(
              notesMode: notesMode,
              provisionalInk: provisionalInk,
              hasProvisionalNotes: hasProvisionalNotes,
              onKey: (_) {},
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadFont);

  Future<void> pumpAndMatch(
    WidgetTester tester,
    Widget widget,
    String name,
  ) async {
    await tester.pumpWidget(widget);
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  // The state a player meets on opening a puzzle: three rows, three named
  // tools, and nothing on screen they have no use for yet.
  testWidgets('the default pad', (tester) async {
    await pumpAndMatch(tester, _host(), 'pad_default');
  });

  testWidgets('notes mode, with the ink control', (tester) async {
    await pumpAndMatch(tester, _host(notesMode: true), 'pad_notes_mode');
  });

  testWidgets('the provisional ink in force', (tester) async {
    await pumpAndMatch(
      tester,
      _host(notesMode: true, provisionalInk: true),
      'pad_provisional_ink',
    );
  });

  // The only state that has four rows, and it exists only while there is a
  // chain test to end.
  testWidgets('a chain test running', (tester) async {
    await pumpAndMatch(
      tester,
      _host(notesMode: true, provisionalInk: true, hasProvisionalNotes: true),
      'pad_chain_test',
    );
  });
}
