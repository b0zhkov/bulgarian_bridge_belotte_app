/// Timing of the dealing animation, shared by the table view (which plays
/// it) and the game drivers (which hold the bots until it has finished).
class DealTiming {
  const DealTiming._();

  /// Global speed factor (tests shrink it; reduced motion skips the
  /// animation in the view, the short hold is harmless).
  static double scale = 1;

  static Duration get stagger =>
      Duration(microseconds: (70000 * scale).round());
  static Duration get flight =>
      Duration(microseconds: (300000 * scale).round());

  /// Duration of dealing [cards] cards (20 for 3+2, 12 for the last 3).
  static Duration total(int cards) =>
      stagger * (cards <= 0 ? 0 : cards - 1) + flight;

  /// How long drivers keep bots (and, online, intents) on hold after a deal
  /// so the animation can play. Slightly shorter than [total] so a player
  /// whose animation started later never acts while the host still holds.
  static Duration hold(int cards) => total(cards) * 0.9;

  /// Seat order of the dealt cards: counter-clockwise from the seat after
  /// the [dealer], [rounds] cards each (e.g. `[3, 2]`, then `[3]`).
  static List<int> order(int dealer, List<int> rounds) => [
    for (final n in rounds)
      for (var k = 1; k <= 4; k++)
        for (var j = 0; j < n; j++) (dealer + k) % 4,
  ];
}
