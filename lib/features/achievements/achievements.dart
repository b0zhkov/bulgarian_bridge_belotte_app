import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/bot_agent.dart';
import '../../core/rules/rules.dart';
import '../../online/db.dart';
import '../../online/rating.dart';
import '../settings/settings_controller.dart';

/// Achievements (16). Checked locally after every deal and match, so they
/// also unlock offline; synced to `ach/{uid}` when online.
enum Achievement {
  firstWin('🏆'),
  wins10('🔟'),
  wins50('🎖️'),
  wins100('👑'),
  capot('💯'),
  belot('💍'),
  square('🟪'),
  quint('🖐️'),
  noTrumpMade('🚫'),
  allTrumpMade('⭐'),
  contraWon('✋'),
  recontraMade('✌️'),
  comeback('🔄'),
  beatHard('🤖'),
  firstQuick('⚡'),
  rankGold('🥇');

  const Achievement(this.icon);
  final String icon;

  static Achievement? parse(String id) =>
      values.where((a) => a.name == id).firstOrNull;
}

/// Pure unlock rules. All states are seen from the player (seat 0 = me,
/// team 0 = my team).
class AchievementRules {
  const AchievementRules._();

  /// How far behind (match points) a winning team must have been for
  /// [Achievement.comeback].
  static const comebackGap = 50;

  /// After a scored deal. [belots] are the seats that announced a belot in
  /// that deal (null when unknown, e.g. joined late).
  static Set<Achievement> forDeal(DealScore d, {List<int>? belots}) {
    final out = <Achievement>{};
    final c = d.contract;
    final ours = c.declarerTeam == 0;
    final made = d.outcome == DealOutcome.outside;
    if (d.valatTeam == 0) out.add(Achievement.capot);
    if (belots != null && belots.contains(0)) out.add(Achievement.belot);
    for (final x in d.scoringDeclarations) {
      if (x.seat != 0) continue;
      if (x.type == DeclarationType.square) out.add(Achievement.square);
      if (x.type == DeclarationType.quint) out.add(Achievement.quint);
    }
    if (ours && made && c.type == ContractType.noTrump) {
      out.add(Achievement.noTrumpMade);
    }
    if (ours && made && c.type == ContractType.allTrump) {
      out.add(Achievement.allTrumpMade);
    }
    if (!ours &&
        c.multiplier != Multiplier.none &&
        d.outcome == DealOutcome.inside) {
      out.add(Achievement.contraWon);
    }
    if (ours && made && c.multiplier == Multiplier.redoubled) {
      out.add(Achievement.recontraMade);
    }
    return out;
  }

  /// After a finished match. [history] is the match's deals (team 0 =
  /// mine), [wins] the total matches won including this one.
  static Set<Achievement> forMatch({
    required bool won,
    required int wins,
    required List<DealScore> history,
    BotLevel? offlineLevel,
    bool quick = false,
  }) {
    final out = <Achievement>{};
    if (quick) out.add(Achievement.firstQuick);
    if (!won) return out;
    if (wins >= 1) out.add(Achievement.firstWin);
    if (wins >= 10) out.add(Achievement.wins10);
    if (wins >= 50) out.add(Achievement.wins50);
    if (wins >= 100) out.add(Achievement.wins100);
    if (offlineLevel == BotLevel.hard) out.add(Achievement.beatHard);
    var us = 0, them = 0, worst = 0;
    for (final d in history) {
      us += d.scored[0];
      them += d.scored[1];
      if (us - them < worst) worst = us - them;
    }
    if (-worst >= comebackGap) out.add(Achievement.comeback);
    return out;
  }

  static Set<Achievement> forRating(int rating) => {
    if (rating >= RatingRank.gold.min) Achievement.rankGold,
  };
}

/// Unlocked achievements (id → unlock time, ms) persisted locally.
class AchievementsController extends Notifier<Map<Achievement, int>> {
  static const _key = 'achievements_v1';

  /// The latest unlock, shown as a small toast (no sound).
  final StreamController<Achievement> _unlocks = StreamController.broadcast();
  Stream<Achievement> get unlocks => _unlocks.stream;

  @override
  Map<Achievement, int> build() {
    ref.onDispose(_unlocks.close);
    try {
      final raw = ref.read(sharedPrefsProvider).getString(_key);
      if (raw != null) return _decode(jsonDecode(raw));
    } catch (_) {}
    return const {};
  }

  static Map<Achievement, int> _decode(Object? v) => {
    if (v is Map)
      for (final e in v.entries)
        if (Achievement.parse(e.key as String) != null && e.value is num)
          Achievement.parse(e.key as String)!: (e.value as num).toInt(),
  };

  void _save(Map<Achievement, int> m) {
    state = Map.unmodifiable(m);
    ref
        .read(sharedPrefsProvider)
        .setString(
          _key,
          jsonEncode({for (final e in m.entries) e.key.name: e.value}),
        );
  }

  /// Unlocks [a]; returns the ones that are new (each also toasts).
  Set<Achievement> unlock(Iterable<Achievement> a) {
    final fresh = a.where((x) => !state.containsKey(x)).toSet();
    if (fresh.isEmpty) return fresh;
    final now = DateTime.now().millisecondsSinceEpoch;
    _save({...state, for (final x in fresh) x: now});
    for (final x in Achievement.values) {
      if (fresh.contains(x)) _unlocks.add(x);
    }
    _pending?.call();
    return fresh;
  }

  void Function()? _pending;

  /// Merges `ach/{uid}` with the local list (union, earliest time wins) and
  /// writes back what the server is missing. Keeps syncing new unlocks
  /// while [db] stays connected.
  Future<void> sync(Db db) async {
    final path = 'ach/${db.uid}';
    Future<void> push() async {
      try {
        final remote = _decode(await db.get(path));
        final merged = {...remote};
        for (final e in state.entries) {
          final r = merged[e.key];
          if (r == null || e.value < r) merged[e.key] = e.value;
        }
        final missing = {
          for (final e in merged.entries)
            if (remote[e.key] != e.value) '$path/${e.key.name}': e.value,
        };
        if (missing.isNotEmpty) await db.update(missing);
        if (merged.length != state.length ||
            merged.entries.any((e) => state[e.key] != e.value)) {
          _save(merged);
        }
      } catch (_) {}
    }

    _pending = () => push();
    await push();
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsController, Map<Achievement, int>>(
      AchievementsController.new,
    );
