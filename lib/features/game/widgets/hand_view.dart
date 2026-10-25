import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../../../core/models/card.dart';
import 'playing_card.dart';

/// The local player's hand as an overlapping row of large cards.
class HandView extends StatelessWidget {
  const HandView({
    super.key,
    required this.cards,
    required this.legal,
    required this.interactive,
    required this.onPlay,
    this.hint,
    this.hidden = const {},
    this.maxCardWidth = 104,
  });

  /// Cards still being dealt: left out, the rest fans around them.
  final Set<Card> hidden;

  final List<Card> cards;
  final Set<Card> legal;
  final bool interactive;
  final void Function(Card) onPlay;

  /// Suggested card to highlight (glow + extra lift).
  final Card? hint;
  final double maxCardWidth;

  @override
  Widget build(BuildContext context) {
    final cards = hidden.isEmpty
        ? this.cards
        : [
            for (final c in this.cards)
              if (!hidden.contains(c)) c,
          ];
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final n = math.max(cards.length, 1);
        final cw = math
            .min(maxCardWidth, w / (1 + (n - 1) * 0.55))
            .clamp(40.0, maxCardWidth)
            .floorToDouble();
        final step = n == 1
            ? 0.0
            : math.min(cw * 0.86, (w - cw) / (n - 1)).floorToDouble();
        final totalW = cw + step * (n - 1);
        final left0 = ((w - totalW) / 2).roundToDouble();
        final ch = cw * PlayingCardView.aspect;
        // All cards sit on one straight baseline; only the hinted card lifts.
        const hintLift = 14.0;
        return SizedBox(
          height: ch + hintLift,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (i, card) in cards.indexed)
                AnimatedPositioned(
                  key: ValueKey(card.code),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: left0 + step * i,
                  top: interactive && card == hint ? 0 : hintLift,
                  child: GestureDetector(
                    key: Key('hand-${card.code}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: interactive && legal.contains(card)
                        ? () => onPlay(card)
                        : null,
                    child: _FanIn(
                      child: PlayingCardView(
                        card: card,
                        width: cw,
                        dimmed: interactive && !legal.contains(card),
                        glow: interactive && card == hint,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A card arriving in the hand: a short rise and fade in.
class _FanIn extends StatelessWidget {
  const _FanIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
