import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/online/host_driver.dart';
import 'package:bulgarian_bridge_belotte_app/online/memory_db.dart';
import 'package:bulgarian_bridge_belotte_app/online/quick_match.dart';
import 'package:bulgarian_bridge_belotte_app/online/rating.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_client.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_models.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beta 11: seat reservations, quick matchmaking and rating results on the
/// in-memory database.
void main() {
  late MemoryDbServer server;

  setUp(() {
    HostDriver.botDelay = const Duration(milliseconds: 100);
    HostDriver.trickPause = const Duration(milliseconds: 200);
    HostDriver.redealPause = const Duration(milliseconds: 200);
    HostDriver.dealEndTimeout = const Duration(seconds: 2);
    HostDriver.matchEndTimeout = const Duration(seconds: 5);
    HostDriver.turnTimeout = const Duration(seconds: 90);
    QuickMatcher.wait = const Duration(seconds: 30);
    QuickMatcher.grace = const Duration(seconds: 10);
    QuickMatcher.joinWait = const Duration(seconds: 8);
    RatingService.resultWait = const Duration(seconds: 40);
  });

  RoomClient create(FakeAsync a, String uid, String name) {
    late RoomClient c;
    RoomClient.create(
      server.client(uid),
      name: name,
      codeGen: () => 'ABCDE',
    ).then((x) => c = x);
    a.flushMicrotasks();
    a.elapse(const Duration(milliseconds: 10));
    return c;
  }

  RoomClient join(
    FakeAsync a,
    String uid,
    String name, [
    String code = 'ABCDE',
  ]) {
    late RoomClient c;
    RoomClient.join(server.client(uid), code, name: name).then((x) => c = x);
    a.flushMicrotasks();
    a.elapse(const Duration(milliseconds: 10));
    return c;
  }

  void autoplay(
    FakeAsync a,
    List<RoomClient> clients, {
    int maxSteps = 4000,
    bool Function()? until,
  }) {
    for (var i = 0; i < maxSteps; i++) {
      if (until != null && until()) return;
      for (final c in clients) {
        final g = c.game;
        final seat = c.mySeat;
        if (g == null ||
            seat == null ||
            g.currentSeat != seat ||
            !c.handInSync) {
          continue;
        }
        if (g.phase == GamePhase.bidding) {
          final bids = BelotEngine.validBids(g, seat);
          c.bid(g.contract == null ? bids[1] : Bid.pass);
        } else if (g.phase == GamePhase.playing) {
          c.play(BelotEngine.getLegalMoves(g, seat).first);
        }
      }
      a.elapse(const Duration(milliseconds: 150));
    }
  }

  /// A and B (teams 0/1) plus two bots, match running.
  (RoomClient, RoomClient) startTwo(FakeAsync a) {
    final host = create(a, 'A', 'Георги');
    final b = join(a, 'B', 'Иван');
    b.setTeam(1);
    a.elapse(const Duration(milliseconds: 10));
    host.addBots();
    a.elapse(const Duration(milliseconds: 10));
    host.startMatch();
    a.elapse(const Duration(milliseconds: 50));
    return (host, b);
  }

  group('seat reservation', () {
    test('a dropped player gets the seat back in a later deal', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final (host, b) = startTwo(a);
        final deal = host.game!.dealNumber;
        server.disconnect('B');
        a.elapse(const Duration(milliseconds: 50));
        expect(host.seats![1].heldFor, 'B');
        autoplay(a, [
          host,
        ], until: () => (host.game?.dealNumber ?? 0) >= deal + 2);
        expect(host.seats![1].heldFor, 'B', reason: 'still reserved');
        server.reconnect('B');
        a.elapse(const Duration(milliseconds: 100));
        expect(host.seats![1], const Seat.human('B', 'Иван'));
        expect(b.mySeat, 1);
        expect(b.game!.hands[1], isNotEmpty);
      });
    });

    test('leaving keeps the reservation; rejoin by code takes it back', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final (host, b) = startTwo(a);
        b.leave();
        a.elapse(const Duration(milliseconds: 50));
        expect(server.read('rooms/ABCDE/members/B/o'), false);
        expect(host.seats![1].heldFor, 'B');
        // A newcomer only gets a free bot seat at the end of the deal.
        final c = join(a, 'C', 'Мария');
        c.chooseWaitingTeam(1);
        final deal = host.game!.dealNumber;
        autoplay(a, [host], until: () => (host.game?.dealNumber ?? 0) > deal);
        a.elapse(const Duration(milliseconds: 50));
        expect(host.seats![1].heldFor, 'B');
        expect(c.mySeat, anyOf(2, 3));
        expect(host.seats![c.mySeat!].uid, 'C');
        final b2 = join(a, 'B', 'Иван');
        a.elapse(const Duration(milliseconds: 100));
        expect(b2.mySeat, 1);
        expect(host.seats![1].bot, isFalse);
      });
    });

    test('a room with only absent reserved players closes', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final (host, _) = startTwo(a);
        server.disconnect('B');
        a.elapse(const Duration(milliseconds: 50));
        host.leave();
        a.elapse(const Duration(milliseconds: 50));
        expect(server.read('rooms/ABCDE'), isNull);
        server.reconnect('B');
        final back = join(a, 'B', 'Иван');
        expect(back.connection, RoomConnection.notFound);
      });
    });

    test('host migration keeps reservations', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final (host, b) = startTwo(a);
        final c = join(a, 'C', 'Мария');
        a.elapse(const Duration(milliseconds: 50));
        server.disconnect('A');
        host.detach();
        a.elapse(const Duration(milliseconds: 200));
        expect(b.isHost, isTrue);
        expect(b.seats![0].heldFor, 'A');
        expect(c.mySeat, isNull, reason: 'reserved seat not given away');
      });
    });

    test('match end clears reservations (back to the lobby)', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final (host, _) = startTwo(a);
        server.disconnect('B');
        a.elapse(const Duration(milliseconds: 50));
        autoplay(
          a,
          [host],
          maxSteps: 40000,
          until: () => host.meta?.status == RoomStatus.lobby,
        );
        expect(host.meta!.status, RoomStatus.lobby);
        expect(host.seats, isNull);
      });
    });
  });

  group('quick match', () {
    QuickMatcher start(FakeAsync a, String uid, {int rating = 1000}) {
      final m = QuickMatcher(
        server.client(uid),
        name: 'P$uid',
        rating: rating,
        codeGen: () => 'Q${uid}QQQ'.substring(0, 5),
      );
      m.start();
      a.flushMicrotasks();
      a.elapse(const Duration(milliseconds: 20));
      return m;
    }

    Future<RoomClient?> follow(QuickMatcher m) async => m.hostClient;

    test('four players are matched at once into one room', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final ms = [
          for (final u in ['A', 'B', 'C', 'D']) start(a, u),
        ];
        a.elapse(const Duration(seconds: 1));
        final codes = ms.map((m) => m.matchedCode).toSet();
        expect(codes.length, 1);
        expect(codes.first, isNotNull);
        final host = ms.firstWhere((m) => m.hostClient != null);
        expect(host.uid, 'A', reason: 'oldest entry is the matchmaker');
        // The others join the room they were claimed for.
        final joined = [
          for (final m in ms.where((m) => m.hostClient == null))
            join(a, m.uid, 'P${m.uid}', m.matchedCode!),
        ];
        a.elapse(const Duration(seconds: 9));
        final hc = host.hostClient!;
        expect(hc.meta!.quick, isTrue);
        expect(hc.meta!.status, RoomStatus.playing);
        expect(hc.seats!.where((s) => !s.bot).length, 4);
        for (final j in joined) {
          expect(j.mySeat, isNotNull);
        }
        expect(server.read('queue'), isNull, reason: 'entries removed');
        follow(host);
      });
    });

    test('one player alone starts with three bots after 30 s', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final m = start(a, 'A');
        a.elapse(const Duration(seconds: 20));
        expect(m.phase, QuickPhase.searching);
        expect(m.found, 1);
        expect(m.secondsLeft, inInclusiveRange(9, 11));
        a.elapse(const Duration(seconds: 11));
        a.elapse(const Duration(seconds: 1));
        expect(m.phase, QuickPhase.matched);
        final c = m.hostClient!;
        expect(c.meta!.status, RoomStatus.playing);
        expect(c.seats!.where((s) => s.bot).length, 3);
        expect(c.mySeat, isNotNull);
      });
    });

    test('two players are matched together when the time is up', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final x = start(a, 'A');
        a.elapse(const Duration(seconds: 5));
        final y = start(a, 'B');
        a.elapse(const Duration(seconds: 2));
        expect(x.found, 2);
        expect(y.found, 2);
        a.elapse(const Duration(seconds: 24));
        expect(x.matchedCode, isNotNull);
        expect(y.matchedCode, x.matchedCode);
        final b = join(a, 'B', 'PB', y.matchedCode!);
        a.elapse(const Duration(seconds: 2));
        final seats = x.hostClient!.seats!;
        expect(seats.where((s) => !s.bot).length, 2);
        expect(b.mySeat, isNotNull);
      });
    });

    test('a claimed player who never shows gets a reserved seat', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final x = start(a, 'A');
        start(a, 'B');
        a.elapse(const Duration(seconds: 40));
        final seats = x.hostClient!.seats!;
        expect(seats.where((s) => s.heldFor == 'B').length, 1);
        final b = join(a, 'B', 'PB', x.matchedCode!);
        a.elapse(const Duration(milliseconds: 200));
        expect(b.mySeat, isNotNull, reason: 'takes the reserved seat');
      });
    });

    test('stale queue entries are ignored', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        server.client('Z').set('queue/Z', {'n': 'Old', 't': 1, 'h': -90000});
        final m = start(a, 'A');
        a.elapse(const Duration(seconds: 1));
        expect(m.found, 1);
        a.elapse(const Duration(seconds: 31));
        expect(m.hostClient!.seats!.where((s) => !s.bot).length, 1);
        expect(server.read('queue/Z/room'), isNull, reason: 'not claimed');
      });
    });

    test('cancel removes the entry; a dropped client is removed too', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final m = start(a, 'A');
        start(a, 'B');
        expect(server.read('queue/A'), isNotNull);
        m.cancel();
        a.elapse(const Duration(milliseconds: 20));
        expect(server.read('queue/A'), isNull);
        server.disconnect('B');
        expect(server.read('queue/B'), isNull);
      });
    });
  });

  group('rating results', () {
    test('host writes results; players apply them once', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        server.client('A').set('ratings/A', {'r': 1100, 'g': 3});
        final ra = RatingService(server.client('A'));
        ra.writeResults('ABCDE', 'm0_1', ['A', 'B', null, null], 0);
        a.flushMicrotasks();
        final res = server.read('qresults/ABCDE/m0_1') as Map;
        // Team 0: (1100 + 1000) / 2 = 1050 vs bots/B (1000) → won: +14.
        expect(res['A'], {'b': 1100, 'd': 14, 'k': 'B', 'o1': 'B'});
        expect(res['B'], {'b': 1000, 'd': -14, 'k': 'A', 'o1': 'A'});
        RatingChange? ca, cb;
        ra.apply('ABCDE', 'm0_1').then((x) => ca = x?.change);
        RatingService(server.client('B'))
            .apply('ABCDE', 'm0_1')
            .then((x) => cb = x?.change);
        a.flushMicrotasks();
        a.elapse(const Duration(milliseconds: 10));
        expect(ca!.after, 1114);
        expect(cb!.after, 986);
        expect((server.read('ratings/A') as Map)['g'], 4);
        expect((server.read('ratings/B') as Map)['r'], 986);
        expect(server.read('qresults/ABCDE/m0_1/A'), isNull, reason: 'used');
        // Applying again does nothing (the result is gone).
        RatingService.resultWait = const Duration(seconds: 1);
        RatingOutcome? again;
        ra.apply('ABCDE', 'm0_1').then((x) => again = x);
        a.elapse(const Duration(seconds: 2));
        expect(again?.change, isNull);
        expect(again?.unrated, UnratedReason.failed);
      });
    });

    test('a quick match against bots only is unrated', () {
      fakeAsync((a) {
        server = MemoryDbServer();
        QuickMatcher.wait = const Duration(seconds: 1);
        final m = QuickMatcher(
          server.client('A'),
          name: 'PA',
          codeGen: () => 'QQQQQ',
        )..start();
        a.flushMicrotasks();
        a.elapse(const Duration(seconds: 3));
        final c = m.hostClient!;
        autoplay(
          a,
          [c],
          maxSteps: 40000,
          until: () => c.game?.phase == GamePhase.matchOver,
        );
        a.elapse(const Duration(milliseconds: 100));
        final id = c.meta!.matchId;
        expect(server.read('qresults/QQQQQ/$id'), isNull);
        expect(server.read('rooms/QQQQQ/meta/ur'), '$id:bots');
      });
    });
  });
}
