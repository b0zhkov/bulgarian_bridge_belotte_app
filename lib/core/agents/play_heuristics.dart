import '../rules/rules.dart';
import 'card_memory.dart';

/// Card-play heuristics shared by the Medium bot, the hint and the
/// Monte Carlo rollouts (with [OpenKnowledge]). Pure and deterministic.
///
/// * Leading: draw trumps with the master trump when our side declared;
///   cash master cards in suits the opponents cannot ruff; lead a low card
///   to a partner who can ruff; otherwise a low card from the longest side
///   suit, avoiding unguarded tens.
/// * Partner winning safely: feed points (never overtake); otherwise play
///   cheap.
/// * Opponent winning: win when the win cannot be taken back by a later
///   opponent (with the most points if it is a plain card, the cheapest
///   trump otherwise); else throw the cheapest card, keeping masters and
///   the belot pair.
Card heuristicPlay(GameState s, int seat, Knowledge k) {
  final legal = BelotEngine.getLegalMoves(s, seat);
  if (legal.isEmpty) throw StateError('No legal moves for seat $seat');
  if (legal.length == 1) return legal.first;
  return _Ctx(s, seat, k, legal).choose();
}

class _Ctx {
  _Ctx(this.s, this.seat, this.k, this.legal)
    : type = s.contract!.type,
      trick = s.currentTrick,
      hand = s.hands[seat];

  final GameState s;
  final int seat;
  final Knowledge k;
  final List<Card> legal;
  final ContractType type;
  final Trick trick;
  final List<Card> hand;

  Suit? get trump => type.trumpSuit;
  int partner(int x) => (x + 2) % 4;
  bool isTrump(Card c) => trump == c.suit;
  bool trumpRanked(Suit su) => type == ContractType.allTrump || trump == su;
  int value(Card c) => cardPoints(c, type);
  int strength(Card c) => strengthInSuit(c, type);
  bool get ourContract => s.contract!.declarerTeam == teamOf(seat);

  /// Seats still to play in this trick after [seat].
  List<int> get after => [
    for (var i = trick.plays.length + 1; i < 4; i++) (trick.leader + i) % 4,
  ];

  bool anyMayHold(int who, bool Function(Card) test) =>
      k.outstanding.any((c) => test(c) && k.mayHold(who, c));

  /// Highest outstanding card of [suit] (null if none outstanding).
  bool isMaster(Card c) =>
      !k.outstanding.any((u) => u.suit == c.suit && strength(u) > strength(c));

  /// Whether opponent [op] could take [t] (after our play) with some card.
  bool couldBeat(int op, Trick t) {
    final led = t.ledSuit!;
    final hasLed = anyMayHold(op, (c) => c.suit == led);
    for (final c in k.outstanding) {
      if (!k.mayHold(op, c)) continue;
      if (hasLed && c.suit != led) continue;
      if (currentWinner(t.add(Play(op, c)), type) == op) return true;
    }
    return false;
  }

  bool safeAfter(Trick t) {
    for (final op in after) {
      if (teamOf(op) == teamOf(seat)) continue;
      if (couldBeat(op, t)) return false;
    }
    return true;
  }

  int trickPoints(Trick t) => t.cards.fold(0, (a, c) => a + value(c));

  int cheapCmp(Card a, Card b) {
    final t = (trumpRanked(a.suit) ? 1 : 0).compareTo(
      trumpRanked(b.suit) ? 1 : 0,
    );
    if (t != 0) return t;
    final v = value(a).compareTo(value(b));
    if (v != 0) return v;
    return strength(a).compareTo(strength(b));
  }

  int suitLen(Suit su) => hand.where((c) => c.suit == su).length;

  bool breaksBelot(Card c) {
    if (type == ContractType.noTrump) return false;
    if (!trumpRanked(c.suit)) return false;
    if (c.rank != Rank.king && c.rank != Rank.queen) return false;
    final other = Card(c.suit, c.rank == Rank.king ? Rank.queen : Rank.king);
    return hand.contains(other);
  }

  /// Cheapest card to give away: low value, keep masters, belot pairs and
  /// guards; prefer short suits (to create voids).
  Card discard(List<Card> pool) {
    double cost(Card c) {
      var x = value(c) * 1.0 + strength(c) * 0.3;
      if (trumpRanked(c.suit)) x += 12;
      if (isMaster(c)) x += 8;
      if (breaksBelot(c)) x += 15;
      x += suitLen(c.suit) * 0.4;
      return x;
    }

    return (List.of(pool)..sort((a, b) {
          final d = cost(a).compareTo(cost(b));
          return d != 0 ? d : a.index.compareTo(b.index);
        }))
        .first;
  }

  Card choose() => trick.isEmpty ? lead() : follow();

  // ----------------------------------------------------------- leading

