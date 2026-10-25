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
          fontSize: size * 0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Emoji avatar with name, dealer badge and a chip showing the last bid or
/// the current announcement, dimmed when it is not this seat's turn.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.seat, required this.table});
  final int seat;
  final TableState table;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = table.game;
    final info = seatInfo(l, seat);
    final active =
        !table.holding &&
        g.currentSeat == seat &&
        (g.phase == GamePhase.bidding || g.phase == GamePhase.playing);
    final isPartner = seat == 2;

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
        if (b.kind == BidKind.contract && (b.type!.trumpSuit?.isRed ?? false)) {
          chipColor = c.cardRed;
        }
      }
    }
    final bubble = table.bubbles[seat];
    if (bubble != null) {
      chip = announcementText(l, bubble);
      chipContract = null;
      chipColor = c.chipText;
    }

    return SizedBox(
      width: 104,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity:
            active ||
                g.phase == GamePhase.dealScored ||
                g.phase == GamePhase.matchOver
            ? 1
            : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: active ? 1.08 : 1,
                  child: Text(info.emoji, style: const TextStyle(fontSize: 44)),
                ),
                if (g.dealer == seat)
                  const Positioned(right: -6, bottom: 2, child: DealerBadge()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              info.name,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: isPartner ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            Text(
              '${g.hands[seat].length}',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
