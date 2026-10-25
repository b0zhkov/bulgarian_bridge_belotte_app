import '../rules/rules.dart';

/// Suggests a sensible legal card for [seat]. Pure and deterministic; used
/// for the hint shown when the player takes long, and a building block for
/// future bots.
///
/// Heuristic:
/// * Leading: lead the most valuable "master" card (no unseen card of that
///   suit can beat it) outside trumps; otherwise lead the cheapest card.
/// * Partner winning: never overtake the partner; add the most points that
///   still leave partner winning when partner's card is safe, else the
///   cheapest card.
/// * Opponent winning: win as cheaply as possible; if impossible, throw the
///   cheapest card.
Card suggestCard(GameState s, int seat) {
  final legal = BelotEngine.getLegalMoves(s, seat);
  if (legal.isEmpty) {
    throw StateError('No legal moves for seat $seat');
  }
  if (legal.length == 1) return legal.first;
  final type = s.contract!.type;
  final trick = s.currentTrick;

  int value(Card c) => cardPoints(c, type);
  int strength(Card c) => strengthInSuit(c, type);
  bool isTrump(Card c) => type.trumpSuit == c.suit;

  // cheapest: lowest points, then lowest strength, non-trumps first.
  int cheapCmp(Card a, Card b) {
    final t = (isTrump(a) ? 1 : 0).compareTo(isTrump(b) ? 1 : 0);
    if (t != 0) return t;
    final v = value(a).compareTo(value(b));
    if (v != 0) return v;
    return strength(a).compareTo(strength(b));
  }

  Card cheapest(Iterable<Card> cards) => (cards.toList()..sort(cheapCmp)).first;

  final seen = <Card>{
    for (final t in s.tricks) ...t.cards,
    ...trick.cards,
    ...s.hands[seat],
  };
  final unseen = fullDeck.where((c) => !seen.contains(c)).toList();

  bool isMaster(Card c) =>
      !unseen.any((u) => u.suit == c.suit && strength(u) > strength(c));

  if (trick.isEmpty) {
    final masters = legal.where((c) => isMaster(c) && !isTrump(c)).toList()
      ..sort((a, b) => value(b).compareTo(value(a)));
    if (masters.isNotEmpty) return masters.first;
    return cheapest(legal);
  }

  bool winsWith(Card c) {
    final t = trick.add(Play(seat, c));
    return currentWinner(t, type) == seat;
  }

  final winner = currentWinner(trick, type);
  final partnerWinning = teamOf(winner) == teamOf(seat);
  final lastToPlay = trick.plays.length == 3;

  if (partnerWinning) {
    final keepPartner = legal.where((c) => !winsWith(c)).toList();
    if (keepPartner.isEmpty) return cheapest(legal);
    final partnerCard = trick.plays.firstWhere((p) => p.seat == winner).card;
    final safe = lastToPlay || isMaster(partnerCard);
    if (safe) {
      final nonTrump = keepPartner.where((c) => !isTrump(c)).toList();
      final pool = nonTrump.isNotEmpty ? nonTrump : keepPartner;
      pool.sort((a, b) => value(b).compareTo(value(a)));
      return pool.first;
    }
    return cheapest(keepPartner);
  }

  final winning = legal.where(winsWith).toList();
  if (winning.isNotEmpty) {
    winning.sort((a, b) {
      final t = (isTrump(a) ? 1 : 0).compareTo(isTrump(b) ? 1 : 0);
      if (t != 0) return t;
      return strength(a).compareTo(strength(b));
    });
    return winning.first;
  }
  return cheapest(legal);
}
