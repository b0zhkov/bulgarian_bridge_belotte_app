import 'package:bulgarian_bridge_belotte_app/online/quick_match.dart';
import 'package:bulgarian_bridge_belotte_app/online/rating.dart';
import 'package:flutter_test/flutter_test.dart';

QueueEntry q(String uid, int t, {int h = 100000, String? room}) =>
    QueueEntry(uid: uid, name: uid, joinedAt: t, beat: h, room: room);

void main() {
  group('Elo', () {
    test('equal teams: ±16', () {
      expect(eloDelta(1000, 1000, won: true), 16);
      expect(eloDelta(1000, 1000, won: false), -16);
    });

    test('favourites win less, lose more', () {
      expect(eloDelta(1200, 1000, won: true), 8);
      expect(eloDelta(1200, 1000, won: false), -24);
      expect(eloDelta(1000, 1200, won: true), 24);
    });

    test('deltas are bounded by K', () {
      for (final d in [-800, -200, 0, 200, 800]) {
        for (final w in [true, false]) {
          expect(
            eloDelta(1000.0 + d, 1000, won: w).abs(),
            lessThanOrEqualTo(32),
          );
        }
      }
    });

    test('team averages, bots count as 1000, only rated seats get a delta', () {
      final d = matchDeltas([1200, null, 1000, 1400], 0);
      // Team 0: 1100; team 1: (1000 + 1400) / 2 = 1200.
      expect(d, [20, null, 20, -20]);
    });
  });

  group('ranks', () {
    test('thresholds', () {
      expect(RatingRank.of(0), RatingRank.novice);
      expect(RatingRank.of(899), RatingRank.novice);
      expect(RatingRank.of(900), RatingRank.bronze);
      expect(RatingRank.of(1000), RatingRank.bronze);
      expect(RatingRank.of(1050), RatingRank.silver);
      expect(RatingRank.of(1200), RatingRank.gold);
      expect(RatingRank.of(1350), RatingRank.platinum);
      expect(RatingRank.of(1500), RatingRank.diamond);
      expect(RatingRank.of(1700), RatingRank.master);
      expect(RatingRank.of(2500), RatingRank.master);
    });
  });

  group('matchmaking logic', () {
    test('fresh: unclaimed, recent heartbeat, oldest first', () {
      final all = [
        q('c', 30),
        q('a', 10),
        q('old', 5, h: 1000),
        q('taken', 1, room: 'ABCDE'),
        q('b', 10),
      ];
      expect(QuickLogic.fresh(all, 100000).map((e) => e.uid), ['a', 'b', 'c']);
    });

    test('the oldest waits for four or for its time', () {
      final f = [q('a', 1), q('b', 2), q('c', 3)];
      expect(QuickLogic.batch(f, 'a', timeUp: false, overdue: false), isNull);
      expect(
        QuickLogic.batch(
          f,
          'a',
          timeUp: true,
          overdue: false,
        )!.map((e) => e.uid),
        ['a', 'b', 'c'],
      );
      expect(
        QuickLogic.batch(f, 'b', timeUp: true, overdue: false),
        isNull,
        reason: 'not the matchmaker',
      );
      final four = [...f, q('d', 4), q('e', 5)];
      expect(
        QuickLogic.batch(
          four,
          'a',
          timeUp: false,
          overdue: false,
        )!.map((e) => e.uid),
        ['a', 'b', 'c', 'd'],
      );
    });

    test('an overdue player takes over from a silent matchmaker', () {
      final f = [q('a', 1), q('b', 2), q('c', 3)];
      expect(
        QuickLogic.batch(
          f,
          'b',
          timeUp: true,
          overdue: true,
        )!.map((e) => e.uid),
        ['b', 'a', 'c'],
      );
    });

    test('parse ignores malformed entries', () {
      final l = QueueEntry.parseAll({
        'a': {'n': 'A', 't': 1, 'h': 2, 'r': 1010, 'a': '🦊'},
        'b': {'room': 'ABCDE'},
        'c': 'junk',
      });
      expect(l.map((e) => e.uid), ['a']);
      expect(l.first.rating, 1010);
    });
  });
}
