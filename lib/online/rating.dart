import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';

import 'db.dart';

/// Quick-match rating (Elo).
///
/// * Everybody starts at [kStartRating].
/// * Team-based Elo: a team's rating is the average of its two seats; bots
///   count as [kStartRating]. `E = 1 / (1 + 10^((Ropp - Rteam) / 400))`,
///   `delta = round(K * (S - E))` with `K = 32`, `S` = 1 win / 0 loss.
///   Both players of a team get the same delta.
/// * Only humans still seated (online) when the match ends are rated, so
///   a player who dropped and did not return is not penalised.
const int kStartRating = 1000;
const int kEloK = 32;

/// Expected score of a team rated [team] against [opp].
double eloExpected(double team, double opp) =>
    1 / (1 + pow(10, (opp - team) / 400));

/// Rating change for a team rated [team] that [won] against [opp].
int eloDelta(double team, double opp, {required bool won}) =>
    (kEloK * ((won ? 1 : 0) - eloExpected(team, opp))).round();

/// Deltas for every rated seat. [ratings] has one entry per absolute seat
/// (null for a bot or a player who is not rated); seats 0/2 are team 0.
List<int?> matchDeltas(List<int?> ratings, int winnerTeam) {
  double team(int t) =>
      ((ratings[t] ?? kStartRating) + (ratings[t + 2] ?? kStartRating)) / 2;
  final d = [
    eloDelta(team(0), team(1), won: winnerTeam == 0),
    eloDelta(team(1), team(0), won: winnerTeam == 1),
  ];
  return [for (var s = 0; s < 4; s++) ratings[s] == null ? null : d[s % 2]];
}

/// RatingRank names (Bulgarian in the ARB files) by minimum rating.
enum RatingRank {
  novice(0),
  bronze(900),
  silver(1050),
  gold(1200),
  platinum(1350),
  diamond(1500),
  master(1700);

  const RatingRank(this.min);
  final int min;

  static RatingRank of(int rating) {
    var r = RatingRank.novice;
    for (final x in RatingRank.values) {
      if (rating >= x.min) r = x;
    }
    return r;
  }
}

class Rating {
  const Rating(this.value, this.games);
  final int value;
  final int games;
  static const initial = Rating(kStartRating, 0);

  RatingRank get rank => RatingRank.of(value);

