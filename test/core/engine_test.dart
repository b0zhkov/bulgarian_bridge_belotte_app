import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

GameState bidAll(GameState s, List<Bid> bids) {
  for (final b in bids) {
    s = BelotEngine.applyBid(s, s.currentSeat, b);
  }
  return s;
}

const p = Bid.pass;
Bid ct(ContractType t) => Bid.contract(t);

void main() {
  group('dealing', () {
    test('3 + 2 cards counter-clockwise starting right of dealer', () {
      final deck = List.of(fullDeck);
      final s = BelotEngine.newMatch(seed: 1, firstDealer: 3, deck: deck);
      expect(s.hands.every((h) => h.length == 5), isTrue);
      expect(s.stock.length, 12);
      // seat 0 (right of dealer 3) gets cards 0-2 and 12-13
      expect(s.hands[0], [deck[0], deck[1], deck[2], deck[12], deck[13]]);
      expect(s.hands[3], [deck[9], deck[10], deck[11], deck[18], deck[19]]);
      expect(s.currentSeat, 0);
      expect(s.phase, GamePhase.bidding);
    });
    test('remaining 3 dealt after contract -> 8 cards each, all distinct', () {
      var s = BelotEngine.newMatch(seed: 2);
      s = bidAll(s, [ct(ContractType.hearts), p, p, p]);
      expect(s.phase, GamePhase.playing);
      expect(s.hands.every((h) => h.length == 8), isTrue);
      expect(s.hands.expand((h) => h).toSet().length, 32);
      expect(s.stock, isEmpty);
      expect(s.currentSeat, 0, reason: 'player right of dealer leads');
    });
    test('deterministic for the same seed, different for other seeds', () {
      expect(
        BelotEngine.newMatch(seed: 5).hands,
        BelotEngine.newMatch(seed: 5).hands,
      );
      expect(
        BelotEngine.newMatch(seed: 5).hands,
        isNot(BelotEngine.newMatch(seed: 6).hands),
      );
    });
    test('deckFor helper deals exact hands', () {
      final hands = [
        cs('7C 8C 9C 10C JC QC KC AC'),
        cs('7D 8D 9D 10D JD QD KD AD'),
        cs('7H 8H 9H 10H JH QH KH AH'),
        cs('7S 8S 9S 10S JS QS KS AS'),
      ];
      var s = BelotEngine.newMatch(deck: deckFor(hands));
      s = bidAll(s, [ct(ContractType.clubs), p, p, p]);
      for (var i = 0; i < 4; i++) {
        expect(s.hands[i].toSet(), hands[i].toSet());
      }
    });
  });

  group('bidding', () {
    test('ranking clubs < diamonds < hearts < spades < NT < AT', () {
      for (var i = 0; i < ContractType.values.length - 1; i++) {
        expect(ContractType.values[i + 1] > ContractType.values[i], isTrue);
      }
    });
    test('first bidder may bid anything or pass; no double', () {
      final s = BelotEngine.newMatch(seed: 1);
      final v = BelotEngine.validBids(s, 0);
      expect(v.length, 7);
      expect(v.contains(Bid.double), isFalse);
    });
    test('only higher contracts may overcall', () {
      var s = BelotEngine.newMatch(seed: 1);
      s = bidAll(s, [ct(ContractType.hearts)]);
      final v = BelotEngine.validBids(s, 1);
      expect(v.contains(ct(ContractType.hearts)), isFalse);
      expect(v.contains(ct(ContractType.diamonds)), isFalse);
      expect(v.contains(ct(ContractType.spades)), isTrue);
      expect(v.contains(ct(ContractType.allTrump)), isTrue);
      expect(
        () => BelotEngine.applyBid(s, 1, ct(ContractType.clubs)),
        throwsA(isA<IllegalActionException>()),
      );
    });
    test('wrong seat cannot bid', () {
      final s = BelotEngine.newMatch(seed: 1);
      expect(
        () => BelotEngine.applyBid(s, 2, p),
        throwsA(isA<IllegalActionException>()),
      );
    });
    test('double only by opponents of the last bidder', () {
      var s = BelotEngine.newMatch(seed: 1);
      s = bidAll(s, [ct(ContractType.hearts)]);
      expect(BelotEngine.validBids(s, 1).contains(Bid.double), isTrue);
      s = bidAll(s, [p]);
      expect(
        BelotEngine.validBids(s, 2).contains(Bid.double),
        isFalse,
        reason: 'partner cannot double',
      );
    });
    test('redouble only by declaring team after a double', () {
      var s = BelotEngine.newMatch(seed: 1);
      s = bidAll(s, [ct(ContractType.hearts), Bid.double]);
      expect(BelotEngine.validBids(s, 2).contains(Bid.redouble), isTrue);
      expect(BelotEngine.validBids(s, 2).contains(Bid.double), isFalse);
      s = bidAll(s, [p]);
      expect(BelotEngine.validBids(s, 3).contains(Bid.redouble), isFalse);
      s = bidAll(s, [p]);
      expect(BelotEngine.validBids(s, 0).contains(Bid.redouble), isTrue);
      s = bidAll(s, [Bid.redouble]);
      expect(s.contract!.multiplier, Multiplier.redoubled);
      expect(BelotEngine.validBids(s, 1).contains(Bid.double), isFalse);
      expect(BelotEngine.validBids(s, 1).contains(Bid.redouble), isFalse);
    });
    test('a higher contract after a double resets the multiplier', () {
      var s = BelotEngine.newMatch(seed: 1);
      s = bidAll(s, [
        ct(ContractType.hearts),
        Bid.double,
        ct(ContractType.allTrump),
      ]);
      expect(s.contract, const Contract(ContractType.allTrump, 2));
    });
    test('bidding ends after three passes following a contract', () {
      var s = BelotEngine.newMatch(seed: 1);
      s = bidAll(s, [p, ct(ContractType.clubs), p, p]);
      expect(s.phase, GamePhase.bidding);
      s = bidAll(s, [p]);
      expect(s.phase, GamePhase.playing);
      expect(s.contract, const Contract(ContractType.clubs, 1));
    });
    test('three passes after a double end bidding with doubled contract', () {
      var s = BelotEngine.newMatch(seed: 1);
      s = bidAll(s, [ct(ContractType.spades), Bid.double, p, p, p]);
      expect(s.phase, GamePhase.playing);
      expect(s.contract!.multiplier, Multiplier.doubled);
    });
    test('all four pass -> redeal by next dealer, scores unchanged', () {
      var s = BelotEngine.newMatch(seed: 1, firstDealer: 3);
      s = bidAll(s, [p, p, p, p]);
      expect(s.phase, GamePhase.allPassed);
      s = BelotEngine.nextDeal(s);
      expect(s.dealer, 0);
      expect(s.currentSeat, 1);
      expect(s.phase, GamePhase.bidding);
      expect(s.scores, [0, 0]);
      expect(s.hands.every((h) => h.length == 5), isTrue);
    });
  });

  group('play flow', () {
    final hands = [
      cs('JS 9S AS 10S KH QH 7C 8C'),
      cs('KS QS 8S 7S AH 10H 9C 10C'),
      cs('JH 9H 8H 7H AC KC QC JC'),
      cs('AD 10D KD QD JD 9D 8D 7D'),
    ];
    GameState start(ContractType t) =>
        bidAll(BelotEngine.newMatch(deck: deckFor(hands)), [ct(t), p, p, p]);

    test('illegal card is rejected', () {
      var s = start(ContractType.spades);
      s = BelotEngine.applyPlay(s, 0, c('7C'));
      expect(
        () => BelotEngine.applyPlay(s, 1, c('AH')),
        throwsA(isA<IllegalActionException>()),
      );
    });
    test('trick winner leads next', () {
      var s = start(ContractType.spades);
      s = BelotEngine.applyPlay(s, 0, c('7C'));
      s = BelotEngine.applyPlay(s, 1, c('10C'));
      s = BelotEngine.applyPlay(s, 2, c('AC'));
      s = BelotEngine.applyPlay(s, 3, c('AD'));
      expect(s.tricks.single.winner, 2);
      expect(s.currentSeat, 2);
      expect(s.currentTrick.isEmpty, isTrue);
    });
    test('declarations announced automatically with the first card', () {
      var s = start(ContractType.allTrump);
      s = BelotEngine.applyPlay(s, 0, c('7C'));
      s = BelotEngine.applyPlay(s, 1, c('9C'));
      s = BelotEngine.applyPlay(s, 2, c('JC'));
      // J-Q-K-A clubs (quarte) + 7-8-9 hearts (tierce)
      expect(s.lastAnnouncement!.declarations.map((d) => d.type).toSet(), {
        DeclarationType.quarte,
        DeclarationType.tierce,
      });
      s = BelotEngine.applyPlay(s, 3, c('AD'));
      // 8 diamonds: quint + tierce
      expect(s.lastAnnouncement!.declarations.map((d) => d.type).toSet(), {
        DeclarationType.quint,
        DeclarationType.tierce,
      });
      expect(s.declarations.length, 5); // + seat 0's 9-10-J spades tierce
    });
    test('belot is recorded when the first of K/Q is played', () {
      var s = start(ContractType.spades);
      s = BelotEngine.applyPlay(s, 0, c('JS'));
      s = BelotEngine.applyPlay(s, 1, c('KS'));
      expect(s.belots, [1]);
      expect(s.lastAnnouncement!.belot, isTrue);
    });
    test('complete deal is scored and dealer rotates', () {
      var s = start(ContractType.spades);
      final agent = RandomAgent(1);
      while (s.phase == GamePhase.playing) {
        s = BelotEngine.applyPlay(
          s,
          s.currentSeat,
          agent.choosePlay(s, s.currentSeat),
        );
      }
      expect(s.phase, GamePhase.dealScored);
      expect(s.history.length, 1);
      final d = s.history.single;
      expect(d.cardPoints[0] + d.cardPoints[1], 152);
      s = BelotEngine.nextDeal(s);
      expect(s.dealer, 0);
    });
  });

  group('simulation', () {
    test('random legal matches complete with consistent scoring', () {
      for (var seed = 0; seed < 150; seed++) {
        var s = BelotEngine.newMatch(seed: seed);
        final agent = RandomAgent(seed);
        var deals = 0;
        while (s.phase != GamePhase.matchOver && deals < 500) {
          switch (s.phase) {
            case GamePhase.bidding:
              s = BelotEngine.applyBid(
                s,
                s.currentSeat,
                agent.chooseBid(s, s.currentSeat),
              );
            case GamePhase.playing:
              final moves = BelotEngine.getLegalMoves(s, s.currentSeat);
              expect(moves, isNotEmpty);
              expect(moves.every(s.hands[s.currentSeat].contains), isTrue);
              s = BelotEngine.applyPlay(
                s,
                s.currentSeat,
                agent.choosePlay(s, s.currentSeat),
              );
            case GamePhase.allPassed:
              s = BelotEngine.nextDeal(s);
            case GamePhase.dealScored:
              final d = s.lastDeal!;
              final type = d.contract.type;
              final expectedCards = type == ContractType.noTrump
                  ? 120
                  : (type == ContractType.allTrump ? 248 : 152);
              expect(d.cardPoints[0] + d.cardPoints[1], expectedCards);
              final total =
                  roundPoints(d.rawPoints[0] + d.rawPoints[1], type) *
                  d.contract.multiplier.factor;
              expect(
                d.scored[0] + d.scored[1] - d.hangingAwarded + d.newlyHanging,
                total,
              );
              deals++;
              s = BelotEngine.nextDeal(s);
            case GamePhase.matchOver:
              break;
          }
        }
        expect(s.phase, GamePhase.matchOver, reason: 'seed $seed');
        expect(s.scores[s.winnerTeam!], greaterThanOrEqualTo(151));
        expect(
          s.scores[s.winnerTeam!],
          greaterThan(s.scores[1 - s.winnerTeam!]),
        );
        expect(s.lastDeal!.isValat, isFalse);
      }
    });
  });
}
