import 'package:flutter/material.dart';

import '../../core/agents/bot_agent.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';

String levelLabel(AppLocalizations l, BotLevel v) => switch (v) {
  BotLevel.easy => l.levelEasy,
  BotLevel.medium => l.levelMedium,
  BotLevel.hard => l.levelHard,
};

String levelHint(AppLocalizations l, BotLevel v) => switch (v) {
  BotLevel.easy => l.levelEasyHint,
  BotLevel.medium => l.levelMediumHint,
  BotLevel.hard => l.levelHardHint,
};

/// Лесно / Средно / Трудно as three pills (keys `level-easy` ...), with a
/// one-line description of the selected level. [onChanged] null = read
/// only (e.g. non-host players in the lobby).
class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.value,
    this.onChanged,
    this.showHint = true,
    this.height = 48,
  });

  final BotLevel value;
  final ValueChanged<BotLevel>? onChanged;
  final bool showHint;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final v in BotLevel.values) ...[
              if (v != BotLevel.values.first) const SizedBox(width: Gap.s),
              Expanded(
                child: PillButton(
                  key: Key('level-${v.name}'),
                  label: levelLabel(l, v),
                  height: height,
                  fontSize: 15,
                  selected: v == value,
                  onTap: onChanged == null && v != value
                      ? null
                      : () => onChanged?.call(v),
                ),
              ),
            ],
          ],
        ),
        if (showHint) ...[
          const SizedBox(height: Gap.s),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              levelHint(l, value),
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
