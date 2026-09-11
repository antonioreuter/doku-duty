import 'package:flutter/services.dart';

import '../domain/pack.dart';

/// Where a **pack** is read from.
///
/// An interface so the installer can be tested without an asset bundle, and so
/// a later change can add a downloaded source without touching the installer.
abstract interface class PackSource {
  /// Never throws. A missing or corrupt **pack** comes back as an
  /// [InvalidPack], because an installer running after the first frame has
  /// nothing useful to do with an exception.
  Future<PackParseResult> read();
}

/// The **pack** bundled inside the app (D-32).
///
/// No network is involved, which is the point: a fresh install in airplane mode
/// has the full six **rank**s of content.
final class BundledPackSource implements PackSource {
  const BundledPackSource({this.assetPath = defaultAssetPath, this.bundle});

  /// Declared in `pubspec.yaml`. A path that is generated but never bundled is
  /// invisible to every host test, because the host reads it from disk — the
  /// shape of defect D-77 records.
  static const String defaultAssetPath = 'assets/packs/frontier-1.json';

  final String assetPath;

  /// Overridden only by tests; the app reads the real bundle.
  final AssetBundle? bundle;

  @override
  Future<PackParseResult> read() async {
    final String source;
    try {
      source = await (bundle ?? rootBundle).loadString(assetPath);
    } on Object catch (error) {
      return InvalidPack(
        problem: PackProblem.unreadable,
        description: 'could not read $assetPath: $error',
      );
    }
    return Pack.parse(source);
  }
}
