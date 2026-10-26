import 'dart:math';

import '../core/rules/rules.dart';
import 'rating.dart';
import 'room_models.dart';

/// Pure room rules: lobby/teams, seats, host election, bot takeover and
/// intent validation. No I/O, fully unit-tested.
class RoomLogic {
  const RoomLogic._();

  static const maxPerTeam = 2;

  /// Online members in [team], earliest team pick first.
  static List<Member> teamHumans(Map<String, Member> members, int team) {
    final l = members.values.where((m) => m.online && m.team == team).toList()
      ..sort((a, b) {
        final c = a.teamAt.compareTo(b.teamAt);
        return c != 0 ? c : a.joinedAt.compareTo(b.joinedAt);
      });
    return l;
  }

  static bool canJoinTeam(Map<String, Member> members, String uid, int team) {
    if (members[uid]?.team == team) return false;
    return teamHumans(members, team).where((m) => m.uid != uid).length <
        maxPerTeam;
  }

  /// Bots shown in a lobby team: requested bots never push humans out.
  static int lobbyBots(Map<String, Member> members, List<int> bots, int team) =>
      max(0, min(bots[team], maxPerTeam - teamHumans(members, team).length));

  static bool canFillBots(Map<String, Member> members, List<int> bots) {
    final h = [teamHumans(members, 0).length, teamHumans(members, 1).length];
    if (h[0] == 0 || h[1] == 0) return false;
    return h[0] + lobbyBots(members, bots, 0) < maxPerTeam ||
        h[1] + lobbyBots(members, bots, 1) < maxPerTeam;
  }

  static List<int> fillBots(Map<String, Member> members) => [
    maxPerTeam - min(maxPerTeam, teamHumans(members, 0).length),
    maxPerTeam - min(maxPerTeam, teamHumans(members, 1).length),
  ];

  static bool canStart(Map<String, Member> members, List<int> bots) {
    for (final t in [0, 1]) {
      final h = min(maxPerTeam, teamHumans(members, t).length);
      if (h == 0) return false;
      if (h + lobbyBots(members, bots, t) != maxPerTeam) return false;
    }
    return true;
  }

  /// Players beyond two per team (lost a race for the last slot) are moved
  /// to the other team when it has room, otherwise left without a team.
  static Map<String, int?> normalizeTeams(Map<String, Member> members) {
    final out = <String, int?>{};
    final counts = [
      teamHumans(members, 0).length,
      teamHumans(members, 1).length,
    ];
    for (final t in [0, 1]) {
      final l = teamHumans(members, t);
      for (final m in l.skip(maxPerTeam)) {
        final other = 1 - t;
        if (counts[other] < maxPerTeam) {
          out[m.uid] = other;
          counts[other]++;
        } else {
          out[m.uid] = null;
        }
        counts[t]--;
      }
    }
    return out;
  }

  /// Seats for a new match: team 0 takes seats 0 and 2, team 1 seats 1 and
  /// 3 (partners opposite), in team-pick order; bots fill the rest.
  static List<Seat> seatsFromTeams(Map<String, Member> members) {
    final seats = List<Seat>.filled(4, const Seat.bot());
    for (final t in [0, 1]) {
      final humans = teamHumans(members, t).take(maxPerTeam).toList();
      for (var i = 0; i < humans.length; i++) {
        seats[t + 2 * i] = Seat.human(humans[i].uid, humans[i].name);
      }
    }
    return seats;
  }

  /// Host stays while online; otherwise the earliest-joined online member.
  static String? electHost(Map<String, Member> members, String? current) {
    if (current != null && members[current]?.online == true) return current;
    final online = members.values.where((m) => m.online).toList()
      ..sort((a, b) {
        final c = a.joinedAt.compareTo(b.joinedAt);
        return c != 0 ? c : a.uid.compareTo(b.uid);
      });
    return online.isEmpty ? null : online.first.uid;
  }

  /// Bot takeover and seat reclaim:
  /// * a seated human who is offline or gone is replaced by a bot that
  ///   keeps the seat reserved for them (by uid) until the match ends;
  /// * a reserved seat goes back to its player as soon as they are online
  ///   again, at any point of the match.
  static List<Seat> applyPresence(
    List<Seat> seats,
    Map<String, Member> members,
    int dealNumber,
  ) {
    return [
      for (final s in seats)
        if (!s.bot && members[s.uid]?.online != true)
          Seat.bot(name: s.name, heldFor: s.uid, heldDeal: dealNumber)
        else if (s.bot &&
            s.heldFor != null &&
            members[s.heldFor]?.online == true)
          Seat.human(s.heldFor!, members[s.heldFor]!.name)
        else
          s,
    ];
  }

  static int? seatOf(List<Seat>? seats, String uid) {
    if (seats == null) return null;
    final i = seats.indexWhere((s) => !s.bot && s.uid == uid);
    return i < 0 ? null : i;
  }

