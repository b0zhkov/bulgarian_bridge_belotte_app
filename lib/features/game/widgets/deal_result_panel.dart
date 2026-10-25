import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../labels.dart';
import 'score_sheet.dart';

/// Overlay shown when a deal is scored or the match is over: an animated
/// recap of the deal (driven by the engine's [DealScoreBreakdown]) and, at
/// match end, the score sheet.
class DealResultPanel extends StatefulWidget {
  const DealResultPanel({
    super.key,
    required this.game,
    required this.onNext,
    required this.onNewMatch,
    this.newMatchLabel,
    this.waiting = false,
    this.nameOf,
    this.onRecapDone,
  });
  final GameState game;

  /// Called with the number of deals once the recap has finished counting
  /// (or was skipped); at match end right away (the sheet is shown).
  final void Function(int deals)? onRecapDone;
  final VoidCallback onNext;
  final VoidCallback onNewMatch;

  /// Online: label for the match-over button ("back to lobby").
  final String? newMatchLabel;

  /// Online: this player already continued; waiting for the others.
  final bool waiting;

  /// Display name for a (view) seat.
  final String Function(int seat)? nameOf;

  @override
  State<DealResultPanel> createState() => _DealResultPanelState();
}

class _DealResultPanelState extends State<DealResultPanel> {
  /// Match over: show the sheet (default) or the last deal's recap.
  bool _sheet = true;

  @override
  void initState() {
    super.initState();
    if (widget.game.phase == GamePhase.matchOver) _done();
  }

