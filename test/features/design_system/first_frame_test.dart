import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doku_duty/features/design_system/presentation/doku_theme.dart';

/// The design system must cost nothing at startup.
///
/// Everything added to the first-frame path is paid on every cold start for the
/// life of the app, and the 2-second budget the shell established has no slack
/// budgeted for a theme.
void main() {
  test('the design system places no network call, ever', () {
    // Not "no call at startup" — no call at all. Tokens are compiled in and the
    // font is an asset. Season definitions arrive over the network one day, but
    // through add-remote-config, and never on the path to a frame.
    final banned = <RegExp, String>{
      RegExp(r'\bhttp\b|HttpClient|dart:io'): 'a network client',
      RegExp(r'rootBundle|loadString|AssetBundle'): 'a runtime asset load',
      RegExp(r'\bgoogle_fonts\b'): 'a runtime font fetch',
      RegExp(r'loadLibrary'): 'a deferred component',
    };
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/design_system',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        for (final entry in banned.entries) {
          if (entry.key.hasMatch(code)) {
            offenders.add('${entity.path}:${i + 1} — ${entry.value}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  testWidgets('the theme resolves synchronously, with no future to await', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // If building the theme ever became asynchronous, this would not compile —
    // which is the assertion. A theme behind a FutureProvider is a spinner on
    // the first frame.
    final theme = container.read(appThemeProvider);
    expect(theme.scaffoldBackgroundColor, isNotNull);
  });

  testWidgets('the font is declared as a bundled asset, not fetched', (
    tester,
  ) async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/fonts/Nunito-Regular.ttf'));

    // Declarations only. The pubspec names google_fonts in a comment, to say
    // why it is not used — that comment is the opposite of a violation.
    final declarations = pubspec
        .split('\n')
        .map((line) => line.split('#').first)
        .join('\n');
    expect(declarations, isNot(contains('google_fonts')));
  });

  test('the bundled font files exist and are the three declared weights', () {
    for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
      final file = File('assets/fonts/Nunito-$weight.ttf');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(1000), reason: file.path);
    }
    // The licence ships with them.
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
  });
}
