import '../../online/rating.dart';
import '../quick/quick_labels.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/bot_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../online/room_client.dart';
import '../../online/room_logic.dart';
import '../../online/room_models.dart';
import '../game/difficulty_picker.dart';
import '../game/game_screen.dart';
import '../game/labels.dart';
import '../profile/profile_controller.dart';
import 'online_controller.dart';
import 'room_code.dart';

/// Names of the humans in the room (members and players holding seats);
/// bots never get one of these.
List<String> roomHumanNames(RoomClient c) => [
  for (final m in c.members.values) m.name,
  for (final s in c.seats ?? const <Seat>[])
    if (!s.bot && s.name != null) s.name!,
  c.name,
];

/// Avatar of a human at absolute seat [abs] (picked one or seat default).
String roomAvatar(RoomClient c, String? uid, int abs) =>
    c.members[uid]?.avatar ?? humanAvatar(kHumanAvatars[abs % 4]);

/// Names/emojis for the four view seats (0 = this player).
List<SeatInfo> seatInfosFor(
  AppLocalizations l,
  RoomClient c,
  String myName, [
  String? myAvatar,
  Map<String, int> ratings = const {},
]) {
  final mySeat = c.mySeat ?? 0;
  final seats = c.seats!;
  final bots = botNames(l, roomHumanNames(c));
  return [
    for (var v = 0; v < 4; v++)
      () {
        final abs = (v + mySeat) % 4;
        final s = seats[abs];
        if (v == 0) {
          return SeatInfo(
            humanAvatar(myAvatar ?? kSelfAvatar),
            myName,
            ratings[c.uid]?.toString(),
          );
        }
        if (!s.bot) {
          return SeatInfo(
            roomAvatar(c, s.uid, abs),
            s.name ?? '?',
            ratings[s.uid]?.toString(),
          );
        }
        return SeatInfo(kBotAvatar, bots[abs]);
      }(),
  ];
}

/// The room: lobby (team selection), the table, or the waiting screen for
/// a player who joined during a deal.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key});

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref, {
    bool confirm = true,
  }) async {
    final l = AppLocalizations.of(context);
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.leaveRoomTitle),
          content: Text(l.leaveRoomBody),
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
      if (ok != true) return;
    }
    await ref.read(onlineControllerProvider.notifier).leave();
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Quick match over: leave and queue again.
  Future<void> _quickAgain(BuildContext context, WidgetRef ref) async {
    await ref.read(onlineControllerProvider.notifier).leave();
    if (context.mounted) Navigator.of(context).pushReplacementNamed('/quick');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(onlineControllerProvider);
    final c = s.client;
    final ctrl = ref.read(onlineControllerProvider.notifier);
    if (c == null) {
      return _Message(
        text: l.connectionError,
        onBack: () => Navigator.of(context).pop(),
      );
    }
    switch (c.connection) {
      case RoomConnection.connecting:
        return _Message(
          text: l.connecting,
          onBack: () => _leave(context, ref, confirm: false),
        );
      case RoomConnection.notFound:
        return _Message(
          text: l.roomNotFound,
          onBack: () => _leave(context, ref, confirm: false),
        );
      case RoomConnection.closed:
        return _Message(
          text: l.roomClosed,
          onBack: () => _leave(context, ref, confirm: false),
        );
      case RoomConnection.error:
        return _Message(
          text: l.connectionError,
          onBack: () => _leave(context, ref, confirm: false),
        );
      case RoomConnection.active:
        break;
    }
    final meta = c.meta!;
    if (meta.status == RoomStatus.playing &&
        c.seats != null &&
        c.game != null) {
      final table = s.table;
      if (c.mySeat != null && table != null) {
        final quick = meta.quick;
        return TableView(
          table: table.copyWith(
            seatInfos: seatInfosFor(
              l,
              c,
              c.name,
              ref.watch(playerAvatarProvider),
              s.ratings,
            ),
          ),
          actions: ctrl,
          onLeave: () => _leave(context, ref, confirm: false),
          // Quick rooms are for strangers: no code / invite.
          footer: quick ? null : RoomCodeChip(code: c.code),
          newMatchLabel: quick ? l.quickAgain : l.backToLobby,
          onNewMatch: quick ? () => _quickAgain(context, ref) : null,
          secondaryLabel: quick ? l.goHome : null,
          onSecondary: quick
              ? () => _leave(context, ref, confirm: false)
              : null,
          matchExtra: quick ? RatingChangeLine(change: s.ratingChange) : null,
          leaveTitle: l.leaveOnlineGameTitle,
          leaveBody: l.leaveOnlineGameBody,
          notice: SeatNoticeToast(notice: s.notice),
          onEmote: ctrl.sendEmote,
          canEmote: () => ctrl.canEmote,
        );
      }
      return _WaitingView(client: c, onLeave: () => _leave(context, ref));
    }
    if (meta.quick) {
      return _QuickRoomView(
        over: meta.matchNo > 0,
        onAgain: () => _quickAgain(context, ref),
        onHome: () => _leave(context, ref, confirm: false),
      );
    }
    return _LobbyView(client: c, onLeave: () => _leave(context, ref));
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onBack});
  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  key: const Key('room-message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.body,
                  ),
                ),
                const SizedBox(height: Gap.xl),
                PillButton(label: l.back, onTap: onBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onLeave});
  final String title;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        IconButton(
          key: const Key('room-back'),
          onPressed: onLeave,
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
        ),
        const SizedBox(width: Gap.xs),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: AppText.title,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A neutral (grey) team box. Team colours are kept for the table, where
