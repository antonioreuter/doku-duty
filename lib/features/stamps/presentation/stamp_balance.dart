import 'package:flutter/material.dart';

import '../../design_system/presentation/doku_type.dart';

/// The player's **stamp** balance, as one line in the **cabinet** (D-134).
///
/// **A receipt, not an invitation.** It takes no tap and has no neighbour that
/// sells anything: **stamp**s are earned in play and nothing else (D-66,
/// constraint 10), so there is nowhere for a tap on the balance to go.
///
/// Zero is shown as a number. A new player's empty balance is a fact about
/// where they stand, and a blank or a "get more" would read as a gap to fill.
class StampBalance extends StatelessWidget {
  const StampBalance({required this.balance, super.key});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final label = Text('Stamps', style: TypeRole.body.style);
    final value = Text('$balance', style: TypeRole.body.style);
    // The threshold the **cabinet**'s statistics use: above 2x, side by side
    // stops fitting the smallest phone the app targets (D-84).
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 2;

    return Semantics(
      label: 'Stamps, $balance',
      container: true,
      excludeSemantics: true,
      child: Padding(
        key: const ValueKey<String>('cabinet-stamp-balance'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[label, value],
              )
            : Row(
                children: <Widget>[
                  Expanded(child: label),
                  const SizedBox(width: 12),
                  value,
                ],
              ),
      ),
    );
  }
}
