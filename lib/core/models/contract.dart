import 'card.dart';

/// Contract types in ascending bidding strength, exactly as belot.bg:
/// ♣ < ♦ < ♥ < ♠ < No Trump < All Trump.
enum ContractType {
  clubs,
  diamonds,
  hearts,
  spades,
  noTrump,
  allTrump;

  bool get isSuit => index <= ContractType.spades.index;

  /// Trump suit for a suit contract, otherwise null.
  Suit? get trumpSuit => isSuit ? Suit.values[index] : null;

  static ContractType forSuit(Suit s) => ContractType.values[s.index];

  bool operator >(ContractType o) => index > o.index;
}

enum Multiplier {
  none(1),
  doubled(2),
  redoubled(4);

  const Multiplier(this.factor);
  final int factor;
}

/// A seat is 0..3, counter-clockwise. Partners sit opposite (0&2, 1&3).
int teamOf(int seat) => seat % 2;
int nextSeat(int seat) => (seat + 1) % 4;

class Contract {
  const Contract(this.type, this.declarer, [this.multiplier = Multiplier.none]);

  final ContractType type;
  final int declarer;
  final Multiplier multiplier;

  int get declarerTeam => teamOf(declarer);
  Suit? get trumpSuit => type.trumpSuit;

  /// Whether [suit] plays with trump ranking in this contract.
  bool isTrumpSuit(Suit suit) =>
      type == ContractType.allTrump || type.trumpSuit == suit;

  Contract withMultiplier(Multiplier m) => Contract(type, declarer, m);

  @override
  bool operator ==(Object other) =>
      other is Contract &&
      other.type == type &&
      other.declarer == declarer &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(type, declarer, multiplier);

  @override
  String toString() => 'Contract($type by $declarer, ${multiplier.name})';
}
