import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../labels.dart';

/// Keeps a [ValueListenable] of the table's game so sheets opened from the
/// table (separate routes) follow live updates, e.g. host state online.
class LiveGame extends StatefulWidget {
  const LiveGame({super.key, required this.game, required this.builder});
  final GameState game;
  final Widget Function(
    BuildContext context,
    ValueListenable<GameState> live,
    ValueNotifier<int> recapDone,
  )
  builder;

  @override
  State<LiveGame> createState() => _LiveGameState();
}

class _LiveGameState extends State<LiveGame> {
  late final ValueNotifier<GameState> _live = ValueNotifier(widget.game);

  /// Number of deals whose recap has finished (or was skipped); the score
  /// shown at the top waits for it.
  late final ValueNotifier<int> _recapDone = ValueNotifier(
    widget.game.history.length,
  );

  @override
  void didUpdateWidget(LiveGame old) {
    super.didUpdateWidget(old);
    if (!identical(old.game, widget.game)) {
      // Never notify during build.
      final g = widget.game;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _live.value = g;
      });
    }
  }

  @override
  void dispose() {
    _live.dispose();
    _recapDone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _live, _recapDone);
}

/// The score sheet as a bottom sheet that follows [live].
Future<void> showScoreSheet(
  BuildContext context,
  ValueListenable<GameState> live, {
  String Function(int seat)? nameOf,
}) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: c.surface,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
      ),
      child: SafeArea(
        child: Padding(
          key: const Key('score-sheet'),
          padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.scoreSheetTitle,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                l.tapRowForDetails,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.caption,
                ),
              ),
              const SizedBox(height: Gap.m),
              Flexible(
                child: ValueListenableBuilder<GameState>(
                  valueListenable: live,
                  builder: (context, g, _) =>
                      ScoreSheetTable(game: g, nameOf: nameOf),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Classic "Ние / Вие" paper sheet: one row per deal with the points written
/// for each team, a small running total, the contract badge in the middle and
/// markers (вкарана, висяща, капо, контра…), then the totals.
class ScoreSheetTable extends StatelessWidget {
  const ScoreSheetTable({
    super.key,
    required this.game,
    this.shrinkWrap = false,
    this.nameOf,
  });
  final GameState game;
  final bool shrinkWrap;

  /// Display name for a (view) seat, for declaration owners in the details.
  final String Function(int seat)? nameOf;

  static const double _mid = 52;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final rows = game.history;
    final line = BorderSide(color: c.textSecondary.withValues(alpha: 0.5));

    Widget header(String text, Color color) => Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: AppText.body,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final running = [0, 0];
    final body = <Widget>[];
    for (final (i, d) in rows.indexed) {
      running[0] += d.scored[0];
      running[1] += d.scored[1];
      body.add(
        _SheetRow(
          key: Key('sheet-row-$i'),
          index: i,
          deal: d,
          totals: List.of(running),
          divider: line,
          nameOf: nameOf,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: Gap.s),
          decoration: BoxDecoration(border: Border(bottom: line)),
          child: Row(
            children: [
              header(l.us, c.teamUs),
              const SizedBox(width: _mid),
              header(l.them, c.teamThem),
            ],
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xl),
            child: Text(
              l.noDealsYet,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
          )
        else
          _fit(
            // Reversed so the latest deal (bottom) is visible first.
            ListView(
              shrinkWrap: true,
              reverse: true,
              padding: EdgeInsets.zero,
              children: body.reversed.toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.only(top: Gap.s),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.textPrimary, width: 1.5)),
          ),
          child: Row(
            children: [
              _total(c, '${game.scores[0]}', const Key('sheet-total-us')),
              SizedBox(
                width: _mid,
                child: game.hanging > 0
                    ? Text(
                        l.hangingLeft(game.hanging),
                        key: const Key('sheet-hanging'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.chipText, fontSize: 10),
                      )
                    : null,
              ),
              _total(c, '${game.scores[1]}', const Key('sheet-total-them')),
            ],
          ),
        ),
      ],
    );
  }

  /// In a bottom sheet the rows take the free height; inside a scrolling
  /// panel ([shrinkWrap]) they get a fixed maximum.
  Widget _fit(Widget list) => shrinkWrap
      ? ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: list,
        )
      : Flexible(child: list);

  Widget _total(BelotColors c, String v, Key key) => Expanded(
    child: Text(
      v,
      key: key,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: c.textPrimary,
        fontSize: AppText.score,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SheetRow extends StatefulWidget {
  const _SheetRow({
    super.key,
    required this.index,
    required this.deal,
    required this.totals,
    required this.divider,
    this.nameOf,
  });
  final int index;
  final DealScore deal;
  final List<int> totals;
  final BorderSide divider;
  final String Function(int seat)? nameOf;

  @override
  State<_SheetRow> createState() => _SheetRowState();
}

class _SheetRowState extends State<_SheetRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final d = widget.deal;
    final index = widget.index;
    final totals = widget.totals;
    final divider = widget.divider;
    final marks = sheetMarks(l, d);

    Widget cell(int t) {
      final pts = d.scored[t];
      return Expanded(
        child: Column(
          children: [
            Text(
              pts == 0 ? '–' : '$pts',
              key: Key('sheet-${t == 0 ? 'us' : 'them'}-$index'),
              style: TextStyle(
                color: pts == 0 ? c.textSecondary : c.textPrimary,
                fontSize: AppText.title,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
            Text(
              '${totals[t]}',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
          ],
        ),
      );
    }

    final declarerTeam = d.contract.declarerTeam;
    return InkWell(
      key: Key('sheet-tap-$index'),
      onTap: () => setState(() => _open = !_open),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Gap.s),
        decoration: BoxDecoration(
          border: Border(bottom: divider.copyWith(width: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                cell(0),
                SizedBox(
                  width: ScoreSheetTable._mid,
                  child: Center(
                    child: Container(
                      key: Key('sheet-badge-$index'),
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.surfaceHigh,
                        border: Border.all(
                          color: declarerTeam == 0 ? c.teamUs : c.teamThem,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ContractGlyph(
                            d.contract.type,
                            size: 16,
                            color: c.textPrimary,
                            red: c.cardRed,
                          ),
                          if (d.contract.multiplier != Multiplier.none)
                            Text(
                              '×${d.contract.multiplier.factor}',
                              style: TextStyle(
                                color: c.chipText,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                cell(1),
              ],
            ),
            if (marks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  marks,
                  key: Key('sheet-marks-$index'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.chipText,
                    fontSize: AppText.caption,
                  ),
                ),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: Gap.s),
                      child: DealBreakdown(
                        key: Key('sheet-details-$index'),
                        deal: d,
                        index: index,
                        nameOf: widget.nameOf,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static per-deal breakdown for the score sheet: contract, card points,
/// last 10, each declaration (in its owner's column), belot, the No Trump
/// doubling, капо, the raw totals, the outcome (контра / реконтра, вкарана,
/// висяща), the belot.bg rounding and the points written.
class DealBreakdown extends StatelessWidget {
  const DealBreakdown({super.key, required this.deal, this.index, this.nameOf});
  final DealScore deal;
  final int? index;
  final String Function(int seat)? nameOf;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final d = deal;
    final contract = d.contract;
    final dt = contract.declarerTeam;
    final declarer = nameOf?.call(contract.declarer) ?? teamName(l, dt);

    Widget nums(String key, List<int> pts, {bool strong = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var t = 0; t < 2; t++)
          SizedBox(
            width: 52,
            child: Text(
              strong || pts[t] != 0 ? '${pts[t]}' : '–',
              key: Key('detail-$key-$t'),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: strong
                    ? c.textPrimary
                    : (pts[t] == 0
                          ? c.textSecondary.withValues(alpha: 0.5)
                          : c.textPrimary),
                fontSize: strong ? AppText.body : AppText.label,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );

    Widget row(
      String key,
      String label,
      List<int> pts, {
      String? sub,
      int? subTeam,
      bool strong = false,
      bool topLine = false,
      BreakdownRow? source,
    }) => Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: topLine
          ? BoxDecoration(
              border: Border(top: BorderSide(color: c.outline)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: BreakdownLabel(
              source ?? BreakdownRow(key, label, pts),
              key: Key('detail-label-$key'),
              color: c.textPrimary,
              red: c.cardRed,
              style: TextStyle(
                color: strong ? c.textPrimary : c.textSecondary,
                fontSize: strong ? AppText.label + 1 : AppText.label,
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
              ),
              trailing: sub == null
                  ? null
                  : TextSpan(
                      text: '  $sub',
                      style: TextStyle(
                        color: subTeam == null
                            ? c.textSecondary
                            : (subTeam == 0 ? c.teamUs : c.teamThem),
                        fontSize: AppText.caption,
                      ),
                    ),
            ),
          ),
          nums(key, pts, strong: strong),
        ],
      ),
    );

    final written = d.writtenForDeal;
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.m),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ContractGlyph(
                contract.type,
                size: 18,
                color: c.textPrimary,
                red: c.cardRed,
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text:
                        '${index == null ? '' : '${l.dealNumberTitle(index! + 1)} · '}'
                        '${contractName(l, contract.type)}'
                        '${multiplierSuffix(l, contract.multiplier)}',
                    children: [
                      TextSpan(
                        text: '\n${l.playsContract(declarer)}',
                        style: TextStyle(
                          color: dt == 0 ? c.teamUs : c.teamThem,
                          fontSize: AppText.caption,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final (label, color) in [
                (l.us, c.teamUs),
                (l.them, c.teamThem),
              ])
                SizedBox(
                  width: 52,
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: AppText.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.xs),
          for (final r in breakdownRows(l, d, nameOf: nameOf))
            row(
              r.key,
              r.label,
              r.points,
              sub: r.sub,
              subTeam: r.subTeam,
              source: r,
            ),
          row('raw', l.total, d.rawPoints, strong: true, topLine: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outcomeExplain(l, d),
                  key: const Key('detail-outcome'),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${l.roundingTitle}: ${roundingText(l, d)}',
                  key: const Key('detail-rounding'),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.caption,
                  ),
                ),
              ],
            ),
          ),
          row('written', l.written, written, strong: true, topLine: true),
          if (d.hangingAwarded > 0)
            row('awarded', l.hangingAwardedLine(d.hangingAwarded), [
              for (var t = 0; t < 2; t++)
                d.hangingAwardedTo == t ? d.hangingAwarded : 0,
            ]),
          if (d.newlyHanging > 0)
            Text(
              l.hangingLeft(d.newlyHanging),
              key: const Key('detail-hanging'),
              style: TextStyle(color: c.chipText, fontSize: AppText.caption),
            ),
        ],
      ),
    );
  }
}

/// Short markers for a sheet row: вкарана / висяща, капо, контра…, and
/// hanging points carried or awarded.
String sheetMarks(AppLocalizations l, DealScore d) => [
  if (d.outcome == DealOutcome.inside) l.markInside,
  if (d.outcome == DealOutcome.hanging) l.markHanging,
  if (d.isValat) l.markValat,
  if (d.contract.multiplier == Multiplier.doubled) l.markDouble,
  if (d.contract.multiplier == Multiplier.redoubled) l.markRedouble,
  if (d.newlyHanging > 0) l.hangingLeft(d.newlyHanging),
  if (d.hangingAwarded > 0) l.hangingAwardedLine(d.hangingAwarded),
].join(' · ');

/// Scores (and hanging points) to show at the top: until the recap of the
/// last deal has finished they stay as they were before that deal.
({List<int> scores, int hanging}) shownScore(GameState g, int recapDone) {
  final scored =
      g.phase == GamePhase.dealScored || g.phase == GamePhase.matchOver;
  if (!scored || g.history.isEmpty || recapDone >= g.history.length) {
    return (scores: g.scores, hanging: g.hanging);
  }
  final d = g.history.last;
  final before = [for (var t = 0; t < 2; t++) g.scores[t] - d.scored[t]];
  final hanging = d.hangingAwarded > 0
      ? d.hangingAwarded
      : g.hanging - d.newlyHanging;
  return (scores: before, hanging: hanging);
}
