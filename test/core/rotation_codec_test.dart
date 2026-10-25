import 'dart:convert';
import 'dart:math';

import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays random games and yields every intermediate state.
Iterable<GameState> randomStates(int games) sync* {
  for (var seed = 0; seed < games; seed++) {
    final agent = RandomAgent(seed);
    var s = BelotEngine.newMatch(seed: seed, firstDealer: seed % 4);
    for (var step = 0; step < 400 && s.phase != GamePhase.matchOver; step++) {
      yield s;
      final seat = s.currentSeat;
      s = switch (s.phase) {
        GamePhase.bidding => BelotEngine.applyBid(
          s,
          seat,
          agent.chooseBid(s, seat),
        ),
        GamePhase.playing => BelotEngine.applyPlay(
          s,
          seat,
          agent.choosePlay(s, seat),
        ),
        _ => BelotEngine.nextDeal(s),
      };
    }
    yield s;
  }
}

String canon(GameState s) => jsonEncode(StateCodec.encodeGameState(s));

void main() {
  test('full codec round-trips every state (through JSON text)', () {
    var n = 0;
    for (final s in randomStates(12)) {
      final text = jsonEncode(StateCodec.encodeGameState(s));
      final back = StateCodec.decodeGameState(jsonDecode(text) as Map);
      expect(canon(back), canon(s));
      n++;
    }
    expect(n, greaterThan(1000));
  });

  test('public encoding hides hands, stock and seed', () {
    for (final s in randomStates(2)) {
      final pub = StateCodec.encodeGameState(s, full: false);
      expect(pub.containsKey('hands'), isFalse);
      expect(pub.containsKey('stock'), isFalse);
      expect(pub.containsKey('seed'), isFalse);
      expect(StateCodec.handCounts(pub), [for (final h in s.hands) h.length]);
      final text = jsonEncode(pub);
      for (final h in s.hands) {
        for (final c in h) {
          // A card in someone's hand never appears in the public JSON unless
          // it is on the table or in a previous deal's scored declarations.
          final played =
              s.tricks.any((t) => t.cards.contains(c)) ||
              s.currentTrick.cards.contains(c);
          final pastDeals = s.history.any(
            (d) => d.scoringDeclarations.any((x) => x.cards.contains(c)),
          );
          if (!played && !pastDeals) {
            expect(
              text.contains('"${c.code}"'),
              isFalse,
              reason: '${c.code} leaked',
            );
          }
        }
      }
    }
  });

  test('rotation by 4 is identity and rotations compose', () {
    for (final s in randomStates(4)) {
      expect(canon(rotateState(s, 0)), canon(s));
      for (final k in [1, 2, 3]) {
        expect(canon(rotateState(rotateState(s, k), 4 - k)), canon(s));
      }
    }
  });

  test('engine commutes with rotation (view of any seat is consistent)', () {
    final rnd = Random(3);
    var checked = 0;
    for (final s in randomStates(10)) {
      if (s.phase != GamePhase.playing && s.phase != GamePhase.bidding) {
        continue;
      }
      final k = rnd.nextInt(4);
      final r = rotateState(s, k);
      final seat = s.currentSeat;
      final view = (seat - k) % 4;
      if (s.phase == GamePhase.playing) {
        final moves = BelotEngine.getLegalMoves(s, seat);
        expect(BelotEngine.getLegalMoves(r, view), moves);
        final next = BelotEngine.applyPlay(s, seat, moves.first);
        expect(
          canon(BelotEngine.applyPlay(r, view, moves.first)),
          canon(rotateState(next, k)),
        );
      } else {
        expect(BelotEngine.validBids(r, view), BelotEngine.validBids(s, seat));
      }
      checked++;
    }
    expect(checked, greaterThan(300));
  });

  test('odd rotation swaps teams so team 0 is always the viewer', () {
    final s = BelotEngine.newMatch(seed: 1)
        .copyWith(scores: const [10, 20], winnerTeam: 1);
    final r = rotateState(s, 1);
    expect(r.scores, [20, 10]);
    expect(r.winnerTeam, 0);
    expect(rotateState(s, 2).scores, [10, 20]);
  });
}
