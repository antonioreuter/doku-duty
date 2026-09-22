import 'dart:io';

import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/grid_input/presentation/free_play_screen.dart';
import 'package:doku_duty/features/season_map/presentation/trail_screen.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails the moment anything asks for an HTTP client.
class _NoNetworkOverrides extends HttpOverrides {
  bool wasAsked = false;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    wasAsked = true;
    throw StateError('the shell must not open a network connection');
  }
}

void main() {
  // In memory, because the **trail** reads progress, and **free play** reads
  // the pack, a frame after the first one. The real opener wants an application-support directory, which a host
  // test does not have — and what these tests are about is the shell, not
  // storage.
  Widget shellFor(FlavourConfig config) => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(config),
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase(NativeDatabase.memory()),
      ),
    ],
    child: const DokuDutyApp(),
  );

  testWidgets('launches straight to the trail', (tester) async {
    await tester.pumpWidget(shellFor(FlavourConfig.prod));
    await tester.pumpAndSettle();

    expect(find.byType(TrailScreen), findsOneWidget);
    // **Free play** is built alongside it and offstage, so switching to it
    // costs no rebuild and loses no scroll position (D-111).
    expect(find.byType(FreePlayScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('the first frame needs no network', (tester) async {
    final overrides = _NoNetworkOverrides();

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(shellFor(FlavourConfig.prod));
      await tester.pumpAndSettle();
    }, createHttpClient: overrides.createHttpClient);

    expect(overrides.wasAsked, isFalse);
    expect(tester.takeException(), isNull);
    expect(find.byType(TrailScreen), findsOneWidget);
  });

  testWidgets(
    'the route is interactive on the first pump, with no timed delay',
    (tester) async {
      await tester.pumpWidget(shellFor(FlavourConfig.prod));

      // No pumpAndSettle: a splash animation or a timed gate would leave the
      // screen absent here, and would also make pumpAndSettle time out.
      expect(find.byType(TrailScreen), findsOneWidget);
    },
  );

  // `add-grid-and-input` replaced the empty placeholder with a **rank** picker;
  // `add-season-map` replaced that as home with the **trail**. What the shell
  // must still never do is reach for content on the way to the first frame: the
  // 42 **node**s come from the **season**, which is compiled in or already in
  // memory, and completion state is read from the database a frame later.
  testWidgets('the first frame needs no content', (tester) async {
    await tester.pumpWidget(shellFor(FlavourConfig.prod));

    expect(find.byType(TrailScreen), findsOneWidget);
    expect(find.text('Dust Gulch'), findsOneWidget);
    expect(find.text('Node 1'), findsOneWidget);
    expect(
      find.text('Trail progress'),
      findsOneWidget,
      reason: 'the header is there, with no count until progress is read',
    );
  });

  // The other half of the same rule, on the other tab. **Free play** is built
  // on the first frame too, and must be just as content-free on it.
  testWidgets('free play needs no content on the first frame', (tester) async {
    await tester.pumpWidget(shellFor(FlavourConfig.prod));

    Finder offstage(String text) => find.text(text, skipOffstage: false);
    expect(offstage('Greenhorn rank'), findsOneWidget);
    expect(offstage('Legend rank'), findsOneWidget);
    expect(
      offstage('Nothing left here for now'),
      findsNothing,
      reason: 'absence is only known once the pack has been read',
    );
  });
}
