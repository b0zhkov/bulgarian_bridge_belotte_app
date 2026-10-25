import '../models/models.dart';
import 'declarations.dart';
import 'scoring.dart';

enum GamePhase {
  /// Five cards dealt, players are bidding.
  bidding,

  /// Everybody passed; call [BelotEngine.nextDeal] to redeal.
  allPassed,

  /// Eight cards dealt, tricks are being played.
  playing,

  /// Deal is over and scored; call [BelotEngine.nextDeal].
  dealScored,

  /// Match finished.
  matchOver,
}

/// Announcement event for the UI (declarations shown with a first card,
/// belot shown when the first of K/Q is played).
class Announcement {
  const Announcement({
    required this.seat,
    this.declarations = const [],
    this.belot = false,
  });
  final int seat;
  final List<Declaration> declarations;
  final bool belot;
}

/// Immutable snapshot of a whole match.
class GameState {
  const GameState({
    required this.seed,
    required this.dealNumber,
    required this.dealer,
    required this.phase,
    required this.hands,
    required this.stock,
    required this.bids,
    required this.currentSeat,
    required this.contract,
    required this.currentTrick,
    required this.tricks,
    required this.declarations,
    required this.belots,
    required this.firstCardPlayed,
    required this.scores,
    required this.hanging,
    required this.history,
    required this.lastAnnouncement,
    required this.winnerTeam,
  });

  final int seed;

  /// Number of deals started so far (1-based for the current one). Used to
  /// derive a deterministic shuffle per deal.
  final int dealNumber;
  final int dealer;
  final GamePhase phase;
  final List<List<Card>> hands;

  /// Cards not dealt yet (12 during bidding, empty afterwards).
  final List<Card> stock;
  final List<SeatBid> bids;

  /// Seat whose turn it is to bid or play.
  final int currentSeat;

  /// Highest contract so far during bidding; final contract when playing.
  final Contract? contract;
  final Trick currentTrick;
  final List<Trick> tricks;
  final List<Declaration> declarations;
  final List<int> belots;
  final List<bool> firstCardPlayed;
  final List<int> scores;

  /// Match points hanging for the winner of the next deal.
  final int hanging;
  final List<DealScore> history;
  final Announcement? lastAnnouncement;
  final int? winnerTeam;

  GameState copyWith({
    int? dealNumber,
    int? dealer,
    GamePhase? phase,
    List<List<Card>>? hands,
    List<Card>? stock,
    List<SeatBid>? bids,
    int? currentSeat,
    Contract? contract,
    bool clearContract = false,
    Trick? currentTrick,
    List<Trick>? tricks,
    List<Declaration>? declarations,
    List<int>? belots,
    List<bool>? firstCardPlayed,
    List<int>? scores,
    int? hanging,
    List<DealScore>? history,
    Announcement? lastAnnouncement,
    bool clearAnnouncement = false,
    int? winnerTeam,
  }) {
    return GameState(
      seed: seed,
      dealNumber: dealNumber ?? this.dealNumber,
      dealer: dealer ?? this.dealer,
      phase: phase ?? this.phase,
      hands: hands ?? this.hands,
      stock: stock ?? this.stock,
      bids: bids ?? this.bids,
      currentSeat: currentSeat ?? this.currentSeat,
      contract: clearContract ? null : (contract ?? this.contract),
      currentTrick: currentTrick ?? this.currentTrick,
      tricks: tricks ?? this.tricks,
      declarations: declarations ?? this.declarations,
      belots: belots ?? this.belots,
      firstCardPlayed: firstCardPlayed ?? this.firstCardPlayed,
      scores: scores ?? this.scores,
      hanging: hanging ?? this.hanging,
      history: history ?? this.history,
      lastAnnouncement: clearAnnouncement
          ? null
          : (lastAnnouncement ?? this.lastAnnouncement),
      winnerTeam: winnerTeam ?? this.winnerTeam,
    );
  }

  /// Number of consecutive passes at the end of the bid list.
  int get trailingPasses {
    var n = 0;
    for (
      var i = bids.length - 1;
      i >= 0 && bids[i].bid.kind == BidKind.pass;
      i--
    ) {
      n++;
    }
    return n;
  }

  DealScore? get lastDeal => history.isEmpty ? null : history.last;
}
