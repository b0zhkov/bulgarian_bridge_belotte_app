import '../models/models.dart';
import 'card_ranking.dart';

/// Legal cards [seat] may play from [hand] onto [trick] under [type],
/// following belot.bg:
/// * Suit contract: follow suit; when trump is led you must raise if able.
///   If void and an opponent is winning you must trump, and if an opponent
///   has already trumped you must over-trump. If you cannot over-trump you
///   may play any card. If your partner is winning you may play anything.
/// * No Trump: only following suit is mandatory.
/// * All Trump: follow suit and raise (beat the highest card of the led suit)
///   whenever possible, regardless of who is winning.
List<Card> legalMoves({
  required List<Card> hand,
  required Trick trick,
  required ContractType type,
  required int seat,
}) {
  if (trick.isEmpty) return List.of(hand);
  final led = trick.ledSuit!;
  final ofLed = hand.where((c) => c.suit == led).toList();

  int highestOf(Suit s) => trick.plays
      .where((p) => p.card.suit == s)
      .map((p) => strengthInSuit(p.card, type))
      .fold(-1, (a, b) => a > b ? a : b);

  List<Card> higherThan(List<Card> cards, int strength) =>
      cards.where((c) => strengthInSuit(c, type) > strength).toList();

  switch (type) {
    case ContractType.noTrump:
      return ofLed.isNotEmpty ? ofLed : List.of(hand);

    case ContractType.allTrump:
      if (ofLed.isEmpty) return List.of(hand);
      final higher = higherThan(ofLed, highestOf(led));
      return higher.isNotEmpty ? higher : ofLed;

    case ContractType.clubs:
    case ContractType.diamonds:
    case ContractType.hearts:
    case ContractType.spades:
      final trump = type.trumpSuit!;
      if (ofLed.isNotEmpty) {
        if (led == trump) {
          final higher = higherThan(ofLed, highestOf(trump));
          return higher.isNotEmpty ? higher : ofLed;
        }
        return ofLed;
      }
      final winner = currentWinner(trick, type);
      if (teamOf(winner) == teamOf(seat)) return List.of(hand);
      final trumps = hand.where((c) => c.suit == trump).toList();
      if (trumps.isEmpty) return List.of(hand);
      final trickHasTrump = trick.plays.any((p) => p.card.suit == trump);
      if (!trickHasTrump) return trumps;
      final higher = higherThan(trumps, highestOf(trump));
      return higher.isNotEmpty ? higher : List.of(hand);
  }
}
