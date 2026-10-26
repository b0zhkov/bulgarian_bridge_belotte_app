import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../online/rating.dart';
import '../achievements/achievements.dart';
import '../quick/quick_labels.dart';
import '../quick/rating_controller.dart';

/// Profile: quick-match rating with its rank and the progress to the next.
class RatingCard extends ConsumerWidget {
  const RatingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final r = ref.watch(myRatingProvider);
    final rank = r.rank;
    final next = RatingRank.values.where((x) => x.min > r.value).firstOrNull;
    final from = rank.min == 0 ? 600 : rank.min;
    final progress = next == null
        ? 1.0
        : ((r.value - from) / (next.min - from)).clamp(0.0, 1.0);
    return Container(
      key: const Key('rating-card'),
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.value}',
                key: const Key('rating-value'),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: AppText.score + 6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l.rating,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.m,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  rankName(l, rank),
                  key: const Key('rating-rank'),
                  style: TextStyle(
                    color: c.chipText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: c.teamUs,
              backgroundColor: c.surfaceHigh,
            ),
          ),
          const SizedBox(height: Gap.s),
          Text(
            [
              if (next != null) '${rankName(l, next)} ${next.min}',
              l.ratingGames(r.games),
              l.ratingRules(kMinMatch.inMinutes, kDailyCap),
            ].join(' · '),
            style: TextStyle(color: c.textSecondary, fontSize: AppText.caption),
          ),
        ],
      ),
    );
  }
}

/// Profile: every achievement, unlocked ones in colour, locked greyed out.
class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final got = ref.watch(achievementsProvider);
    return Column(
      key: const Key('achievements'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.achievements,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppText.title,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              l.achievementsCount(got.length, Achievement.values.length),
              style: TextStyle(color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: Gap.m),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 460 ? 4 : 3;
            final w = (box.maxWidth - Gap.s * (cols - 1)) / cols;
            return Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: [
                for (final a in Achievement.values)
                  SizedBox(
                    width: w,
                    child: _AchievementTile(a: a, unlocked: got.containsKey(a)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.a, required this.unlocked});
  final Achievement a;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Tooltip(
      message: achievementDesc(l, a),
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        key: Key('ach-${a.name}'),
        height: 92,
        padding: const EdgeInsets.all(Gap.s),
        decoration: BoxDecoration(
          color: unlocked ? c.surfaceHigh : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unlocked ? c.chipText : c.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.3,
              child: Text(
                unlocked ? a.icon : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: Gap.xs),
            Text(
              achievementName(l, a),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? c.textPrimary : c.textSecondary,
                fontSize: AppText.caption,
                fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
