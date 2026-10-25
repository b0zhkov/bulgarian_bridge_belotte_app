import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/labels.dart';
import 'package:bulgarian_bridge_belotte_app/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rotation_codec_test.dart' show randomStates;

DealScore scored(
  List<int> raw, {
  ContractType type = ContractType.hearts,
  int declarer = 0,
  Multiplier mult = Multiplier.none,
}) {
  final contract = Contract(type, declarer, mult);
  final st = settle(raw: raw, contract: contract);
  return DealScore(
    contract: contract,
    cardPoints: raw,
    declarationPoints: const [0, 0],
    belotPoints: const [0, 0],
    lastTrickTeam: 0,
    valatTeam: null,
    rawPoints: raw,
    outcome: st.outcome,
    scored: st.scored,
    newlyHanging: st.newlyHanging,
    hangingAwarded: 0,
    hangingAwardedTo: null,
    scoringDeclarations: const [],
  );
}

void main() {
  final l = lookupAppLocalizations(const Locale('bg'));

  test('rounding explanation matches the engine in random deals', () {
    var n = 0;
    final seen = <String>{};
    GameState? prev;
    for (final s in randomStates(60)) {
      if (prev != null &&
          prev.phase == GamePhase.playing &&
          s.history.length > prev.history.length) {
        final d = s.history.last;
        final r = d.rounding;
        final w = d.writtenForDeal;
        final dt = d.contract.declarerTeam;
        final ot = 1 - dt;
        expect(r.total, d.rawPoints[0] + d.rawPoints[1]);
        if (r.multiplied) {
          seen.add('mult');
          if (r.outcome == DealOutcome.hanging) {
            expect(d.newlyHanging, r.roundedTotal * r.factor);
          } else {
            final win = d.rawPoints[0] > d.rawPoints[1] ? 0 : 1;
            expect(w[win], r.roundedTotal * r.factor);
            expect(w[1 - win], 0);
          }
        } else {
          seen.add(r.outcome.name);
          switch (r.outcome) {
            case DealOutcome.outside:
              expect(w, r.rounded);
            case DealOutcome.inside:
              expect(w[ot], r.roundedTotal);
              expect(w[dt], 0);
            case DealOutcome.hanging:
              expect(w[ot], r.rounded[ot]);
              expect(w[ot] + d.newlyHanging, r.roundedTotal);
          }
        }
        // Rows add up to the raw points, each declaration in its column.
        final rows = breakdownRows(l, d);
        for (var t = 0; t < 2; t++) {
          expect(rows.fold<int>(0, (a, x) => a + x.points[t]), d.rawPoints[t]);
        }
        for (final (i, x) in d.scoringDeclarations.indexed) {
          final row = rows.firstWhere((r) => r.key == 'decl$i');
          expect(row.points[teamOf(x.seat)], x.points);
          expect(row.points[1 - teamOf(x.seat)], 0);
          expect(row.subTeam, teamOf(x.seat));
        }
        expect(roundingText(l, d), isNotEmpty);
        n++;
      }
      prev = s;
    }
    expect(n, greaterThan(100));
    expect(seen, containsAll(['outside', 'inside']));
  });

  test('belot.bg rounding examples in words', () {
    // Suit: 6 rounds up only for the lower team.
    expect(roundingText(l, scored([96, 66])), 'Ние 96 → 9 · Вие 66 → 7');
    // All Trump: 134-124 -> 13-13.
    expect(
      roundingText(l, scored([134, 124], type: ContractType.allTrump)),
      'Ние 134 → 13 · Вие 124 → 13',
    );
    // Inside: everything to the opponents.
    expect(roundingText(l, scored([60, 102])), 'Общо 162 → 16 за Вие');
    // Hanging: opponents write theirs, the rest hangs.
    expect(roundingText(l, scored([81, 81])), 'Вие: 81 → 8; 8 висят');
    // Contra: the stronger team takes all ×2.
    expect(
      roundingText(l, scored([100, 62], mult: Multiplier.doubled)),
      'Общо 162 → 16 ×2 = 32 за Ние',
    );
    expect(
      roundingText(l, scored([62, 100], mult: Multiplier.redoubled)),
      'Общо 162 → 16 ×4 = 64 за Вие',
    );
  });

  test('declaration names with their cards', () {
    final tierce = Declaration(DeclarationType.tierce, [
      Card.parse('QH'),
      Card.parse('KH'),
      Card.parse('AH'),
    ], 1);
    expect(declarationDetail(l, tierce), 'Терца ${Suit.hearts.glyph} до A');
    final square = Declaration(DeclarationType.square, [
      for (final s in Suit.values) Card(s, Rank.jack),
    ], 2);
    expect(declarationDetail(l, square), 'Каре J');
  });
}
