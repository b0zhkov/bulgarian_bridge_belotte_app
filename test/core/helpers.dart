import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';

List<Card> cs(String s) => Card.parseList(s);
Card c(String s) => Card.parse(s);

Trick trickOf(int leader, String cards) {
  var t = Trick(leader);
  var seat = leader;
  for (final card in cs(cards)) {
    t = t.add(Play(seat, card));
    seat = nextSeat(seat);
  }
  return t;
}

/// Builds 8 completed tricks: team 0 wins tricks containing [team0Cards]
/// (seat 0 as winner), team 1 wins the rest (seat 1). The final trick goes
/// to [lastTeam].
List<Trick> tricksFor(String team0Cards, {required int lastTeam}) {
  final t0 = cs(team0Cards);
  final t1 = fullDeck.where((x) => !t0.contains(x)).toList();
  assert(t0.length % 4 == 0);
  List<Trick> chunk(List<Card> cards, int winner) => [
    for (var i = 0; i < cards.length; i += 4)
      Trick(0, [for (var k = 0; k < 4; k++) Play(k, cards[i + k])], winner),
  ];
  final a = chunk(t0, 0), b = chunk(t1, 1);
  return lastTeam == 0 ? [...b, ...a] : [...a, ...b];
}

/// A deck that deals the given 8-card hands (seat order 0..3) with
/// dealer [dealer]: first 3+2 then 3 per player counter-clockwise.
List<Card> deckFor(List<List<Card>> hands, {int dealer = 3}) {
  final deck = <Card>[];
  final pos = [0, 0, 0, 0];
  for (final n in const [3, 2, 3]) {
    for (var k = 1; k <= 4; k++) {
      final seat = (dealer + k) % 4;
      for (var j = 0; j < n; j++) {
        deck.add(hands[seat][pos[seat]++]);
      }
    }
  }
  return deck;
}
