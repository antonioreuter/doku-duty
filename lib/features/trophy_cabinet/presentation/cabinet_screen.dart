import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../persistence/data/app_database.dart';
import '../../technique_tutorials/presentation/lessons_screen.dart';
import '../application/cabinet_providers.dart';
import '../data/statistics_repository.dart';
import '../domain/award.dart';
import 'shelf.dart';
import 'statistics_panel.dart';

/// The **cabinet** — the permanent layer of D-17's three.
///
/// **Nothing here is read before the first frame.** The shell keeps every
/// destination built at once, so this screen builds on launch whether or not
/// the player ever opens it, and all of its state lives in the database.
/// Reading eagerly would open the database on the path to the first frame,
/// which `lazy_open_test.dart` forbids. The **trail** and the **daily
/// challenge** both defer the same way.
class CabinetScreen extends ConsumerStatefulWidget {
  const CabinetScreen({super.key});

  @override
  ConsumerState<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends ConsumerState<CabinetScreen> {
  bool _pastFirstFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pastFirstFrame = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(awardCatalogueProvider);

    final earned = _pastFirstFrame
        ? ref.watch(earnedTrophiesProvider)
        : const AsyncValue<List<Trophy>>.loading();
    final stats = _pastFirstFrame
        ? ref.watch(cabinetStatisticsProvider)
        : const AsyncValue<CabinetStatistics>.loading();

    // The **award**s are known without reading anything, so the shelf has its
    // shape on the first frame and fills in rather than appearing. An
    // **unfiled** **award** is the correct thing to show before the read
    // lands: it is what the player has, until the database says otherwise.
    final earnedIds = <String>{
      for (final trophy in earned.value ?? const <Trophy>[]) trophy.awardId,
    };

    return Scaffold(
      // No app bar, so nothing keeps the title clear of the status bar on its
      // own — the same omission that drew the **daily challenge**'s title
      // through the clock on a real device.
      body: SafeArea(
        child: PaperGrain(
          child: ListView(
            key: const ValueKey<String>('cabinet-screen'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              Text('Cabinet', style: TypeRole.screenTitle.style),
              const SizedBox(height: 12),
              Shelf(
                awards: catalogue.awards,
                earnedIds: earnedIds,
                earned: earned.value ?? const <Trophy>[],
              ),
              const SizedBox(height: 24),
              StatisticsPanel(
                statistics: stats.value ?? const CabinetStatistics.empty(),
              ),
              const SizedBox(height: 24),
              _LessonsRow(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The **lesson** list, which `docs/SPEC.md` §5.1 puts here.
///
/// It was parked behind a settings row by `add-technique-tutorials`, which
/// built it self-contained so this change could take it whole rather than
/// rebuild it. This is that.
class _LessonsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const ValueKey<String>('cabinet-open-lessons'),
      contentPadding: EdgeInsets.zero,
      title: Text('Lessons', style: TypeRole.body.style),
      subtitle: Text(
        'Replay any technique lesson, met or not.',
        style: TypeRole.label.style,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const LessonsScreen()),
      ),
    );
  }
}

/// Exposed so the shelf can be built from a list the screen already has.
typedef AwardList = List<Award>;
