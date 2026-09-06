import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';

/// The fixture is what the first real upload should be checked against, so it
/// has to actually be valid rather than merely look it.
void main() {
  final fixture = File(
    'test/features/remote_config/fixtures/config.json',
  ).readAsStringSync();

  test('the published fixture parses', () {
    expect(RemoteConfigParser.parse(fixture), isNotNull);
  });

  test('it carries every key the client knows about', () {
    // A fixture that silently stopped covering a key would stop being a
    // specification for the file.
    for (final value in ConfigValue.values) {
      expect(fixture, contains(value.key), reason: value.key);
    }
  });

  test('its values are exactly the documented defaults', () {
    final config = RemoteConfigParser.parse(fixture)!;
    for (final value in ConfigValue.values) {
      expect(config[value], value.defaultValue, reason: value.key);
    }
    expect(config.schemaVersion, 1);
  });

  test('the publishing note documents every key', () {
    final doc = File(
      'lib/features/remote_config/PUBLISHING.md',
    ).readAsStringSync();
    for (final value in ConfigValue.values) {
      expect(
        doc,
        contains(value.key),
        reason: '${value.key} is publishable but undocumented',
      );
    }
  });
}
