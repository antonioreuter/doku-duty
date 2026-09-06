import 'dart:io';

import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/platform_shell/presentation/placeholder_screen.dart';
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
  Widget shellFor(FlavourConfig config) => ProviderScope(
    overrides: [flavourConfigProvider.overrideWithValue(config)],
    child: const DokuDutyApp(),
  );

  testWidgets('launches straight to the single route', (tester) async {
    await tester.pumpWidget(shellFor(FlavourConfig.prod));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderScreen), findsOneWidget);
  });

  testWidgets('the first frame needs no network', (tester) async {
    final overrides = _NoNetworkOverrides();

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(shellFor(FlavourConfig.prod));
      await tester.pumpAndSettle();
    }, createHttpClient: overrides.createHttpClient);

    expect(overrides.wasAsked, isFalse);
    expect(tester.takeException(), isNull);
    expect(find.byType(PlaceholderScreen), findsOneWidget);
  });

  testWidgets(
    'the route is interactive on the first pump, with no timed delay',
    (tester) async {
      await tester.pumpWidget(shellFor(FlavourConfig.prod));

      // No pumpAndSettle: a splash animation or a timed gate would leave the
      // screen absent here, and would also make pumpAndSettle time out.
      expect(find.byType(PlaceholderScreen), findsOneWidget);
    },
  );

  testWidgets('the shell shows no gameplay content yet', (tester) async {
    await tester.pumpWidget(shellFor(FlavourConfig.prod));
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
  });
}
