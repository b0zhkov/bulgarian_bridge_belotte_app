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
/// owner's side; a won trick slides off toward the winner's seat.
class TrickArea extends StatefulWidget {
  const TrickArea({super.key, required this.table});
  final TableState table;

  @override
  State<TrickArea> createState() => _TrickAreaState();
}

class _TrickAreaState extends State<TrickArea>
    with SingleTickerProviderStateMixin {
  TableState get table => widget.table;

  /// The trick being collected (animating toward its winner).
  Trick? _leaving;
  late final AnimationController _collect =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _leaving = null);
        }
      });

  @override
  void didUpdateWidget(TrickArea old) {
    super.didUpdateWidget(old);
    final held = old.table.displayTrick;
    if (held != null &&
        held.winner != null &&
        widget.table.displayTrick == null &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _leaving = held;
      _collect.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _collect.dispose();
    super.dispose();
  }

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
        final cw = math
            .min(76.0, math.min(box.maxWidth / 3.3, box.maxHeight / 2.75))
            .floorToDouble();
        final ch = cw * PlayingCardView.aspect;
        final center = Offset(box.maxWidth / 2, box.maxHeight / 2);
        final spreadX = cw * 1.15;
        final spreadY = ch * 0.63;
        Offset slot(int seat) => Offset(
          (center.dx + _dir(seat).dx * spreadX - cw / 2).roundToDouble(),
          (center.dy + _dir(seat).dy * spreadY - ch / 2).roundToDouble(),
        );
        final leaving = _leaving;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (leaving != null)
              for (final p in leaving.plays)
                AnimatedBuilder(
                  key: ValueKey('leaving-${leaving.leader}-${p.card.code}'),
                  animation: _collect,
                  builder: (context, child) {
                    final t = Curves.easeInCubic.transform(_collect.value);
                    final to =
                        center -
                        Offset(cw / 2, ch / 2) +
                        _dir(leaving.winner!) *
                            (box.maxWidth * 0.55 + cw * 0.5);
                    final o = Offset.lerp(slot(p.seat), to, t)!;
                    return Positioned(
                      left: o.dx,
                      top: o.dy,
                      child: Opacity(
                        opacity: (1 - t * t).clamp(0, 1),
                        child: Transform.scale(
                          scale: 1 - 0.35 * t,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: PlayingCardView(card: p.card, width: cw),
                ),
            for (final p in trick.plays)
              _FlyingCard(
                key: ValueKey('${trick.leader}-${p.card.code}'),
                from: _dir(p.seat) * (box.maxWidth * 0.6),
                // Straight, symmetric cross snapped to whole pixels.
                target: Offset(
                  (center.dx + _dir(p.seat).dx * spreadX - cw / 2)
                      .roundToDouble(),
                  (center.dy + _dir(p.seat).dy * spreadY - ch / 2)
                      .roundToDouble(),
                ),
                child: PlayingCardView(
                  key: Key('trick-${p.seat}'),
                  card: p.card,
                  width: cw,
                  highlighted: winnerSeat == p.seat,
                  dimmed: winnerSeat != null && winnerSeat != p.seat,
                ),
              ),
            if (table.game.phase == GamePhase.bidding)
              Positioned.fill(child: _BiddingCenter(table: table)),
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
    required this.child,
  });
  final Offset from;
  final Offset target;
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
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        );
      },
      child: child,
    );
  }
}

class _BiddingCenter extends StatelessWidget {
  const _BiddingCenter({required this.table});
  final TableState table;
  GameState get game => table.game;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final contract = game.contract;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.bidding,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: AppText.caption,
              ),
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
                            fontSize: AppText.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          table.infoFor(l, contract.declarer).name,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: AppText.caption,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