  Card lead() {
    final opps = [(seat + 1) % 4, (seat + 3) % 4];
    bool oppMayTrump(Suit su) =>
        trump != null &&
        su != trump &&
        opps.any(
          (o) =>
              !anyMayHold(o, (c) => c.suit == su) &&
              anyMayHold(o, (c) => c.suit == trump),
        );
    bool oppsHaveTrumps() =>
        trump != null && opps.any((o) => anyMayHold(o, (c) => c.suit == trump));

    // Draw trumps when our side declared and we hold the master trump.
    if (trump != null && ourContract && oppsHaveTrumps()) {
      final masters = legal.where((c) => isTrump(c) && isMaster(c)).toList()
        ..sort((a, b) => strength(b).compareTo(strength(a)));
      if (masters.isNotEmpty) return masters.first;
    }
    // All Trump: cash masters (J, then 9...) – most valuable first.
    final masters = legal.where((c) {
      if (!isMaster(c)) return false;
      if (isTrump(c)) return false;
      if (oppMayTrump(c.suit)) return false;
      // Is anybody left in the suit? Cashing a master nobody can follow
      // only wins our own points.
      return true;
    }).toList()..sort((a, b) => value(b).compareTo(value(a)));
    if (masters.isNotEmpty) {
      // In All Trump prefer the strongest master (draws the suit).
      return masters.first;
    }
    // Lead a low card to a partner who can ruff.
    if (trump != null) {
      final p = partner(seat);
      final ruffable = legal.where(
        (c) =>
            !isTrump(c) &&
            !anyMayHold(p, (x) => x.suit == c.suit) &&
            anyMayHold(p, (x) => x.suit == trump) &&
            !oppMayTrump(c.suit),
      );
      if (ruffable.isNotEmpty) return discard(ruffable.toList());
    }
    // Otherwise a low card from the longest plain suit; avoid giving away
    // unguarded tens/kings and (as defenders) leading trumps.
    final plain = legal.where((c) => !isTrump(c)).toList();
    final pool = plain.isNotEmpty ? plain : legal;
    double cost(Card c) {
      var x = value(c) * 1.0 + strength(c) * 0.2 - suitLen(c.suit) * 1.5;
      final topOutstanding = k.outstanding.any(
        (u) => u.suit == c.suit && strength(u) > strength(c),
      );
      if (topOutstanding && value(c) >= 10) x += 20; // unguarded 10/A-ish
      if (oppMayTrump(c.suit)) x += 6;
      if (breaksBelot(c)) x += 4;
      return x;
    }

    return (List.of(pool)..sort((a, b) {
          final d = cost(a).compareTo(cost(b));
          return d != 0 ? d : a.index.compareTo(b.index);
        }))
        .first;
  }

  // --------------------------------------------------------- following

  Card follow() {
    final winner = currentWinner(trick, type);
    final partnerWinning = teamOf(winner) == teamOf(seat);
    bool wins(Card c) => currentWinner(trick.add(Play(seat, c)), type) == seat;
    final last = trick.plays.length == 3;

    if (partnerWinning) {
      final keep = legal.where((c) => !wins(c)).toList();
      if (keep.isEmpty) {
        // Forced to overtake (raise rule): cheapest.
        return (List.of(legal)..sort(cheapCmp)).first;
      }
      final safe = last || safeAfter(trick.add(Play(seat, keep.first)));
      if (safe) {
        // Feed the most points without using trumps/masters if possible.
        double gain(Card c) {
          var x = value(c) * 1.0;
          if (isTrump(c) && type != ContractType.allTrump) x -= 25;
          if (breaksBelot(c)) x -= 30;
          if (isMaster(c) && c.suit != trick.ledSuit) x -= 6;
          return x;
        }

        return (List.of(keep)..sort((a, b) {
              final d = gain(b).compareTo(gain(a));
              return d != 0 ? d : a.index.compareTo(b.index);
            }))
            .first;
      }
      // Partner may be beaten: can we take it safely ourselves?
      final safeWins = legal
          .where((c) => wins(c) && safeAfter(trick.add(Play(seat, c))))
          .toList();
      if (safeWins.isNotEmpty && trickPoints(trick) >= 10) {
        return _bestWinner(safeWins);
      }
      return discard(keep);
    }

    final winners = legal.where(wins).toList();
    if (winners.isNotEmpty) {
      final safeWins = last
          ? winners
          : winners.where((c) => safeAfter(trick.add(Play(seat, c)))).toList();
      if (safeWins.isNotEmpty) return _bestWinner(safeWins);
      // Partner still to play may win it; don't waste high cards.
      final partnerAfter = after.contains(partner(seat));
      if (!partnerAfter && trickPoints(trick) >= 10) {
        // Try anyway with the cheapest winner.
        return (List.of(winners)..sort((a, b) {
              final t = (isTrump(a) ? 1 : 0).compareTo(isTrump(b) ? 1 : 0);
              return t != 0 ? t : strength(a).compareTo(strength(b));
            }))
            .first;
      }
    }
    return discard(legal);
  }

  /// Among winning cards: plain cards with the most points (an A or 10 of
  /// the led suit), trumps as cheap as possible.
  Card _bestWinner(List<Card> ws) {
    double score(Card c) {
      if (isTrump(c) && type != ContractType.allTrump) {
        return -strength(c).toDouble() - 10;
      }
      // All Trump / plain: take with points, but keep J/9 if cheaper wins.
      if (trumpRanked(c.suit)) return -strength(c).toDouble();
      return value(c).toDouble();
    }

    return (List.of(ws)..sort((a, b) {
          final d = score(b).compareTo(score(a));
          return d != 0 ? d : a.index.compareTo(b.index);
        }))
        .first;
  }
}
