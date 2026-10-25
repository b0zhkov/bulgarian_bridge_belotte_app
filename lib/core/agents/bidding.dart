import 'dart:math';

import '../rules/rules.dart';

/// Hand evaluation for bidding (the five cards seen while bidding).
///
/// Each contract gets a strength score where ~[bidThreshold] means "should
/// make it with an average partner". Trump J/9 dominate suit and All Trump
/// contracts, aces and tens No Trump; length in trumps, belot (K+Q) and
/// sequence/square potential add to it, and partner's bids support it.
class HandEvaluator {
  const HandEvaluator._();

  static const double bidThreshold = 6.0;

  static double strength(
    List<Card> hand,
    ContractType t, {
    List<ContractType> partnerBids = const [],
    List<ContractType> opponentBids = const [],
  }) {
    var x = switch (t) {
      ContractType.allTrump => _allTrump(hand),
      ContractType.noTrump => _noTrump(hand),
      _ => _suit(hand, t.trumpSuit!),
    };
    x += _declarationPotential(hand);
    for (final p in partnerBids) {
      if (p == t) {
        x += 1.6;
      } else if (t == ContractType.allTrump && p.isSuit) {
        x += 0.8;
      } else if (t == ContractType.noTrump && p == ContractType.noTrump) {
        x += 1.6;
      }
    }
    for (final o in opponentBids) {
      if (t.isSuit && o == t) x -= 1.5; // they hold our trumps
    }
    return x;
  }

  static double _suit(List<Card> hand, Suit trump) {
    final trumps = hand.where((c) => c.suit == trump).toList();
    bool has(Rank r) => trumps.any((c) => c.rank == r);
    var x = 0.0;
    if (has(Rank.jack)) x += 3.5;
    if (has(Rank.nine)) x += has(Rank.jack) ? 3.0 : 2.2;
    if (has(Rank.ace)) x += 1.3;
    if (has(Rank.ten)) x += 1.0;
    if (has(Rank.king) && has(Rank.queen)) x += 1.6; // belot
    x +=
        trumps
            .where(
              (c) =>
                  !{Rank.jack, Rank.nine, Rank.ace, Rank.ten}.contains(c.rank),
            )
            .length *
        0.6;
    if (trumps.length >= 3) x += (trumps.length - 2) * 0.8;
    if (trumps.isEmpty) x -= 3;
    if (!has(Rank.jack) && !(has(Rank.nine) && trumps.length >= 3)) x -= 2;
    for (final su in Suit.values.where((s) => s != trump)) {
      final cs = hand.where((c) => c.suit == su).toList();
      final ace = cs.any((c) => c.rank == Rank.ace);
      if (ace) x += 1.3;
      if (cs.any((c) => c.rank == Rank.ten)) x += ace ? 0.9 : 0.2;
      if (cs.isEmpty && trumps.length >= 2) x += 0.4; // ruffing
    }
    return x;
  }

  static double _allTrump(List<Card> hand) {
    var x = 0.0;
    for (final su in Suit.values) {
      final cs = hand.where((c) => c.suit == su).toList();
      bool has(Rank r) => cs.any((c) => c.rank == r);
      if (has(Rank.jack)) x += 2.6;
      if (has(Rank.nine)) {
        x += has(Rank.jack) ? 1.8 : (cs.length >= 2 ? 0.9 : 0.3);
      }
      if (has(Rank.ace)) x += has(Rank.jack) || has(Rank.nine) ? 0.6 : 0.3;
      if (has(Rank.king) && has(Rank.queen)) x += 1.0;
    }
    return x - 0.6;
  }

  static double _noTrump(List<Card> hand) {
    var x = 0.0;
    for (final su in Suit.values) {
      final cs = hand.where((c) => c.suit == su).toList();
      bool has(Rank r) => cs.any((c) => c.rank == r);
      if (has(Rank.ace)) x += 2.5;
      if (has(Rank.ten)) x += has(Rank.ace) ? 1.6 : (cs.length >= 2 ? 0.4 : 0);
      if (has(Rank.king) && (has(Rank.ace) || has(Rank.ten))) x += 0.4;
      if (cs.isNotEmpty && !has(Rank.ace) && !has(Rank.ten) && cs.length == 1) {
        x -= 0.3; // a loose low card
      }
    }
    return x - 0.5;
  }

