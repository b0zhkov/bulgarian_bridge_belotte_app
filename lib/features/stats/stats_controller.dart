import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/bot_agent.dart';
import '../../core/rules/rules.dart';
import '../settings/settings_controller.dart';

/// Lifetime performance of the local player (team 0), stored locally.
class PlayerStats {
  const PlayerStats({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.dealsPlayed = 0,
    this.pointsWritten = 0,
    this.contractsDeclared = 0,
    this.contractsMade = 0,
    this.valats = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  /// Matches won in a row (now) and the longest such run.
  final int currentStreak;
  final int bestStreak;

  final int matchesPlayed;
  final int matchesWon;
  final int dealsPlayed;

  /// Match points written for our team across all deals.
  final int pointsWritten;

  /// Deals where our team set the contract, and how many were made (outside).
  final int contractsDeclared;
  final int contractsMade;
  final int valats;

  double get winRate => matchesPlayed == 0 ? 0 : matchesWon / matchesPlayed;
  double get avgPointsPerDeal =>
      dealsPlayed == 0 ? 0 : pointsWritten / dealsPlayed;
  double get contractSuccess =>
      contractsDeclared == 0 ? 0 : contractsMade / contractsDeclared;

  PlayerStats copyWith({
    int? matchesPlayed,
    int? matchesWon,
    int? dealsPlayed,
    int? pointsWritten,
    int? contractsDeclared,
    int? contractsMade,
    int? valats,
    int? currentStreak,
    int? bestStreak,
  }) => PlayerStats(
    matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    matchesWon: matchesWon ?? this.matchesWon,
    dealsPlayed: dealsPlayed ?? this.dealsPlayed,
    pointsWritten: pointsWritten ?? this.pointsWritten,
    contractsDeclared: contractsDeclared ?? this.contractsDeclared,
    contractsMade: contractsMade ?? this.contractsMade,
    valats: valats ?? this.valats,
    currentStreak: currentStreak ?? this.currentStreak,
    bestStreak: bestStreak ?? this.bestStreak,
  );

  Map<String, dynamic> toJson() => {
    'matchesPlayed': matchesPlayed,
    'matchesWon': matchesWon,
    'dealsPlayed': dealsPlayed,
    'pointsWritten': pointsWritten,
    'contractsDeclared': contractsDeclared,
    'contractsMade': contractsMade,
    'valats': valats,
    'streak': currentStreak,
    'best': bestStreak,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> j) => PlayerStats(
    matchesPlayed: j['matchesPlayed'] as int? ?? 0,
    matchesWon: j['matchesWon'] as int? ?? 0,
    dealsPlayed: j['dealsPlayed'] as int? ?? 0,
    pointsWritten: j['pointsWritten'] as int? ?? 0,
    contractsDeclared: j['contractsDeclared'] as int? ?? 0,
    contractsMade: j['contractsMade'] as int? ?? 0,
    valats: j['valats'] as int? ?? 0,
    currentStreak: j['streak'] as int? ?? 0,
    bestStreak: j['best'] as int? ?? 0,
  );

  /// Stats after a scored deal for team [team].
  PlayerStats withDeal(DealScore d, {int team = 0}) {
    final declared = d.contract.declarerTeam == team;
    final made = declared && d.outcome == DealOutcome.outside;
    return copyWith(
      dealsPlayed: dealsPlayed + 1,
      pointsWritten: pointsWritten + d.scored[team],
      contractsDeclared: contractsDeclared + (declared ? 1 : 0),
      contractsMade: contractsMade + (made ? 1 : 0),
      valats: valats + (d.valatTeam == team ? 1 : 0),
    );
  }

  PlayerStats withMatch({required bool won}) {
    final streak = won ? currentStreak + 1 : 0;
    return copyWith(
      matchesPlayed: matchesPlayed + 1,
      matchesWon: matchesWon + (won ? 1 : 0),
      currentStreak: streak,
      bestStreak: streak > bestStreak ? streak : bestStreak,
    );
  }
}

/// Where a match was played: offline against bots of a [level], or online.
class PlayMode {
  const PlayMode.offline(BotLevel this.level) : online = false;
  const PlayMode.online() : online = true, level = null;
  final bool online;
  final BotLevel? level;

  /// Stats buckets this mode counts towards.
  List<StatsBucket> get buckets => online
      ? const [StatsBucket.all, StatsBucket.online]
      : [StatsBucket.all, StatsBucket.offline, StatsBucket.forLevel(level!)];
}

/// Stats are kept per bucket (all, offline, offline per difficulty, online)
/// so streaks stay exact for each split.
enum StatsBucket {
  all,
  offline,
  offlineEasy,
  offlineMedium,
  offlineHard,
  online;

  static StatsBucket forLevel(BotLevel l) => switch (l) {
    BotLevel.easy => offlineEasy,
    BotLevel.medium => offlineMedium,
    BotLevel.hard => offlineHard,
  };
}

class StatsBook {
  const StatsBook([this.buckets = const {}]);
  final Map<StatsBucket, PlayerStats> buckets;

  PlayerStats operator [](StatsBucket b) => buckets[b] ?? const PlayerStats();
  PlayerStats get all => this[StatsBucket.all];

  StatsBook _update(PlayMode mode, PlayerStats Function(PlayerStats s) f) =>
      StatsBook({...buckets, for (final b in mode.buckets) b: f(this[b])});

  StatsBook withDeal(DealScore d, PlayMode mode) =>
      _update(mode, (s) => s.withDeal(d));
  StatsBook withMatch(PlayMode mode, {required bool won}) =>
      _update(mode, (s) => s.withMatch(won: won));

  Map<String, dynamic> toJson() => {
    for (final e in buckets.entries) e.key.name: e.value.toJson(),
  };

  factory StatsBook.fromJson(Map<String, dynamic> j) => StatsBook({
    for (final b in StatsBucket.values)
      if (j[b.name] is Map)
        b: PlayerStats.fromJson((j[b.name] as Map).cast<String, dynamic>()),
  });
}

class StatsController extends Notifier<StatsBook> {
  static const _key = 'player_stats_v2';

  /// Beta 1–7 kept one offline-only record; it becomes "all" + "offline".
  static const _legacyKey = 'player_stats_v1';

  @override
  StatsBook build() {
    final prefs = ref.read(sharedPrefsProvider);
    try {
      final raw = prefs.getString(_key);
      if (raw != null) {
        return StatsBook.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null) {
        final s = PlayerStats.fromJson(
          jsonDecode(legacy) as Map<String, dynamic>,
        );
        return StatsBook({StatsBucket.all: s, StatsBucket.offline: s});
      }
    } catch (_) {}
    return const StatsBook();
  }

  void _save(StatsBook s) {
    state = s;
    ref.read(sharedPrefsProvider).setString(_key, jsonEncode(s.toJson()));
  }

  void recordDeal(DealScore d, PlayMode mode) => _save(state.withDeal(d, mode));
  void recordMatch(PlayMode mode, {required bool won}) =>
      _save(state.withMatch(mode, won: won));
  void reset() => _save(const StatsBook());
}

final statsProvider = NotifierProvider<StatsController, StatsBook>(
  StatsController.new,
);
