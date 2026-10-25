import '../../core/widgets/pill_button.dart';
import '../game/difficulty_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/card.dart' as m;
import '../../core/perf/perf_log.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/suit_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../game/widgets/playing_card.dart';
import '../profile/profile_controller.dart';
import '../pwa/pwa_banners.dart';
import '../stats/stats_controller.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final name = ref.watch(playerNameProvider);
    final stats = ref.watch(statsProvider).all;
    final avatar = ref.watch(playerAvatarProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Gap.page,
                Gap.s,
                Gap.page,
                Gap.xl,
              ),
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      for (final suit in const [
                        m.Suit.spades,
                        m.Suit.hearts,
                        m.Suit.clubs,
                        m.Suit.diamonds,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: Gap.s),
                          child: SuitIcon(
                            suit,
                            size: 16,
                            color: suit.isRed ? c.cardRed : c.textSecondary,
                          ),
                        ),
                      const Spacer(),
                      InkWell(
                        key: const Key('open-profile'),
                        customBorder: const CircleBorder(),
                        onTap: () =>
                            Navigator.of(context).pushNamed('/profile'),
                        child: AvatarCircle(emoji: avatar, size: 40),
                      ),
                      const SizedBox(width: Gap.xs),
                      IconButton(
                        key: const Key('open-settings'),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: c.textPrimary,
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/settings'),
                      ),
                    ],
                  ),
                ),
                const PwaBanners(),
                const SizedBox(height: Gap.xl),
                if (name != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/profile'),
                      child: Text(
                        l.greeting(name),
                        key: const Key('greeting'),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: AppText.body,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: Gap.xs),
                Text(
                  l.appTitle,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.display,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: Gap.xl),
                _ModeCard(
                  key: const Key('play-offline'),
                  title: l.homeOfflineTitle,
                  subtitle: l.homeOfflineSubtitle,
                  colors: const [Color(0xFFE4E9FF), Color(0xFFDDF0D8)],
                  art: const _FannedCards(),
                  onTap: () => showOfflineStartSheet(context),
                ),
                const SizedBox(height: Gap.m),
                _ModeCard(
                  key: const Key('play-online'),
                  title: l.homeOnlineTitle,
                  subtitle: l.homeOnlineSubtitle,
                  colors: const [Color(0xFFFFE3E0), Color(0xFFFFF1D6)],
                  art: const Text('👥', style: TextStyle(fontSize: 44)),
                  onTap: () => Navigator.of(context).pushNamed('/online'),
                ),
                const SizedBox(height: Gap.m),
                _StatsCard(stats: stats),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('open-stats'),
        onTap: () => Navigator.of(context).pushNamed('/profile'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.page, Gap.l, Gap.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.stats,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: AppText.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
              const SizedBox(height: Gap.l),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${stats.matchesPlayed}',
                      label: l.statsMatches,
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      value: '${stats.matchesWon}',
                      label: l.statsWins,
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      value: percent(stats.winRate),
                      label: l.statsWinRate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.art,
    this.onTap,
  }) : badge = null;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Widget art;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 76, child: art),
                    const Spacer(),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.m,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x14000000),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontSize: AppText.caption,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.l),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: AppText.label,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FannedCards extends StatelessWidget {
  const _FannedCards();

  @override
  Widget build(BuildContext context) {
    const cards = [
      m.Card(m.Suit.spades, m.Rank.jack),
      m.Card(m.Suit.hearts, m.Rank.nine),
      m.Card(m.Suit.clubs, m.Rank.ace),
    ];
    return SizedBox(
      width: 130,
      child: Stack(
        children: [
          for (final (i, card) in cards.indexed)
            Positioned(
              left: i * 28.0,
              top: 4,
              child: Transform.rotate(
                angle: (i - 1) * 0.12,
                child: PlayingCardView(card: card, width: 50),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown before an offline game: pick the bots' difficulty
/// (preselected with the default from Settings, which it also updates).
Future<void> showOfflineStartSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => const _OfflineStartSheet(),
    );

class _OfflineStartSheet extends ConsumerWidget {
  const _OfflineStartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final level = ref.watch(botLevelProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.l),
        child: Column(
          key: const Key('offline-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.chooseDifficulty,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppText.title,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Gap.l),
            DifficultyPicker(
              value: level,
              onChanged: (v) => ref.read(botLevelProvider.notifier).set(v),
            ),
            const SizedBox(height: Gap.xl),
            PillButton(
              key: const Key('start-offline'),
              label: l.play,
              selected: true,
              onTap: () {
                PerfLog.mark('tap play');
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/game');
              },
            ),
          ],
        ),
      ),
    );
  }
}
