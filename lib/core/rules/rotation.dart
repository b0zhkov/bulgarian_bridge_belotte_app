import '../models/models.dart';
import 'declarations.dart';
import 'game_state.dart';
import 'scoring.dart';

/// Rotates a state so that absolute seat [k] becomes seat 0 (the bottom of
/// the table). Seat `s` maps to `(s - k) mod 4`; when [k] is odd the team
/// indices swap too, so team 0 is always "us" for the viewer. The engine
/// commutes with rotation, which the tests check.
GameState rotateState(GameState s, int k) {
  k %= 4;
  if (k == 0) return s;
  int seat(int x) => (x - k) % 4;
  int team(int t) => k.isOdd ? 1 - t : t;
  int? teamN(int? t) => t == null ? null : team(t);
  List<T> byTeam<T>(List<T> l) => k.isOdd ? List.unmodifiable([l[1], l[0]]) : l;
  List<T> bySeat<T>(List<T> l) =>
      List.unmodifiable([for (var v = 0; v < 4; v++) l[(v + k) % 4]]);
  Contract contract(Contract c) =>
      Contract(c.type, seat(c.declarer), c.multiplier);
  Trick trick(Trick t) => Trick(
    seat(t.leader),
    List.unmodifiable([for (final p in t.plays) Play(seat(p.seat), p.card)]),
    t.winner == null ? null : seat(t.winner!),
  );
  Declaration decl(Declaration d) => Declaration(d.type, d.cards, seat(d.seat));
  DealScore deal(DealScore d) => DealScore(
    contract: contract(d.contract),
    cardPoints: byTeam(d.cardPoints),
    declarationPoints: byTeam(d.declarationPoints),
    belotPoints: byTeam(d.belotPoints),
    lastTrickTeam: team(d.lastTrickTeam),
    valatTeam: teamN(d.valatTeam),
    rawPoints: byTeam(d.rawPoints),
    outcome: d.outcome,
    scored: byTeam(d.scored),
    newlyHanging: d.newlyHanging,
    hangingAwarded: d.hangingAwarded,
    hangingAwardedTo: teamN(d.hangingAwardedTo),
    scoringDeclarations: List.unmodifiable(d.scoringDeclarations.map(decl)),
  );
  final a = s.lastAnnouncement;
  return GameState(
    seed: s.seed,
    dealNumber: s.dealNumber,
    dealer: seat(s.dealer),
    phase: s.phase,
    hands: bySeat(s.hands),
    stock: s.stock,
    bids: List.unmodifiable([
      for (final b in s.bids) SeatBid(seat(b.seat), b.bid),
    ]),
    currentSeat: seat(s.currentSeat),
    contract: s.contract == null ? null : contract(s.contract!),
    currentTrick: trick(s.currentTrick),
    tricks: List.unmodifiable(s.tricks.map(trick)),
    declarations: List.unmodifiable(s.declarations.map(decl)),
    belots: List.unmodifiable(s.belots.map(seat)),
    firstCardPlayed: bySeat(s.firstCardPlayed),
    scores: byTeam(s.scores),
    hanging: s.hanging,
    history: List.unmodifiable(s.history.map(deal)),
    lastAnnouncement: a == null
        ? null
        : Announcement(
            seat: seat(a.seat),
            declarations: List.unmodifiable(a.declarations.map(decl)),
            belot: a.belot,
          ),
    winnerTeam: teamN(s.winnerTeam),
  );
}
