import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/rules.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/suit_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/profile_controller.dart';
import '../emotes/emotes.dart';
import 'game_controller.dart';
import 'labels.dart';
import 'widgets/deal_result_panel.dart';
import 'widgets/hand_view.dart';
import 'widgets/last_trick.dart';
import 'widgets/score_sheet.dart';
import 'widgets/player_avatar.dart';
import 'widgets/table_effects.dart';
import 'widgets/trick_area.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return TableView(
      table: ref
          .watch(gameControllerProvider)
          .copyWith(
            seatInfos: offlineSeatInfos(
              l,
              ref.watch(playerNameProvider),
              ref.watch(playerAvatarProvider),
            ),
          ),
      actions: ref.read(gameControllerProvider.notifier),
      onLeave: () => Navigator.of(context).pop(),
    );
  }
}

/// The game table (shared by offline and online play).
class TableView extends ConsumerWidget {
  const TableView({
    super.key,
    required this.table,
    required this.actions,
    required this.onLeave,
    this.footer,
    this.newMatchLabel,
    this.leaveTitle,
    this.leaveBody,
    this.notice,
    this.onEmote,
    this.canEmote,
  });

  /// Online only: sends an emote (null hides the emote button).
  final void Function(Emote e)? onEmote;

  /// Online only: whether the emote rate limit allows sending now.
  final bool Function()? canEmote;

  /// Short-lived message shown over the status line, between the trick area
  /// and the player's own cards (never over an avatar).
  final Widget? notice;

  /// Leave-confirmation copy (defaults to the offline wording).
  final String? leaveTitle;
  final String? leaveBody;

  final TableState table;
  final TableActions actions;

  /// Called after the player confirmed leaving.
  final VoidCallback onLeave;

  /// Extra widget below the hand (online: the room code).
  final Widget? footer;
  final String? newMatchLabel;

