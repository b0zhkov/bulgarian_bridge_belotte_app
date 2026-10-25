import 'package:flutter/material.dart';

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../game_controller.dart';
import '../labels.dart';

class DealerBadge extends StatelessWidget {
  const DealerBadge({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(color: c.background, width: 2),
      ),
      child: Text(
        l.dealer,
        style: TextStyle(
          color: c.textPrimary,
          fontSize: size * 0.48,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

Color teamColor(BuildContext context, int seat) =>
    teamOf(seat) == teamOf(kHumanSeat)
    ? context.colors.teamUs
    : context.colors.teamThem;

/// Emoji in a ring coloured by team, with an optional dealer badge.
class TeamEmoji extends StatelessWidget {
  const TeamEmoji({
    super.key,
    required this.seat,
    required this.emoji,
    this.size = 40,
    this.dealer = false,
    this.active = false,
  });
  final int seat;
  final String emoji;
  final double size;
  final bool dealer;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(context, seat);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size + 14,
          height: size + 14,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: active ? 3 : 2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Text(
              emoji,
              key: ValueKey(emoji),
              style: TextStyle(fontSize: size * 0.82, height: 1.1),
            ),
          ),
        ),
        if (dealer)
          const Positioned(right: -4, bottom: -2, child: DealerBadge()),
      ],
    );
  }
}

/// A seat at the table: team-ringed emoji, name, role ("Партньор" /
/// "Противник") in the team colour, and a chip with the last bid or the
/// current announcement. Dimmed when it is not this seat's turn.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.seat,
    required this.table,
    this.width = 84,
  });
  final int seat;
  final TableState table;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = table.game;
    final info = table.infoFor(l, seat);
    final active =
        !table.holding &&
        g.currentSeat == seat &&
        (g.phase == GamePhase.bidding || g.phase == GamePhase.playing);

    String? chip;
    ContractType? chipContract;
    Color chipColor = c.chipText;
    if (g.phase == GamePhase.bidding || g.phase == GamePhase.allPassed) {
      final mine = g.bids.where((b) => b.seat == seat);
      if (mine.isNotEmpty) {
        final b = mine.last.bid;
        if (b.kind == BidKind.contract) chipContract = b.type;
        chip = b.kind == BidKind.contract
            ? contractShort(l, b.type!)
            : bidLabel(l, b);
        if (b.kind == BidKind.pass) chipColor = Colors.white70;
      }
    }
    final bubble = table.bubbles[seat];
    if (bubble != null) {
      chip = announcementText(l, bubble);
      chipContract = null;
      chipColor = c.chipText;
    }

    return SizedBox(
      width: width,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity:
            active ||
                g.phase == GamePhase.dealScored ||
                g.phase == GamePhase.matchOver
            ? 1
            : 0.55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamEmoji(
              seat: seat,
              emoji: info.emoji,
              dealer: g.dealer == seat,
              active: active,
            ),
            const SizedBox(height: Gap.xs + 2),
            // Crossfade when a bot takes over a seat or a player returns.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: Text(
                info.name,
                key: ValueKey(info.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: AppText.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: Gap.xs),
            SizedBox(
              height: 26,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: chip == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(chip),
                        constraints: BoxConstraints(maxWidth: width),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.chip,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: chipContract != null
                            ? ContractGlyph(
                                chipContract,
                                size: 15,
                                color: Colors.white,
                                red: c.cardRed,
                              )
                            : Text(
                                chip,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: chipColor,
                                  fontSize: AppText.caption,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
