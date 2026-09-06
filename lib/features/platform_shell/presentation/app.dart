import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_theme.dart';
import '../application/flavour_provider.dart';
import '../application/router_provider.dart';

/// The application shell.
///
/// Styling comes from the design system's tokens, resolved for the active
/// season. Nothing here picks a colour, a size, or a radius of its own.
class DokuDutyApp extends ConsumerWidget {
  const DokuDutyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(flavourConfigProvider);

    return MaterialApp.router(
      title: config.appName,
      theme: ref.watch(appThemeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
