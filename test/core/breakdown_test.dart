import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rotation_codec_test.dart' show randomStates;

void main() {
  test('breakdown adds up to the engine score in random deals', () {
    var deals = 0, nt = 0, decl = 0, hanging = 0, doubled = 0;
    GameState? prev;
    for (final s in randomStates(60)) {
      if (prev != null &&
          prev.phase == GamePhase.playing &&
          s.history.length > prev.history.length) {
        deals++;
        final d = s.history.last;
        // Independent recount from the played tricks.
        final cards = [0, 0];
        for (final t in s.tricks) {
          for (final c in t.cards) {
            cards[teamOf(t.winner!)] += cardPoints(c, d.contract.type);
          }
        }
        expect(d.cardPoints, cards);
        expect(d.lastTrickTeam, teamOf(s.tricks.last.winner!));
        final lines = d.breakdown;
        for (var t = 0; t < 2; t++) {
          expect(lines.fold<int>(0, (a, l) => a + l.points[t]), d.rawPoints[t]);
          expect(
            d.writtenForDeal[t] +
                (d.hangingAwardedTo == t ? d.hangingAwarded : 0),
            d.scored[t],
          );
        }
        // Scores accumulate exactly what the history says.
        for (var t = 0; t < 2; t++) {
          expect(s.scores[t], prev.scores[t] + d.scored[t]);
        }
        if (d.contract.type == ContractType.noTrump) nt++;
        if (lines.any((l) => l.step == ScoreStep.declarations)) decl++;
        if (d.outcome == DealOutcome.hanging) hanging++;
        if (d.contract.multiplier != Multiplier.none) doubled++;
      }
      prev = s;
    }
    expect(deals, greaterThan(200));
    expect(nt, greaterThan(10));
    expect(decl, greaterThan(10));
    expect(doubled, greaterThan(5));
    // ignore: avoid_print
    print('deals $deals nt $nt decl $decl hanging $hanging doubled $doubled');
  });

  test('valat line: 90 to the valat team, never doubled', () {
    const d = DealScore(
      contract: Contract(ContractType.noTrump, 0),
      cardPoints: [120, 0],
      declarationPoints: [0, 0],
      belotPoints: [0, 0],
      lastTrickTeam: 0,
      valatTeam: 0,
      rawPoints: [350, 0],
      outcome: DealOutcome.outside,
      scored: [35, 0],
      newlyHanging: 0,
      hangingAwarded: 0,
      hangingAwardedTo: null,
      scoringDeclarations: [],
    );
    final lines = d.breakdown;
    expect(lines.map((l) => l.step), [
      ScoreStep.cards,
      ScoreStep.lastTen,
      ScoreStep.noTrumpDouble,
      ScoreStep.valat,
    ]);
    expect(lines.fold<int>(0, (a, l) => a + l.points[0]), 350);
  });
}
