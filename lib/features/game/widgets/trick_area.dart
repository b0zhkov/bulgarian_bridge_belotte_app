import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../game_controller.dart';
import '../labels.dart';
import 'playing_card.dart';

/// Centre of the table: the four cards of the current trick arranged in a
/// cross (you at the bottom, partner at the top). Cards fly in from their
/// owner's side.
class TrickArea extends StatelessWidget {
  const TrickArea({super.key, required this.table});
  final TableState table;

  static Offset _dir(int seat) => switch (seat) {
    0 => const Offset(0, 1),
    1 => const Offset(1, 0),
    2 => const Offset(0, -1),
    _ => const Offset(-1, 0),
  };

  @override
  Widget build(BuildContext context) {
    final trick = table.visibleTrick;
    final winnerSeat = table.displayTrick?.winner;
    return LayoutBuilder(
      builder: (context, box) {
        final cw = math.min(
          76.0,
          math.min(box.maxWidth * 0.2, box.maxHeight / 2.9),
        );
        final ch = cw * PlayingCardView.aspect;
        final center = Offset(box.maxWidth / 2, box.maxHeight / 2);
        final spreadX = cw * 1.1;
        final spreadY = ch * 0.6;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (i, p) in trick.plays.indexed)
              _FlyingCard(
                key: ValueKey('${trick.leader}-${p.card.code}'),
                from: _dir(p.seat) * (box.maxWidth * 0.6),
                target:
                    center +
                    Offset(
                      _dir(p.seat).dx * spreadX,
                      _dir(p.seat).dy * spreadY,
                    ) -
                    Offset(cw / 2, ch / 2),
                angle: (p.seat.isEven ? 0.02 : -0.03) * (i.isEven ? 1 : -1),
                child: PlayingCardView(
                  card: p.card,
                  width: cw,
                  highlighted: winnerSeat == p.seat,
                  dimmed: winnerSeat != null && winnerSeat != p.seat,
                ),
              ),
            if (table.game.phase == GamePhase.bidding)
              Positioned.fill(child: _BiddingCenter(game: table.game)),
          ],
        );
      },
    );
  }
}

class _FlyingCard extends StatelessWidget {
  const _FlyingCard({
    super.key,
    required this.from,
    required this.target,
    required this.angle,
    required this.child,
  });
  final Offset from;
  final Offset target;
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final o = target + from * (1 - t);
        return Positioned(
          left: o.dx,
          top: o.dy,
          child: Opacity(
            opacity: t.clamp(0, 1),
            child: Transform.rotate(angle: angle * t, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _BiddingCenter extends StatelessWidget {
  const _BiddingCenter({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final contract = game.contract;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.bidding,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, a) =>
                ScaleTransition(scale: a, child: child),
            child: contract == null
                ? Text(
                    '—',
                    key: const ValueKey('none'),
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                    ),
                  )
                : Column(
                    key: ValueKey(contract),
                    children: [
                      ContractGlyph(
                        contract.type,
                        size: 56,
                        color: c.textPrimary,
                        red: c.cardRed,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${contractName(l, contract.type)}${multiplierSuffix(l, contract.multiplier)}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        seatInfo(l, contract.declarer).name,
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
