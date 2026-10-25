import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'playing_card.dart';

/// Small round button in the corner of the trick area; opens the previous
/// trick.
class LastTrickButton extends StatelessWidget {
  const LastTrickButton({
    super.key,
    required this.trick,
    required this.nameOf,
    this.live,
    this.contract,
  });
  final Trick trick;
  final String Function(int seat) nameOf;

  /// The table's game: the view closes when the next card is played.
  final ValueListenable<GameState>? live;

  /// For the trick's points.
  final ContractType? contract;

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
          onTap: () => showLastTrick(
            context,
            trick,
            nameOf,
            live: live,
            contract: contract,
          ),
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

/// Cards played so far in the deal (tricks done plus the current one).
int playedCount(GameState g) =>
    g.tricks.length * 4 + g.currentTrick.plays.length;

/// Shows [trick] as a cross (you at the bottom) with names and the winner
/// highlighted; any tap closes it, and so does the next card played (or the
/// deal ending) when [live] is given.
Future<void> showLastTrick(
  BuildContext context,
  Trick trick,
  String Function(int seat) nameOf, {
  ValueListenable<GameState>? live,
  ContractType? contract,
}) {
  final l = AppLocalizations.of(context);
  final nav = Navigator.of(context);
  final played = live == null ? null : playedCount(live.value);
  final phase = live?.value.phase;
  final deal = live?.value.dealNumber;
  ModalRoute<Object?>? route;
  void watch() {
    final g = live!.value;
    final r = route;
    if (r == null || !r.isActive) return;
    if (playedCount(g) != played || g.phase != phase || g.dealNumber != deal) {
      // Only ever this dialog: never a route below it.
      if (r.isCurrent) {
        nav.pop();
      } else {
        nav.removeRoute(r);
      }
    }
  }

  live?.addListener(watch);
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
    pageBuilder: (ctx, _, _) {
      route ??= ModalRoute.of(ctx);
      return GestureDetector(
        key: const Key('last-trick'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Already closing (e.g. the next card was played): never pop the
          // table underneath.
          if (route?.isCurrent ?? false) Navigator.of(ctx).pop();
        },
        child: SafeArea(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: _LastTrickView(
                trick: trick,
                nameOf: nameOf,
                contract: contract,
                autoHides: live != null,
              ),
            ),
          ),
        ),
      );
    },
  ).whenComplete(() => live?.removeListener(watch));
}

class _LastTrickView extends StatelessWidget {
  const _LastTrickView({
    required this.trick,
    required this.nameOf,
    this.contract,
    this.autoHides = false,
  });
  final Trick trick;
  final String Function(int seat) nameOf;
  final ContractType? contract;
  final bool autoHides;

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
          if (contract case final t?)
            Text(
              l.trickPoints(
                trick.cards.fold(0, (a, card) => a + cardPoints(card, t)),
              ),
              key: const Key('last-trick-points'),
              style: TextStyle(
                color: c.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
          const SizedBox(height: Gap.xs),
          Text(
            autoHides ? '${l.tapToClose} · ${l.lastTrickHides}' : l.tapToClose,
            textAlign: TextAlign.center,
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
