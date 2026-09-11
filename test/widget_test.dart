import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app builds for every flavour', (tester) async {
    for (final config in FlavourConfig.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            flavourConfigProvider.overrideWithValue(config),
            // The home screen reads the pack once it is on screen; a host test
            // has no application-support directory for the real opener.
            appDatabaseProvider.overrideWith(
              (ref) => AppDatabase(NativeDatabase.memory()),
            ),
          ],
          child: const DokuDutyApp(),
        ),
      );

      expect(find.byType(DokuDutyApp), findsOneWidget);
    }
  });
}
