import '../models/models.dart';
import 'declarations.dart';
import 'game_state.dart';
import 'scoring.dart';

/// JSON (de)serialisation of [GameState] for online play.
///
/// [encodeGameState] with `full: true` keeps everything (host-only copy);
/// `full: false` drops the secret parts (seed, stock and every hand) and
/// keeps only the number of cards each seat holds.
class StateCodec {
  const StateCodec._();

  static String card(Card c) => c.code;
  static List<String> cards(List<Card> cs) => [for (final c in cs) c.code];
  static List<Card> parseCards(Object? v) => [
    for (final s in (v as List? ?? const [])) Card.parse(s as String),
  ];

  static String bid(Bid b) =>
      b.kind == BidKind.contract ? 'c:${b.type!.name}' : b.kind.name;
  static Bid parseBid(String s) {
    if (s.startsWith('c:')) {
      return Bid.contract(ContractType.values.byName(s.substring(2)));
    }
    return switch (s) {
      'pass' => Bid.pass,
      'double' => Bid.double,
      'redouble' => Bid.redouble,
      _ => throw FormatException('bad bid $s'),
    };
  }

  static Map<String, Object?> contract(Contract c) => {
    't': c.type.name,
    'd': c.declarer,
    'm': c.multiplier.name,
  };
  static Contract parseContract(Map m) => Contract(
    ContractType.values.byName(m['t'] as String),
    m['d'] as int,
    Multiplier.values.byName(m['m'] as String),
  );

  static Map<String, Object?> trick(Trick t) => {
    'l': t.leader,
    'p': [
      for (final p in t.plays) [p.seat, p.card.code],
    ],
    'w': t.winner,
  };
  static Trick parseTrick(Map m) => Trick(
    m['l'] as int,
    List.unmodifiable([
      for (final p in (m['p'] as List? ?? const []))
        Play((p as List)[0] as int, Card.parse(p[1] as String)),
    ]),
    m['w'] as int?,
  );

  static Map<String, Object?> decl(Declaration d, {bool hideCards = false}) => {
    't': d.type.name,
    'c': hideCards ? const <String>[] : cards(d.cards),
    's': d.seat,
  };
  static Declaration parseDecl(Map m) => Declaration(
    DeclarationType.values.byName(m['t'] as String),
    List.unmodifiable(parseCards(m['c'])),
    m['s'] as int,
  );

  static List<int> _ints(Object? v) =>
      List.unmodifiable([for (final x in (v as List? ?? const [])) x as int]);

  static Map<String, Object?> dealScore(DealScore d) => {
    'contract': contract(d.contract),
    'cardPoints': d.cardPoints,
    'declarationPoints': d.declarationPoints,
    'belotPoints': d.belotPoints,
    'lastTrickTeam': d.lastTrickTeam,
    'valatTeam': d.valatTeam,
    'rawPoints': d.rawPoints,
    'outcome': d.outcome.name,
    'scored': d.scored,
    'newlyHanging': d.newlyHanging,
    'hangingAwarded': d.hangingAwarded,
    'hangingAwardedTo': d.hangingAwardedTo,
    'decls': [for (final x in d.scoringDeclarations) decl(x)],
  };
  static DealScore parseDealScore(Map m) => DealScore(
    contract: parseContract(m['contract'] as Map),
    cardPoints: _ints(m['cardPoints']),
    declarationPoints: _ints(m['declarationPoints']),
    belotPoints: _ints(m['belotPoints']),
    lastTrickTeam: m['lastTrickTeam'] as int,
    valatTeam: m['valatTeam'] as int?,
    rawPoints: _ints(m['rawPoints']),
    outcome: DealOutcome.values.byName(m['outcome'] as String),
    scored: _ints(m['scored']),
    newlyHanging: m['newlyHanging'] as int,
    hangingAwarded: m['hangingAwarded'] as int,
    hangingAwardedTo: m['hangingAwardedTo'] as int?,
    scoringDeclarations: List.unmodifiable([
      for (final x in (m['decls'] as List? ?? const [])) parseDecl(x as Map),
    ]),
  );

