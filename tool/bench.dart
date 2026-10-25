import 'dart:io';

import 'package:bulgarian_bridge_belotte_app/core/agents/bot_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';

/// Plays [n] matches (each seed twice with sides swapped). Returns team-A win rate.
(double, int, Duration) bench(
  PlayerAgent Function(int seed) a,
  PlayerAgent Function(int seed) b,
  int n, {
  int seed0 = 1000,
}) {
  var wins = 0, games = 0;
  var maxMove = Duration.zero;
  for (var i = 0; i < n; i++) {
    for (final swap in [false, true]) {
      final seed = seed0 + i;
      final aa = a(seed), bb = b(seed + 7);
      final agents = swap ? [bb, aa, bb, aa] : [aa, bb, aa, bb];
      final aTeam = swap ? 1 : 0;
      var s = BelotEngine.newMatch(seed: seed);
      var deals = 0;
      while (s.phase != GamePhase.matchOver && deals < 60) {
        switch (s.phase) {
          case GamePhase.bidding:
            s = BelotEngine.applyBid(
              s,
              s.currentSeat,
              agents[s.currentSeat].chooseBid(s, s.currentSeat),
            );
          case GamePhase.playing:
            final sw = Stopwatch()..start();
            final c = agents[s.currentSeat].choosePlay(s, s.currentSeat);
            if (sw.elapsed > maxMove) maxMove = sw.elapsed;
            s = BelotEngine.applyPlay(s, s.currentSeat, c);
          case GamePhase.allPassed:
          case GamePhase.dealScored:
            deals++;
            s = BelotEngine.nextDeal(s);
          case GamePhase.matchOver:
            break;
        }
      }
      games++;
      if (s.winnerTeam == aTeam) wins++;
    }
  }
  return (wins / games, games, maxMove);
}

void main(List<String> args) {
  final n = int.parse(args.isNotEmpty ? args[0] : '50');
  final which = args.length > 1 ? args[1] : 'all';
  final hardBudget = const Duration(milliseconds: 250);
  PlayerAgent rnd(int s) => RandomAgent(s);
  PlayerAgent lvl(BotLevel l, int s) => BotAgent(
    l,
    seed: s,
    budget: l == BotLevel.hard ? hardBudget : null,
    maxWorlds: 40,
  );
  void run(
    String name,
    PlayerAgent Function(int) a,
    PlayerAgent Function(int) b,
  ) {
    final sw = Stopwatch()..start();
    final (rate, games, maxMove) = bench(a, b, n);
    stdout.writeln(
      '$name: ${(rate * 100).toStringAsFixed(1)}% of $games matches '
      '(max move ${maxMove.inMilliseconds} ms, ${sw.elapsed.inSeconds}s)',
    );
  }

  if (which == 'all' || which == 'easy')
    run('easy vs random', (s) => lvl(BotLevel.easy, s), rnd);
  if (which == 'all' || which == 'medium')
    run('medium vs random', (s) => lvl(BotLevel.medium, s), rnd);
  if (which == 'all' || which == 'me')
    run(
      'medium vs easy',
      (s) => lvl(BotLevel.medium, s),
      (s) => lvl(BotLevel.easy, s),
    );
  if (which == 'all' || which == 'he')
    run(
      'hard vs easy',
      (s) => lvl(BotLevel.hard, s),
      (s) => lvl(BotLevel.easy, s),
    );
  if (which == 'all' || which == 'hm')
    run(
      'hard vs medium',
      (s) => lvl(BotLevel.hard, s),
      (s) => lvl(BotLevel.medium, s),
    );
}
