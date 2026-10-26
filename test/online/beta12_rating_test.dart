import 'dart:math';

import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/online/host_driver.dart';
import 'package:bulgarian_bridge_belotte_app/online/memory_db.dart';
import 'package:bulgarian_bridge_belotte_app/online/quick_match.dart';
import 'package:bulgarian_bridge_belotte_app/online/rating.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_client.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_logic.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_models.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beta 12: anti-farming limits for quick-match rating.
void main() {
  const day = 20387;
  final noon = day * kDayMs + 12 * 3600000;

  group('limits (pure)', () {
    test('repeat factor: 100 %, 50 %, 25 %, then 0 %', () {
      expect(
        [for (var n = 1; n <= 5; n++) repeatFactor(n)],
        [1, 0.5, 0.25, 0, 0],
      );
    });

    test('recent matches count only the last 24 h', () {
      expect(recentMatches(null, noon), 0);
      expect(recentMatches({'a': noon - 1000}, noon), 1);
      expect(
        recentMatches({
          'a': noon - 1000,
          'b': noon - 2000,
          'c': noon - kRepeatWindowMs - 1,
        }, noon),
        2,
      );
      expect(recentMatches({'a': noon - kRepeatWindowMs}, noon), 0);
    });

    test('opponent key is order independent', () {
      expect(opponentKey(['z', 'b']), 'b_z');
      expect(opponentKey(['b', 'z']), 'b_z');
      expect(opponentKey(['q']), 'q');
    });

    test('daily cap clips gains, losses are never capped', () {
      final rec = {'r': 1092, 'dy': day, 'gd': 92};
      final win = RatingPlan.of(raw: 16, record: rec, hist: null, nowMs: noon);
      expect(win.applied, 8);
      expect(win.capped, isTrue);
      expect(win.gainedToday, 100);
      final full = RatingPlan.of(
        raw: 16,
        record: {'r': 1100, 'dy': day, 'gd': 100},
        hist: null,
        nowMs: noon,
      );
      expect(full.applied, 0);
      final loss = RatingPlan.of(
        raw: -16,
        record: rec,
        hist: null,
        nowMs: noon,
      );
      expect(loss.applied, -16);
      expect(loss.capped, isFalse);
      expect(loss.gainedToday, 92);
      // A new UTC day resets the allowance.
      final tomorrow = RatingPlan.of(
        raw: 16,
        record: rec,
        hist: null,
        nowMs: noon + kDayMs,
      );
      expect(tomorrow.applied, 16);
      expect(tomorrow.day, day + 1);
      expect(tomorrow.gainedToday, 16);
    });

    test('repeat opponents scale gains and losses', () {
      Object? hist(int n) => {
        if (n > 0) 'a': noon - 1000,
        if (n > 1) 'b': noon - 2000,
        if (n > 2) 'c': noon - 3000,
      };
      expect(
        [
          for (var n = 0; n < 4; n++)
            RatingPlan.of(
              raw: 32,
              record: null,
              hist: hist(n),
              nowMs: noon,
            ).applied,
        ],
        [32, 16, 8, 0],
      );
      expect(
        [
          for (var n = 0; n < 4; n++)
            RatingPlan.of(
              raw: -15,
              record: null,
              hist: hist(n),
              nowMs: noon,
            ).applied,
        ],
        [-15, -8, -4, 0],
      );
      final p = RatingPlan.of(
        raw: 32,
        record: null,
        hist: hist(1),
        nowMs: noon,
      );
      expect(p.nth, 2);
      expect(p.factor, 0.5);
    });

    test('repeat scale and cap combine', () {
      final p = RatingPlan.of(
        raw: 32,
        record: {'dy': day, 'gd': 90},
        hist: {'a': noon - 1},
        nowMs: noon,
      );
      expect(p.applied, 10, reason: '32 × 50 % = 16, clipped to 10');
      expect(p.capped, isTrue);
      expect(p.nth, 2);
    });
  });

  group('line-up', () {
    test('two or more humans always sit on both teams', () {
      for (var seed = 0; seed < 200; seed++) {
        for (final n in [2, 3, 4]) {
          final s = RoomLogic.quickSeats([
            for (var i = 0; i < n; i++)
              (uid: 'u$i', name: 'U$i', present: true),
          ], Random(seed));
          final u = [for (final x in s) x.bot ? null : x.uid];
          expect(bothTeamsHuman(u), isTrue, reason: 'seed $seed, n $n');
          expect(u.whereType<String>().length, n);
        }
      }
    });

    test('rated only with a human on both teams', () {
      expect(bothTeamsHuman(['a', null, null, null]), isFalse);
      expect(bothTeamsHuman(['a', null, 'b', null]), isFalse);
      expect(bothTeamsHuman(['a', 'b', null, null]), isTrue);
      expect(bothTeamsHuman([null, null, 'a', 'b']), isTrue);
      final seats = [
        const Seat.human('a', 'A'),
        const Seat.bot(),
        const Seat.bot(),
        const Seat.bot(),
      ];
      expect(RoomLogic.lineupRated(seats), isFalse);
      seats[1] = const Seat.bot(name: 'B', heldFor: 'b');
      expect(RoomLogic.lineupRated(seats), isTrue, reason: 'B may return');
      final online = {
        'a': const Member(uid: 'a', name: 'A', joinedAt: 0, online: true),
        'b': const Member(uid: 'b', name: 'B', joinedAt: 0, online: false),
      };
      expect(
        bothTeamsHuman(RoomLogic.ratedUids(seats, online)),
        isFalse,
        reason: 'B is not seated at the end',
      );
    });
  });

  group('results and apply', () {
    late MemoryDbServer server;

    test('bots-only results are not written', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        bool? ok;
        RatingService(server.client('A'))
            .writeResults('ABCDE', 'm0_1', ['A', null, null, null], 0)
            .then((x) => ok = x);
        a.flushMicrotasks();
        expect(ok, isFalse);
        expect(server.read('qresults'), isNull);
      });
    });

    test('results list the human opponents (sorted key)', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        RatingService(server.client('A'))
            .writeResults('ABCDE', 'm0_1', ['A', 'z', 'C', 'b'], 1);
        a.flushMicrotasks();
        final r = server.read('qresults/ABCDE/m0_1') as Map;
        expect(r['A'], {'b': 1000, 'd': -16, 'k': 'b_z', 'o1': 'b', 'o2': 'z'});
        expect(r['z'], {'b': 1000, 'd': 16, 'k': 'A_C', 'o1': 'A', 'o2': 'C'});
      });
    });

    RatingOutcome? applyOne(FakeAsync a, {int d = 16}) {
      server.client('B').set('qresults/ABCDE/m0_1/A', {
        'b':
            ((server.read('ratings/A') as Map?)?['r'] as num?)?.toInt() ?? 1000,
        'd': d,
        'k': 'B',
        'o1': 'B',
      });
      RatingOutcome? out;
      RatingService(server.client('A'))
          .apply('ABCDE', 'm0_1')
          .then((x) => out = x);
      a.flushMicrotasks();
      a.elapse(const Duration(milliseconds: 10));
      return out;
    }

    test('daily cap: the gain is clipped and the counter written', () {
      fakeAsync((a) {
        server = MemoryDbServer(
          timeSource: () => clock.now().millisecondsSinceEpoch,
        );
        final today = utcDay(clock.now().millisecondsSinceEpoch);
        server.client('A').set('ratings/A', {
          'r': 1092,
          'g': 9,
          'dy': today,
          'gd': 92,
        });
        final o = applyOne(a)!;
        expect(o.change!.delta, 8);
        expect(o.change!.raw, 16);
        expect(o.change!.capped, isTrue);
        final r = server.read('ratings/A') as Map;
        expect(r['r'], 1100);
        expect(r['gd'], 100);
        expect(r['dy'], today);
        expect(r['d'], 16);
        expect(r['k'], 'B');
        expect((server.read('rhist/A/B') as Map)['a'], isA<int>());
      });
    });

    test('repeat opponents: 2nd, 3rd and 4th match within 24 h', () {
      fakeAsync((a) {
        server = MemoryDbServer(
          timeSource: () => clock.now().millisecondsSinceEpoch,
        );
        final got = <int>[];
        for (var i = 0; i < 4; i++) {
          final o = applyOne(a, d: 32)!;
          got.add(o.change!.delta);
          a.elapse(const Duration(minutes: 10));
        }
        expect(got, [32, 16, 8, 0]);
        final h = server.read('rhist/A/B') as Map;
        expect(h.keys.toSet(), {'a', 'b', 'c'}, reason: 'three latest kept');
        // A day later the same opponents count fully again.
        a.elapse(const Duration(hours: 24));
        expect(applyOne(a, d: 32)!.change!.delta, 32);
      });
    });

    test('losses are scaled for repeats too, and never capped', () {
      fakeAsync((a) {
        server = MemoryDbServer(
          timeSource: () => clock.now().millisecondsSinceEpoch,
        );
        server.client('A').set('ratings/A', {
          'r': 1200,
          'g': 9,
          'dy': utcDay(clock.now().millisecondsSinceEpoch),
          'gd': 100,
        });
        expect(applyOne(a, d: -20)!.change!.delta, -20);
        a.elapse(const Duration(minutes: 10));
        final o = applyOne(a, d: -20)!.change!;
        expect(o.delta, -10);
        expect(o.nth, 2);
        expect((server.read('ratings/A') as Map)['r'], 1170);
      });
    });

    test('an unrated marker from the host ends the wait', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        RatingOutcome? out;
        RatingService(server.client('A'))
            .apply('ABCDE', 'm0_1')
            .then((x) => out = x);
        a.flushMicrotasks();
        RatingService(server.client('H'))
            .markUnrated('ABCDE', 'm0_1', UnratedReason.short);
        a.elapse(const Duration(milliseconds: 10));
        expect(out?.unrated, UnratedReason.short);
        expect(server.read('ratings/A'), isNull);
      });
    });

    test('a marker for another match is ignored', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        RatingService.resultWait = const Duration(seconds: 2);
        server.client('H').set('rooms/ABCDE/meta/ur', 'm0_0:bots');
        RatingOutcome? out;
        RatingService(server.client('A'))
            .apply('ABCDE', 'm0_1')
            .then((x) => out = x);
        a.elapse(const Duration(seconds: 1));
        expect(out, isNull);
        a.elapse(const Duration(seconds: 2));
        expect(out?.unrated, UnratedReason.failed);
        RatingService.resultWait = const Duration(seconds: 40);
      });
    });
  });

  group('quick match flow', () {
    late MemoryDbServer server;

    setUp(() {
      HostDriver.botDelay = const Duration(milliseconds: 100);
      HostDriver.trickPause = const Duration(milliseconds: 200);
      HostDriver.redealPause = const Duration(milliseconds: 200);
      HostDriver.dealEndTimeout = const Duration(seconds: 2);
      HostDriver.matchEndTimeout = const Duration(seconds: 5);
      QuickMatcher.wait = const Duration(seconds: 30);
      QuickMatcher.grace = const Duration(seconds: 10);
      QuickMatcher.joinWait = const Duration(seconds: 8);
      RatingService.resultWait = const Duration(seconds: 40);
    });
    tearDown(() => HostDriver.minMatch = kMinMatch);

    /// Two humans matched by the queue, played to the end by autoplay.
    (RoomClient, RoomClient) playTwo(FakeAsync a) {
      server = MemoryDbServer(
        timeSource: () => clock.now().millisecondsSinceEpoch,
      );
      QuickMatcher q(String uid) {
        final m = QuickMatcher(
          server.client(uid),
          name: 'P$uid',
          codeGen: () => 'QZZZZ',
        )..start();
        a.flushMicrotasks();
        a.elapse(const Duration(milliseconds: 20));
        return m;
      }

      final x = q('A');
      a.elapse(const Duration(seconds: 2));
      final y = q('B');
      a.elapse(const Duration(seconds: 30));
      late RoomClient b;
      RoomClient.join(
        server.client('B'),
        y.matchedCode!,
        name: 'PB',
      ).then((c) => b = c);
      a.elapse(const Duration(seconds: 2));
      final h = x.hostClient!;
      expect(h.meta!.startedAt, isNotNull, reason: 'meta/st written');
      expect(
        RoomLogic.lineupRated(h.seats!),
        isTrue,
        reason: 'humans on both teams',
      );
      for (var i = 0; i < 40000; i++) {
        if (h.game?.phase == GamePhase.matchOver) break;
        for (final c in [h, b]) {
          final g = c.game;
          final seat = c.mySeat;
          if (g == null || seat == null || g.currentSeat != seat) continue;
          if (!c.handInSync) continue;
          if (g.phase == GamePhase.bidding) {
            final bids = BelotEngine.validBids(g, seat);
            c.bid(g.contract == null ? bids[1] : Bid.pass);
          } else if (g.phase == GamePhase.playing) {
            c.play(BelotEngine.getLegalMoves(g, seat).first);
          }
        }
        a.elapse(const Duration(milliseconds: 150));
      }
      expect(h.game?.phase, GamePhase.matchOver);
      a.elapse(const Duration(milliseconds: 200));
      return (h, b);
    }

    test('a long enough match with humans on both teams is rated', () {
      fakeAsync((a) {
        HostDriver.minMatch = Duration.zero;
        final (h, _) = playTwo(a);
        final id = h.meta!.matchId;
        final r = server.read('qresults/QZZZZ/$id') as Map;
        expect(r.keys.toSet(), {'A', 'B'});
        expect((r['A'] as Map)['o1'], 'B');
        expect((r['A'] as Map)['d'], -(r['B'] as Map)['d']);
        expect(server.read('rooms/QZZZZ/meta/ur'), isNull);
      });
    });

    test('a match shorter than the minimum is unrated ("short")', () {
      fakeAsync((a) {
        HostDriver.minMatch = const Duration(days: 1);
        final (h, b) = playTwo(a);
        final id = h.meta!.matchId;
        expect(server.read('qresults/QZZZZ/$id'), isNull);
        expect(server.read('rooms/QZZZZ/meta/ur'), '$id:short');
        RatingOutcome? out;
        RatingService(b.db).apply('QZZZZ', id).then((x) => out = x);
        a.elapse(const Duration(milliseconds: 10));
        expect(out?.unrated, UnratedReason.short);
      });
    });
  });
}
