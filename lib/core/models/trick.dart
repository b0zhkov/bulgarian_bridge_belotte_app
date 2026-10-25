import 'card.dart';

class Play {
  const Play(this.seat, this.card);
  final int seat;
  final Card card;
  @override
  String toString() => '$seat:$card';
}

/// A trick in progress or completed. Immutable.
class Trick {
  const Trick(this.leader, [this.plays = const [], this.winner]);

  final int leader;
  final List<Play> plays;

  /// Set once the trick is complete.
  final int? winner;

  bool get isEmpty => plays.isEmpty;
  bool get isComplete => plays.length == 4;
  Suit? get ledSuit => plays.isEmpty ? null : plays.first.card.suit;
  List<Card> get cards => [for (final p in plays) p.card];

  Trick add(Play p) => Trick(leader, List.unmodifiable([...plays, p]));
  Trick withWinner(int w) => Trick(leader, plays, w);
}
