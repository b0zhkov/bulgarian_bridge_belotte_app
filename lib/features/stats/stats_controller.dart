import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

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
  }) => PlayerStats(
    matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    matchesWon: matchesWon ?? this.matchesWon,
    dealsPlayed: dealsPlayed ?? this.dealsPlayed,
    pointsWritten: pointsWritten ?? this.pointsWritten,
    contractsDeclared: contractsDeclared ?? this.contractsDeclared,
    contractsMade: contractsMade ?? this.contractsMade,
    valats: valats ?? this.valats,
  );

  Map<String, dynamic> toJson() => {
    'matchesPlayed': matchesPlayed,
    'matchesWon': matchesWon,
    'dealsPlayed': dealsPlayed,
    'pointsWritten': pointsWritten,
    'contractsDeclared': contractsDeclared,
    'contractsMade': contractsMade,
    'valats': valats,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> j) => PlayerStats(
    matchesPlayed: j['matchesPlayed'] as int? ?? 0,
    matchesWon: j['matchesWon'] as int? ?? 0,
    dealsPlayed: j['dealsPlayed'] as int? ?? 0,
    pointsWritten: j['pointsWritten'] as int? ?? 0,
    contractsDeclared: j['contractsDeclared'] as int? ?? 0,
    contractsMade: j['contractsMade'] as int? ?? 0,
    valats: j['valats'] as int? ?? 0,
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

  PlayerStats withMatch({required bool won}) => copyWith(
    matchesPlayed: matchesPlayed + 1,
    matchesWon: matchesWon + (won ? 1 : 0),
  );
}

class StatsController extends Notifier<PlayerStats> {
  static const _key = 'player_stats_v1';

  @override
  PlayerStats build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const PlayerStats();
    try {
      return PlayerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PlayerStats();
    }
  }

  void _save(PlayerStats s) {
    state = s;
    ref.read(sharedPrefsProvider).setString(_key, jsonEncode(s.toJson()));
  }

  void recordDeal(DealScore d) => _save(state.withDeal(d));
  void recordMatch({required bool won}) => _save(state.withMatch(won: won));
  void reset() => _save(const PlayerStats());
}

final statsProvider = NotifierProvider<StatsController, PlayerStats>(
  StatsController.new,
);
