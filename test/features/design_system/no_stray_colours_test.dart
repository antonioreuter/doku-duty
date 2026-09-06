import 'dart:io';

import 'package:test/test.dart';

/// The enforcement for D-71, and the reason the token API exists at all.
///
/// A palette rule that lives only in a document survives until the first person
/// who needs "just this one shade". This walks the source and fails the build
/// instead.
void main() {
  // The single file allowed to construct a Color, plus the pure-Dart value
  // source it reads from.
  const allowed = <String>{
    'lib/features/design_system/presentation/doku_colours.dart',
    'lib/features/design_system/domain/palette.dart',
    'lib/features/design_system/domain/note_ink.dart',
  };

  // `Color(0x…)`, `Color.fromARGB(…)`, `Color.fromRGBO(…)`, and any use of the
  // Material colour constants, which would smuggle in a ninth hue by the back
  // door.
  final offenders = <RegExp, String>{
    RegExp(r'\bColor\s*\('): 'a Color literal',
    RegExp(r'\bColor\.from(ARGB|RGBO)\s*\('): 'a Color constructor',
    RegExp(r'\bColors\.\w+'): 'a Material colour constant',
    RegExp(r'\bColorSwatch\s*\('): 'a ColorSwatch',
  };

  test('no colour is constructed outside the token layer', () {
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (allowed.contains(entity.path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Comments may name a colour without creating one.
        final code = line.split('//').first;
        for (final entry in offenders.entries) {
          if (entry.key.hasMatch(code)) {
            violations.add(
              '${entity.path}:${i + 1} — ${entry.value}: ${line.trim()}',
            );
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Colour belongs to the design system. Add or reuse a token in '
          'PaletteToken rather than writing a value here — there are eight and '
          'there is no ninth (D-71).\n${violations.join('\n')}',
    );
  });

  test('the allowlist names only files that exist', () {
    for (final path in allowed) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
