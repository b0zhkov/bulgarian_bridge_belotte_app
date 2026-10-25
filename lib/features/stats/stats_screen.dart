import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/profile_controller.dart';
import 'stats_controller.dart';

String percent(double v) => '${(v * 100).round()}%';

/// One number + caption tile.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.big = false,
  });
  final String value;
  final String label;
  final bool big;

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
          child: Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: big ? 34 : AppText.score,
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
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

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(statsProvider);
    final name = ref.watch(playerNameProvider) ?? l.you;

    Widget box(Widget child) => Container(
      padding: const EdgeInsets.all(Gap.page),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.outline),
      ),
      child: child,
    );

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: Gap.l),
        Expanded(child: b),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.stats,
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
            key: const Key('stats-screen'),
            padding: const EdgeInsets.all(Gap.page),
            children: [
              Text(
                name,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Gap.xs),
              Text(
                l.statsSubtitle,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.label,
                ),
              ),
              const SizedBox(height: Gap.xl),
              box(
                Column(
                  children: [
                    pair(
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
                    ),
                    const SizedBox(height: Gap.xl),
                    pair(
                      StatTile(
                        key: const Key('stat-winrate'),
                        value: percent(s.winRate),
                        label: l.statsWinRate,
                        big: true,
                      ),
                      StatTile(
                        key: const Key('stat-deals'),
                        value: '${s.dealsPlayed}',
                        label: l.statsDeals,
                        big: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.l),
              box(
                Column(
                  children: [
                    pair(
                      StatTile(
                        value: s.avgPointsPerDeal.toStringAsFixed(1),
                        label: l.statsAvgPoints,
                      ),
                      StatTile(
                        value: '${s.contractsMade}/${s.contractsDeclared}',
                        label: l.statsContracts,
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    pair(
                      StatTile(value: '${s.valats}', label: l.statsValats),
                      const SizedBox(),
                    ),
                  ],
                ),
              ),
              if (s.matchesPlayed == 0 && s.dealsPlayed == 0) ...[
                const SizedBox(height: Gap.l),
                Text(
                  l.statsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.label,
                  ),
                ),
              ],
              const SizedBox(height: Gap.xxl),
              PillButton(
                label: l.statsReset,
                outlined: true,
                textColor: c.textSecondary,
                fontSize: AppText.label,
                height: 48,
                onTap: s.dealsPlayed == 0 && s.matchesPlayed == 0
                    ? null
                    : () async {
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
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
