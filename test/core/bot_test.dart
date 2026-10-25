import 'package:bulgarian_bridge_belotte_app/core/agents/bidding.dart';
import 'package:bulgarian_bridge_belotte_app/core/agents/bot_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/agents/card_memory.dart';
import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:math';

/// Plays deals with [agents] (seat -> agent), checking every decision is
/// legal; [onPlay] can inspect states before each card. Returns deals played.
int playDeals(
  List<PlayerAgent> agents,
  int deals, {
  int seed = 0,
  void Function(GameState s)? onPlay,
}) {
  var played = 0;
  var m = 0;
  while (played < deals) {
    var s = BelotEngine.newMatch(seed: seed + m++);
    while (s.phase != GamePhase.matchOver && played < deals) {
      switch (s.phase) {
        case GamePhase.bidding:
          final seat = s.currentSeat;
          final b = agents[seat].chooseBid(s, seat);
          expect(BelotEngine.validBids(s, seat), contains(b));
          s = BelotEngine.applyBid(s, seat, b);
        case GamePhase.playing:
          final seat = s.currentSeat;
          onPlay?.call(s);
          final c = agents[seat].choosePlay(s, seat);
          expect(BelotEngine.getLegalMoves(s, seat), contains(c));
          s = BelotEngine.applyPlay(s, seat, c);
        case GamePhase.allPassed:
        case GamePhase.dealScored:
          played++;
          s = BelotEngine.nextDeal(s);
        case GamePhase.matchOver:
          break;
      }
    }
    if (s.phase == GamePhase.matchOver) played++;
  }
  return played;
}

/// Win rate of team A (agents from [a]) over [n] seeds, each played twice
/// with the sides swapped so deal luck cancels out.
double winRate(
  PlayerAgent Function(int) a,
  PlayerAgent Function(int) b,
  int n, {
  int seed0 = 500,
}) {
  var wins = 0, games = 0;
  for (var i = 0; i < n; i++) {
    for (final swap in [false, true]) {
      final aa = a(seed0 + i), bb = b(seed0 + i + 7);
      final agents = swap ? [bb, aa, bb, aa] : [aa, bb, aa, bb];
      var s = BelotEngine.newMatch(seed: seed0 + i);
      var guard = 0;
      while (s.phase != GamePhase.matchOver && guard++ < 5000) {
        final seat = s.currentSeat;
        s = switch (s.phase) {
          GamePhase.bidding => BelotEngine.applyBid(
            s,
            seat,
            agents[seat].chooseBid(s, seat),
          ),
          GamePhase.playing => BelotEngine.applyPlay(
            s,
            seat,
            agents[seat].choosePlay(s, seat),
          ),
          _ => BelotEngine.nextDeal(s),
        };
      }
      games++;
      if (s.winnerTeam == (swap ? 1 : 0)) wins++;
    }
  }
  return wins / games;
}