  void _done() {
    final n = widget.game.history.length;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onRecapDone?.call(n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final game = widget.game;
    final over = game.phase == GamePhase.matchOver;
    final won = game.winnerTeam == 0;
    final waiting = widget.waiting;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        color: c.background.withValues(alpha: 0.86),
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
                      style: const TextStyle(fontSize: 44),
                    ),
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
                    const SizedBox(height: Gap.m),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            key: const Key('tab-sheet'),
                            label: l.sheetTab,
                            height: 40,
                            fontSize: 14,
                            selected: _sheet,
                            onTap: () => setState(() => _sheet = true),
                          ),
                        ),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: PillButton(
                            key: const Key('tab-recap'),
                            label: l.recapTab,
                            height: 40,
                            fontSize: 14,
                            selected: !_sheet,
                            onTap: () => setState(() => _sheet = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.l),
                  ],
                  if (over && _sheet)
                    ScoreSheetTable(game: game, shrinkWrap: true)
                  else
                    DealRecap(
                      key: ValueKey('recap-${game.history.length}'),
                      game: game,
                      nameOf: widget.nameOf,
                      onDone: _done,
                    ),
                  const SizedBox(height: 18),
                  PillButton(
                    key: const Key('result-continue'),
                    label: waiting
                        ? l.readyWaiting
                        : over
                        ? (widget.newMatchLabel ?? l.newMatch)
                        : l.nextDeal,
                    selected: !waiting,
                    onTap: waiting
                        ? null
                        : (over ? widget.onNewMatch : widget.onNext),
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

class _Row {
  const _Row(
    this.key,
    this.label,
    this.points, {
    this.sub,
    this.strong = false,
  });
  final String key;
  final String label;
  final List<int> points;
  final String? sub;
  final bool strong;
}

/// Animated breakdown of the last deal: each line appears in turn and its
/// numbers count up; tap to show everything at once. Reduced motion shows the
/// final state directly. Every number comes from the engine's score.
class DealRecap extends StatefulWidget {
  const DealRecap({super.key, required this.game, this.nameOf, this.onDone});
  final GameState game;

  /// Counting finished or skipped.
  final VoidCallback? onDone;
  final String Function(int seat)? nameOf;

  /// Delay between lines and the count-up duration of each line.
  static Duration step = const Duration(milliseconds: 260);
  static Duration count = const Duration(milliseconds: 520);

  @override
  State<DealRecap> createState() => _DealRecapState();
}

class _DealRecapState extends State<DealRecap>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  int _lines = 0;

  DealScore get d => widget.game.lastDeal!;

  List<_Row> _rows(AppLocalizations l) {
    final rows = <_Row>[];
    for (final line in d.breakdown) {
      switch (line.step) {
        case ScoreStep.cards:
          rows.add(_Row('cards', l.cardPoints, line.points));
        case ScoreStep.lastTen:
          rows.add(_Row('lastTen', l.lastTen, line.points));
        case ScoreStep.declarations:
          rows.add(
            _Row(
              'declarations',
              l.premiums,
              line.points,
              sub: d.scoringDeclarations
                  .map((x) => declarationName(l, x))
                  .join(' · '),
            ),
          );
        case ScoreStep.belot:
          rows.add(_Row('belot', l.belot, line.points));
        case ScoreStep.noTrumpDouble:
          rows.add(_Row('noTrumpDouble', l.noTrumpDouble, line.points));
        case ScoreStep.valat:
          rows.add(_Row('valat', l.valat, line.points));
      }
    }
    rows.add(_Row('raw', l.total, d.rawPoints, strong: true));
    return rows;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctrl != null) return;
    final l = AppLocalizations.of(context);
    // Lines + outcome + written (+ hanging awarded).
    _lines = _rows(l).length + 2 + (d.hangingAwarded > 0 ? 1 : 0);
    final total = DealRecap.step * (_lines - 1) + DealRecap.count;
    _ctrl = AnimationController(vsync: this, duration: total)
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) widget.onDone?.call();
      });
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _ctrl!.value = 1;
    } else {
      _ctrl!.forward();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  /// Progress (0..1) of line [i].
  double _p(int i) {
    final ctrl = _ctrl!;
    final ms = ctrl.value * ctrl.duration!.inMicroseconds;
    final start = DealRecap.step.inMicroseconds * i;
    return ((ms - start) / DealRecap.count.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final rows = _rows(l);
    final contract = d.contract;
    final declarer = widget.nameOf?.call(contract.declarer);

    String outcomeText() {
      final mult = contract.multiplier;
      if (mult != Multiplier.none) {
        final name = mult == Multiplier.doubled ? l.double : l.redouble;
        return d.outcome == DealOutcome.hanging
            ? l.doubledHangingExplain(name, mult.factor)
            : '${outcomeLabel(l, d)} · ${l.doubledExplain(name, mult.factor)}';
      }
      return switch (d.outcome) {
        DealOutcome.outside => l.outsideExplain,
        DealOutcome.inside => l.insideExplain,
        DealOutcome.hanging => l.hangingExplain,
      };
    }

    Widget numbers(int i, String key, List<int> pts, {bool strong = false}) {
      final p = Curves.easeOutCubic.transform(_p(i));
      TextStyle st(int t) => TextStyle(
        color: strong ? c.textPrimary : c.textSecondary,
        fontSize: strong ? AppText.title : AppText.body,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var t = 0; t < 2; t++)
            SizedBox(
              width: 64,
              child: Text(
                '${(pts[t] * p).round()}',
                key: Key('recap-$key-$t'),
                textAlign: TextAlign.right,
                style: st(t),
              ),
            ),
        ],
      );
    }

    Widget line(int i, Widget child) {
      final p = _p(i);
      return Opacity(
        opacity: math.min(1, p * 3),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - math.min(1, p * 3))),
          child: child,
        ),
      );
    }

    Widget labelled(String label, {String? sub, bool strong = false}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: strong ? c.textPrimary : c.textSecondary,
                  fontSize: strong ? AppText.body : AppText.label,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (sub != null && sub.isNotEmpty)
                Text(
                  sub,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.caption,
                  ),
                ),
            ],
          ),
        );

    final written = d.writtenForDeal;
    final outcomeIndex = rows.length;
    final writtenIndex = rows.length + 1;

    return GestureDetector(
      key: const Key('recap'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_ctrl!.isAnimating) _ctrl!.value = 1;
      },
      child: AnimatedBuilder(
        animation: _ctrl!,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ContractGlyph(
                  contract.type,
                  size: 26,
                  color: c.textPrimary,
                  red: c.cardRed,
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${contractName(l, contract.type)}${multiplierSuffix(l, contract.multiplier)}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.title,
                        ),
                      ),
                      if (declarer != null)
                        Text(
                          l.playsContract(declarer),
                          style: TextStyle(
                            color: contract.declarerTeam == 0
                                ? c.teamUs
                                : c.teamThem,
                            fontSize: AppText.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.m),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                for (final (label, color) in [
                  (l.us, c.teamUs),
                  (l.them, c.teamThem),
                ])
                  SizedBox(
                    width: 64,
                    child: Text(
                      label,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.xs),
            for (final (i, r) in rows.indexed)
              line(
                i,
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: r.strong
                      ? BoxDecoration(
                          border: Border(top: BorderSide(color: c.outline)),
                        )
                      : null,
                  child: Row(
                    children: [
                      labelled(r.label, sub: r.sub, strong: r.strong),
                      numbers(i, r.key, r.points, strong: r.strong),
                    ],
                  ),
                ),
              ),
            line(
              outcomeIndex,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.s),
                child: Text(
                  outcomeText(),
                  key: const Key('recap-outcome'),
                  style: TextStyle(color: c.chipText, fontSize: AppText.label),
                ),
              ),
            ),
            line(
              writtenIndex,
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: c.textPrimary, width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    labelled(l.written, strong: true),
                    numbers(writtenIndex, 'written', written, strong: true),
                  ],
                ),
              ),
            ),
            if (d.hangingAwarded > 0)
              line(
                writtenIndex + 1,
                Row(
                  children: [
                    labelled(l.hangingAwardedLine(d.hangingAwarded)),
                    numbers(writtenIndex + 1, 'awarded', [
                      for (var t = 0; t < 2; t++)
                        d.hangingAwardedTo == t ? d.hangingAwarded : 0,
                    ]),
                  ],
                ),
              ),
            if (d.newlyHanging > 0 || widget.game.hanging > 0)
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Text(
                  l.hanging(widget.game.hanging),
                  key: const Key('recap-hanging'),
                  style: TextStyle(color: c.chipText),
                ),
              ),
            const SizedBox(height: Gap.s),
            Text(
              '${l.matchScore}  ${widget.game.scores[0]} : ${widget.game.scores[1]}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
            AnimatedOpacity(
              opacity: _ctrl!.isAnimating ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                l.tapToSkip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
