import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/online/host_driver.dart';
import 'package:bulgarian_bridge_belotte_app/online/memory_db.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_client.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_logic.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_models.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Multi-client room scenarios on the in-memory database (no network).
void main() {
  setUp(() {
    HostDriver.botDelay = const Duration(milliseconds: 100);
    HostDriver.trickPause = const Duration(milliseconds: 200);
    HostDriver.redealPause = const Duration(milliseconds: 200);
    HostDriver.dealEndTimeout = const Duration(seconds: 5);
    HostDriver.turnTimeout = const Duration(seconds: 90);
  });

  late MemoryDbServer server;

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

  /// Every human whose turn it is plays its first legal action.
  void autoplay(
    FakeAsync a,
    List<RoomClient> clients, {
    Duration step = const Duration(milliseconds: 150),
    int maxSteps = 2000,
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
        } else if ((g.phase == GamePhase.dealScored ||
                g.phase == GamePhase.matchOver) &&
            !c.ready.contains(c.uid)) {
          c.markReady();
        }
      }
      a.elapse(step);
    }
  }

  test('lobby: teams, bots, start; 2 humans + 2 bots play a full deal', () {
    fakeAsync((a) {
      server = MemoryDbServer();
      final host = create(a, 'A', 'Георги');
      expect(host.connection, RoomConnection.active);
      expect(host.isHost, isTrue);
      expect(host.members['A']!.team, 0);
      final b = join(a, 'B', 'Иван');
      expect(b.connection, RoomConnection.active);
      expect(b.members.length, 2);
      expect(b.meta!.onlineCount, 2);
      expect(RoomLogic.canStart(host.members, host.meta!.bots), isFalse);
      b.setTeam(1);
      a.elapse(const Duration(milliseconds: 10));
      expect(host.members['B']!.team, 1);
      expect(RoomLogic.canFillBots(host.members, host.meta!.bots), isTrue);
      host.addBots();
      a.elapse(const Duration(milliseconds: 10));
      expect(host.meta!.bots, [1, 1]);
      expect(RoomLogic.canStart(host.members, host.meta!.bots), isTrue);
      host.startMatch();
      a.elapse(const Duration(milliseconds: 50));
      expect(b.meta!.status, RoomStatus.playing);
      expect(b.seats!.map((s) => s.bot), [false, false, true, true]);
      expect(host.mySeat, 0);
      expect(b.mySeat, 1);
      // Each player sees only their own hand.
      expect(b.game!.hands[1].length, 5);
      expect(b.game!.hands[0], isEmpty);
      expect(
        server.read('rooms/ABCDE/pub').toString(),
        isNot(contains('"hands"')),
      );
      autoplay(a, [
        host,
        b,
      ], until: () => (host.game?.history.isNotEmpty ?? false));
      expect(host.game!.history.length, 1, reason: 'a full deal was scored');
      expect(b.game!.scores, host.game!.scores);
    });
  });

  test(
    'disconnect -> bot takes the seat; reconnect within the deal reclaims it',
    () {
      fakeAsync((a) {
        server = MemoryDbServer();
        final host = create(a, 'A', 'Георги');
        final b = join(a, 'B', 'Иван');
        b.setTeam(1);
        a.elapse(const Duration(milliseconds: 10));
        host.addBots();
        a.elapse(const Duration(milliseconds: 10));
        host.startMatch();
        a.elapse(const Duration(milliseconds: 50));
        final deal = host.game!.dealNumber;
        server.disconnect('B');
        a.elapse(const Duration(milliseconds: 50));
        expect(host.members['B']!.online, isFalse);
        expect(host.seats![1].bot, isTrue);
        expect(host.seats![1].heldFor, 'B');
        // The bot keeps the game moving while B is away.
        autoplay(
          a,
          [host],
          maxSteps: 3,
          step: const Duration(milliseconds: 300),
        );
        server.reconnect('B');
        a.elapse(const Duration(milliseconds: 50));
        if (host.game!.dealNumber == deal) {
          expect(host.seats![1].bot, isFalse);
          expect(b.mySeat, 1);
        }
      });
    },
  );

  test('host leaves mid-match: earliest remaining human becomes host and continues', () {
    fakeAsync((a) {
      server = MemoryDbServer();
      final host = create(a, 'A', 'Георги');
      final b = join(a, 'B', 'Иван');
      b.setTeam(1);
      a.elapse(const Duration(milliseconds: 10));
      host.addBots();
      a.elapse(const Duration(milliseconds: 10));
      host.startMatch();
      a.elapse(const Duration(milliseconds: 50));
      autoplay(a, [host, b], maxSteps: 10);
      final v = b.version;
      server.disconnect('A');
      host.detach();
      a.elapse(const Duration(milliseconds: 50));
      expect(b.meta!.host, 'B');
      expect(b.isHost, isTrue);
      expect(b.seats![0].bot, isTrue, reason: 'old host seat taken by a bot');
      autoplay(a, [b], until: () => (b.game?.history.isNotEmpty ?? false));
      expect(b.version, greaterThan(v));
      expect(b.game!.history, isNotEmpty);
    });
  });

  test('late joiner waits for the deal to end, then takes a bot seat', () {
    fakeAsync((a) {
      server = MemoryDbServer();
      final host = create(a, 'A', 'Георги');
      final b = join(a, 'B', 'Иван');
      b.setTeam(1);
      a.elapse(const Duration(milliseconds: 10));
      host.addBots();
      a.elapse(const Duration(milliseconds: 10));
      host.startMatch();
      a.elapse(const Duration(milliseconds: 50));
      final c = join(a, 'C', 'Мария');
      expect(c.mySeat, isNull);
      expect(RoomLogic.openTeams(c.seats!), [0, 1]);
      c.setTeam(0);
      a.elapse(const Duration(milliseconds: 10));
      final deal = host.game!.dealNumber;
      autoplay(a, [
        host,
        b,
        c,
      ], until: () => (host.game?.dealNumber ?? 0) > deal);
      expect(c.mySeat, 2, reason: 'took the bot seat in team 0');
    });
  });

  test('last player leaving deletes the room', () {
    fakeAsync((a) {
      server = MemoryDbServer();
      final host = create(a, 'A', 'Георги');
      final b = join(a, 'B', 'Иван');
      host.leave();
      a.elapse(const Duration(milliseconds: 20));
      expect(b.meta!.host, 'B', reason: 'host role handed over');
      b.leave();
      a.elapse(const Duration(milliseconds: 20));
      expect(server.read('rooms/ABCDE'), isNull);
      expect(server.read('hostState/ABCDE'), isNull);
    });
  });

  test('abandoned room (everyone disconnected) is closed for joiners', () {
    fakeAsync((a) {
      server = MemoryDbServer();
      final host = create(a, 'A', 'Георги');
      server.disconnect('A');
      host.detach();
      a.elapse(const Duration(milliseconds: 20));
      final c = join(a, 'C', 'Мария');
      expect(c.connection, RoomConnection.closed);
      expect(server.read('rooms/ABCDE'), isNull);
    });
  });
}