/// blue always means "your team".
class _TeamBox extends StatelessWidget {
  const _TeamBox({
    required this.team,
    required this.client,
    required this.bots,
    required this.onJoin,
  });
  final int team;
  final RoomClient client;
  final int bots;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final humans = RoomLogic.teamHumans(client.members, team).take(2).toList();
    final mine = client.me?.team == team;
    Widget slot(
      Widget leading,
      String text, {
      bool you = false,
      bool host = false,
      bool muted = false,
    }) => Container(
      height: 48,
      margin: const EdgeInsets.only(top: Gap.s),
      padding: const EdgeInsets.symmetric(horizontal: Gap.m),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted ? c.textSecondary : c.textPrimary,
                fontSize: AppText.label,
                fontWeight: you ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (host) Icon(Icons.star_rounded, size: 18, color: c.textSecondary),
        ],
      ),
    );
    final rows = <Widget>[
      for (final m in humans)
        slot(
          Text(
            m.avatar ??
                (m.name.isEmpty ? '?' : m.name.characters.first.toUpperCase()),
            key: Key('lobby-avatar-${m.uid}'),
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
          ),
          m.uid == client.uid ? '${m.name} (${l.youLabel})' : m.name,
          you: m.uid == client.uid,
          host: client.meta?.host == m.uid,
        ),
      for (var i = 0; i < bots; i++)
        slot(
          const Text(kBotAvatar),
          // The seat this bot will get when the match starts.
          botSeatInfo(
            l,
            team + 2 * (humans.length + i),
            roomHumanNames(client),
          ).name,
          muted: true,
        ),
    ];
    while (rows.length < 2) {
      rows.add(
        slot(
          Icon(Icons.person_outline_rounded, size: 18, color: c.textSecondary),
          l.emptySlot,
          muted: true,
        ),
      );
    }
    return Container(
      key: Key('team-$team'),
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: mine ? c.textSecondary : c.surface,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    team == 0 ? l.team1 : l.team2,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onJoin != null)
                  SizedBox(
                    height: 34,
                    child: TextButton(
                      key: Key('join-team-$team'),
                      onPressed: onJoin,
                      style: TextButton.styleFrom(
                        backgroundColor: c.surfaceHigh,
                        foregroundColor: c.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        l.joinTeam,
                        style: const TextStyle(
                          fontSize: AppText.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _LobbyView extends ConsumerWidget {
  const _LobbyView({required this.client, required this.onLeave});
  final RoomClient client;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final ctrl = ref.read(onlineControllerProvider.notifier);
    final members = client.members;
    final bots = client.meta!.bots;
    final noTeam = members.values
        .where((m) => m.online && m.team == null)
        .toList();
    final canFill = RoomLogic.canFillBots(members, bots);
    final canStart = RoomLogic.canStart(members, bots);
    final eachTeam =
        RoomLogic.teamHumans(members, 0).isNotEmpty &&
        RoomLogic.teamHumans(members, 1).isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onLeave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                key: const Key('lobby'),
                padding: const EdgeInsets.all(Gap.page),
                children: [
                  _Header(title: l.onlineTitle, onLeave: onLeave),
                  const SizedBox(height: Gap.l),
                  RoomCodeCard(code: client.code),
                  const SizedBox(height: Gap.l),
                  LayoutBuilder(
                    builder: (context, box) {
                      Widget team(int t) => _TeamBox(
                        team: t,
                        client: client,
                        bots: RoomLogic.lobbyBots(members, bots, t),
                        onJoin: RoomLogic.canJoinTeam(members, client.uid, t)
                            ? () => ctrl.setTeam(t)
                            : null,
                      );
                      if (box.maxWidth >= 480) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: team(0)),
                            const SizedBox(width: Gap.m),
                            Expanded(child: team(1)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          team(0),
                          const SizedBox(height: Gap.m),
                          team(1),
                        ],
                      );
                    },
                  ),
                  if (noTeam.isNotEmpty) ...[
                    const SizedBox(height: Gap.m),
                    Text(
                      '${l.spectators}: ${noTeam.map((m) => m.name).join(', ')}',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.label,
                      ),
                    ),
                  ],
                  const SizedBox(height: Gap.l),
                  Column(
                    key: const Key('lobby-bot-level'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$kBotAvatar ${l.botLevel}',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: AppText.label,
                        ),
                      ),
                      const SizedBox(height: Gap.s),
                      DifficultyPicker(
                        value: client.meta!.botLevel,
                        height: 42,
                        showHint: false,
                        onChanged: client.isHost
                            ? (v) => ctrl.setBotLevel(v)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.xl),
                  if (client.isHost) ...[
                    if (!canStart)
                      PillButton(
                        key: const Key('add-bots'),
                        label: l.addBots,
                        icon: Icons.smart_toy_outlined,
                        onTap: canFill ? ctrl.addBots : null,
                      ),
                    if (!canStart) const SizedBox(height: Gap.m),
                    PillButton(
                      key: const Key('start-game'),
                      label: l.startGame,
                      selected: canStart,
                      onTap: canStart ? ctrl.startMatch : null,
                    ),
                    const SizedBox(height: Gap.m),
                    if (!canStart)
                      Text(
                        eachTeam ? l.needFullTeams : l.needEachTeam,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: AppText.caption,
                        ),
                      ),
                  ] else
                    Text(
                      client.me?.team == null ? l.noTeamYet : l.waitingForHost,
                      key: const Key('waiting-host'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.label,
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

class _WaitingView extends ConsumerWidget {
  const _WaitingView({required this.client, required this.onLeave});
  final RoomClient client;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final ctrl = ref.read(onlineControllerProvider.notifier);
    final seats = client.seats!;
    final open = RoomLogic.openTeams(seats);
    final g = client.game!;
    final myTeam = client.me?.team;

    Widget teamChoice(int t) {
      final n = [t, t + 2].where((i) => seats[i].bot).length;
      final names = [
        for (final i in [t, t + 2])
          seats[i].bot
              ? () {
                  final b = botSeatInfo(l, i, roomHumanNames(client));
                  return '${b.emoji} ${b.name}';
                }()
              : (seats[i].name ?? '?'),
      ].join(' · ');
      final selected = myTeam == t;
      return Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: Key('wait-team-$t'),
          borderRadius: BorderRadius.circular(20),
          onTap: n > 0 ? () => ctrl.chooseWaitingTeam(t) : null,
          child: Container(
            padding: const EdgeInsets.all(Gap.l),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? c.textPrimary : c.surface,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t == 0 ? l.team1 : l.team2} · ${g.scores[t]}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: Gap.xs),
                      Text(
                        names,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: AppText.label,
                        ),
                      ),
                    ],
                  ),
                ),
                if (n > 0)
                  Text(
                    l.seatsWithBots(n),
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: AppText.caption,
                    ),
                  ),
                if (selected) ...[
                  const SizedBox(width: Gap.s),
                  Icon(
                    Icons.check_circle_rounded,
                    color: c.textPrimary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onLeave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                key: const Key('waiting-screen'),
                padding: const EdgeInsets.all(Gap.page),
                children: [
                  _Header(title: l.onlineTitle, onLeave: onLeave),
                  const SizedBox(height: Gap.xl),
                  const Center(
                    child: Text('⏳', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: Gap.m),
                  Text(
                    l.waitingTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: AppText.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Gap.s),
                  Text(
                    open.isEmpty ? l.waitingNoSeat : l.waitingBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: AppText.label,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  if (open.isNotEmpty) ...[
                    Text(
                      l.chooseTeam,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Gap.s),
                  ],
                  teamChoice(0),
                  const SizedBox(height: Gap.m),
                  teamChoice(1),
                  const SizedBox(height: Gap.xl),
                  RoomCodeChip(code: client.code),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text for a seat-change toast.
String seatNoticeText(AppLocalizations l, SeatNotice n) => switch (n.kind) {
  SeatNoticeKind.leftBot => l.seatLeftBot(n.name),
  SeatNoticeKind.back => l.seatBack(n.name),
  SeatNoticeKind.joined => l.seatJoined(n.name),
};

/// Small pill shown just above the player's own cards (over the status
/// line) that fades in and out when a seat changes hands. Ignores touches so
/// it never blocks the game.
class SeatNoticeToast extends StatelessWidget {
  const SeatNoticeToast({super.key, required this.notice});
  final SeatNotice? notice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final n = notice;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: n == null
                ? const SizedBox.shrink()
                : Material(
                    key: ValueKey(n.id),
                    color: c.surfaceHigh.withValues(alpha: 0.96),
                    elevation: 4,
                    shape: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.l,
                        vertical: Gap.s + 2,
                      ),
                      child: Text(
                        seatNoticeText(l, n),
                        key: const Key('seat-notice'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Quick match: "Rating 1012 (+12) · Silver" under the final score.
class RatingChangeLine extends StatelessWidget {
  const RatingChangeLine({super.key, this.change});
  final RatingChange? change;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final r = change;
    final up = (r?.delta ?? 0) >= 0;
    return Text(
      r == null
          ? l.ratingPending
          : l.ratingChange(
              r.after,
              signed(r.delta),
              rankName(l, RatingRank.of(r.after)),
            ),
      key: const Key('rating-change'),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: r == null ? c.textSecondary : (up ? c.success : c.danger),
        fontSize: AppText.body,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A quick room outside a match: setting up (before the first deal) or
/// the end of the match ("new quick match" / home).
class _QuickRoomView extends StatelessWidget {
  const _QuickRoomView({
    required this.over,
    required this.onAgain,
    required this.onHome,
  });
  final bool over;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(Gap.page),
              child: Column(
                key: const Key('quick-room'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!over) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: Gap.l),
                    Text(
                      l.quickWaitingStart,
                      style: TextStyle(color: c.textPrimary),
                    ),
                  ] else ...[
                    PillButton(
                      key: const Key('quick-again'),
                      label: l.quickAgain,
                      selected: true,
                      onTap: onAgain,
                    ),
                    const SizedBox(height: Gap.s),
                  ],
                  const SizedBox(height: Gap.s),
                  PillButton(
                    key: const Key('quick-home'),
                    label: l.goHome,
                    onTap: onHome,
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
