/// Card primitives for Bulgarian Belot. Pure Dart, no Flutter imports.
library;

/// The four suits. Declaration order matches belot.bg bid ranking
/// (clubs < diamonds < hearts < spades).
enum Suit {
  clubs('♣', 'C'),
  diamonds('♦', 'D'),
  hearts('♥', 'H'),
  spades('♠', 'S');

  const Suit(this.symbol, this.code);
  final String symbol;
  final String code;

  bool get isRed => this == Suit.diamonds || this == Suit.hearts;

  static Suit fromCode(String c) =>
      Suit.values.firstWhere((s) => s.code == c.toUpperCase());
}

/// Ranks in natural sequence order (7-8-9-10-J-Q-K-A), which is the order
/// used for sequence declarations (tierce/quarte/quint).
enum Rank {
  seven('7'),
  eight('8'),
  nine('9'),
  ten('10'),
  jack('J'),
  queen('Q'),
  king('K'),
  ace('A');

  const Rank(this.label);
  final String label;

  static Rank fromLabel(String l) {
    final u = l.toUpperCase();
    if (u == 'T') return Rank.ten;
    return Rank.values.firstWhere((r) => r.label == u);
  }
}

class Card implements Comparable<Card> {
  const Card(this.suit, this.rank);

  final Suit suit;
  final Rank rank;

  /// Parses short notation such as `JS`, `10H`, `TH`, `7C`, `AD`.
  factory Card.parse(String s) {
    final t = s.trim();
    return Card(Suit.fromCode(t.substring(t.length - 1)),
        Rank.fromLabel(t.substring(0, t.length - 1)));
  }

  /// Parses a space separated list of cards.
  static List<Card> parseList(String s) => s
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .map(Card.parse)
      .toList();

  /// Stable index 0..31.
  int get index => suit.index * 8 + rank.index;

  String get code => '${rank.label}${suit.code}';

  @override
  bool operator ==(Object other) =>
      other is Card && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => index;

  @override
  int compareTo(Card other) => index.compareTo(other.index);

  @override
  String toString() => '${rank.label}${suit.symbol}';
}

/// All 32 cards in a fixed order.
final List<Card> fullDeck = List.unmodifiable([
  for (final s in Suit.values)
    for (final r in Rank.values) Card(s, r),
]);
