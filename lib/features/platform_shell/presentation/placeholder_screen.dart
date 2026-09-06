import 'package:flutter/material.dart';

import '../../design_system/presentation/paper_grain.dart';

/// The empty screen the app launches to.
///
/// No splash animation and no timed delay: it is interactive on the first
/// frame, which is what the cold-start budget is measured against.
///
/// Still empty — the design system gives it a surface and a grain, not content.
/// The season map, the grid, and the cabinet arrive with the changes that own
/// them.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Surface colour comes from the theme's scaffold background, which the
    // season paints. The grain sits on top of it and behind nothing.
    return const Scaffold(body: PaperGrain(child: SizedBox.expand()));
  }
}
