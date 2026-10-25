import 'dart:math';

import '../constants/game_constants.dart';
import '../models/models.dart';
import 'card_ranking.dart';
import 'declarations.dart';
import 'game_state.dart';
import 'legal_moves.dart';
import 'scoring.dart';

class IllegalActionException implements Exception {
  IllegalActionException(this.message);
  final String message;
  @override
  String toString() => 'IllegalActionException: $message';
}

/// Pure, deterministic Belot engine. All methods return new states.
class BelotEngine {
  const BelotEngine._();

  /// Shuffled deck for the given seed and deal number (deterministic).
  static List<Card> shuffledDeck(int seed, int dealNumber) {
    final rnd = Random(seed * 7919 + dealNumber * 104729);
    return List.of(fullDeck)..shuffle(rnd);
  }

  /// Starts a new match. [firstDealer] defaults to seat 3 so that seat 0
  /// (the local player) bids and leads first.
  static GameState newMatch({
    int seed = 0,
    int firstDealer = 3,
    List<Card>? deck,
  }) {
    final empty = GameState(
      seed: seed,
      dealNumber: 0,
      dealer: firstDealer,
      phase: GamePhase.bidding,
      hands: const [[], [], [], []],
      stock: const [],
      bids: const [],
      currentSeat: nextSeat(firstDealer),
      contract: null,
      currentTrick: Trick(nextSeat(firstDealer)),
      tricks: const [],
      declarations: const [],
      belots: const [],
      firstCardPlayed: const [false, false, false, false],
      scores: const [0, 0],
      hanging: 0,
      history: const [],
      lastAnnouncement: null,
      winnerTeam: null,
    );
    return dealInitial(empty, dealer: firstDealer, deck: deck);
  }

  /// Deals 3 + 2 cards counter-clockwise starting right of [dealer].
  static GameState dealInitial(
    GameState s, {
    required int dealer,
    List<Card>? deck,
  }) {
    final dealNumber = s.dealNumber + 1;
    final d = deck ?? shuffledDeck(s.seed, dealNumber);
    if (d.length != 32 || d.toSet().length != 32) {
      throw ArgumentError('Deck must contain 32 distinct cards');
    }
    final hands = [<Card>[], <Card>[], <Card>[], <Card>[]];
    var i = 0;
    for (final n in const [3, 2]) {
      for (var k = 1; k <= 4; k++) {
        final seat = (dealer + k) % 4;
        for (var j = 0; j < n; j++) {
          hands[seat].add(d[i++]);
        }
      }
    }
    final first = nextSeat(dealer);
    return s.copyWith(
      dealNumber: dealNumber,
      dealer: dealer,
      phase: GamePhase.bidding,
      hands: List.unmodifiable(hands.map(List<Card>.unmodifiable)),
      stock: List.unmodifiable(d.sublist(i)),
      bids: const [],
      currentSeat: first,
      clearContract: true,
      currentTrick: Trick(first),
      tricks: const [],
      declarations: const [],
      belots: const [],
      firstCardPlayed: const [false, false, false, false],
      clearAnnouncement: true,
    );
  }

  /// Deals the remaining 3 cards to each player after a contract is set.
  static GameState dealRemaining(GameState s) {
    final hands = [for (final h in s.hands) List.of(h)];
    var i = 0;
    for (var k = 1; k <= 4; k++) {
      final seat = (s.dealer + k) % 4;
      for (var j = 0; j < 3; j++) {
        hands[seat].add(s.stock[i++]);
      }
    }
    final first = nextSeat(s.dealer);
    return s.copyWith(
      phase: GamePhase.playing,
      hands: List.unmodifiable(hands.map(List<Card>.unmodifiable)),
      stock: const [],
      currentSeat: first,
      currentTrick: Trick(first),
    );
  }

  // ---------------------------------------------------------------- Bidding

  /// All bids [seat] may make now.
  static List<Bid> validBids(GameState s, int seat) {
    if (s.phase != GamePhase.bidding || s.currentSeat != seat) return const [];
    final c = s.contract;
    return [
      Bid.pass,
      for (final t in ContractType.values)
        if (c == null || t > c.type) Bid.contract(t),
      if (c != null &&
          c.multiplier == Multiplier.none &&
          teamOf(seat) != c.declarerTeam)
        Bid.double,
      if (c != null &&
          c.multiplier == Multiplier.doubled &&
          teamOf(seat) == c.declarerTeam)
        Bid.redouble,
    ];
  }

  static bool validateBid(GameState s, int seat, Bid bid) =>
      validBids(s, seat).contains(bid);

