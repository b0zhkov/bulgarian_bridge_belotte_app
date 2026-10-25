import 'package:flutter/material.dart';

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../labels.dart';

/// Overlay shown when a deal is scored or the match is over.
class DealResultPanel extends StatelessWidget {
  const DealResultPanel({
    super.key,
    required this.game,
    required this.onNext,
    required this.onNewMatch,
  });
  final GameState game;
  final VoidCallback onNext;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final d = game.lastDeal!;
    final over = game.phase == GamePhase.matchOver;
    final won = game.winnerTeam == 0;

    TableRow row(String label, int a, int b, {bool strong = false}) {
      final st = TextStyle(
        color: strong ? c.textPrimary : c.textSecondary,
        fontSize: strong ? AppText.body : AppText.label,
        fontWeight: strong ? FontWeight.w500 : FontWeight.w400,
      );
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label, style: st),
          ),
          Text('$a', textAlign: TextAlign.right, style: st),
          Text('$b', textAlign: TextAlign.right, style: st),
        ],
      );
    }

    final noTrumpFactor = d.contract.type == ContractType.noTrump ? 2 : 1;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        color: c.background.withValues(alpha: 0.82),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.page),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                Gap.xl,
                Gap.xl,
                Gap.xl,
                Gap.page,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (over) ...[
                    Text(
                      won ? '🏆' : '🤝',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      won ? l.matchWon : l.matchLost,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      l.finalScore(game.scores[0], game.scores[1]),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    l.dealResult,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: AppText.caption,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${contractName(l, d.contract.type)}${multiplierSuffix(l, d.contract.multiplier)} · ${outcomeLabel(l, d)}',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: AppText.title,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        children: [
                          const SizedBox(),
                          Text(
                            l.us,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            l.them,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      row(
                        l.cardPoints,
                        d.cardPoints[0] * noTrumpFactor,
                        d.cardPoints[1] * noTrumpFactor,
                      ),
                      row(
                        l.lastTen,
                        d.lastTrickTeam == 0 ? 10 * noTrumpFactor : 0,
                        d.lastTrickTeam == 1 ? 10 * noTrumpFactor : 0,
                      ),
                      if (d.contract.type != ContractType.noTrump) ...[
                        row(
                          l.premiums,
                          d.declarationPoints[0],
                          d.declarationPoints[1],
                        ),
                        row(l.belot, d.belotPoints[0], d.belotPoints[1]),
                      ],
                      if (d.isValat)
                        row(
                          l.valat,
                          d.valatTeam == 0 ? 90 : 0,
                          d.valatTeam == 1 ? 90 : 0,
                        ),
                      row(
                        l.total,
                        d.rawPoints[0],
                        d.rawPoints[1],
                        strong: true,
                      ),
                      row(l.written, d.scored[0], d.scored[1], strong: true),
                    ],
                  ),
                  if (d.newlyHanging > 0 || game.hanging > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l.hanging(game.hanging),
                        style: TextStyle(color: c.chipText),
                      ),
                    ),
                  const SizedBox(height: 18),
                  PillButton(
                    key: const Key('result-continue'),
                    label: over ? l.newMatch : l.nextDeal,
                    selected: true,
                    onTap: over ? onNewMatch : onNext,
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
