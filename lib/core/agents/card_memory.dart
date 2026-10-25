import '../rules/rules.dart';

/// What a seat can know about the other hands from public information:
/// cards played, the length of each hand, voids and "no higher card"
/// limits inferred from the follow/trump/raise obligations, and cards that
/// must still be held because they were shown in a declaration or belot.
abstract class Knowledge {
  /// Cards not yet played and not in the observer's hand.
  List<Card> get outstanding;

  /// Whether [seat] may still hold [card].
  bool mayHold(int seat, Card card);
}

/// Inferences for [observer] from a [GameState] (only public info + own
/// hand is used, so it is safe for bots).
class CardMemory implements Knowledge {
  CardMemory._(
    this.observer,
    this.outstanding,
    this._cap,
    this.forced,
    this.type,
  ) : _out = outstanding.toSet();

  factory CardMemory.of(GameState s, int observer) {
    final type = s.contract!.type;
    final trump = type.trumpSuit;
    final played = <Card>{
      for (final t in s.tricks) ...t.cards,
      ...s.currentTrick.cards,
    };
    final mine = s.hands[observer].toSet();
    final outstanding = [
      for (final c in fullDeck)
        if (!played.contains(c) && !mine.contains(c)) c,
    ];
    // cap[seat][suit] = highest strength the seat may still hold (7 = any,
    // -1 = void).
    final cap = List.generate(4, (_) => List.filled(4, 7));
    void limit(int seat, Suit suit, int max) {
      if (max < cap[seat][suit.index]) cap[seat][suit.index] = max;
    }

    int highest(List<Play> plays, Suit suit) => plays
        .where((p) => p.card.suit == suit)
        .map((p) => strengthInSuit(p.card, type))
        .fold(-1, (a, b) => a > b ? a : b);

    for (final t in [...s.tricks, s.currentTrick]) {
      if (t.plays.isEmpty) continue;
      final led = t.plays.first.card.suit;
      for (var i = 1; i < t.plays.length; i++) {
        final before = t.plays.sublist(0, i);
        final p = t.plays[i];
        final card = p.card;
        if (card.suit != led) {
          limit(p.seat, led, -1);
          if (trump != null && card.suit != trump) {
            final winner = currentWinner(Trick(t.leader, before), type);
            if (teamOf(winner) != teamOf(p.seat)) {
              // Had to trump (or over-trump) if able.
              limit(p.seat, trump, highest(before, trump));
            }
          }
          continue;
        }
        // Raise obligation: trumps in a suit contract, every suit in All
        // Trump.
        final mustRaise =
            type == ContractType.allTrump || (trump != null && led == trump);
        if (mustRaise) {
          final top = highest(before, led);
          if (strengthInSuit(card, type) < top) limit(p.seat, led, top);
        }
      }
    }
    // Cards shown in declarations / belot that are still in hand.
    final forced = <int, Set<Card>>{};
    for (final d in s.declarations) {
      if (d.seat == observer) continue;
      for (final c in d.cards) {
        if (!played.contains(c)) (forced[d.seat] ??= {}).add(c);
      }
    }
    // Belot: the other half of an announced K/Q pair is still in hand. Only
    // used when unambiguous (every open K/Q the seat played must have been
    // a belot announcement).
    for (final seat in s.belots.toSet()) {
      if (seat == observer || type == ContractType.noTrump) continue;
      final plays = [
        for (final t in [...s.tricks, s.currentTrick])
          for (final p in t.plays)
            if (p.seat == seat) p.card,
      ];
      Card pairOf(Card c) =>
          Card(c.suit, c.rank == Rank.king ? Rank.queen : Rank.king);
      bool kq(Card c) =>
          (c.rank == Rank.king || c.rank == Rank.queen) &&
          (type == ContractType.allTrump || c.suit == trump);
      final open = plays
          .where((c) => kq(c) && !played.contains(pairOf(c)))
          .toList();
      final completed = plays
          .where(
            (c) => c.rank == Rank.king && kq(c) && plays.contains(pairOf(c)),
          )
          .length;
      final announced = s.belots.where((x) => x == seat).length;
      if (open.isNotEmpty && announced - completed >= open.length) {
        for (final c in open) {
          (forced[seat] ??= {}).add(pairOf(c));
        }
      }
    }
    // A forced card is not "may hold" for anyone else; caps must not
    // exclude it for its owner.
    return CardMemory._(observer, outstanding, cap, forced, type);
  }

  final int observer;
  @override
  final List<Card> outstanding;
  final List<List<int>> _cap;
  final Map<int, Set<Card>> forced;
  final ContractType type;
  final Set<Card> _out;

  int capOf(int seat, Suit suit) => _cap[seat][suit.index];
  bool isVoid(int seat, Suit suit) => _cap[seat][suit.index] < 0;

  @override
  bool mayHold(int seat, Card card) {
    if (seat == observer || !_out.contains(card)) return false;
    for (final e in forced.entries) {
      if (e.value.contains(card)) return e.key == seat;
    }
    return strengthInSuit(card, type) <= _cap[seat][card.suit.index];
  }
}

/// Perfect information (used inside Monte Carlo rollouts, where every hand
/// of the sampled world is known).
class OpenKnowledge implements Knowledge {
  OpenKnowledge(this.s, this.observer);
  final GameState s;
  final int observer;

  @override
  late final List<Card> outstanding = [
    for (var i = 0; i < 4; i++)
      if (i != observer) ...s.hands[i],
  ];

  @override
  bool mayHold(int seat, Card card) =>
      seat != observer && s.hands[seat].contains(card);
}
