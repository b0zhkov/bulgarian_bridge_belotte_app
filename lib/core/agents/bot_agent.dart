import 'dart:math';

import '../rules/rules.dart';
import 'bidding.dart';
import 'card_memory.dart';
import 'play_heuristics.dart';
import 'player_agent.dart';

/// Bot difficulty.
enum BotLevel {
  /// Heuristics with noise and occasional random cards.
  easy,

  /// Full heuristics with card memory and inference.
  medium,

  /// Medium + Monte Carlo over sampled (determinized) unseen hands.
  hard;

  static BotLevel parse(String? v) =>
      BotLevel.values.firstWhere((l) => l.name == v, orElse: () => medium);
}

/// A real bot behind [PlayerAgent]. Stateless between calls: every decision
/// is a pure function of (state, seat, [seed]), so results are reproducible
/// and the computation can run in another isolate.
class BotAgent implements PlayerAgent {
  BotAgent(this.level, {this.seed = 0, this.budget, this.maxWorlds = 40});

  final BotLevel level;
  final int seed;

  /// Time limit for Hard's sampling (null = only [maxWorlds] bounds it, which
  /// keeps it deterministic, e.g. in tests).
  final Duration? budget;
  final int maxWorlds;

  Random _rndFor(GameState s, int seat, int salt) => Random(
    Object.hash(
          seed,
          s.seed,
          s.dealNumber,
          s.bids.length,
          s.tricks.length,
          s.currentTrick.plays.length,
          seat,
          salt,
        ) &
        0x7fffffff,
  );

  @override
  Bid chooseBid(GameState state, int seat) => switch (level) {
    BotLevel.easy => chooseBidHeuristic(
      state,
      seat,
      noise: 1.8,
      allowDoubles: false,
      rnd: _rndFor(state, seat, 1),
    ),
    _ => chooseBidHeuristic(state, seat),
  };

  @override
  Card choosePlay(GameState state, int seat) {
    final legal = BelotEngine.getLegalMoves(state, seat);
    if (legal.length == 1) return legal.first;
    switch (level) {
      case BotLevel.easy:
        final rnd = _rndFor(state, seat, 2);
        if (rnd.nextDouble() < 0.3) return legal[rnd.nextInt(legal.length)];
        return heuristicPlay(state, seat, PlayedOnlyKnowledge(state, seat));
      case BotLevel.medium:
        return heuristicPlay(state, seat, CardMemory.of(state, seat));
      case BotLevel.hard:
        return monteCarloPlay(
          state,
          seat,
          rnd: _rndFor(state, seat, 3),
          budget: budget,
          maxWorlds: maxWorlds,
        );
    }
  }
}

/// Knowledge from played cards only (no inference) – the Easy bot.
class PlayedOnlyKnowledge implements Knowledge {
  PlayedOnlyKnowledge(GameState s, this.observer)
    : outstanding = CardMemory.of(s, observer).outstanding;
  final int observer;
  @override
  final List<Card> outstanding;
  @override
  bool mayHold(int seat, Card card) =>
      seat != observer && outstanding.contains(card);
}

/// Determinized Monte Carlo: sample hands for the unseen cards consistent
/// with what [seat] knows, play every candidate out with the heuristic
/// policy (perfect information inside the sample) and pick the card with
/// the best average deal result for our team.
Card monteCarloPlay(
  GameState s,
  int seat, {
  required Random rnd,
  Duration? budget,
  int maxWorlds = 40,
}) {
  final legal = BelotEngine.getLegalMoves(s, seat);
  if (legal.length == 1) return legal.first;
  final memory = CardMemory.of(s, seat);
  final fallback = heuristicPlay(s, seat, memory);
  final sw = Stopwatch()..start();
  final totals = List<double>.filled(legal.length, 0);
  var worlds = 0;
  while (worlds < maxWorlds) {
    if (budget != null && worlds >= 2 && sw.elapsed >= budget) break;
    final world = sampleWorld(s, seat, memory, rnd);
    for (var i = 0; i < legal.length; i++) {
      totals[i] += _rollout(BelotEngine.applyPlay(world, seat, legal[i]), seat);
    }
    worlds++;
  }
  var best = legal.indexOf(fallback);
  // The heuristic choice wins ties (and gets a tiny prior).
  totals[best] += 0.25 * worlds;
  for (var i = 0; i < legal.length; i++) {
    if (totals[i] > totals[best]) best = i;
  }
  return legal[best];
}

double _rollout(GameState s, int me) {
  var st = s;
  while (st.phase == GamePhase.playing) {
    final seat = st.currentSeat;
    final card = heuristicPlay(st, seat, OpenKnowledge(st, seat));
    st = BelotEngine.applyPlay(st, seat, card);
  }
  final d = st.history.last;
  final us = teamOf(me), them = 1 - us;
  return (d.scored[us] - d.scored[them]) +
      0.02 * (d.rawPoints[us] - d.rawPoints[them]);
}

/// One possible deal of the unseen cards to the other seats, consistent with
/// hand sizes, voids/limits and shown cards. Falls back to ignoring limits if
/// no consistent deal is found quickly.
GameState sampleWorld(GameState s, int me, CardMemory m, Random rnd) {
  final need = [for (var i = 0; i < 4; i++) i == me ? 0 : s.hands[i].length];
  for (var attempt = 0; attempt < 30; attempt++) {
    final hands = List.generate(
      4,
      (i) => i == me ? List.of(s.hands[me]) : <Card>[],
    );
    final left = List.of(need);
    var ok = true;
    final pool = <Card>[];
    for (final c in m.outstanding) {
      final owner = m.forced.entries
          .where((e) => e.value.contains(c))
          .map((e) => e.key)
          .firstOrNull;
      if (owner != null && left[owner] > 0) {
        hands[owner].add(c);
        left[owner]--;
      } else {
        pool.add(c);
      }
    }
    pool.shuffle(rnd);
    if (attempt < 25) {
      // Most constrained cards first.
      List<int> eligible(Card c) => [
        for (var i = 0; i < 4; i++)
          if (left[i] > 0 && m.mayHold(i, c)) i,
      ];
      pool.sort((a, b) => eligible(a).length.compareTo(eligible(b).length));
      for (final c in pool) {
        final e = eligible(c);
        if (e.isEmpty) {
          ok = false;
          break;
        }
        // Weight by remaining capacity.
        final total = e.fold(0, (a, i) => a + left[i]);
        var r = rnd.nextInt(total);
        var pick = e.first;
        for (final i in e) {
          if (r < left[i]) {
            pick = i;
            break;
          }
          r -= left[i];
        }
        hands[pick].add(c);
        left[pick]--;
      }
    } else {
      for (final c in pool) {
        final i = [
          for (var j = 0; j < 4; j++)
            if (left[j] > 0) j,
        ].first;
        hands[i].add(c);
        left[i]--;
      }
    }
    if (ok && left.every((x) => x == 0)) {
      return s.copyWith(
        hands: List.unmodifiable(hands.map(List<Card>.unmodifiable)),
      );
    }
  }
  throw StateError('Could not sample a world');
}