  static Rating fromMap(Object? v) {
    if (v is! Map) return initial;
    return Rating(
      (v['r'] as num?)?.toInt() ?? kStartRating,
      (v['g'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Why a finished quick match did not change anybody's rating.
enum UnratedReason {
  /// One team had no human seated at the end (bots only).
  bots,

  /// The match lasted less than [kMinMatch].
  short,

  /// The result could not be written or did not arrive in time.
  failed;

  static UnratedReason? parse(String? v) {
    for (final r in values) {
      if (r.name == v) return r;
    }
    return null;
  }
}

/// Beta 12 anti-farming limits (mirrored in `database.rules.json`, see
/// `tool/gen_rating_rules.py`).
const Duration kMinMatch = Duration(minutes: 8);
const int kDailyCap = 100;
const int kDayMs = 86400000;
const int kRepeatWindowMs = 86400000;

/// UTC day number of [ms] (the rules only know UTC `now`).
int utcDay(int ms) => ms ~/ kDayMs;

/// Scale for the n-th match (1-based) against the same opponents within
/// 24 h: 100 %, 50 %, 25 %, then 0 %.
double repeatFactor(int nth) => switch (nth) {
  <= 1 => 1,
  2 => 0.5,
  3 => 0.25,
  _ => 0,
};

/// Key of an opponent set: the sorted human opponent uids joined by `_`.
String opponentKey(Iterable<String> uids) => (uids.toList()..sort()).join('_');

/// Earlier matches against the same opponents within the window, from a
/// `rhist/{uid}/{key}` entry `{a, b, c}` (the three latest, newest first).
int recentMatches(Object? hist, int nowMs) {
  if (hist is! Map) return 0;
  var n = 0;
  for (final k in const ['a', 'b', 'c']) {
    final t = (hist[k] as num?)?.toInt();
    if (t == null || t <= nowMs - kRepeatWindowMs) break;
    n++;
  }
  return n;
}

/// What a raw Elo delta becomes after the repeat-opponent scale and the
/// daily cap (gains only; losses are never capped).
class RatingPlan {
  const RatingPlan({
    required this.raw,
    required this.applied,
    required this.nth,
    required this.capped,
    required this.day,
    required this.gainedToday,
  });

  final int raw;
  final int applied;

  /// This is the n-th match against these opponents in 24 h.
  final int nth;
  final bool capped;
  final int day;

  /// Gained today after this match.
  final int gainedToday;

  double get factor => repeatFactor(nth);

  static RatingPlan of({
    required int raw,
    required Object? record,
    required Object? hist,
    required int nowMs,
  }) {
    final day = utcDay(nowMs);
    final rec = record is Map ? record : const {};
    final sameDay = (rec['dy'] as num?)?.toInt() == day;
    final gained = sameDay ? ((rec['gd'] as num?)?.toInt() ?? 0) : 0;
    final nth = recentMatches(hist, nowMs) + 1;
    final scaled = (raw * repeatFactor(nth)).round();
    var applied = scaled;
    var capped = false;
    if (scaled > 0) {
      final rem = max(0, kDailyCap - gained);
      if (scaled > rem) {
        applied = rem;
        capped = true;
      }
    }
    return RatingPlan(
      raw: raw,
      applied: applied,
      nth: nth,
      capped: capped,
      day: day,
      gainedToday: gained + max(0, applied),
    );
  }
}

/// Result of applying a match result to the player's own rating.
class RatingChange {
  const RatingChange(
    this.before,
    this.delta, {
    int? raw,
    this.nth = 1,
    this.capped = false,
  }) : raw = raw ?? delta;
  final int before;

  /// The change actually applied.
  final int delta;

  /// The Elo change before the anti-farming limits.
  final int raw;
  final int nth;
  final bool capped;
  int get after => before + delta;
  double get factor => repeatFactor(nth);
  bool get repeated => nth > 1;
  bool get limited => repeated || capped;
}

/// A finished quick match for this player: a rating change or the reason
/// it was unrated.
class RatingOutcome {
  const RatingOutcome.changed(RatingChange this.change) : unrated = null;
  const RatingOutcome.unrated(UnratedReason this.unrated) : change = null;
  final RatingChange? change;
  final UnratedReason? unrated;
}

/// Both teams (seats 0/2 and 1/3) have at least one rated human.
bool bothTeamsHuman(List<String?> uids) =>
    (uids[0] != null || uids[2] != null) &&
    (uids[1] != null || uids[3] != null);

/// Reads and writes ratings in the database:
/// * `qresults/{code}/{matchId}/{uid}` = `{b, d, k, o1, o2?}` written once
///   by the host of a quick-match room: the rating before, the raw Elo
///   delta, the opponent key and the human opponents (who must have a
///   result in the same write that lists this player back);
/// * `ratings/{uid}` = `{r, g, c, x, t, k, d, dy, gd}` written by the
///   player together with `rhist/{uid}/{k}` (the repeat-opponent history);
///   the rules check the repeat scale and the daily cap;
/// * `rooms/{code}/meta/ur` = `"{matchId}:{reason}"` when the host decides
///   a match is unrated.
class RatingService {
  RatingService(this.db, {DateTime Function()? now})
    : _now = now ?? (() => clock.now());
  final Db db;
  final DateTime Function() _now;

  static Duration resultWait = const Duration(seconds: 40);

  /// Clock offsets tried when the server rejects a write (client clock
  /// skew around a UTC midnight or a 24 h boundary).
  static const List<int> _skews = [0, -300000, 300000, -1800000, 1800000];

  Future<Rating> load(String uid) async {
    try {
      return Rating.fromMap(await db.get('ratings/$uid'));
    } catch (_) {
      return Rating.initial;
    }
  }

  Future<Map<String, Rating>> loadAll(Iterable<String> uids) async => {
    for (final u in uids) u: await load(u),
  };

  /// Host: writes the result of a finished quick match. [seatUids] holds
  /// the rated humans per absolute seat (null = bot / not rated). Returns
  /// false (and writes nothing) when a team has no human.
  Future<bool> writeResults(
    String code,
    String matchId,
    List<String?> seatUids,
    int winnerTeam,
  ) async {
    if (!bothTeamsHuman(seatUids)) return false;
    final before = <int?>[
      for (final u in seatUids) u == null ? null : (await load(u)).value,
    ];
    final d = matchDeltas(before, winnerTeam);
    final out = <String, Object?>{};
    for (var s = 0; s < 4; s++) {
      final u = seatUids[s];
      if (u == null) continue;
      final opp = [
        for (final o in [seatUids[(s + 1) % 4], seatUids[(s + 3) % 4]]) ?o,
      ]..sort();
      out[u] = {
        'b': before[s],
        'd': d[s],
        'k': opponentKey(opp),
        'o1': opp[0],
        if (opp.length > 1) 'o2': opp[1],
      };
    }
    await db.set('qresults/$code/$matchId', out);
    return true;
  }

  /// Host: marks the match unrated for everybody.
  Future<void> markUnrated(String code, String matchId, UnratedReason r) =>
      db.set('rooms/$code/meta/ur', '$matchId:${r.name}');

  /// Player: waits for this match's result (or the host's unrated marker)
  /// and applies it. Null when the result is stale (already applied).
  Future<RatingOutcome?> apply(String code, String matchId) async {
    final path = 'qresults/$code/$matchId/${db.uid}';
    final done = Completer<Object?>();
    final sub = db.watch(path).listen((v) {
      if (v is Map && !done.isCompleted) done.complete(v);
    }, onError: (_) {});
    final sub2 = db.watch('rooms/$code/meta/ur').listen((v) {
      if (v is String && v.startsWith('$matchId:') && !done.isCompleted) {
        done.complete(
          UnratedReason.parse(v.substring(matchId.length + 1)) ??
              UnratedReason.failed,
        );
      }
    }, onError: (_) {});
    final res = await done.future.timeout(resultWait, onTimeout: () => null);
    unawaited(sub.cancel());
    unawaited(sub2.cancel());
    if (res is UnratedReason) return RatingOutcome.unrated(res);
    if (res is! Map) return const RatingOutcome.unrated(UnratedReason.failed);
    final b = (res['b'] as num?)?.toInt();
    final raw = (res['d'] as num?)?.toInt();
    final k = res['k'];
    if (b == null || raw == null || k is! String || k.isEmpty) {
      return const RatingOutcome.unrated(UnratedReason.failed);
    }
    final uid = db.uid;
    Object? record;
    Object? hist;
    try {
      record = await db.get('ratings/$uid');
      hist = await db.get('rhist/$uid/$k');
    } catch (_) {}
    final cur = Rating.fromMap(record);
    if (cur.value != b) return null;
    final h = hist is Map ? hist : const {};
    RatingPlan? done2;
    final tried = <String>{};
    for (final skew in _skews) {
      final plan = RatingPlan.of(
        raw: raw,
        record: record,
        hist: hist,
        nowMs: _now().millisecondsSinceEpoch + skew,
      );
      if (!tried.add('${plan.applied}/${plan.day}/${plan.gainedToday}')) {
        continue;
      }
      try {
        await db.update({
          'ratings/$uid': {
            'r': b + plan.applied,
            'g': cur.games + 1,
            'c': code,
            'x': matchId,
            't': const ServerTimestamp(),
            'k': k,
            'd': raw,
            'dy': plan.day,
            'gd': plan.gainedToday,
          },
          'rhist/$uid/$k': {
            'a': const ServerTimestamp(),
            if (h['a'] != null) 'b': h['a'],
            if (h['b'] != null) 'c': h['b'],
          },
        });
        done2 = plan;
        break;
      } catch (_) {}
    }
    if (done2 == null) {
      return const RatingOutcome.unrated(UnratedReason.failed);
    }
    try {
      await db.set(path, null);
    } catch (_) {}
    unawaited(_prune(uid));
    return RatingOutcome.changed(
      RatingChange(
        b,
        done2.applied,
        raw: raw,
        nth: done2.nth,
        capped: done2.capped,
      ),
    );
  }

  /// Drops repeat-history entries older than the window (+1 h margin).
  Future<void> _prune(String uid) async {
    try {
      final all = await db.get('rhist/$uid');
      if (all is! Map) return;
      final limit = _now().millisecondsSinceEpoch - kRepeatWindowMs - 3600000;
      for (final e in all.entries) {
        final a = e.value is Map ? (e.value['a'] as num?)?.toInt() : null;
        if (a != null && a < limit) await db.set('rhist/$uid/${e.key}', null);
      }
    } catch (_) {}
  }
}
