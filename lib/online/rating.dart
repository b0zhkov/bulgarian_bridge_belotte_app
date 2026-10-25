import 'dart:async';
import 'dart:math';

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

/// Result of applying a match result to the player's own rating.
class RatingChange {
  const RatingChange(this.before, this.delta);
  final int before;
  final int delta;
  int get after => before + delta;
}

/// Reads and writes ratings in the database:
/// * `qresults/{code}/{matchId}/{uid}` = `{b: before, d: delta}` written
///   once by the host of a quick-match room;
/// * `ratings/{uid}` = `{r, g, c, x, t}` written by the player, only as
///   `r = b + d` of such a result (enforced by the security rules); the
///   consumed result entry is deleted afterwards.
class RatingService {
  RatingService(this.db);
  final Db db;

  static Duration resultWait = const Duration(seconds: 40);

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
  /// the rated humans per absolute seat (null = bot / not rated).
  Future<void> writeResults(
    String code,
    String matchId,
    List<String?> seatUids,
    int winnerTeam,
  ) async {
    final before = <int?>[
      for (final u in seatUids) u == null ? null : (await load(u)).value,
    ];
    final d = matchDeltas(before, winnerTeam);
    final out = <String, Object?>{
      for (var s = 0; s < 4; s++)
        if (seatUids[s] != null) seatUids[s]!: {'b': before[s], 'd': d[s]},
    };
    if (out.isEmpty) return;
    await db.set('qresults/$code/$matchId', out);
  }

  /// Player: waits for this match's result and applies it. Null when no
  /// result arrives (e.g. the player was not rated) or it is stale.
  Future<RatingChange?> apply(String code, String matchId) async {
    final path = 'qresults/$code/$matchId/${db.uid}';
    final done = Completer<Map?>();
    final sub = db.watch(path).listen((v) {
      if (v is Map && !done.isCompleted) done.complete(v);
    }, onError: (_) {});
    final res = await done.future.timeout(resultWait, onTimeout: () => null);
    unawaited(sub.cancel());
    if (res == null) return null;
    final b = (res['b'] as num?)?.toInt();
    final dl = (res['d'] as num?)?.toInt();
    if (b == null || dl == null) return null;
    final cur = await load(db.uid);
    if (cur.value != b) return null;
    try {
      await db.set('ratings/${db.uid}', {
        'r': b + dl,
        'g': cur.games + 1,
        'c': code,
        'x': matchId,
        't': const ServerTimestamp(),
      });
    } catch (_) {
      return null;
    }
    try {
      await db.set(path, null);
    } catch (_) {}
    return RatingChange(b, dl);
  }
}
