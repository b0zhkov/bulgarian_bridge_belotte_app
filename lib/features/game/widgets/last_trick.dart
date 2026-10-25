import 'package:flutter/material.dart' hide Card;

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'playing_card.dart';

/// Small round button in the corner of the trick area; opens the previous
/// trick.
class LastTrickButton extends StatelessWidget {
  const LastTrickButton({super.key, required this.trick, required this.nameOf});
  final Trick trick;
  final String Function(int seat) nameOf;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Tooltip(
      message: l.lastTrick,
      child: Material(
        color: c.surfaceHigh,
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('last-trick-button'),
          customBorder: const CircleBorder(),
          onTap: () => showLastTrick(context, trick, nameOf),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              Icons.history_rounded,
              size: 20,
              color: c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [trick] as a cross (you at the bottom) with names and the winner
/// highlighted; any tap closes it.
Future<void> showLastTrick(
  BuildContext context,
  Trick trick,
  String Function(int seat) nameOf,
) {
  final l = AppLocalizations.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l.tapToClose,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(a),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, _) => GestureDetector(
      key: const Key('last-trick'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(ctx).pop(),
      child: SafeArea(
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: _LastTrickView(trick: trick, nameOf: nameOf),
          ),
        ),
      ),
    ),
  );
}

class _LastTrickView extends StatelessWidget {
  const _LastTrickView({required this.trick, required this.nameOf});
  final Trick trick;
  final String Function(int seat) nameOf;

  static Alignment _at(int seat) => switch (seat) {
    0 => const Alignment(0, 0.62),
    1 => const Alignment(0.9, 0),
    2 => const Alignment(0, -0.62),
    _ => const Alignment(-0.9, 0),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final winner = trick.winner;
    const cw = 64.0;
    return Container(
      width: 340,
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.lastTrick,
            style: TextStyle(color: c.textPrimary, fontSize: AppText.title),
          ),
          const SizedBox(height: Gap.m),
          SizedBox(
            height: 330,
            child: Stack(
              children: [
                for (final p in trick.plays)
                  Align(
                    alignment: _at(p.seat),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.seat != 0) _name(c, p.seat, winner),
                        PlayingCardView(
                          key: Key('last-trick-${p.seat}'),
                          card: p.card,
                          width: cw,
                          highlighted: p.seat == winner,
                          dimmed: winner != null && p.seat != winner,
                        ),
                        if (p.seat == 0) _name(c, p.seat, winner),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (winner != null)
            Text(
              l.trickTakenBy(nameOf(winner)),
              key: const Key('last-trick-winner'),
              style: TextStyle(
                color: teamOf(winner) == 0 ? c.teamUs : c.teamThem,
                fontSize: AppText.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: Gap.xs),
          Text(
            l.tapToClose,
            style: TextStyle(color: c.textSecondary, fontSize: AppText.caption),
          ),
        ],
      ),
    );
  }

  Widget _name(BelotColors c, int seat, int? winner) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text(
      nameOf(seat),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: seat == winner ? c.textPrimary : c.textSecondary,
        fontSize: AppText.caption,
        fontWeight: seat == winner ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}
