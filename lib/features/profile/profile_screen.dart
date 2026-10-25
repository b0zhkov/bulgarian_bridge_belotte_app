import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/bot_agent.dart';
import '../../core/agents/bot_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../game/difficulty_picker.dart';
import '../game/widgets/score_sheet.dart';
import '../stats/stats_controller.dart';
import 'match_history.dart';
import 'name_form.dart';
import 'profile_controller.dart';

String percent(double v) => '${(v * 100).round()}%';

/// One number + caption.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.big = false,
    this.detail,
  });
  final String value;
  final String label;
  final bool big;

  /// Small text after the value (e.g. "7/10").
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: big ? 34 : AppText.score,
                  fontWeight: FontWeight.w300,
                  height: 1.1,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: Gap.xs),
                Text(
                  detail!,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.caption,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.xs),
        Text(
          label,
          maxLines: 2,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: AppText.caption,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Large round avatar.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.emoji, this.size = 112});
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surfaceHigh,
        border: Border.all(color: c.outline, width: 1.5),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.56, height: 1.1)),
    );
  }
}

/// Grid of the avatars a player may pick; the robot is never offered.
Future<String?> showAvatarPicker(BuildContext context, String current) {
  final c = context.colors;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: c.surface,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return SafeArea(
        child: Padding(
          key: const Key('avatar-picker'),
          padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.chooseAvatar,
                style: TextStyle(color: c.textPrimary, fontSize: AppText.title),
              ),
              const SizedBox(height: Gap.l),
              GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                mainAxisSpacing: Gap.s,
                crossAxisSpacing: Gap.s,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final (i, a) in kHumanAvatars.indexed)
                    if (!isReservedAvatar(a))
                      Material(
                        color: a == current
                            ? c.surfaceHigh
                            : Colors.transparent,
                        shape: CircleBorder(
                          side: BorderSide(
                            color: a == current ? c.textPrimary : c.outline,
                            width: a == current ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          key: Key('avatar-$i'),
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(ctx).pop(a),
                          child: Center(
                            child: Text(
                              a,
                              style: const TextStyle(fontSize: 28, height: 1.1),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: Gap.m),
              Text(
                l.avatarReserved,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.caption,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String two(int v) => v.toString().padLeft(2, '0');

/// "25.10.2026, 19:14" in the device's local time.
String formatWhen(DateTime t) {
  final d = t.toLocal();
  return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
}

String modeLabel(AppLocalizations l, MatchRecord r) => r.mode.online
    ? l.historyOnline(r.room ?? '—')
    : l.historyOffline(levelLabel(l, r.mode.level!));

enum _Filter { all, offline, online }

/// Profile: avatar, name, stats (split offline by difficulty / online) and
/// the recent matches with their score sheets.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _Filter _filter = _Filter.all;
  BotLevel? _level;

  StatsBucket get _bucket => switch (_filter) {
    _Filter.all => StatsBucket.all,
    _Filter.online => StatsBucket.online,
    _Filter.offline =>
      _level == null ? StatsBucket.offline : StatsBucket.forLevel(_level!),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final book = ref.watch(statsProvider);
    final s = book[_bucket];
    final name = ref.watch(playerNameProvider) ?? l.you;
    final avatar = ref.watch(playerAvatarProvider);
    final history = ref.watch(matchHistoryProvider);

    Widget chip(String label, bool selected, VoidCallback onTap, Key key) =>
        Padding(
          padding: const EdgeInsets.only(right: Gap.s),
          child: ChoiceChip(
            key: key,
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onTap(),
            selectedColor: c.textPrimary,
            labelStyle: TextStyle(
              color: selected ? c.background : c.textPrimary,
              fontSize: AppText.label,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: c.surface,
            side: BorderSide(color: selected ? c.textPrimary : c.outline),
            shape: const StadiumBorder(),
          ),
        );

    Widget tile(Widget child) => Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.outline),
      ),
      child: child,
    );

    final tiles = [
      StatTile(
        key: const Key('stat-matches'),
        value: '${s.matchesPlayed}',
        label: l.statsMatches,
        big: true,
      ),
      StatTile(
        key: const Key('stat-wins'),
        value: '${s.matchesWon}',
        label: l.statsWins,
        big: true,
      ),
      StatTile(
        key: const Key('stat-winrate'),
        value: percent(s.winRate),
        label: l.statsWinRate,
        big: true,
      ),
      StatTile(
        key: const Key('stat-streak'),
        value: '${s.currentStreak}',
        label: l.statsStreak,
        big: true,
      ),
      StatTile(
        key: const Key('stat-best-streak'),
        value: '${s.bestStreak}',
        label: l.statsBestStreak,
        big: true,
      ),
      StatTile(
        key: const Key('stat-deals'),
        value: '${s.dealsPlayed}',
        label: l.statsDeals,
        big: true,
      ),
      StatTile(
        key: const Key('stat-contracts'),
        value: percent(s.contractSuccess),
        detail: '${s.contractsMade}/${s.contractsDeclared}',
        label: l.statsContractsPct,
        big: true,
      ),
      StatTile(
        key: const Key('stat-valats'),
        value: '${s.valats}',
        label: l.statsValats,
        big: true,
      ),
    ];

    final empty = book.all.matchesPlayed == 0 && book.all.dealsPlayed == 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.profile,
          style: const TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            key: const Key('profile-screen'),
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.s,
              Gap.page,
              Gap.xxl,
            ),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _pickAvatar(avatar),
                      child: AvatarCircle(
                        key: const Key('profile-avatar'),
                        emoji: avatar,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: c.textPrimary,
                        shape: CircleBorder(
                          side: BorderSide(color: c.background, width: 3),
                        ),
                        child: InkWell(
                          key: const Key('edit-avatar'),
                          customBorder: const CircleBorder(),
                          onTap: () => _pickAvatar(avatar),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: c.background,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.l),
              Center(
                child: InkWell(
                  key: const Key('edit-name'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showNameSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.m,
                      vertical: Gap.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            key: const Key('profile-name'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Gap.s),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: c.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.xl),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (f, label) in [
                      (_Filter.all, l.filterAll),
                      (_Filter.offline, l.filterOffline),
                      (_Filter.online, l.filterOnline),
                    ])
                      chip(
                        label,
                        _filter == f,
                        () => setState(() {
                          _filter = f;
                          _level = null;
                        }),
                        Key('filter-${f.name}'),
                      ),
                  ],
                ),
              ),
              if (_filter == _Filter.offline) ...[
                const SizedBox(height: Gap.s),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      chip(
                        l.allLevels,
                        _level == null,
                        () => setState(() => _level = null),
                        const Key('flevel-all'),
                      ),
                      for (final v in BotLevel.values)
                        chip(
                          levelLabel(l, v),
                          _level == v,
                          () => setState(() => _level = v),
                          Key('flevel-${v.name}'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.l),
              LayoutBuilder(
                builder: (context, box) {
                  final w = (box.maxWidth - Gap.m) / 2;
                  return Wrap(
                    spacing: Gap.m,
                    runSpacing: Gap.m,
                    children: [
                      for (final t in tiles) SizedBox(width: w, child: tile(t)),
                    ],
                  );
                },
              ),
              const SizedBox(height: Gap.xl),
              Text(
                l.matchHistory,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Gap.m),
              if (history.isEmpty)
                Text(
                  empty ? l.statsEmpty : l.historyEmpty,
                  key: const Key('history-empty'),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.label,
                  ),
                ),
              for (final (i, r) in history.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s),
                  child: _HistoryRow(
                    key: Key('history-$i'),
                    record: r,
                    onTap: () => showHistorySheet(context, r),
                  ),
                ),
              const SizedBox(height: Gap.xl),
              PillButton(
                label: l.statsReset,
                outlined: true,
                textColor: c.textSecondary,
                fontSize: AppText.label,
                height: 48,
                onTap: empty ? null : () => _confirmReset(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(String current) async {
    final a = await showAvatarPicker(context, current);
    if (a != null) ref.read(playerAvatarProvider.notifier).set(a);
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.statsReset,
          style: const TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.statsResetConfirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(statsProvider.notifier).reset();
      ref.read(matchHistoryProvider.notifier).clear();
    }
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({super.key, required this.record, required this.onTap});
  final MatchRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final r = record;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Gap.m),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 52,
                decoration: BoxDecoration(
                  color: r.won ? c.success : c.cardRed,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.won ? l.historyWin : l.historyLoss} · ${modeLabel(l, r)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: AppText.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l.teamUs}: ${r.us.join(', ')} · ${l.teamThem}: ${r.them.join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.caption,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatWhen(r.ended),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.m),
              Text(
                '${r.scores[0]} : ${r.scores[1]}',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Ние / Вие" sheet of a past match.
Future<void> showHistorySheet(BuildContext context, MatchRecord r) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: c.surface,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
      ),
      child: SafeArea(
        child: Padding(
          key: const Key('history-sheet'),
          padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${r.won ? l.historyWin : l.historyLoss} · ${modeLabel(l, r)}',
                style: TextStyle(color: c.textPrimary, fontSize: AppText.title),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                '${formatWhen(r.ended)}\n${l.teamUs}: ${r.us.join(', ')}\n${l.teamThem}: ${r.them.join(', ')}',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.caption,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: Gap.m),
              Flexible(child: ScoreSheetTable(game: r.sheetState)),
            ],
          ),
        ),
      ),
    ),
  );
}