  Future<void> _confirmLeave(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          leaveTitle ?? l.leaveMatchTitle,
          style: const TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          leaveBody ?? l.leaveMatchBody,
          style: const TextStyle(fontSize: AppText.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('confirm-leave'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.leave),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) onLeave();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final ctrl = actions;
    final myName = ref.watch(playerNameProvider);
    final hintsOn = ref.watch(hintsEnabledProvider);
    final g = table.game;
    final showResult =
        !table.holding &&
        (g.phase == GamePhase.dealScored || g.phase == GamePhase.matchOver);

    String nameOf(int seat) => table.infoFor(l, seat, myName).name;

    return LiveGame(
      game: g,
      builder: (context, live, recapDone) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave(context);
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final narrow = box.maxWidth < 380;
                    final sideW = narrow ? 76.0 : 92.0;
                    return TableEffects(
                      table: table,
                      builder: (context, deal) => Stack(
                        children: [
                          Column(
                            children: [
                              ValueListenableBuilder<int>(
                                valueListenable: recapDone,
                                builder: (context, done, _) {
                                  final shown = shownScore(g, done);
                                  return _TopBar(
                                    onBack: () => _confirmLeave(context),
                                    onScore: () => showScoreSheet(
                                      context,
                                      live,
                                      nameOf: nameOf,
                                    ),
                                    game: g,
                                    scores: shown.scores,
                                    hanging: shown.hanging,
                                  );
                                },
                              ),
                              // Partner sits opposite (top), opponents left and right.
                              KeyedSubtree(
                                key: deal.anchors[2],
                                child: PlayerAvatar(
                                  key: const Key('seat-2'),
                                  seat: 2,
                                  table: table,
                                  width: 120,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: sideW,
                                      child: Center(
                                        child: KeyedSubtree(
                                          key: deal.anchors[3],
                                          child: PlayerAvatar(
                                            key: const Key('seat-3'),
                                            seat: 3,
                                            table: table,
                                            width: sideW,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: TrickArea(table: table),
                                          ),
                                          if (onEmote case final send?)
                                            Positioned(
                                              left: 0,
                                              bottom: 0,
                                              child: EmoteButton(
                                                onPick: send,
                                                canSend: canEmote,
                                              ),
                                            ),
                                          if (g.phase == GamePhase.playing &&
                                              g.tricks.isNotEmpty)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: LastTrickButton(
                                                trick: g.tricks.last,
                                                nameOf: nameOf,
                                                live: live,
                                                contract: g.contract?.type,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: sideW,
                                      child: Center(
                                        child: KeyedSubtree(
                                          key: deal.anchors[1],
                                          child: PlayerAvatar(
                                            key: const Key('seat-1'),
                                            seat: 1,
                                            table: table,
                                            width: sideW,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  _StatusLine(
                                    table: table,
                                    hintShown: hintsOn && table.hint != null,
                                  ),
                                  ?notice,
                                  if (table.emotes[kHumanSeat] case final e?)
                                    Positioned(
                                      bottom: 0,
                                      child: EmoteBurst(
                                        key: const Key('emote-over-0'),
                                        show: e,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: Gap.s),
                              if (g.phase == GamePhase.bidding)
                                _BiddingPanel(
                                  bids: ctrl.humanBids(),
                                  onBid: ctrl.humanBid,
                                  active: table.isHumanTurn && !deal.dealing,
                                  compact: box.maxHeight < 720,
                                )
                              else
                                _SelfStrip(table: table, name: myName),
                              const SizedBox(height: Gap.m),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Gap.l,
                                ),
                                child: KeyedSubtree(
                                  key: deal.anchors[kHumanSeat],
                                  child: HandView(
                                    cards: sortHand(
                                      g.hands[kHumanSeat],
                                      g.phase == GamePhase.bidding
                                          ? null
                                          : g.contract?.type,
                                    ),
                                    legal: ctrl.humanLegalCards(),
                                    hidden: deal.hiddenHand,
                                    interactive:
                                        table.isHumanTurn &&
                                        !deal.dealing &&
                                        g.phase == GamePhase.playing,
                                    hint: hintsOn ? table.hint : null,
                                    maxCardWidth: box.maxHeight < 720
                                        ? 92
                                        : 104,
                                    onPlay: ctrl.humanPlay,
                                  ),
                                ),
                              ),
                              if (footer != null) ...[
                                const SizedBox(height: Gap.s),
                                footer!,
                                const SizedBox(height: Gap.s),
                              ] else
                                const SizedBox(height: Gap.l),
                            ],
                          ),
                          if (showResult)
                            Positioned.fill(
                              child: DealResultPanel(
                                game: g,
                                onNext: ctrl.nextDeal,
                                onNewMatch: ctrl.newMatch,
                                newMatchLabel: newMatchLabel,
                                waiting: table.waitingReady,
                                nameOf: nameOf,
                                onRecapDone: (n) {
                                  if (n > recapDone.value) {
                                    recapDone.value = n;
                                  }
                                },
                              ),
                            ),
                          if (g.phase == GamePhase.allPassed)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(Gap.page),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Gap.page,
                                      vertical: Gap.m + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surfaceHigh,
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: Text(
                                      l.allPassed,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: c.textPrimary,
                                        fontSize: AppText.label,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
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
    required this.scores,
    required this.hanging,
  });
  final VoidCallback onBack;
  final VoidCallback onScore;
  final GameState game;
  final List<int> scores;
  final int hanging;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final contract = game.contract;

    Widget team(
      String label,
      int score,
      Color color,
      CrossAxisAlignment align,
      Key key,
    ) => Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: AppText.caption,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$score',
          key: key,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: AppText.score,
            fontWeight: FontWeight.w400,
            height: 1.15,
          ),
        ),
      ],
    );

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.s),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: IconButton(
                key: const Key('back'),
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                onPressed: onBack,
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: InkWell(
                        key: const Key('scoreboard'),
                        borderRadius: BorderRadius.circular(24),
                        onTap: onScore,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Gap.m,
                            vertical: Gap.xs,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                team(
                                  l.teamUs,
                                  scores[0],
                                  c.teamUs,
                                  CrossAxisAlignment.end,
                                  const Key('score-us'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Gap.m,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        ':',
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: AppText.title,
                                        ),
                                      ),
                                      if (hanging > 0)
                                        Text(
                                          l.hanging(hanging),
                                          style: TextStyle(
                                            color: c.chipText,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                team(
                                  l.teamThem,
                                  scores[1],
                                  c.teamThem,
                                  CrossAxisAlignment.start,
                                  const Key('score-them'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: AppLocalizations.of(context).scoreSheet,
                      child: Material(
                        color: c.surfaceHigh,
                        shape: const CircleBorder(),
                        child: InkWell(
                          key: const Key('score-sheet-button'),
                          customBorder: const CircleBorder(),
                          onTap: onScore,
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: teamColor(context, contract.declarer),
            width: 1.5,
          ),
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
                style: TextStyle(color: c.chipText, fontSize: 10, height: 1.3),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.table, required this.hintShown});
  final TableState table;
  final bool hintShown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = table.game;
    var text = '';
    if (g.phase == GamePhase.bidding || g.phase == GamePhase.playing) {
      if (table.isHumanTurn) {
        text = g.phase == GamePhase.bidding
            ? l.yourBid
            : (hintShown ? '${l.yourTurn} · ${l.hintLabel}' : l.yourTurn);
      } else if (!table.holding) {
        text = l.waitingFor(table.infoFor(l, g.currentSeat).name);
      }
    }
    return SizedBox(
      height: 24,
      // Plain text: an AnimatedSwitcher keyed by text threw duplicate-key
      // errors when the same status reappeared within its fade.
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: hintShown && table.isHumanTurn
                ? c.chipText
                : (table.isHumanTurn ? c.textPrimary : c.textSecondary),
            fontSize: AppText.label,
            fontWeight: table.isHumanTurn ? FontWeight.w700 : FontWeight.w400,
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
    this.compact = false,
  });
  final List<Bid> bids;
  final void Function(Bid) onBid;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final h = compact ? 46.0 : 52.0;
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
          height: h,
          outlined: !active,
          onTap: on(Bid.contract(t)),
        ),
      );
    }

    Widget text(String key, String label, VoidCallback? onTap) => Expanded(
      child: PillButton(
        key: Key(key),
        label: label,
        height: h,
        outlined: !active,
        fontSize: AppText.body - 1,
        onTap: onTap,
      ),
    );

    const gap = SizedBox(width: Gap.s);
    const vgap = SizedBox(height: Gap.s);
    final canRedouble = bids.contains(Bid.redouble);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.l),
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
          vgap,
          Row(
            children: [
              text(
                'bid-noTrump',
                l.noTrump,
                on(const Bid.contract(ContractType.noTrump)),
              ),
              gap,
              text(
                'bid-allTrump',
                l.allTrump,
                on(const Bid.contract(ContractType.allTrump)),
              ),
            ],
          ),
          vgap,
          Row(
            children: [
              text('bid-pass', l.pass, on(Bid.pass)),
              gap,
              text(
                'bid-double',
                canRedouble ? l.redouble : l.double,
                canRedouble ? on(Bid.redouble) : on(Bid.double),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Strip above the hand during play: the local player's team-ringed avatar,
/// name and the current contract (mirrors Offsuit's "High Card" box).
class _SelfStrip extends StatelessWidget {
  const _SelfStrip({required this.table, required this.name});
  final TableState table;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = table.game;
    final contract = g.contract;
    final bubble = table.bubbles[kHumanSeat];
    final me = table.infoFor(l, kHumanSeat, name);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: Gap.m),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: table.isHumanTurn ? c.teamUs : c.outline,
            width: table.isHumanTurn ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            TeamEmoji(
              seat: kHumanSeat,
              emoji: me.emoji,
              size: 30,
              dealer: g.dealer == kHumanSeat,
              active: table.isHumanTurn,
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bubble != null ? announcementText(l, bubble) : me.name,
                    key: const Key('self-name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: bubble != null ? c.chipText : c.textPrimary,
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (contract != null)
                    Text(
                      '${contractName(l, contract.type)}${multiplierSuffix(l, contract.multiplier)} · ${table.infoFor(l, contract.declarer, name).name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
