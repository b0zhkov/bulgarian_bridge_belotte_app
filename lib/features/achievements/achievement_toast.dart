import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quick/quick_labels.dart';
import 'achievements.dart';

/// A small, silent pill at the top of the screen for each newly unlocked
/// achievement (one at a time). Never takes taps.
class AchievementToastHost extends ConsumerStatefulWidget {
  const AchievementToastHost({super.key});

  static Duration showFor = const Duration(milliseconds: 2800);

  @override
  ConsumerState<AchievementToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends ConsumerState<AchievementToastHost> {
  final List<Achievement> _queue = [];
  Achievement? _current;
  bool _visible = false;
  StreamSubscription<Achievement>? _sub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(achievementsProvider.notifier).unlocks.listen((a) {
      _queue.add(a);
      if (_current == null) _next();
    });
  }

  void _next() {
    if (!mounted) return;
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    setState(() {
      _current = _queue.removeAt(0);
      _visible = true;
    });
    _timer = Timer(AchievementToastHost.showFor, () {
      if (!mounted) return;
      setState(() => _visible = false);
      _timer = Timer(const Duration(milliseconds: 300), _next);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _current;
    if (a == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: _visible ? Offset.zero : const Offset(0, -0.6),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _visible ? 1 : 0,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    key: const Key('achievement-toast'),
                    margin: const EdgeInsets.fromLTRB(
                      Gap.page,
                      Gap.s,
                      Gap.page,
                      0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.l,
                      vertical: Gap.s,
                    ),
                    decoration: BoxDecoration(
                      color: c.chip,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: Gap.s),
                        Flexible(
                          child: Text(
                            '${l.achievementUnlocked}: ${achievementName(l, a)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.chipText,
                              fontSize: AppText.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
