import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/rules.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/suit_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import 'game_controller.dart';
import 'labels.dart';
import 'widgets/deal_result_panel.dart';
import 'widgets/hand_view.dart';
import 'widgets/history_sheet.dart';
import 'widgets/player_avatar.dart';
import 'widgets/trick_area.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  Future<void> _confirmLeave(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.leaveMatchTitle),
        content: Text(l.leaveMatchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.leave),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final table = ref.watch(gameControllerProvider);
    final ctrl = ref.read(gameControllerProvider.notifier);
    final g = table.game;
    final showResult =
        !table.holding &&
        (g.phase == GamePhase.dealScored || g.phase == GamePhase.matchOver);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(
                        onBack: () => _confirmLeave(context),
                        onScore: () => showHistorySheet(context, g),
                        game: g,
                      ),
                      const SizedBox(height: 8),
                      _OpponentsRow(table: table),
                      Expanded(child: TrickArea(table: table)),
                      _StatusLine(table: table),
                      const SizedBox(height: 10),
                      if (g.phase == GamePhase.bidding)
                        _BiddingPanel(
                          bids: ctrl.humanBids(),
                          onBid: ctrl.humanBid,
                          active: table.isHumanTurn,
                        ),
                      if (g.phase != GamePhase.bidding)
                        _SelfStrip(table: table),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: HandView(
                          cards: sortHand(
                            g.hands[kHumanSeat],
                            g.phase == GamePhase.bidding
                                ? null
                                : g.contract?.type,
                          ),
                          legal: ctrl.humanLegalCards(),
                          interactive:
                              table.isHumanTurn && g.phase == GamePhase.playing,
                          onPlay: ctrl.humanPlay,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  if (showResult)
                    Positioned.fill(
                      child: DealResultPanel(
                        game: g,
                        onNext: ctrl.nextDeal,
                        onNewMatch: ctrl.newMatch,
                      ),
                    ),
                  if (g.phase == GamePhase.allPassed)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: c.surfaceHigh,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              l.allPassed,
                              style: TextStyle(color: c.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onScore,
    required this.game,
  });
  final VoidCallback onBack;
  final VoidCallback onScore;
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final contract = game.contract;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('back'),
            icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
            onPressed: onBack,
          ),
          Expanded(
            child: Center(
              child: InkWell(
                key: const Key('scoreboard'),
                borderRadius: BorderRadius.circular(30),
                onTap: onScore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              l.us,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${game.scores[0]}',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              '  :  ',
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              '${game.scores[1]}',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.them,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (game.hanging > 0)
                        Text(
                          l.hanging(game.hanging),
                          style: TextStyle(color: c.chipText, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: contract == null || game.phase == GamePhase.bidding
                ? const SizedBox()
                : _ContractBadge(contract: contract),
          ),
        ],
      ),
    );
  }
}

class _ContractBadge extends StatelessWidget {
  const _ContractBadge({required this.contract});
  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final red = contract.trumpSuit?.isRed ?? false;
    return Tooltip(
      message:
          contractName(l, contract.type) +
          multiplierSuffix(l, contract.multiplier),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ContractGlyph(
              contract.type,
              size: 18,
              color: red ? c.cardRed : c.textPrimary,
            ),
            if (contract.multiplier != Multiplier.none)
              Text(
                '×${contract.multiplier.factor}',
                style: TextStyle(color: c.chipText, fontSize: 10, height: 1.2),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpponentsRow extends StatelessWidget {
  const _OpponentsRow({required this.table});
  final TableState table;

  @override
  Widget build(BuildContext context) {
    // Seat order on screen: left (3), partner (2), right (1).
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final seat in const [3, 2, 1])
          PlayerAvatar(seat: seat, table: table),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.table});
  final TableState table;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = table.game;
    String text = '';
    if (g.phase == GamePhase.bidding || g.phase == GamePhase.playing) {
      if (table.isHumanTurn) {
        text = g.phase == GamePhase.bidding ? l.yourBid : l.yourTurn;
      } else if (!table.holding) {
        text = l.waitingFor(seatInfo(l, g.currentSeat).name);
      }
    }
    return SizedBox(
      height: 22,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          text,
          key: ValueKey(text),
          style: TextStyle(
            color: table.isHumanTurn ? c.textPrimary : c.textSecondary,
            fontSize: 15,
            fontWeight: table.isHumanTurn ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BiddingPanel extends StatelessWidget {
  const _BiddingPanel({
    required this.bids,
    required this.onBid,
    required this.active,
  });
  final List<Bid> bids;
  final void Function(Bid) onBid;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    VoidCallback? on(Bid b) => bids.contains(b) ? () => onBid(b) : null;
    Widget suit(ContractType t) {
      final s = t.trumpSuit!;
      return Expanded(
        child: PillButton(
          key: Key('bid-${t.name}'),
          label: '',
          leading: SuitIcon(
            s,
            size: 22,
            color: s.isRed ? c.cardRed : c.textPrimary,
          ),
          height: 52,
          outlined: !active,
          textColor: s.isRed ? c.cardRed : null,
          onTap: on(Bid.contract(t)),
        ),
      );
    }

    const gap = SizedBox(width: 8);
    final canRedouble = bids.contains(Bid.redouble);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              suit(ContractType.clubs),
              gap,
              suit(ContractType.diamonds),
              gap,
              suit(ContractType.hearts),
              gap,
              suit(ContractType.spades),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  key: const Key('bid-noTrump'),
                  label: l.noTrump,
                  height: 52,
                  outlined: !active,
                  onTap: on(const Bid.contract(ContractType.noTrump)),
                ),
              ),
              gap,
              Expanded(
                child: PillButton(
                  key: const Key('bid-allTrump'),
                  label: l.allTrump,
                  height: 52,
                  outlined: !active,
                  onTap: on(const Bid.contract(ContractType.allTrump)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  key: const Key('bid-pass'),
                  label: l.pass,
                  height: 52,
                  outlined: !active,
                  onTap: on(Bid.pass),
                ),
              ),
              gap,
              Expanded(
                child: PillButton(
                  key: const Key('bid-double'),
                  label: canRedouble ? l.redouble : l.double,
                  height: 52,
                  outlined: !active,
                  onTap: canRedouble ? on(Bid.redouble) : on(Bid.double),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Strip above the hand during play: the local player's avatar, team score
/// and the current contract (mirrors the "High Card" box in Offsuit).
class _SelfStrip extends StatelessWidget {
  const _SelfStrip({required this.table});
  final TableState table;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = table.game;
    final contract = g.contract;
    final bubble = table.bubbles[kHumanSeat];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: table.isHumanTurn
                ? c.accent.withValues(alpha: 0.7)
                : c.outline,
          ),
        ),
        child: Row(
          children: [
            Text(
              seatInfo(l, kHumanSeat).emoji,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bubble != null
                        ? announcementText(l, bubble)
                        : seatInfo(l, kHumanSeat).name,
                    style: TextStyle(
                      color: bubble != null ? c.chipText : c.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  if (contract != null)
                    Text(
                      '${l.contract}: ${contractName(l, contract.type)}${multiplierSuffix(l, contract.multiplier)} · ${seatInfo(l, contract.declarer).name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (g.dealer == kHumanSeat) DealerBadge(),
          ],
        ),
      ),
    );
  }
}
