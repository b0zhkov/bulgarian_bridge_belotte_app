import 'package:flutter/material.dart';

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../labels.dart';

void showHistorySheet(BuildContext context, GameState game) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.history,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 56,
                  child: Text(
                    l.us,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    l.them,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
              ],
            ),
            if (game.history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l.noDealsYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (i, d) in game.history.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.deal(i + 1),
                                  style: TextStyle(color: c.textPrimary),
                                ),
                                Text(
                                  '${contractName(l, d.contract.type)}${multiplierSuffix(l, d.contract.multiplier)} · ${outcomeLabel(l, d)}',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text(
                              '${d.scored[0]}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text(
                              '${d.scored[1]}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: c.outline),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.total,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${game.scores[0]}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: c.textPrimary, fontSize: 20),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${game.scores[1]}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: c.textPrimary, fontSize: 20),
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
