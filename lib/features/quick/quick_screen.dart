import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../online/quick_match.dart';
import 'quick_controller.dart';
import 'quick_labels.dart';
import 'rating_controller.dart';

/// "Бърза игра": waiting in the public queue with a countdown, the number
/// of players found and a cancel button; opens the room once matched.
class QuickMatchScreen extends ConsumerStatefulWidget {
  const QuickMatchScreen({super.key});

  @override
  ConsumerState<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends ConsumerState<QuickMatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(quickControllerProvider.notifier).start();
    });
  }

  Future<void> _cancel() async {
    await ref.read(quickControllerProvider.notifier).cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(quickControllerProvider);
    final rating = ref.watch(myRatingProvider);
    ref.listen(quickControllerProvider, (_, next) {
      if (next.status == QuickStatus.ready) {
        Navigator.of(context).pushReplacementNamed('/room');
      }
    });
    final total = QuickMatcher.wait.inSeconds;
    final searching = s.status == QuickStatus.searching;
    final failed = s.status == QuickStatus.failed;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _cancel,
          ),
          title: Text(l.quickTitle),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(Gap.page),
                child: Column(
                  key: const Key('quick-screen'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 168,
                      height: 168,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: searching
                                  ? s.secondsLeft / total
                                  : (failed ? 0 : null),
                              strokeWidth: 6,
                              color: c.teamUs,
                              backgroundColor: c.surfaceHigh,
                            ),
                          ),
                          Text(
                            searching
                                ? '${s.secondsLeft}'
                                : (failed ? '!' : '…'),
                            key: const Key('quick-countdown'),
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: AppText.display,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    Text(
                      failed
                          ? l.quickFailed
                          : searching
                          ? l.quickSearching
                          : l.quickStarting,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: AppText.title,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    if (!failed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < s.found ? c.teamUs : c.surfaceHigh,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.s),
                      Text(
                        l.quickFound(s.found),
                        key: const Key('quick-found'),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: AppText.body,
                        ),
                      ),
                      const SizedBox(height: Gap.s),
                      Text(
                        l.quickBotsHint(total),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: AppText.caption,
                        ),
                      ),
                      const SizedBox(height: Gap.l),
                      Text(
                        '${l.rating} ${rating.value} · ${rankName(l, rating.rank)}',
                        key: const Key('quick-rating'),
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: Gap.xxl),
                    if (failed) ...[
                      PillButton(
                        key: const Key('quick-retry'),
                        label: l.retry,
                        selected: true,
                        onTap: () =>
                            ref.read(quickControllerProvider.notifier).start(),
                      ),
                      const SizedBox(height: Gap.s),
                    ],
                    PillButton(
                      key: const Key('quick-cancel'),
                      label: l.quickCancel,
                      onTap: searching || failed ? _cancel : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
