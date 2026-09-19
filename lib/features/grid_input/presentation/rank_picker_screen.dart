import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../persistence/data/pack_repository.dart' show StoredPuzzle;
import '../../platform_shell/routing/app_router.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../../rank_progression/domain/player_rank.dart';
import '../application/grid_providers.dart';

/// Six entries, one per **rank**.
///
/// **Scaffolding.** `add-season-map` deletes this screen: a player is meant to
/// reach a puzzle through a node on a territory map, not a list of difficulty
/// tiers. It exists so that all six **rank**s are reachable and testable before
/// the map arrives, and so that this change can be played rather than only
/// tested.
class RankPickerScreen extends ConsumerStatefulWidget {
  const RankPickerScreen({super.key});

  @override
  ConsumerState<RankPickerScreen> createState() => _RankPickerScreenState();
}

class _RankPickerScreenState extends ConsumerState<RankPickerScreen> {
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
        title: Text('Doku Duty', style: TypeRole.screenTitle.style),
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
  });

  final Rank rank;
  final StoredPuzzle? puzzle;
  final bool isLoaded;

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
      onTap: puzzle == null ? null : () => Routes.goPuzzle(context, puzzle!.id),
    );
  }

  /// "Sheriff rank", never a bare rank name — Sheriff and Deputy are characters
  /// as well as **rank**s, and the player is the Deputy (D-57).
  String get _label =>
      '${rank.name[0].toUpperCase()}${rank.name.substring(1)} rank';
}
