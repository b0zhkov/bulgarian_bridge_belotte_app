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
    this.maxCardWidth = 104,
  });

  final List<Card> cards;
  final Set<Card> legal;
  final bool interactive;
  final void Function(Card) onPlay;

  /// Suggested card to highlight (glow + extra lift).
  final Card? hint;
  final double maxCardWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final n = math.max(cards.length, 1);
        final cw = math
            .min(maxCardWidth, w / (1 + (n - 1) * 0.55))
            .clamp(40.0, maxCardWidth);
        final step = n == 1 ? 0.0 : math.min(cw * 0.86, (w - cw) / (n - 1));
        final totalW = cw + step * (n - 1);
        final left0 = (w - totalW) / 2;
        final ch = cw * PlayingCardView.aspect;
        const lift = 14.0;
        const hintLift = 10.0;
        return SizedBox(
          height: ch + lift + hintLift,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (i, card) in cards.indexed)
                AnimatedPositioned(
                  key: ValueKey(card.code),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: left0 + step * i,
                  top:
                      hintLift +
                      (interactive && legal.contains(card) ? 0 : lift) -
                      (interactive && card == hint ? hintLift : 0),
                  child: GestureDetector(
                    key: Key('hand-${card.code}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: interactive && legal.contains(card)
                        ? () => onPlay(card)
                        : null,
                    child: PlayingCardView(
                      card: card,
                      width: cw,
                      dimmed: interactive && !legal.contains(card),
                      glow: interactive && card == hint,
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
