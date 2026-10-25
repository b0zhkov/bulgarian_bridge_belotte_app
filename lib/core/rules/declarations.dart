import '../models/models.dart';

enum DeclarationType {
  tierce(20, 3),
  quarte(50, 4),
  quint(100, 5),
  square(0, 4);

  const DeclarationType(this.basePoints, this.length);
  final int basePoints;
  final int length;
}

/// A combination announced by a player with their first card.
class Declaration {
  const Declaration(this.type, this.cards, this.seat);

  final DeclarationType type;
  final List<Card> cards;
  final int seat;

  bool get isSequence => type != DeclarationType.square;

  /// Highest rank in natural order for sequences; the square's rank for squares.
  Rank get highRank =>
      cards.map((c) => c.rank).reduce((a, b) => a.index >= b.index ? a : b);

  Suit? get suit => isSequence ? cards.first.suit : null;

  int get points {
    if (!isSequence) return squarePoints(cards.first.rank);
    return type.basePoints;
  }

  @override
  String toString() => '${type.name}(${cards.join(' ')})@$seat';
}

/// belot.bg square values. 7s and 8s do not form a square.
int squarePoints(Rank r) {
  switch (r) {
    case Rank.jack:
      return 200;
    case Rank.nine:
      return 150;
    case Rank.ace:
    case Rank.ten:
    case Rank.king:
    case Rank.queen:
      return 100;
    case Rank.seven:
    case Rank.eight:
      return 0;
  }
}

/// Square strength for comparison between teams: "the square with the
/// highest point value (in trump colour)" i.e. J > 9 > A > 10 > K > Q.
const List<Rank> _squareOrderAsc = [
  Rank.queen,
  Rank.king,
  Rank.ten,
  Rank.ace,
  Rank.nine,
  Rank.jack,
];
int squareStrength(Rank r) => _squareOrderAsc.indexOf(r);

/// Splits consecutive runs into declarable sequences. Runs longer than 5
/// declare a quint (the top five cards); a run of 8 also yields a tierce
/// from the remaining three.
List<Declaration> _sequencesFrom(List<Card> cards, int seat) {
  final out = <Declaration>[];
  for (final suit in Suit.values) {
    final ranks = cards
        .where((c) => c.suit == suit)
        .map((c) => c.rank.index)
        .toSet();
    var i = 0;
    while (i < 8) {
      if (!ranks.contains(i)) {
        i++;
        continue;
      }
      var j = i;
      while (j + 1 < 8 && ranks.contains(j + 1)) {
        j++;
      }
      var hi = j;
      var len = j - i + 1;
      while (len >= 3) {
        final take = len >= 5 ? 5 : len;
        final type = take == 5
            ? DeclarationType.quint
            : take == 4
            ? DeclarationType.quarte
            : DeclarationType.tierce;
        out.add(
          Declaration(type, [
            for (var k = hi - take + 1; k <= hi; k++)
              Card(suit, Rank.values[k]),
          ], seat),
        );
        hi -= take;
        len -= take;
      }
      i = j + 1;
    }
  }
  return out;
}

int _total(List<Declaration> ds) => ds.fold(0, (a, d) => a + d.points);

/// Finds the best set of declarations in [hand] for [type]. Declarations are
/// automatic: when a card fits both a square and a sequence, the option with
/// the most points is chosen (ties prefer the square). No Trump allows none.
List<Declaration> findDeclarations(
  List<Card> hand,
  ContractType type,
  int seat,
) {
  if (type == ContractType.noTrump) return const [];
  final squares = <Declaration>[
    for (final r in Rank.values)
      if (squarePoints(r) > 0 &&
          Suit.values.every((s) => hand.contains(Card(s, r))))
        Declaration(DeclarationType.square, [
          for (final s in Suit.values) Card(s, r),
        ], seat),
  ];
  List<Declaration> best = _sequencesFrom(hand, seat);
  var bestScore = _total(best);
  var bestSquares = 0;
  final n = squares.length;
  for (var mask = 1; mask < (1 << n); mask++) {
    final chosen = [
      for (var k = 0; k < n; k++)
        if (mask & (1 << k) != 0) squares[k],
    ];
    final used = chosen.expand((d) => d.cards).toSet();
    final rest = hand.where((c) => !used.contains(c)).toList();
    final combo = [...chosen, ..._sequencesFrom(rest, seat)];
    final score = _total(combo);
    if (score > bestScore ||
        (score == bestScore && chosen.length > bestSquares)) {
      best = combo;
      bestScore = score;
      bestSquares = chosen.length;
    }
  }
  return List.unmodifiable(best);
}

/// Compares two sequences: longer wins, then the higher top card. 0 = equal.
int compareSequences(Declaration a, Declaration b) {
  final l = a.type.length.compareTo(b.type.length);
  if (l != 0) return l;
  return a.highRank.index.compareTo(b.highRank.index);
}

/// Resolves which declarations score, per belot.bg:
/// * Sequences: only the team with the highest sequence scores (all of its
///   sequences). If the best sequences of both teams are equal, no team
///   scores sequences.
/// * Squares: only the team with the strongest square scores its squares.
/// * Squares do not cancel sequences and vice versa.
/// Returns the scoring declarations.
List<Declaration> resolveDeclarations(List<Declaration> all) {
  final result = <Declaration>[];
  // Sequences
  Declaration? bestOf(int team) {
    Declaration? best;
    for (final d in all.where((d) => d.isSequence && teamOf(d.seat) == team)) {
      if (best == null || compareSequences(d, best) > 0) best = d;
    }
    return best;
  }

  final b0 = bestOf(0), b1 = bestOf(1);
  int? seqTeam;
  if (b0 != null && b1 != null) {
    final c = compareSequences(b0, b1);
    seqTeam = c > 0 ? 0 : (c < 0 ? 1 : null);
  } else if (b0 != null) {
    seqTeam = 0;
  } else if (b1 != null) {
    seqTeam = 1;
  }
  if (seqTeam != null) {
    result.addAll(all.where((d) => d.isSequence && teamOf(d.seat) == seqTeam));
  }
  // Squares
  final squares = all.where((d) => !d.isSequence).toList();
  if (squares.isNotEmpty) {
    squares.sort(
      (a, b) =>
          squareStrength(b.highRank).compareTo(squareStrength(a.highRank)),
    );
    final team = teamOf(squares.first.seat);
    result.addAll(squares.where((d) => teamOf(d.seat) == team));
  }
  return result;
}

/// Whether playing [card] announces a Belot (K+Q of a trump suit), given the
/// [hand] held before playing and the [trick] so far. belot.bg: announced with
/// the first of the two cards, when leading, following the led suit, or (in a
/// suit contract) when trumping.
bool isBelotPlay({
  required Card card,
  required List<Card> hand,
  required Trick trick,
  required ContractType type,
}) {
  if (type == ContractType.noTrump) return false;
  if (card.rank != Rank.king && card.rank != Rank.queen) return false;
  final trumpRanked =
      type == ContractType.allTrump || type.trumpSuit == card.suit;
  if (!trumpRanked) return false;
  final partner = Card(
    card.suit,
    card.rank == Rank.king ? Rank.queen : Rank.king,
  );
  if (!hand.contains(partner)) return false;
  if (trick.isEmpty) return true;
  if (trick.ledSuit == card.suit) return true;
  return type.isSuit; // trumping / under-trumping in a suit contract
}