  static GameState applyBid(GameState s, int seat, Bid bid) {
    if (!validateBid(s, seat, bid)) {
      throw IllegalActionException('Seat $seat cannot bid $bid');
    }
    var contract = s.contract;
    switch (bid.kind) {
      case BidKind.pass:
        break;
      case BidKind.contract:
        contract = Contract(bid.type!, seat);
      case BidKind.double:
        contract = contract!.withMultiplier(Multiplier.doubled);
      case BidKind.redouble:
        contract = contract!.withMultiplier(Multiplier.redoubled);
    }
    final next = s.copyWith(
      bids: List.unmodifiable([...s.bids, SeatBid(seat, bid)]),
      contract: contract,
      currentSeat: nextSeat(seat),
    );
    final passes = next.trailingPasses;
    if (contract == null && passes == 4) {
      return next.copyWith(phase: GamePhase.allPassed);
    }
    if (contract != null && passes == 3) {
      return dealRemaining(next);
    }
    return next;
  }

  // ---------------------------------------------------------------- Play

  static List<Card> getLegalMoves(GameState s, int seat) {
    if (s.phase != GamePhase.playing || s.currentSeat != seat) return const [];
    return legalMoves(
      hand: s.hands[seat],
      trick: s.currentTrick,
      type: s.contract!.type,
      seat: seat,
    );
  }

  /// Declarations [seat] would announce with their first card.
  static List<Declaration> calculateDeclarations(GameState s, int seat) =>
      findDeclarations(s.hands[seat], s.contract!.type, seat);

  static GameState applyPlay(GameState s, int seat, Card card) {
    if (!getLegalMoves(s, seat).contains(card)) {
      throw IllegalActionException('Seat $seat cannot play $card');
    }
    final type = s.contract!.type;
    var declarations = s.declarations;
    var belots = s.belots;
    var firstCardPlayed = s.firstCardPlayed;
    List<Declaration> announced = const [];
    if (!s.firstCardPlayed[seat]) {
      announced = calculateDeclarations(s, seat);
      declarations = List.unmodifiable([...declarations, ...announced]);
      firstCardPlayed = List.unmodifiable([
        for (var i = 0; i < 4; i++) i == seat ? true : s.firstCardPlayed[i],
      ]);
    }
    final belot = isBelotPlay(
      card: card,
      hand: s.hands[seat],
      trick: s.currentTrick,
      type: type,
    );
    if (belot) belots = List.unmodifiable([...belots, seat]);

    final hands = List<List<Card>>.unmodifiable([
      for (var i = 0; i < 4; i++)
        i == seat
            ? List<Card>.unmodifiable(s.hands[i].where((c) => c != card))
            : s.hands[i],
    ]);
    var trick = s.currentTrick.add(Play(seat, card));
    final announcement = (announced.isNotEmpty || belot)
        ? Announcement(seat: seat, declarations: announced, belot: belot)
        : null;

    var next = s.copyWith(
      hands: hands,
      declarations: declarations,
      belots: belots,
      firstCardPlayed: firstCardPlayed,
      lastAnnouncement: announcement,
      clearAnnouncement: announcement == null,
    );

    if (!trick.isComplete) {
      return next.copyWith(currentTrick: trick, currentSeat: nextSeat(seat));
    }
    final winner = currentWinner(trick, type);
    trick = trick.withWinner(winner);
    final tricks = List<Trick>.unmodifiable([...s.tricks, trick]);
    next = next.copyWith(
      tricks: tricks,
      currentTrick: Trick(winner),
      currentSeat: winner,
    );
    if (tricks.length == kHandSize) return _finishDeal(next);
    return next;
  }

  static GameState _finishDeal(GameState s) {
    final score = scoreDeal(
      contract: s.contract!,
      tricks: s.tricks,
      declarations: s.declarations,
      belots: s.belots,
      carriedHanging: s.hanging,
    );
    final scores = [
      s.scores[0] + score.scored[0],
      s.scores[1] + score.scored[1],
    ];
    final hanging = score.outcome == DealOutcome.hanging
        ? s.hanging + score.newlyHanging
        : 0;
    final winner = matchWinner(scores, valatDeal: score.isValat);
    return s.copyWith(
      phase: winner == null ? GamePhase.dealScored : GamePhase.matchOver,
      scores: List.unmodifiable(scores),
      hanging: hanging,
      history: List.unmodifiable([...s.history, score]),
      winnerTeam: winner,
    );
  }

  /// Moves to the next deal; the dealer rotates counter-clockwise.
  static GameState nextDeal(GameState s, {List<Card>? deck}) {
    if (s.phase != GamePhase.allPassed && s.phase != GamePhase.dealScored) {
      throw IllegalActionException('Deal not finished');
    }
    return dealInitial(s, dealer: nextSeat(s.dealer), deck: deck);
  }
}

/// belot.bg match end: first to 151; if both reach it, the higher score wins;
/// equal scores continue. "С капо не се излиза": a match cannot be won on a
/// valat deal, so another deal is played.
int? matchWinner(List<int> scores, {required bool valatDeal}) {
  if (valatDeal) return null;
  if (scores[0] < kMatchTarget && scores[1] < kMatchTarget) return null;
  if (scores[0] == scores[1]) return null;
  return scores[0] > scores[1] ? 0 : 1;
}
