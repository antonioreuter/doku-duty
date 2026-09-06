import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app builds for every flavour', (tester) async {
    for (final config in FlavourConfig.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [flavourConfigProvider.overrideWithValue(config)],
          child: const DokuDutyApp(),
        ),
      );

      expect(find.byType(DokuDutyApp), findsOneWidget);
    }
  });
}
