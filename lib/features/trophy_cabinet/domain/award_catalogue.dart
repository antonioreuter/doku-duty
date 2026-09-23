import 'award.dart';

/// Every **award** on offer: the **season**'s, and the permanent ones.
///
/// **A missing published list is not a degraded state.** Most installs, most of
/// the time, have no **season** document — the compiled-in list makes the
/// **cabinet** complete in that case rather than empty, which is the same
/// arrangement the **season** itself and the daily schedule already use
/// (D-125).
class AwardCatalogue {
  const AwardCatalogue(this.awards);

  final List<Award> awards;

  /// The **award**s of [seasonId] plus every permanent one.
  static AwardCatalogue forSeason({
    required String seasonId,
    required String seasonName,
    List<Award> published = const <Award>[],
  }) {
    final seasonal = published.isEmpty
        ? compiledInFor(seasonId: seasonId, seasonName: seasonName)
        : published;
    return AwardCatalogue(<Award>[...seasonal, ...permanent]);
  }

  /// The fallback for a **season** with nothing published.
  ///
  /// Derived from the layout D-18 fixes — **boss node**s at 22 and 41 — rather
  /// than from a second hard-coded list that could disagree with the **season**
  /// model about where a boss is. D-120 pins those positions, and the layout
  /// does not move for the story.
  static List<Award> compiledInFor({
    required String seasonId,
    required String seasonName,
  }) => <Award>[
    Award(
      id: '$seasonId.boss.22',
      name: 'Ace cornered, halfway',
      trigger: AwardTrigger.boss,
      seasonId: seasonId,
      nodePosition: 22,
    ),
    Award(
      id: '$seasonId.boss.41',
      name: 'Ace cornered, at the end',
      trigger: AwardTrigger.boss,
      seasonId: seasonId,
      nodePosition: 41,
    ),
    Award(
      id: '$seasonId.closed',
      name: '$seasonName, closed',
      trigger: AwardTrigger.seasonComplete,
      seasonId: seasonId,
    ),
  ];

  /// **Award**s belonging to no **season**.
  ///
  /// Always on offer and never rotated away, so they are compiled in rather
  /// than published: a document that could withdraw them would make the
  /// permanent layer conditional on a network, which D-17 does not allow.
  static const List<Award> permanent = <Award>[
    Award(
      id: 'permanent.perfect-month',
      name: 'A month without a gap',
      trigger: AwardTrigger.perfectMonth,
    ),
    Award(
      id: 'permanent.rank.sheriff',
      name: 'Sheriff',
      trigger: AwardTrigger.rankReached,
      rankName: 'sheriff',
    ),
    Award(
      id: 'permanent.rank.marshal',
      name: 'Marshal',
      trigger: AwardTrigger.rankReached,
      rankName: 'marshal',
    ),
    Award(
      id: 'permanent.rank.ranger',
      name: 'Ranger',
      trigger: AwardTrigger.rankReached,
      rankName: 'ranger',
    ),
    Award(
      id: 'permanent.rank.legend',
      name: 'Legend',
      trigger: AwardTrigger.rankReached,
      rankName: 'legend',
    ),
  ];

  Award? byId(String id) {
    for (final award in awards) {
      if (award.id == id) return award;
    }
    return null;
  }

  Iterable<Award> get seasonal => awards.where((a) => !a.isPermanent);
}
