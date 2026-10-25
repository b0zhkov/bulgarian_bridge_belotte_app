import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../game/widgets/playing_card.dart';
import 'settings_controller.dart';

String cardBackName(AppLocalizations l, CardBackStyle s) => switch (s) {
  CardBackStyle.classic => l.backClassic,
  CardBackStyle.midnight => l.backMidnight,
  CardBackStyle.forest => l.backForest,
  CardBackStyle.mono => l.backMono,
};

String tableTintName(AppLocalizations l, TableTint t) => switch (t) {
  TableTint.classic => l.tableClassic,
  TableTint.felt => l.tableFelt,
  TableTint.wine => l.tableWine,
  TableTint.slate => l.tableSlate,
};

/// Settings: card back designs and table colours, each with a preview.
class TableStylePicker extends ConsumerWidget {
  const TableStylePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final back = ref.watch(cardBackProvider);
    final tint = ref.watch(tableTintProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.s, left: Gap.xs),
      child: Text(
        t,
        style: TextStyle(color: c.textPrimary, fontSize: AppText.body),
      ),
    );

    Widget option({
      required Key key,
      required bool selected,
      required VoidCallback onTap,
      required Widget preview,
      required String name,
    }) => Expanded(
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? c.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: preview,
            ),
            const SizedBox(height: Gap.xs),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? c.textPrimary : c.textSecondary,
                fontSize: AppText.caption,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(l.cardBack),
        Row(
          children: [
            for (final s in CardBackStyle.values)
              option(
                key: Key('back-${s.name}'),
                selected: s == back,
                onTap: () => ref.read(cardBackProvider.notifier).set(s),
                name: cardBackName(l, s),
                preview: _BackPreview(style: s),
              ),
          ],
        ),
        const SizedBox(height: Gap.l),
        label(l.tableColor),
        Row(
          children: [
            for (final t in TableTint.values)
              option(
                key: Key('table-${t.name}'),
                selected: t == tint,
                onTap: () => ref.read(tableTintProvider.notifier).set(t),
                name: tableTintName(l, t),
                preview: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: dark ? t.dark : t.light,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.outline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(c.teamUs),
                      const SizedBox(width: 6),
                      _dot(c.teamThem),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Widget _dot(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _BackPreview extends StatelessWidget {
  const _BackPreview({required this.style});
  final CardBackStyle style;

  @override
  Widget build(BuildContext context) {
    final (base, line) = style.colors;
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(painter: CardBackPainter(line, style)),
      ),
    );
  }
}
