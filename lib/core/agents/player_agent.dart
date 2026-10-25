import 'dart:math';

import '../rules/rules.dart';

/// Decision-maker for a seat. Real bots will implement this later; the UI
/// and match loop only depend on this interface.
abstract class PlayerAgent {
  Bid chooseBid(GameState state, int seat);
  Card choosePlay(GameState state, int seat);
}

/// Placeholder agent: picks random legal actions purely so the game is
/// testable. Passes most of the time and occasionally bids a contract.
class RandomAgent implements PlayerAgent {
  RandomAgent([int? seed]) : _rnd = Random(seed);
  final Random _rnd;

  @override
  Bid chooseBid(GameState state, int seat) {
    final bids = BelotEngine.validBids(state, seat);
    final contracts = bids.where((b) => b.kind == BidKind.contract).toList();
    final roll = _rnd.nextDouble();
    if (bids.contains(Bid.redouble) && roll < 0.1) return Bid.redouble;
    if (bids.contains(Bid.double) && roll < 0.05) return Bid.double;
    if (contracts.isNotEmpty && roll < (state.contract == null ? 0.45 : 0.12)) {
      // Prefer cheaper contracts.
      return contracts[_rnd.nextInt(min(contracts.length, 4))];
    }
    return Bid.pass;
  }

  @override
  Card choosePlay(GameState state, int seat) {
    final moves = BelotEngine.getLegalMoves(state, seat);
    return moves[_rnd.nextInt(moves.length)];
  }
}
