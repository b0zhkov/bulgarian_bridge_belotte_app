import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const sp = ContractType.spades;
const at = ContractType.allTrump;
const nt = ContractType.noTrump;

Settlement st(
  List<int> raw,
  ContractType t,
  int declarer, {
  Multiplier m = Multiplier.none,
  int carried = 0,
}) => settle(
  raw: raw,
  contract: Contract(t, declarer, m),
  carriedHanging: carried,
);

void main() {
  group('rounding (belot.bg)', () {
    test('suit contract: 6 rounds up only for the lower team', () {
      expect(st([96, 66], sp, 0).scored, [9, 7]);
      expect(st([56, 106], sp, 1).scored, [6, 10]);
      expect(st([115, 47], sp, 0).scored, [11, 5]);
      expect(st([6, 156], sp, 1).scored, [1, 15]);
    });
    test('All Trump: 4 rounds up only for the lower team', () {
      expect(st([134, 124], at, 0).scored, [13, 13]);
      expect(st([34, 224], at, 1).scored, [4, 22]);
      expect(st([164, 194], at, 1).scored, [17, 19]);
      expect(st([190, 68], at, 0).scored, [19, 7]);
      expect(st([133, 125], at, 0).scored, [13, 13]);
    });
    test('No Trump: rounded after doubling', () {
      expect(st([220, 40], nt, 0).scored, [22, 4]);
      expect(st([146, 114], nt, 0).scored, [15, 11]);
    });
    test('roundPoints totals', () {
      expect(roundPoints(162, sp), 16);
      expect(roundPoints(258, at), 26);
      expect(roundPoints(260, nt), 26);
    });
  });

  group('outcomes', () {
    test('outside: each team writes its own points', () {
      final s = st([115, 47], sp, 0);
      expect(s.outcome, DealOutcome.outside);
      expect(s.scored, [11, 5]);
    });
    test('inside: opponents write all points', () {
      final s = st([115, 47], sp, 1);
      expect(s.outcome, DealOutcome.inside);
      expect(s.scored, [16, 0]);
    });
    test('inside with premiums: total includes premiums', () {
      expect(st([80, 152], sp, 0).scored, [0, 23]);
    });
    test('hanging: declarers write nothing, opponents write theirs', () {
      final s = st([81, 81], sp, 0);
      expect(s.outcome, DealOutcome.hanging);
      expect(s.scored, [0, 8]);
      expect(s.newlyHanging, 8);
    });
    test('hanging 106-106 suit: 10 written, 11 hang (belot.bg)', () {
      final s = st([106, 106], sp, 0);
      expect(s.scored, [0, 10]);
      expect(s.newlyHanging, 11);
    });
    test('hanging 154-154 All Trump: 15 written, 16 hang (belot.bg)', () {
      final s = st([154, 154], at, 1);
      expect(s.scored, [15, 0]);
      expect(s.newlyHanging, 16);
    });
    test('hanging points go to the winner of the next deal (outside)', () {
      final s = st([100, 62], sp, 0, carried: 8);
      expect(s.scored, [18, 6]);
      expect(s.hangingAwardedTo, 0);
    });
    test('hanging points go to the winner of the next deal (inside)', () {
      final s = st([50, 112], sp, 0, carried: 8);
      expect(s.scored, [0, 24]);
      expect(s.hangingAwardedTo, 1);
    });
    test('hanging deal keeps carried points hanging', () {
      final s = st([81, 81], sp, 1, carried: 8);
      expect(s.hangingAwarded, 0);
      expect(s.scored, [8, 0]);
    });
  });

  group('double / redouble', () {
    test('double: team with more points takes all x2', () {
      expect(st([115, 47], sp, 0, m: Multiplier.doubled).scored, [32, 0]);
      expect(st([115, 47], sp, 1, m: Multiplier.doubled).scored, [32, 0]);
    });
    test('redouble: x4', () {
      expect(st([47, 115], sp, 1, m: Multiplier.redoubled).scored, [0, 64]);
    });
    test('double in All Trump', () {
      expect(st([190, 68], at, 0, m: Multiplier.doubled).scored, [52, 0]);
    });
    test('double includes valat premium', () {
      expect(st([252, 0], sp, 0, m: Multiplier.doubled).scored, [50, 0]);
    });
    test('doubled hanging: all doubled points hang, nobody writes', () {
      final s = st([81, 81], sp, 0, m: Multiplier.doubled);
      expect(s.scored, [0, 0]);
      expect(s.newlyHanging, 32);
    });
  });

  group('full deal scoring from tricks', () {
    test('suit contract outside', () {
      final s = scoreDeal(
        contract: const Contract(sp, 0),
        tricks: tricksFor('7S 8S 9S 10S JS QS KS AS AC AD AH 10C', lastTeam: 0),
        declarations: const [],
        belots: const [],
      );
      expect(s.rawPoints, [115, 47]);
      expect(s.scored, [11, 5]);
      expect(s.isValat, isFalse);
    });
    test('valat: +90, last 10 included', () {
      final s = scoreDeal(
        contract: const Contract(sp, 0),
        tricks: tricksFor(fullDeck.map((x) => x.code).join(' '), lastTeam: 0),
        declarations: const [],
        belots: const [],
      );
      expect(s.valatTeam, 0);
      expect(s.rawPoints, [252, 0]);
      expect(s.scored, [25, 0]);
    });
    test('valat against declarers: opponents take all', () {
      final s = scoreDeal(
        contract: const Contract(sp, 1),
        tricks: tricksFor(fullDeck.map((x) => x.code).join(' '), lastTeam: 0),
        declarations: const [],
        belots: const [],
      );
      expect(s.outcome, DealOutcome.inside);
      expect(s.scored, [25, 0]);
    });
    test('No Trump: card points doubled, valat not doubled', () {
      final s = scoreDeal(
        contract: const Contract(nt, 0),
        tricks: tricksFor(fullDeck.map((x) => x.code).join(' '), lastTeam: 0),
        declarations: const [],
        belots: const [],
      );
      expect(s.rawPoints, [350, 0]);
      expect(s.scored, [35, 0]);
    });
    test('No Trump normal deal totals 26', () {
      final s = scoreDeal(
        contract: const Contract(nt, 0),
        tricks: tricksFor(
          'AC AD AH AS 10C 10D 10H 10S KC KD KH KS',
          lastTeam: 0,
        ),
        declarations: const [],
        belots: const [],
      );
      expect(s.rawPoints, [220, 40]);
      expect(s.scored, [22, 4]);
    });
    test('No Trump ignores declarations and belot', () {
      final s = scoreDeal(
        contract: const Contract(nt, 0),
        tricks: tricksFor(
          'AC AD AH AS 10C 10D 10H 10S KC KD KH KS',
          lastTeam: 0,
        ),
        declarations: [
          Declaration(DeclarationType.square, cs('JC JD JH JS'), 1),
        ],
        belots: const [1],
      );
      expect(s.rawPoints, [220, 40]);
    });
    test('All Trump totals 258', () {
      final s = scoreDeal(
        contract: const Contract(at, 0),
        tricks: tricksFor('JC JD JH JS 9C 9D 9H 9S AC AD AH AS', lastTeam: 0),
        declarations: const [],
        belots: const [],
      );
      expect(s.rawPoints, [190, 68]);
      expect(s.scored, [19, 7]);
    });
    test('declarations and belot are added to raw points', () {
      final s = scoreDeal(
        contract: const Contract(sp, 0),
        tricks: tricksFor('7S 8S 9S 10S JS QS KS AS AC AD AH 10C', lastTeam: 0),
        declarations: [
          Declaration(DeclarationType.tierce, cs('7S 8S 9S'), 0),
          Declaration(DeclarationType.square, cs('KC KD KH KS'), 1),
        ],
        belots: const [2],
      );
      expect(s.declarationPoints, [20, 100]);
      expect(s.belotPoints, [20, 0]);
      expect(s.rawPoints, [155, 147]);
      expect(s.outcome, DealOutcome.outside);
      expect(s.scored, [15, 15]);
    });
    test('declarers losing on premiums go inside', () {
      final s = scoreDeal(
        contract: const Contract(sp, 0),
        tricks: tricksFor('7S 8S 9S 10S JS QS KS AS AC AD AH 10C', lastTeam: 0),
        declarations: [
          Declaration(DeclarationType.square, cs('JC JD JH JS'), 1),
        ],
        belots: const [],
      );
      expect(s.rawPoints, [115, 247]);
      expect(s.scored, [0, 36]);
    });
  });

  group('match end', () {
    test('first to 151 wins', () {
      expect(matchWinner([151, 90], valatDeal: false), 0);
      expect(matchWinner([150, 90], valatDeal: false), isNull);
    });
    test('both over 151: higher wins; equal continues', () {
      expect(matchWinner([155, 160], valatDeal: false), 1);
      expect(matchWinner([155, 155], valatDeal: false), isNull);
    });
    test('cannot win on a valat deal', () {
      expect(matchWinner([170, 90], valatDeal: true), isNull);
    });
  });
}
