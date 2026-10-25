import 'package:bulgarian_bridge_belotte_app/core/agents/hint.dart';
import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

GameState playing(List<List<Card>> hands, ContractType t, {List<String> plays = const []}) {
  var s = BelotEngine.newMatch(deck: deckFor(hands));
  s = BelotEngine.applyBid(s, 0, Bid.contract(t));
  for (var i = 0; i < 3; i++) {
    s = BelotEngine.applyBid(s, s.currentSeat, Bid.pass);
  }
  for (final p in plays) {
    s = BelotEngine.applyPlay(s, s.currentSeat, c(p));
  }
  return s;
}

void main() {
  test('hint is always a legal move (random games, all contracts)', () {
    var checked = 0;
    for (var seed = 0; seed < 120; seed++) {
      var s = BelotEngine.newMatch(seed: seed);
      final agent = RandomAgent(seed);
      while (s.phase != GamePhase.matchOver && s.history.length < 6) {
        switch (s.phase) {
          case GamePhase.bidding:
            s = BelotEngine.applyBid(s, s.currentSeat, agent.chooseBid(s, s.currentSeat));
          case GamePhase.playing:
            final seat = s.currentSeat;
            final hint = suggestCard(s, seat);
            expect(BelotEngine.getLegalMoves(s, seat), contains(hint));
            checked++;
            s = BelotEngine.applyPlay(s, seat, hint);
          case GamePhase.allPassed:
          case GamePhase.dealScored:
            s = BelotEngine.nextDeal(s);
          case GamePhase.matchOver:
            break;
        }
      }
    }
    expect(checked, greaterThan(1000));
  });

  // Seat 0 leads (dealer 3). Hands are 8 cards each.
  final hands = [
    cs('AH 7H 8C 9C 7S JD 10D 8D'),
    cs('KH QH 7C 10C 8S 9S AD QD'),
    cs('10H 9H JC QC KC AC 7D 9D'),
    cs('JH 8H AS 10S KS QS JS KD'),
  ];

  test('leading: plays a master card outside trumps (ace)', () {
    final s = playing(hands, ContractType.spades);
    expect(suggestCard(s, 0), c('AH'));
  });

  test('opponent winning: wins as cheaply as possible', () {
    // seat 0 leads 8C, seat 1 plays 10C; seat 2 can beat with AC only (QC/KC/JC lower than 10)
    final s = playing(hands, ContractType.noTrump, plays: ['8C', '10C']);
    expect(suggestCard(s, 2), c('AC'));
  });

  test('cannot win: throws the cheapest card', () {
    // seat 0 leads 7H, seat 1 KH; seat 2 has 10H 9H -> 10H wins in NT; check cheapest-win instead
    final s = playing(hands, ContractType.noTrump, plays: ['7H', 'KH']);
    expect(suggestCard(s, 2), c('10H'));
    // seat 3 after 10H: has JH 8H, cannot beat 10H, partner? seat 3 is opponent of seat 2 -> cheapest
    final s2 = BelotEngine.applyPlay(s, 2, c('10H'));
    expect(suggestCard(s2, 3), c('8H'));
  });

  test('partner winning: never overtakes partner, adds points when last', () {
    // NT: seat 0 leads AH, seat 1 QH, seat 2 must follow hearts (10H/9H) -> both lose to AH, adds 10H
    final s = playing(hands, ContractType.noTrump, plays: ['AH', 'QH']);
    expect(suggestCard(s, 2), c('10H'));
  });

  test('suit contract: does not over-trump a winning partner', () {
    final h = [
      cs('AC 7H 8H 9H 10H JH QH KH'),
      cs('7C 8D 9D 10D JD QD KD AD'),
      cs('JS 9S 7S 8S AS 10S KS QS'),
      cs('8C 9C 10C JC QC KC 7D AH'),
    ];
    // spades trump; seat 0 leads AC (master), seat1 7C, seat 2 void in clubs: partner winning -> no trump needed
    final s = playing(h, ContractType.spades, plays: ['AC', '7C']);
    final hint = suggestCard(s, 2);
    expect(BelotEngine.getLegalMoves(s, 2), contains(hint));
    expect(hint.suit, Suit.spades); // only spades in hand
    expect(hint, isNot(c('JS'))); // does not waste the top trump
  });
}
