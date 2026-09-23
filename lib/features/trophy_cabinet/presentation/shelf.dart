import 'package:flutter/material.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../persistence/data/app_database.dart';
import '../domain/award.dart';

/// Every **award** on offer, earned or **unfiled**.
///
/// **An unearned one is shown in the place it will occupy, never hidden**
/// (D-21). The visible gap is the point: it drives a return far better than
/// absence does, and it is honest about what has not happened yet.
///
/// **And it is never a reproach.** Nothing here says missed, failed, expired or
/// locked, there is no countdown, and an **unfiled** **award** carries no
/// error colour — `sunsetRed`'s job is "errors, duplicates, Ace", and not
/// having earned something yet is none of those (constraint 1, constraint 4).
class Shelf extends StatelessWidget {
  const Shelf({
    required this.awards,
    required this.earnedIds,
    required this.earned,
    super.key,
  });

  final List<Award> awards;
  final Set<String> earnedIds;

  /// The minted rows, which carry the name and territory as they were when
  /// earned — a **trophy** from a rotated **season** has no **award** left in
  /// the catalogue to read from (D-124).
  final List<Trophy> earned;

  @override
  Widget build(BuildContext context) {
    // A trophy whose award is no longer on offer: its season rotated away.
    // It keeps its place on the shelf rather than vanishing with the document
    // that declared it — that is the whole reason it was minted (D-124).
    final rotated = earned
        .where((t) => !awards.any((a) => a.minted(t.awardId)))
        .toList();

    return Column(
      key: const ValueKey<String>('cabinet-shelf'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final award in awards)
          // A perfect month mints one **trophy** per month. Once any has been
          // earned they stand where the offer stood — oldest first, so a new
          // month joins the end of the run — and the offer stops reading as
          // unfiled.
          if (award.isRepeatable && _monthsOf(award).isNotEmpty)
            for (final month in _monthsOf(award))
              _Entry(
                id: month.awardId,
                name: month.name,
                isEarned: true,
                season: month.seasonName,
              )
          else
            _Entry(
              id: award.id,
              // The name on the day it was earned, not the one published since
              // (D-126). A rename changes only what is still on offer.
              name: _mintedFor(award.id)?.name ?? award.name,
              isEarned: earnedIds.contains(award.id),
              season: _mintedFor(award.id)?.seasonName,
            ),
        for (final trophy in rotated)
          _Entry(
            id: trophy.awardId,
            name: trophy.name,
            isEarned: true,
            season: trophy.seasonName,
          ),
      ],
    );
  }

  List<Trophy> _monthsOf(Award award) =>
      earned
          .where((t) => t.awardId != award.id && award.minted(t.awardId))
          .toList()
        ..sort((a, b) => a.awardId.compareTo(b.awardId));

  Trophy? _mintedFor(String awardId) {
    for (final trophy in earned) {
      if (trophy.awardId == awardId) return trophy;
    }
    return null;
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.id,
    required this.name,
    required this.isEarned,
    required this.season,
  });

  final String id;
  final String name;
  final bool isEarned;
  final String? season;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The state in words. A grid of medals is exactly the screen where colour
      // alone would be easiest to reach for, and the one where a player who
      // cannot see it has most to lose.
      label: isEarned ? '$name, earned' : '$name, unfiled',
      // Its own node. The shelf is one Column, and without this every entry's
      // label merges into a single announcement the player cannot step
      // through a **trophy** at a time.
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          key: ValueKey<String>('cabinet-award-$id'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEarned
                ? PaletteToken.cactusGreen.paleColour
                : PaletteToken.bone.colour,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEarned
                  ? PaletteToken.cactusGreen.colour
                  : DokuColours.hairline,
              width: isEarned ? 3 : 2,
            ),
          ),
          child: Row(
            children: <Widget>[
              // The second channel. An outline for something not yet filed, a
              // filled mark for something that is — legible with the colour
              // taken away entirely (constraint 5).
              Icon(
                isEarned ? Icons.workspace_premium : Icons.bookmark_border,
                color: isEarned ? DokuColours.duskInk : DokuColours.inkSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: TypeRole.body.style),
                    Text(
                      // The third channel, and the one that carries the whole
                      // of D-21's intent: the word is "Unfiled", never
                      // "Missed" and never a date it had to be done by.
                      isEarned
                          ? <String>['Earned', ?season].join(' · ')
                          : 'Unfiled',
                      style: TypeRole.label.style.copyWith(
                        color: DokuColours.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
