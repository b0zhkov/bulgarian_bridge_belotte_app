import '../constants/game_constants.dart';
import '../models/models.dart';
import 'card_ranking.dart';
import 'declarations.dart';

enum DealOutcome { outside, inside, hanging }

/// Divides by 10 and rounds following belot.bg per contract:
/// * Suit contract: units 0-5 down, 7-9 up; 6 rounds up only for the team
///   with fewer points (e.g. 96-66 -> 9-7, 56-106 -> 6-10).
/// * All Trump: units 0-3 down, 5-9 up; 4 rounds up only for the team with
///   fewer points (e.g. 134-124 -> 13-13).
/// * No Trump: rounded after doubling, so units are always even; 6+ up.
int roundPoints(int raw, ContractType type, {bool isLower = false}) {
  final base = raw ~/ 10;
  final u = raw % 10;
  bool up;
  switch (type) {
    case ContractType.allTrump:
      up = u >= 5 || (u == 4 && isLower);
    case ContractType.noTrump:
      up = u >= 5;
    default:
      up = u >= 7 || (u == 6 && isLower);
  }
  return up ? base + 1 : base;
}

class DealScore {
  const DealScore({
    required this.contract,
    required this.cardPoints,
    required this.declarationPoints,
    required this.belotPoints,
    required this.lastTrickTeam,
    required this.valatTeam,
    required this.rawPoints,
    required this.outcome,
    required this.scored,
    required this.newlyHanging,
    required this.hangingAwarded,
    required this.hangingAwardedTo,
    required this.scoringDeclarations,
  });

  final Contract contract;

  /// Raw card points per team (before NT doubling), excluding last 10.
  final List<int> cardPoints;
  final List<int> declarationPoints;
  final List<int> belotPoints;
  final int lastTrickTeam;
  final int? valatTeam;

  /// Final raw points per team that are compared and rounded.
  final List<int> rawPoints;
  final DealOutcome outcome;

  /// Match points written for each team for this deal, including any
  /// previously hanging points awarded now.
  final List<int> scored;

  /// Points left hanging by this deal (to be won by the winner of the next).
  final int newlyHanging;

  /// Previously hanging points awarded in this deal and to whom.
  final int hangingAwarded;
  final int? hangingAwardedTo;

  final List<Declaration> scoringDeclarations;

  bool get isValat => valatTeam != null;
}

/// Scores a completed deal.
///
/// [tricks] are the 8 completed tricks (with winners). [declarations] are all
/// declarations announced (unresolved). [belots] lists the seats that
/// announced a Belot (one entry per Belot). [carriedHanging] is the pool of
/// match points hanging from previous deals.
DealScore scoreDeal({
  required Contract contract,
  required List<Trick> tricks,
  required List<Declaration> declarations,
  required List<int> belots,
  int carriedHanging = 0,
}) {
  assert(tricks.length == kHandSize);
  final type = contract.type;
  final cards = [0, 0];
  final trickCount = [0, 0];
  for (final t in tricks) {
    final team = teamOf(t.winner!);
    trickCount[team]++;
    for (final c in t.cards) {
      cards[team] += cardPoints(c, type);
    }
  }
  final lastTeam = teamOf(tricks.last.winner!);
  final valatTeam = trickCount[0] == kHandSize
      ? 0
      : (trickCount[1] == kHandSize ? 1 : null);

  final scoringDecls = type == ContractType.noTrump
      ? <Declaration>[]
      : resolveDeclarations(declarations);
  final declPts = [0, 0];
  for (final d in scoringDecls) {
    declPts[teamOf(d.seat)] += d.points;
  }
  final belotPts = [0, 0];
  if (type != ContractType.noTrump) {
    for (final s in belots) {
      belotPts[teamOf(s)] += kBelotBonus;
    }
  }

  final raw = [0, 0];
  for (var t = 0; t < 2; t++) {
    var p =
        cards[t] +
        (t == lastTeam ? kLastTrickBonus : 0) +
        declPts[t] +
        belotPts[t];
    if (type == ContractType.noTrump) p *= 2; // valat bonus not doubled
    if (t == valatTeam) p += kValatBonus;
    raw[t] = p;
  }

  final st = settle(
    raw: raw,
    contract: contract,
    carriedHanging: carriedHanging,
  );

  return DealScore(
    contract: contract,
    cardPoints: List.unmodifiable(cards),
    declarationPoints: List.unmodifiable(declPts),
    belotPoints: List.unmodifiable(belotPts),
    lastTrickTeam: lastTeam,
    valatTeam: valatTeam,
    rawPoints: List.unmodifiable(raw),
    outcome: st.outcome,
    scored: st.scored,
    newlyHanging: st.newlyHanging,
    hangingAwarded: st.hangingAwarded,
    hangingAwardedTo: st.hangingAwardedTo,
    scoringDeclarations: List.unmodifiable(scoringDecls),
  );
}

class Settlement {
  const Settlement(
    this.outcome,
    this.scored,
    this.newlyHanging,
    this.hangingAwarded,
    this.hangingAwardedTo,
  );
  final DealOutcome outcome;
  final List<int> scored;
  final int newlyHanging;
  final int hangingAwarded;
  final int? hangingAwardedTo;
}

/// Turns final raw points into match points (outside / inside / hanging,
/// double / redouble, carried hanging points), per belot.bg.
Settlement settle({
  required List<int> raw,
  required Contract contract,
  int carriedHanging = 0,
}) {
  final type = contract.type;
  final dt = contract.declarerTeam;
  final ot = 1 - dt;
  final outcome = raw[dt] > raw[ot]
      ? DealOutcome.outside
      : (raw[dt] < raw[ot] ? DealOutcome.inside : DealOutcome.hanging);
  final total = raw[0] + raw[1];
  final roundedTotal = roundPoints(total, type);
  final scored = [0, 0];
  var hanging = 0;
  final mult = contract.multiplier.factor;

  if (contract.multiplier == Multiplier.none) {
    switch (outcome) {
      case DealOutcome.outside:
        final lowerTeam = raw[0] < raw[1] ? 0 : 1;
        for (var t = 0; t < 2; t++) {
          scored[t] = roundPoints(raw[t], type, isLower: t == lowerTeam);
        }
      case DealOutcome.inside:
        scored[ot] = roundedTotal;
      case DealOutcome.hanging:
        // Opponents write their points; the declarers' points hang and are
        // rounded up (belot.bg: 106-106 -> 10 written, 11 hanging).
        scored[ot] = roundPoints(raw[ot], type);
        hanging = roundedTotal - scored[ot];
    }
  } else {
    // Double / redouble: the team with more points takes everything.
    if (outcome == DealOutcome.hanging) {
      hanging = roundedTotal * mult;
    } else {
      final winner = raw[0] > raw[1] ? 0 : 1;
      scored[winner] = roundedTotal * mult;
    }
  }

  int? awardedTo;
  var awarded = 0;
  if (carriedHanging > 0 && outcome != DealOutcome.hanging) {
    awardedTo = raw[0] > raw[1] ? 0 : 1;
    awarded = carriedHanging;
    scored[awardedTo] += carriedHanging;
  }

  return Settlement(
    outcome,
    List.unmodifiable(scored),
    hanging,
    awarded,
    awardedTo,
  );
}
