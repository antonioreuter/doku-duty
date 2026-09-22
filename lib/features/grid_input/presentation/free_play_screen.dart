import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../persistence/data/pack_repository.dart' show StoredPuzzle;
import '../../platform_shell/routing/app_router.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../../rank_progression/domain/player_rank.dart';
import '../../season_map/application/season_providers.dart';
import '../application/grid_providers.dart';

/// **Free play** — six entries, one per **rank**.
///
/// The **trail** is the spine of the session; this is what keeps the ladder
/// open beside it (D-111). It is not scaffolding, and the distinction matters:
/// a **trail** is walked in order (D-108), so on a fresh **season** a Legend
/// puzzle is forty **node**s away. Deleting this screen would make
/// `grid-input`'s "a puzzle can be reached at any rank" false and re-impose
/// exactly the gate D-103 refused, wearing a map instead of a list.
///
/// A puzzle solved here writes a **solve record** like any other and advances
/// no **season**, which is what keeps D-17's permanent and seasonal layers the
/// separate things they are.
class FreePlayScreen extends ConsumerStatefulWidget {
  const FreePlayScreen({super.key});

  @override
  ConsumerState<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends ConsumerState<FreePlayScreen> {
  /// Whether the first frame has been painted.
  ///
  /// The six rows come from `Rank.values` and need nothing, so they are on
  /// screen immediately. Which puzzle is next lives in the database, and
  /// opening it is not allowed on the path to the first frame — a test asserts
  /// the shell never does.
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
    final byRank = _pastFirstFrame
        ? ref.watch(nextPuzzleByRankProvider)
        : const AsyncValue<Map<Rank, StoredPuzzle?>>.loading();
    // Read on the same terms as the puzzles: after the first frame, never on
    // the path to it. A player's **rank** lives in the database, and the six
    // rows are entitled to be on screen before anything is read.
    final playerRank = _pastFirstFrame
        ? ref.watch(playerRankProvider)
        : const AsyncValue<Rank>.loading();

    return Scaffold(
      appBar: AppBar(
        title: Text('Free play', style: TypeRole.screenTitle.style),
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
        child: ListView(
          children: <Widget>[
            for (final rank in Rank.values)
              _RankTile(
                rank: rank,
                puzzle: byRank.value?[rank],
                // Absence and "not loaded yet" are different: only the first
                // is something to tell the player about.
                isLoaded: byRank.hasValue,
                // Marked, never locked (D-103). Until the player's **rank** has
                // been read nothing is marked, which is the right way round: an
                // unmarked row is openable, and so is a marked one.
                isAbovePlayer:
                    playerRank.hasValue &&
                    PlayerRank.above(playerRank.value!).contains(rank),
                onOpen: () => ref.read(activeNodeProvider.notifier).clear(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.puzzle,
    required this.isLoaded,
    required this.isAbovePlayer,
    required this.onOpen,
  });

  final Rank rank;
  final StoredPuzzle? puzzle;
  final bool isLoaded;

  /// Run just before the puzzle opens. See the tap handler below.
  final VoidCallback onOpen;

  /// Whether this **rank** is harder than the one the player has reached.
  ///
  /// A label and nothing more (D-103). It changes no behaviour on this tile:
  /// the tap, the target size, and the route are identical either way.
  final bool isAbovePlayer;

  @override
  Widget build(BuildContext context) {
    final exhausted = isLoaded && puzzle == null;
    // Both can be true at once, and both are worth saying. Carried in words
    // rather than a colour or an icon, so the mark survives colour vision
    // deficiency and reaches a screen reader as the sentence a player reads
    // (constraint 5).
    final notes = <String>[
      if (isAbovePlayer) 'Above your rank',
      if (exhausted) 'Nothing left here for now',
    ];

    return ListTile(
      key: ValueKey<String>('rank-${rank.name}'),
      title: Text(_label, style: TypeRole.body.style),
      // Nothing left is an ordinary absence, not a lock and not a failure
      // (constraint 1). The tile says so plainly and offers no penalty — and
      // neither does the **rank** mark beside it.
      // One Text per fact rather than one joined string. They are two separate
      // statements — where the player stands, and what is left here — and a
      // reader meeting them as one run-on sentence has to take them apart
      // again. It also keeps each piece of copy findable on its own.
      isThreeLine: notes.length > 1,
      subtitle: notes.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final note in notes)
                  Text(note, style: TypeRole.label.style),
              ],
            ),
      onTap: puzzle == null
          ? null
          : () {
              // A board opened here belongs to no **node**, so completing it
              // advances no **season** (D-111). Cleared rather than assumed
              // absent: the player may have opened a **node**, come back, and
              // chosen a **rank** instead.
              onOpen();
              Routes.goPuzzle(context, puzzle!.id);
            },
    );
  }

  /// "Sheriff rank", never a bare rank name — Sheriff and Deputy are characters
  /// as well as **rank**s, and the player is the Deputy (D-57).
  String get _label =>
      '${rank.name[0].toUpperCase()}${rank.name.substring(1)} rank';
}
