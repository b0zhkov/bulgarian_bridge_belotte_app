import '../models/models.dart';

/// Trump order ascending: 7, 8, Q, K, 10, A, 9, J  (J > 9 > A > 10 > K > Q > 8 > 7).
const List<Rank> trumpOrderAsc = [
  Rank.seven, Rank.eight, Rank.queen, Rank.king, Rank.ten, Rank.ace, Rank.nine, Rank.jack,
];

/// Plain order ascending: 7, 8, 9, J, Q, K, 10, A  (A > 10 > K > Q > J > 9 > 8 > 7).
const List<Rank> plainOrderAsc = [
  Rank.seven, Rank.eight, Rank.nine, Rank.jack, Rank.queen, Rank.king, Rank.ten, Rank.ace,
];

/// Strength of [card] within its own suit for the given contract (0..7).
int strengthInSuit(Card card, ContractType type) {
  final trumpRanked =
      type == ContractType.allTrump || type.trumpSuit == card.suit;
  return (trumpRanked ? trumpOrderAsc : plainOrderAsc).indexOf(card.rank);
}

/// Card point value (belot.bg table) before any No Trump doubling.
int cardPoints(Card card, ContractType type) {
  final trumpRanked =
      type == ContractType.allTrump || type.trumpSuit == card.suit;
  switch (card.rank) {
    case Rank.seven:
    case Rank.eight:
      return 0;
    case Rank.nine:
      return trumpRanked ? 14 : 0;
    case Rank.ten:
      return 10;
    case Rank.jack:
      return trumpRanked ? 20 : 2;
    case Rank.queen:
      return 3;
    case Rank.king:
      return 4;
    case Rank.ace:
      return 11;
  }
}

/// Returns the index in [plays] of the currently winning card.
int winningPlayIndex(List<Play> plays, ContractType type) {
  assert(plays.isNotEmpty);
  final led = plays.first.card.suit;
  final trump = type.trumpSuit;
  var best = 0;
  for (var i = 1; i < plays.length; i++) {
    final c = plays[i].card;
    final b = plays[best].card;
    if (trump != null && c.suit == trump && b.suit != trump) {
      best = i;
    } else if (c.suit == b.suit &&
        (c.suit == led || c.suit == trump) &&
        strengthInSuit(c, type) > strengthInSuit(b, type)) {
      best = i;
    }
  }
  return best;
}

/// Seat currently winning the (possibly incomplete) trick.
int currentWinner(Trick trick, ContractType type) =>
    trick.plays[winningPlayIndex(trick.plays, type)].seat;
