import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/bot_agent.dart';
import '../../core/rules/rules.dart';
import '../settings/settings_controller.dart';
import '../stats/stats_controller.dart';

/// One finished match, from the local player's point of view (team 0 =
/// "Ние"). Kept locally with its per-deal rows so the score sheet can be
/// reopened later.
class MatchRecord {
  const MatchRecord({
    required this.endedAt,
    required this.mode,
    this.room,
    required this.us,
    required this.them,
    required this.scores,
    required this.won,
    required this.deals,
    this.hanging = 0,
  });

  /// When the match ended (UTC millis).
  final int endedAt;
  final PlayMode mode;

  /// Online room code.
  final String? room;

  /// [me, partner] and the two opponents' names.
  final List<String> us;
  final List<String> them;
  final List<int> scores;
  final bool won;
  final List<DealScore> deals;
  final int hanging;

  DateTime get ended => DateTime.fromMillisecondsSinceEpoch(endedAt);

  /// A game state carrying just what the score sheet reads.
  GameState get sheetState => BelotEngine.newMatch(seed: 0).copyWith(
    phase: GamePhase.matchOver,
    scores: scores,
    hanging: hanging,
    history: deals,
  );

  /// Deals without declaration cards (the sheet does not need them).
  static Map<String, Object?> _deal(DealScore d) =>
      StateCodec.dealScore(d)..remove('decls');

  Map<String, Object?> toJson() => {
    't': endedAt,
    'm': mode.online ? 'online' : mode.level!.name,
    'r': ?room,
    'us': us,
    'them': them,
    's': scores,
    'w': won,
    'h': hanging,
    'd': [for (final d in deals) _deal(d)],
  };

  static MatchRecord fromJson(Map m) {
    final mode = m['m'] == 'online'
        ? const PlayMode.online()
        : PlayMode.offline(BotLevel.parse(m['m'] as String?));
    List<String> names(Object? v) => [for (final x in v as List) '$x'];
    return MatchRecord(
      endedAt: m['t'] as int,
      mode: mode,
      room: m['r'] as String?,
      us: names(m['us']),
      them: names(m['them']),
      scores: [for (final x in m['s'] as List) x as int],
      won: m['w'] == true,
      hanging: m['h'] as int? ?? 0,
      deals: [
        for (final d in m['d'] as List? ?? const [])
          StateCodec.parseDealScore(d as Map),
      ],
    );
  }

  /// A record for [g] (a finished match, team 0 = mine).
  static MatchRecord of(
    GameState g, {
    required PlayMode mode,
    String? room,
    required List<String> us,
    required List<String> them,
  }) => MatchRecord(
    endedAt: clock.now().millisecondsSinceEpoch,
    mode: mode,
    room: room,
    us: us,
    them: them,
    scores: List.of(g.scores),
    won: g.winnerTeam == 0,
    hanging: g.hanging,
    deals: List.of(g.history),
  );
}

/// The last [limit] matches, newest first, stored as one JSON string in
/// shared preferences (decoded once, written on each finished match).
class MatchHistoryController extends Notifier<List<MatchRecord>> {
  static const _key = 'match_history_v1';
  static const limit = 50;

  @override
  List<MatchRecord> build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return List.unmodifiable([
        for (final m in jsonDecode(raw) as List) MatchRecord.fromJson(m as Map),
      ]);
    } catch (_) {
      return const [];
    }
  }

  void add(MatchRecord r) {
    final next = List<MatchRecord>.unmodifiable([r, ...state].take(limit));
    state = next;
    ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode([for (final m in next) m.toJson()]));
  }

  void clear() {
    state = const [];
    ref.read(sharedPrefsProvider).remove(_key);
  }
}

final matchHistoryProvider =
    NotifierProvider<MatchHistoryController, List<MatchRecord>>(
      MatchHistoryController.new,
    );