  static Map<String, Object?> encodeGameState(
    GameState s, {
    bool full = true,
  }) => {
    if (full) 'seed': s.seed,
    'dealNumber': s.dealNumber,
    'dealer': s.dealer,
    'phase': s.phase.name,
    if (full) 'hands': [for (final h in s.hands) cards(h)],
    if (full) 'stock': cards(s.stock),
    if (!full) 'handCounts': [for (final h in s.hands) h.length],
    'bids': [
      for (final b in s.bids) [b.seat, bid(b.bid)],
    ],
    'currentSeat': s.currentSeat,
    'contract': s.contract == null ? null : contract(s.contract!),
    'currentTrick': trick(s.currentTrick),
    'tricks': [for (final t in s.tricks) trick(t)],
    // Declarations are announced by type only; their cards stay secret
    // until the deal is scored (history keeps them).
    'declarations': [for (final d in s.declarations) decl(d, hideCards: !full)],
    'belots': s.belots,
    'firstCardPlayed': s.firstCardPlayed,
    'scores': s.scores,
    'hanging': s.hanging,
    'history': [for (final d in s.history) dealScore(d)],
    'announcement': s.lastAnnouncement == null
        ? null
        : {
            's': s.lastAnnouncement!.seat,
            'd': [
              for (final d in s.lastAnnouncement!.declarations)
                decl(d, hideCards: !full),
            ],
            'b': s.lastAnnouncement!.belot,
          },
    'winnerTeam': s.winnerTeam,
  };

  /// Decodes a state produced by [encodeGameState]. For a public state,
  /// [hands] supplies the cards known to the reader (others stay empty).
  static GameState decodeGameState(
    Map m, {
    Map<int, List<Card>> hands = const {},
  }) {
    final rawHands = m['hands'] as List?;
    final a = m['announcement'] as Map?;
    return GameState(
      seed: (m['seed'] as int?) ?? 0,
      dealNumber: m['dealNumber'] as int,
      dealer: m['dealer'] as int,
      phase: GamePhase.values.byName(m['phase'] as String),
      hands: List.unmodifiable([
        for (var i = 0; i < 4; i++)
          List<Card>.unmodifiable(
            rawHands != null ? parseCards(rawHands[i]) : (hands[i] ?? const []),
          ),
      ]),
      stock: List.unmodifiable(parseCards(m['stock'])),
      bids: List.unmodifiable([
        for (final b in (m['bids'] as List? ?? const []))
          SeatBid((b as List)[0] as int, parseBid(b[1] as String)),
      ]),
      currentSeat: m['currentSeat'] as int,
      contract: m['contract'] == null
          ? null
          : parseContract(m['contract'] as Map),
      currentTrick: parseTrick(m['currentTrick'] as Map),
      tricks: List.unmodifiable([
        for (final t in (m['tricks'] as List? ?? const []))
          parseTrick(t as Map),
      ]),
      declarations: List.unmodifiable([
        for (final d in (m['declarations'] as List? ?? const []))
          parseDecl(d as Map),
      ]),
      belots: _ints(m['belots']),
      firstCardPlayed: List.unmodifiable([
        for (final x in (m['firstCardPlayed'] as List)) x as bool,
      ]),
      scores: _ints(m['scores']),
      hanging: m['hanging'] as int,
      history: List.unmodifiable([
        for (final d in (m['history'] as List? ?? const []))
          parseDealScore(d as Map),
      ]),
      lastAnnouncement: a == null
          ? null
          : Announcement(
              seat: a['s'] as int,
              declarations: List.unmodifiable([
                for (final d in (a['d'] as List? ?? const []))
                  parseDecl(d as Map),
              ]),
              belot: a['b'] as bool,
            ),
      winnerTeam: m['winnerTeam'] as int?,
    );
  }

  static List<int> handCounts(Map m) => _ints(m['handCounts']);
}
