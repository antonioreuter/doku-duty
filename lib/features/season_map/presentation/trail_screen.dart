import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../grid_input/application/grid_providers.dart';
import '../../platform_shell/routing/app_router.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../../rank_progression/domain/player_rank.dart';
import '../application/season_providers.dart';
import '../domain/node_type.dart';
import '../domain/season.dart';
import '../domain/trail_progress.dart';
import 'trail_node_marker.dart';

/// The **trail** — the spine of the session.
///
/// **Its structure paints on the first frame.** The **season** is synchronous
/// (it is either compiled in or already in memory from the config), so all 42
/// **node**s are on screen immediately with no state applied. Completion, the
/// player's **rank**, and the puzzle behind each **node** all arrive after,
/// which is the same pattern **free play** uses for the **rank** mark. A test
/// asserts nothing reads the database on the path to that frame.
class TrailScreen extends ConsumerStatefulWidget {
  const TrailScreen({super.key});

  @override
  ConsumerState<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends ConsumerState<TrailScreen> {
  /// Whether the first frame has been painted.
  ///
  /// The **season** needs nothing, so the trail is on screen immediately.
  /// Progress lives in the database, and opening it is not allowed on the path
  /// to the first frame — a test asserts the shell never does.
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
    final season = ref.watch(currentSeasonProvider);

    final progress = _pastFirstFrame
        ? ref.watch(trailProgressProvider)
        : const AsyncValue<TrailProgress>.loading();
    final playerRank = _pastFirstFrame
        ? ref.watch(playerRankProvider)
        : const AsyncValue<Rank>.loading();

    return Scaffold(
      appBar: AppBar(
        // The territory's name is *not* here. An `AppBar` title is one line
        // that ellipsises, and "Dust Gulch" is already cut at 2x on the
        // smallest phone the app targets — a screen named after a place, with
        // the place truncated. It lives in the header below instead, where it
        // can wrap as far as it needs to.
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('open-settings'),
            icon: const Icon(Icons.settings),
            onPressed: () => Routes.goSettings(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: PaperGrain(
        // The header scrolls with the trail rather than being pinned above it.
        // Pinned, it overflows: at 3x text on the smallest phone the app
        // targets (D-84) there is not room for both a fixed header and a node,
        // and the header is the half that can afford to move. A test at every
        // text size from 1x to 5x is what found this.
        child: ListView(
          key: const ValueKey<String>('trail-path'),
          padding: const EdgeInsets.only(bottom: 16),
          children: <Widget>[
            _TrailHeader(season: season, progress: progress.value),
            for (final node in season.nodes)
              _TrailRow(
                node: node,
                // Until progress has been read nothing is marked completed and
                // nothing is current — which is the right way round, because an
                // unread trail offers no taps rather than offering the wrong
                // ones.
                state: progress.value?.stateOf(node.position),
                isAbovePlayerRank:
                    playerRank.hasValue &&
                    node.rank != null &&
                    PlayerRank.above(playerRank.value!).contains(node.rank),
                onTap: _openerFor(node, progress.value),
              ),
          ],
        ),
      ),
    );
  }

  /// What tapping this **node** does, or null where it does nothing yet.
  ///
  /// Null covers two different situations and deliberately looks the same in
  /// both: a **node** the player has not reached, and a **trail** whose
  /// progress has not been read. Neither is an error and neither is announced.
  VoidCallback? _openerFor(SeasonNode node, TrailProgress? progress) {
    if (progress == null || !progress.isOpenable(node.position)) return null;
    return () => _open(node);
  }

  Future<void> _open(SeasonNode node) async {
    // Which **node** the player is on, so completing the board completes this
    // **node** and not another — and so a board played in **free play**
    // afterwards completes none.
    ref.read(activeNodeProvider.notifier).enter(node.position);

    if (!node.type.bearsPuzzle) {
      // A **chest node** is opened, never played and never failed. It needs no
      // puzzle, no network, and no payment — opening it *is* the reward. It
      // grants no currency until `add-stamps`: D-66 wants exactly one place
      // that can mint a **stamp**, and this is not yet it.
      await _openChest(node);
      return;
    }

    if (node.type == NodeType.boss) {
      // Counted, never enforced. D-22 gives a **boss node** unlimited free
      // retries, so nothing reads this before deciding whether to open.
      final seasonId = ref.read(currentSeasonProvider).id;
      await ref
          .read(seasonRepositoryProvider)
          .recordBossAttempt(seasonId: seasonId, position: node.position);
    }

    final puzzle = await ref.read(nodePuzzleProvider(node.position).future);
    if (!mounted) return;

    if (puzzle == null) {
      // Nothing left at this **rank** is an ordinary absence, not a wall
      // (constraint 1). Running out is how a top-up is triggered.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing left at this rank for now')),
      );
      ref.read(activeNodeProvider.notifier).clear();
      return;
    }

    Routes.goPuzzle(context, puzzle.id);
  }

  Future<void> _openChest(SeasonNode node) async {
    final seasonId = ref.read(currentSeasonProvider).id;
    await ref
        .read(seasonRepositoryProvider)
        .completeNode(seasonId: seasonId, position: node.position);
    // The read that says where the player stands is cached and this screen
    // stays mounted, so the write has to say so (D-105).
    ref.invalidate(trailProgressProvider);
    ref.read(activeNodeProvider.notifier).clear();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chest opened')));
  }
}

class _TrailHeader extends StatelessWidget {
  const _TrailHeader({required this.season, required this.progress});

  final Season season;
  final TrailProgress? progress;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = season.daysRemainingAt(DateTime.now());
    final completed = progress?.completedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            season.name,
            key: const ValueKey<String>('trail-season-name'),
            style: TypeRole.screenTitle.style,
          ),
          const SizedBox(height: 2),
          // Null days means the six weeks have elapsed with no successor, and
          // nothing is shown rather than a negative countdown. A clock reading
          // "-4 days" tells a player they are late for something that cannot be
          // late, and constraint 1 has no room for a timer that can beat you
          // (D-109).
          if (daysRemaining != null)
            Text(
              '$daysRemaining days left',
              key: const ValueKey<String>('trail-days-remaining'),
              style: TypeRole.label.style,
            ),
          Text(
            completed == null
                ? 'Trail progress'
                : 'Trail progress  $completed / ${season.nodes.length}',
            key: const ValueKey<String>('trail-progress'),
            style: TypeRole.body.style,
          ),
        ],
      ),
    );
  }
}

class _TrailRow extends StatelessWidget {
  const _TrailRow({
    required this.node,
    required this.state,
    required this.isAbovePlayerRank,
    required this.onTap,
  });

  final SeasonNode node;
  final NodeState? state;
  final bool isAbovePlayerRank;
  final VoidCallback? onTap;

  /// The trail winds. Alternating the alignment is what makes it a path rather
  /// than a list, and it costs nothing to lay out — the artwork the mockup
  /// draws around it (the cactus, the wagon, Biscuit) is `add-running-gags`.
  Alignment get _alignment =>
      node.position.isOdd ? Alignment.centerLeft : Alignment.centerRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Align(
        alignment: _alignment,
        child: TrailNodeMarker(
          // On the marker itself rather than on anything inside it, so a test
          // asking for node 14 gets the widget that knows node 14's state.
          key: ValueKey<String>('trail-node-${node.position}'),
          position: node.position,
          type: node.type,
          state: state,
          isAbovePlayerRank: isAbovePlayerRank,
          onTap: onTap,
        ),
      ),
    );
  }
}