void main() {
  group('legality', () {
    test('easy and medium: thousands of random deals', () {
      for (final level in [BotLevel.easy, BotLevel.medium]) {
        final n = playDeals([
          for (var i = 0; i < 4; i++) BotAgent(level, seed: i),
        ], 2000);
        expect(n, greaterThanOrEqualTo(2000));
      }
    });

    test('mixed table incl. hard and random', () {
      final n = playDeals(
        [
          BotAgent(BotLevel.hard, seed: 1, maxWorlds: 3),
          BotAgent(BotLevel.easy, seed: 2),
          BotAgent(BotLevel.medium, seed: 3),
          RandomAgent(4),
        ],
        400,
        seed: 9000,
      );
      expect(n, greaterThanOrEqualTo(400));
    });
  });

  test('decisions are deterministic for a seed', () {
    final s0 = BelotEngine.newMatch(seed: 77);
    for (final level in BotLevel.values) {
      final a = BotAgent(level, seed: 5, maxWorlds: 6);
      final b = BotAgent(level, seed: 5, maxWorlds: 6);
      var s = s0;
      var steps = 0;
      while (s.phase == GamePhase.bidding || s.phase == GamePhase.playing) {
        final seat = s.currentSeat;
        if (s.phase == GamePhase.bidding) {
          final x = a.chooseBid(s, seat);
          expect(b.chooseBid(s, seat), x);
          s = BelotEngine.applyBid(s, seat, x);
        } else {
          final x = a.choosePlay(s, seat);
          expect(b.choosePlay(s, seat), x);
          s = BelotEngine.applyPlay(s, seat, x);
        }
        if (++steps > 100) break;
      }
    }
  });

  test('card memory never rules out a card a seat really holds', () {
    var checks = 0;
    playDeals(
      [for (var i = 0; i < 4; i++) BotAgent(BotLevel.medium, seed: i)],
      300,
      seed: 4000,
      onPlay: (s) {
        final me = s.currentSeat;
        final m = CardMemory.of(s, me);
        for (var seat = 0; seat < 4; seat++) {
          if (seat == me) continue;
          for (final c in s.hands[seat]) {
            expect(
              m.mayHold(seat, c),
              isTrue,
              reason:
                  '$seat holds $c; ${s.contract} tricks ${s.tricks.map((t) => t.plays).toList()} cur ${s.currentTrick.plays} belots ${s.belots} decl ${s.declarations} hands ${s.hands}',
            );
            checks++;
          }
        }
        // Sampled worlds are consistent with hand sizes and knowledge.
        final w = sampleWorld(s, me, m, Random(checks));
        for (var seat = 0; seat < 4; seat++) {
          expect(w.hands[seat].length, s.hands[seat].length);
        }
        expect(w.hands[me], s.hands[me]);
      },
    );
    expect(checks, greaterThan(10000));
  });

  test('memory infers voids from failing to follow', () {
    // Seat 1 discards a club on a heart lead in No Trump -> void in hearts.
    final hands = [
      Card.parseList('AH 7C 8C 9C 10C JC QC KC'),
      Card.parseList('AC 7D 8D 9D 10D JD QD KD'),
      Card.parseList('7H 8H 9H 10H JH QH KH AD'),
      Card.parseList('7S 8S 9S 10S JS QS KS AS'),
    ];
    final deck = <Card>[];
    // dealInitial: 3 then 2 cards per seat starting at seat 0 (dealer 3),
    // then 3 more each.
    for (final r in [(0, 3), (3, 5)]) {
      for (var seat = 0; seat < 4; seat++) {
        deck.addAll(hands[seat].sublist(r.$1, r.$2));
      }
    }
    for (var seat = 0; seat < 4; seat++) {
      deck.addAll(hands[seat].sublist(5, 8));
    }
    var s = BelotEngine.newMatch(deck: deck);
    s = BelotEngine.applyBid(s, 0, const Bid.contract(ContractType.noTrump));
    for (var i = 0; i < 3; i++) {
      s = BelotEngine.applyBid(s, s.currentSeat, Bid.pass);
    }
    s = BelotEngine.applyPlay(s, 0, Card.parse('AH'));
    s = BelotEngine.applyPlay(s, 1, Card.parse('7D'));
    final m = CardMemory.of(s, 2);
    expect(m.isVoid(1, Suit.hearts), isTrue);
    expect(m.mayHold(1, Card.parse('KH')), isFalse);
    expect(m.mayHold(3, Card.parse('7S')), isTrue);
  });

  group('bidding', () {
    test('strong trump hand bids its suit, weak hand passes', () {
      final s = BelotEngine.newMatch(seed: 1);
      final strong = Card.parseList('JS 9S AS 10S AH');
      final weak = Card.parseList('7C 8D 9H QS 8S');
      double st(List<Card> h, ContractType t) => HandEvaluator.strength(h, t);
      expect(
        st(strong, ContractType.spades),
        greaterThan(HandEvaluator.bidThreshold),
      );
      for (final t in ContractType.values) {
        expect(st(weak, t), lessThan(HandEvaluator.bidThreshold));
      }
      final withStrong = s.copyWith(
        hands: [strong, ...s.hands.sublist(1)],
        currentSeat: 0,
      );
      final b = chooseBidHeuristic(withStrong, 0);
      expect(b.kind, BidKind.contract);
      final withWeak = s.copyWith(
        hands: [weak, ...s.hands.sublist(1)],
        currentSeat: 0,
      );
      expect(chooseBidHeuristic(withWeak, 0), Bid.pass);
    });

    test('jacks bid All Trump, aces and tens No Trump', () {
      expect(
        HandEvaluator.strength(
          Card.parseList('JS JH JD 9D 7C'),
          ContractType.allTrump,
        ),
        greaterThan(HandEvaluator.bidThreshold),
      );
      expect(
        HandEvaluator.strength(
          Card.parseList('AS 10S AH 10H AD'),
          ContractType.noTrump,
        ),
        greaterThan(HandEvaluator.bidThreshold),
      );
    });
  });

  group('strength (seeded matches)', () {
    test('medium beats random', () {
      final r = winRate(
        (s) => BotAgent(BotLevel.medium, seed: s),
        (s) => RandomAgent(s),
        50,
      );
      expect(r, greaterThan(0.9));
    });

    test('medium beats easy', () {
      final r = winRate(
        (s) => BotAgent(BotLevel.medium, seed: s),
        (s) => BotAgent(BotLevel.easy, seed: s),
        100,
      );
      expect(r, greaterThan(0.6));
    });

    test('hard beats easy clearly', () {
      final r = winRate(
        (s) => BotAgent(BotLevel.hard, seed: s, maxWorlds: 12),
        (s) => BotAgent(BotLevel.easy, seed: s),
        30,
      );
      // ignore: avoid_print
      print('hard vs easy (60 matches, 12 worlds): $r');
      expect(r, greaterThan(0.65));
    });
  });

  test('hard move time stays within budget', () {
    final agent = BotAgent(
      BotLevel.hard,
      seed: 1,
      budget: const Duration(milliseconds: 250),
      maxWorlds: 100000,
    );
    var worst = Duration.zero;
    var moves = 0;
    playDeals(
      [agent, BotAgent(BotLevel.medium), agent, BotAgent(BotLevel.medium)],
      2,
      seed: 321,
      onPlay: (s) {
        if (s.currentSeat % 2 != 0) return;
        final sw = Stopwatch()..start();
        agent.choosePlay(s, s.currentSeat);
        if (sw.elapsed > worst) worst = sw.elapsed;
        moves++;
      },
    );
    // ignore: avoid_print
    print('hard: $moves moves, worst ${worst.inMilliseconds} ms');
    expect(moves, greaterThan(10));
    expect(worst, lessThan(const Duration(milliseconds: 300)));
  });
}
