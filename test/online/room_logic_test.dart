import 'dart:math';

import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_logic.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_models.dart';
import 'package:flutter_test/flutter_test.dart';

Member m(String uid, {int? team, int j = 0, int ta = 0, bool online = true}) =>
    Member(
      uid: uid,
      name: 'N$uid',
      joinedAt: j,
      team: team,
      teamAt: ta,
      online: online,
    );

Map<String, Member> ms(List<Member> l) => {for (final x in l) x.uid: x};

void main() {
  group('room code', () {
    test('generated codes use the unambiguous alphabet', () {
      for (var i = 0; i < 200; i++) {
        final c = generateRoomCode();
        expect(isValidCode(c), isTrue);
        expect(c, isNot(matches(RegExp('[01OIL]'))));
      }
    });
    test('normalisation upper-cases and strips junk', () {
      expect(normalizeCode(' ab-cd e'), 'ABCDE');
      expect(isValidCode('ABCD'), isFalse);
      expect(isValidCode('ABCDI'), isFalse);
    });
  });

  group('lobby and teams', () {
    test('max two humans per team; switching needs a free slot', () {
      final members = ms([m('a', team: 0), m('b', team: 0), m('c', team: 1)]);
      expect(RoomLogic.canJoinTeam(members, 'c', 0), isFalse);
      expect(RoomLogic.canJoinTeam(members, 'a', 1), isTrue);
      expect(
        RoomLogic.canJoinTeam(members, 'a', 0),
        isFalse,
        reason: 'already there',
      );
      final full = ms([...members.values, m('d', team: 1)]);
      expect(RoomLogic.canJoinTeam(full, 'a', 1), isFalse);
    });

    test('offline members do not take slots', () {
      final members = ms([m('a', team: 0), m('b', team: 0, online: false)]);
      expect(RoomLogic.teamHumans(members, 0).length, 1);
      expect(RoomLogic.canJoinTeam(members, 'x', 0), isTrue);
    });

    test('bots only after one human per team; start needs 4 seats', () {
      final one = ms([m('a', team: 0), m('b', team: 0)]);
      expect(RoomLogic.canFillBots(one, const [0, 0]), isFalse);
      expect(RoomLogic.canStart(one, const [2, 2]), isFalse);
      final two = ms([m('a', team: 0), m('b', team: 1)]);
      expect(RoomLogic.canFillBots(two, const [0, 0]), isTrue);
      expect(RoomLogic.canStart(two, const [0, 0]), isFalse);
      final bots = RoomLogic.fillBots(two);
      expect(bots, [1, 1]);
      expect(RoomLogic.canStart(two, bots), isTrue);
      expect(RoomLogic.canFillBots(two, bots), isFalse);
      final four = ms([
        m('a', team: 0),
        m('b', team: 1),
        m('c', team: 0),
        m('d', team: 1),
      ]);
      expect(RoomLogic.canStart(four, const [0, 0]), isTrue);
    });

    test('a human joining replaces a lobby bot', () {
      final members = ms([m('a', team: 0), m('b', team: 1), m('c', team: 1)]);
      expect(RoomLogic.lobbyBots(members, const [1, 1], 1), 0);
      expect(RoomLogic.lobbyBots(members, const [1, 1], 0), 1);
    });

    test('overflow from a race is moved to the other team', () {
      final members = ms([
        m('a', team: 0, ta: 1),
        m('b', team: 0, ta: 2),
        m('c', team: 0, ta: 3),
      ]);
      expect(RoomLogic.normalizeTeams(members), {'c': 1});
      final full = ms([
        m('a', team: 0, ta: 1),
        m('b', team: 0, ta: 2),
        m('c', team: 0, ta: 5),
        m('d', team: 1, ta: 1),
        m('e', team: 1, ta: 2),
      ]);
      expect(RoomLogic.normalizeTeams(full), {'c': null});
    });

    test('seats come from teams: partners opposite', () {
      final members = ms([
        m('a', team: 0, ta: 1),
        m('b', team: 1, ta: 2),
        m('c', team: 0, ta: 3),
      ]);
      final seats = RoomLogic.seatsFromTeams(members);
      expect(seats[0].uid, 'a');
      expect(seats[2].uid, 'c');
      expect(seats[1].uid, 'b');
      expect(seats[3].bot, isTrue);
      expect(teamOf(0), teamOf(2));
    });
  });

  group('host migration', () {
    test('host stays while online', () {
      final members = ms([m('a', j: 1), m('b', j: 0)]);
      expect(RoomLogic.electHost(members, 'a'), 'a');
    });
    test('earliest-joined online member takes over', () {
      final members = ms([
        m('a', j: 1, online: false),
        m('b', j: 5),
        m('c', j: 3),
      ]);
      expect(RoomLogic.electHost(members, 'a'), 'c');
    });
    test('host left the room entirely', () {
      final members = ms([m('b', j: 5), m('c', j: 3)]);
      expect(RoomLogic.electHost(members, 'a'), 'c');
    });
    test('nobody online -> no host (room closes)', () {
      final members = ms([m('a', online: false)]);
      expect(RoomLogic.electHost(members, 'a'), isNull);
    });
  });

  group('bot takeover', () {
    final seats = [
      const Seat.human('a', 'A'),
      const Seat.human('b', 'B'),
      const Seat.bot(),
      const Seat.bot(),
    ];

    test('disconnected human is replaced by a bot holding the seat', () {
      final members = ms([m('a'), m('b', online: false)]);
      final next = RoomLogic.applyPresence(seats, members, 3);
      expect(next[1].bot, isTrue);
      expect(next[1].heldFor, 'b');
      expect(next[1].heldDeal, 3);
      expect(next[1].name, 'B');
      expect(next[0], seats[0]);
    });

    test('a player who left the room is replaced too', () {
      final next = RoomLogic.applyPresence(seats, ms([m('a')]), 1);
      expect(next[1].bot, isTrue);
    });

    test('reconnect within the same deal reclaims the seat', () {
      final held = RoomLogic.applyPresence(
        seats,
        ms([m('a'), m('b', online: false)]),
        3,
      );
      final back = RoomLogic.applyPresence(held, ms([m('a'), m('b')]), 3);
      expect(back[1].uid, 'b');
      expect(back[1].bot, isFalse);
    });

    test('the seat stays reserved for the rest of the match', () {
      final held = RoomLogic.applyPresence(
        seats,
        ms([m('a'), m('b', online: false)]),
        3,
      );
      // Several deals later the reservation still holds...
      final members = ms([m('a'), m('b', online: false)]);
      var later = RoomLogic.applyPresence(held, members, 7);
      later = RoomLogic.assignWaiting(later, members);
      expect(later[1].heldFor, 'b');
      // ...and the player takes it back the moment they are online.
      final back = RoomLogic.applyPresence(later, ms([m('a'), m('b')]), 8);
      expect(back[1], const Seat.human('b', 'Nb'));
    });

    test('newcomers never take a reserved seat, only free bot seats', () {
      final held = [
        const Seat.human('a', 'A'),
        const Seat.bot(name: 'B', heldFor: 'b'),
        const Seat.bot(),
        const Seat.bot(name: 'D', heldFor: 'd'),
      ];
      final members = ms([
        m('a'),
        m('b', online: false),
        m('x', team: 1, j: 5),
        m('y', team: 1, j: 6),
      ]);
      expect(RoomLogic.openTeams(held), [0], reason: 'only seat 2 is free');
      final assigned = RoomLogic.assignWaiting(held, members);
      expect(assigned[2].uid, 'x', reason: 'team 1 reserved -> free seat');
      expect(assigned[1].heldFor, 'b');
      expect(assigned[3].heldFor, 'd');
      expect(RoomLogic.waiting(assigned, members).map((e) => e.uid), ['y']);
      expect(RoomLogic.openTeams(assigned), isEmpty);
    });

    test('hasSeat covers seated and reserved players', () {
      final held = [
        const Seat.human('a', 'A'),
        const Seat.bot(name: 'B', heldFor: 'b'),
        const Seat.bot(),
        const Seat.bot(),
      ];
      expect(RoomLogic.hasSeat(held, 'a'), isTrue);
      expect(RoomLogic.hasSeat(held, 'b'), isTrue);
      expect(RoomLogic.hasSeat(held, 'c'), isFalse);
      expect(RoomLogic.hasSeat(null, 'a'), isFalse);
    });

    test('quick seats: random places, absent players reserved', () {
      final s = RoomLogic.quickSeats([
        (uid: 'a', name: 'A', present: true),
        (uid: 'b', name: 'B', present: false),
      ], Random(3));
      expect(s.where((x) => !x.bot).map((x) => x.uid), ['a']);
      expect(s.where((x) => x.heldFor == 'b').length, 1);
      expect(s.where((x) => x.bot && x.heldFor == null).length, 2);
      // Over many seeds both teams get the first player.
      final teams = {
        for (var i = 0; i < 40; i++)
          RoomLogic.quickSeats([
                (uid: 'a', name: 'A', present: true),
              ], Random(i)).indexWhere((x) => !x.bot) %
              2,
      };
      expect(teams, {0, 1});
    });

    test('waiting players take a bot seat in their chosen team', () {
      final members = ms([
        m('a'),
        m('b'),
        m('x', team: 1, j: 1),
        m('y', team: 1, j: 2),
      ]);
      final assigned = RoomLogic.assignWaiting(seats, members);
      expect(assigned[3].uid, 'x');
      expect(assigned[2].uid, 'y', reason: 'team 1 full -> any bot seat');
      expect(RoomLogic.openTeams(assigned), isEmpty);
    });
  });

  group('intent validation', () {
    final g = BelotEngine.newMatch(
      seed: 7,
      firstDealer: 3,
    ); // seat 0 bids first

    test('valid bid is applied', () {
      final next = RoomLogic.applyIntent(
        g,
        0,
        const Intent(nonce: 1, kind: 'bid', version: 5, value: 'c:clubs'),
        version: 5,
      );
      expect(next, isNotNull);
      expect(next!.contract!.type, ContractType.clubs);
    });

    test(
      'stale version, wrong seat, bad payload and illegal bid are rejected',
      () {
        expect(
          RoomLogic.applyIntent(
            g,
            0,
            const Intent(nonce: 1, kind: 'bid', version: 4, value: 'pass'),
            version: 5,
          ),
          isNull,
        );
        expect(
          RoomLogic.applyIntent(
            g,
            1,
            const Intent(nonce: 1, kind: 'bid', version: 5, value: 'pass'),
            version: 5,
          ),
          isNull,
        );
        expect(
          RoomLogic.applyIntent(
            g,
            0,
            const Intent(nonce: 1, kind: 'bid', version: 5, value: 'nonsense'),
            version: 5,
          ),
          isNull,
        );
        expect(
          RoomLogic.applyIntent(
            g,
            0,
            const Intent(nonce: 1, kind: 'bid', version: 5, value: 'double'),
            version: 5,
          ),
          isNull,
        );
        expect(
          RoomLogic.applyIntent(
            g,
            0,
            const Intent(nonce: 1, kind: 'play', version: 5, value: 'AS'),
            version: 5,
          ),
          isNull,
          reason: 'not playing yet',
        );
        expect(
          RoomLogic.applyIntent(
            g,
            0,
            const Intent(nonce: 1, kind: 'hack', version: 5, value: 'x'),
            version: 5,
          ),
          isNull,
        );
      },
    );

    test('plays: only legal cards from own hand', () {
      var s = g;
      s = BelotEngine.applyBid(s, 0, const Bid.contract(ContractType.clubs));
      for (final seat in [1, 2, 3]) {
        s = BelotEngine.applyBid(s, seat, Bid.pass);
      }
      expect(s.phase, GamePhase.playing);
      final seat = s.currentSeat;
      final legal = BelotEngine.getLegalMoves(s, seat);
      final other = s.hands[(seat + 1) % 4].first;
      expect(
        RoomLogic.applyIntent(
          s,
          seat,
          Intent(nonce: 1, kind: 'play', version: 1, value: other.code),
          version: 1,
        ),
        isNull,
      );
      expect(
        RoomLogic.applyIntent(
          s,
          seat,
          const Intent(nonce: 1, kind: 'play', version: 1, value: 'ZZ'),
          version: 1,
        ),
        isNull,
      );
      final next = RoomLogic.applyIntent(
        s,
        seat,
        Intent(nonce: 1, kind: 'play', version: 1, value: legal.first.code),
        version: 1,
      );
      expect(next!.currentTrick.plays.single.card, legal.first);
    });
  });
}