  /// Online members without a seat during a match.
  static List<Member> waiting(List<Seat> seats, Map<String, Member> members) {
    final l =
        members.values
            .where((m) => m.online && seatOf(seats, m.uid) == null)
            .toList()
          ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return l;
  }

  /// A bot seat that is not reserved for an absent player.
  static bool isFree(Seat s) => s.bot && s.heldFor == null;

  /// Teams that currently have a free bot seat a waiting player can take.
  static List<int> openTeams(List<Seat> seats) => [
    for (final t in [0, 1])
      if (isFree(seats[t]) || isFree(seats[t + 2])) t,
  ];

  /// At the end of a deal, waiting players take bot seats: their own
  /// reserved seat first, then a free bot seat in their chosen team, then
  /// any free bot seat. Seats reserved for absent players are never given
  /// away and stay reserved until the match ends.
  static List<Seat> assignWaiting(
    List<Seat> seats,
    Map<String, Member> members,
  ) {
    final out = List.of(seats);
    for (final m in waiting(seats, members)) {
      int? pick;
      for (var i = 0; i < 4 && pick == null; i++) {
        if (out[i].bot && out[i].heldFor == m.uid) pick = i;
      }
      if (m.team != null) {
        for (final i in [m.team!, m.team! + 2]) {
          if (pick == null && isFree(out[i])) pick = i;
        }
      }
      for (var i = 0; i < 4 && pick == null; i++) {
        if (isFree(out[i])) pick = i;
      }
      if (pick != null) out[pick] = Seat.human(m.uid, m.name);
    }
    return out;
  }

  /// Whether [uid] holds a seat (in person or reserved) in [seats].
  static bool hasSeat(List<Seat>? seats, String uid) =>
      seats != null &&
      seats.any((s) => (!s.bot && s.uid == uid) || s.heldFor == uid);

  /// Quick-match seating: [humans] (in queue order) are placed on random
  /// seats, so teams are random; [absent] players get a reserved bot seat.
  static List<Seat> quickSeats(
    List<({String uid, String name, bool present})> humans,
    Random rng,
  ) {
    final order = [0, 1, 2, 3]..shuffle(rng);
    final n = min(humans.length, 4);
    // With two or more humans both teams get one, so the match is rated.
    if (n >= 2 && order.take(n).every((s) => s % 2 == order[0] % 2)) {
      final j = order.indexWhere((s) => s % 2 != order[0] % 2);
      final t = order[1];
      order[1] = order[j];
      order[j] = t;
    }
    final seats = List<Seat>.filled(4, const Seat.bot());
    for (var i = 0; i < n; i++) {
      final h = humans[i];
      seats[order[i]] = h.present
          ? Seat.human(h.uid, h.name)
          : Seat.bot(name: h.name, heldFor: h.uid);
    }
    return seats;
  }

  /// Development builds only (screenshots of rated lines against an
  /// in-memory backend): a bot opposite the first human counts as this
  /// human opponent for rating.
  static String? debugBotOpponent;

  /// Per seat, the uid that counts for rating: humans seated and online.
  static List<String?> ratedUids(
    List<Seat> seats,
    Map<String, Member> members,
  ) {
    final out = [
      for (final x in seats)
        !x.bot && members[x.uid]?.online == true ? x.uid : null,
    ];
    return _withDebugOpponent(seats, out);
  }

  /// Whether the current line-up can still be rated: both teams have a
  /// human seated or a reserved seat (an absent player may come back).
  static bool lineupRated(List<Seat> seats) {
    final out = [for (final x in seats) !x.bot ? x.uid : x.heldFor];
    return bothTeamsHuman(_withDebugOpponent(seats, out));
  }

  static List<String?> _withDebugOpponent(List<Seat> seats, List<String?> u) {
    final opp = debugBotOpponent;
    final me = u.indexWhere((x) => x != null);
    if (opp == null || me < 0) return u;
    for (final s in [(me + 1) % 4, (me + 3) % 4]) {
      if (seats[s].bot && seats[s].heldFor == null) {
        return [...u]..[s] = opp;
      }
    }
    return u;
  }

  /// Validates and applies a bid/play intent from [seat]. Returns null when
  /// the intent is stale, out of turn, malformed or illegal.
  static GameState? applyIntent(
    GameState g,
    int seat,
    Intent i, {
    required int version,
  }) {
    if (i.version != version || g.currentSeat != seat || i.value == null) {
      return null;
    }
    try {
      switch (i.kind) {
        case 'bid':
          if (g.phase != GamePhase.bidding) return null;
          final bid = StateCodec.parseBid(i.value!);
          if (!BelotEngine.validateBid(g, seat, bid)) return null;
          return BelotEngine.applyBid(g, seat, bid);
        case 'play':
          if (g.phase != GamePhase.playing) return null;
          final card = Card.parse(i.value!);
          if (!BelotEngine.getLegalMoves(g, seat).contains(card)) return null;
          return BelotEngine.applyPlay(g, seat, card);
      }
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    } on StateError {
      return null;
    }
    return null;
  }
}