  /// Rough bonus for a sequence or square already in hand.
  static double _declarationPotential(List<Card> hand) {
    var x = 0.0;
    for (final su in Suit.values) {
      final ranks = hand
          .where((c) => c.suit == su)
          .map((c) => c.rank.index)
          .toSet();
      var run = 0, best = 0;
      for (var r = 0; r < 8; r++) {
        run = ranks.contains(r) ? run + 1 : 0;
        best = max(best, run);
      }
      if (best >= 3) x += 0.6 + (best - 3) * 0.8;
    }
    for (final r in [Rank.jack, Rank.nine, Rank.ace, Rank.ten]) {
      if (hand.where((c) => c.rank == r).length >= 3) x += 0.5;
    }
    return x;
  }

  /// Defensive strength against an opponent's contract of type [t].
  static double defense(List<Card> hand, ContractType t) {
    switch (t) {
      case ContractType.allTrump:
        return _allTrump(hand) + 0.5;
      case ContractType.noTrump:
        return _noTrump(hand) + 0.5;
      default:
        final trump = t.trumpSuit!;
        var x = 0.0;
        for (final c in hand) {
          if (c.suit == trump) {
            x += switch (c.rank) {
              Rank.jack => 3.2,
              Rank.nine => 2.2,
              Rank.ace => 1.0,
              _ => 0.5,
            };
          } else if (c.rank == Rank.ace) {
            x += 1.4;
          } else if (c.rank == Rank.ten) {
            x += 0.5;
          }
        }
        return x;
    }
  }
}

/// Bid choice with a [noise] (Easy bots) and margins for overcalling.
Bid chooseBidHeuristic(
  GameState s,
  int seat, {
  double noise = 0,
  bool allowDoubles = true,
  Random? rnd,
}) {
  final valid = BelotEngine.validBids(s, seat);
  if (valid.length == 1) return valid.first;
  final hand = s.hands[seat];
  final partnerBids = [
    for (final b in s.bids)
      if (b.seat == (seat + 2) % 4 && b.bid.kind == BidKind.contract)
        b.bid.type!,
  ];
  final opponentBids = [
    for (final b in s.bids)
      if (teamOf(b.seat) != teamOf(seat) && b.bid.kind == BidKind.contract)
        b.bid.type!,
  ];
  double jitter() => noise == 0 ? 0 : (rnd!.nextDouble() * 2 - 1) * noise;
  final c = s.contract;
  final ours = c != null && teamOf(c.declarer) == teamOf(seat);

  // Redouble: our doubled contract and a strong hand for it.
  if (allowDoubles && valid.contains(Bid.redouble)) {
    final st = HandEvaluator.strength(hand, c!.type, partnerBids: partnerBids);
    if (st + jitter() >= HandEvaluator.bidThreshold + 3.0) return Bid.redouble;
  }

  Bid? best;
  var bestMargin = 0.0;
  for (final b in valid.where((b) => b.kind == BidKind.contract)) {
    final t = b.type!;
    final st = HandEvaluator.strength(
      hand,
      t,
      partnerBids: partnerBids,
      opponentBids: opponentBids,
    );
    var need = HandEvaluator.bidThreshold;
    if (c != null) need += ours ? 1.5 : 0.6;
    // Higher contracts score more; prefer them slightly on equal margins.
    final margin = st + jitter() - need + t.index * 0.05;
    if (margin >= 0 && (best == null || margin > bestMargin)) {
      best = b;
      bestMargin = margin;
    }
  }
  if (best != null) return best;

  // Contra only with a strong defensive hand.
  if (allowDoubles && valid.contains(Bid.double)) {
    final d = HandEvaluator.defense(hand, c!.type);
    if (d + jitter() >= 6.5) return Bid.double;
  }
  return Bid.pass;
}
