import 'dart:convert';

import 'package:bulgarian_bridge_belotte_app/core/agents/bot_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/agents/bot_names.dart';
import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_screen.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/match_history.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/profile_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/profile_screen.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/stats/stats_controller.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' as app;
import 'fakes.dart';

String text(WidgetTester t, Finder f) => t.widget<Text>(f).data!;

/// Plays the offline match to the end through the controller (the human
/// bids or passes and plays the first legal card).
Future<GameState> playOfflineMatch(WidgetTester t, ProviderContainer c) async {
  var bid = false;
  await t.pumpAndSettle(const Duration(milliseconds: 20));
  for (var i = 0; i < 4000; i++) {
    await t.pump(const Duration(milliseconds: 20));
    final ctrl = c.read(gameControllerProvider.notifier);
    final table = c.read(gameControllerProvider);
    final g = table.game;
    if (g.phase == GamePhase.matchOver) return g;
    if (g.phase == GamePhase.dealScored) {
      ctrl.nextDeal();
      bid = false;
      continue;
    }
    if (!table.isHumanTurn) continue;
    if (g.phase == GamePhase.bidding) {
      final bids = ctrl.humanBids();
      final allTrump = bids.where(
        (b) => b.kind == BidKind.contract && b.type == ContractType.allTrump,
      );
      ctrl.humanBid(!bid && allTrump.isNotEmpty ? allTrump.first : Bid.pass);
      bid = true;
    } else if (g.phase == GamePhase.playing) {
      ctrl.humanPlay(ctrl.humanLegalCards().first);
    }
  }
  final g = c.read(gameControllerProvider);
  fail(
    'match did not finish: ${g.game.phase} deal ${g.game.dealNumber} ${g.game.scores} human ${g.isHumanTurn} holding ${g.holding} locked ${g.locked}',
  );
}

void main() {
  setUp(() {
    app.sound = FakeSoundPlayer();
    DealTiming.scale = 0;
    GameController.botDelay = const Duration(milliseconds: 1);
    GameController.trickPause = const Duration(milliseconds: 1);
    GameController.redealPause = const Duration(milliseconds: 1);
    GameController.fixedSeed = 7;
  });

  test('win streaks: current and best', () {
    var s = const PlayerStats();
    for (final w in [true, true, false, true, true, true, false, true]) {
      s = s.withMatch(won: w);
    }
    expect(s.currentStreak, 1);
    expect(s.bestStreak, 3);
    expect(s.matchesWon, 6);
    expect(PlayerStats.fromJson(s.toJson()).bestStreak, 3);
  });

  test('stats book: offline by difficulty, online, all', () {
    var b = const StatsBook();
    b = b.withMatch(const PlayMode.offline(BotLevel.hard), won: true);
    b = b.withMatch(const PlayMode.offline(BotLevel.easy), won: true);
    b = b.withMatch(const PlayMode.online(), won: false);
    b = b.withMatch(const PlayMode.offline(BotLevel.hard), won: true);
    expect(b.all.matchesPlayed, 4);
    expect(b.all.currentStreak, 1);
    expect(b.all.bestStreak, 2);
    expect(b[StatsBucket.offline].bestStreak, 3);
    expect(b[StatsBucket.offlineHard].matchesWon, 2);
    expect(b[StatsBucket.offlineEasy].matchesPlayed, 1);
    expect(b[StatsBucket.offlineMedium].matchesPlayed, 0);
    expect(b[StatsBucket.online].matchesPlayed, 1);
    expect(b[StatsBucket.online].currentStreak, 0);
    final back = StatsBook.fromJson(
      jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>,
    );
    expect(back.toJson(), b.toJson());
  });

  testWidgets('avatar picker: no robot, choice persists and shows', (t) async {
    final c = await app.pumpApp(t);
    expect(c.read(playerAvatarProvider), kSelfAvatar);
    // The robot can't be set even directly.
    expect(c.read(playerAvatarProvider.notifier).set(kBotAvatar), isFalse);
    expect(sanitizeAvatar(kBotAvatar), isNull);

    await t.tap(find.byKey(const Key('open-profile')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('profile-screen')), findsOneWidget);
    await t.tap(find.byKey(const Key('edit-avatar')));
    await t.pumpAndSettle();
    final picker = find.byKey(const Key('avatar-picker'));
    expect(picker, findsOneWidget);
    final options = find.descendant(
      of: picker,
      matching: find.byWidgetPredicate(
        (w) => w is InkWell && '${w.key}'.contains('avatar-'),
      ),
    );
    expect(options.evaluate().length, kHumanAvatars.length);
    expect(options.evaluate().length, greaterThanOrEqualTo(16));
    for (final e in options.evaluate()) {
      final label = find.descendant(
        of: find.byWidget(e.widget),
        matching: find.byType(Text),
      );
      expect(text(t, label), isNot(kBotAvatar));
    }
    // Only the hint mentions the robot.
    expect(
      find.descendant(of: picker, matching: find.text(kBotAvatar)),
      findsNothing,
    );
    await t.tap(find.byKey(const Key('avatar-3')));
    await t.pumpAndSettle();
    expect(c.read(playerAvatarProvider), kHumanAvatars[3]);
    expect(c.read(sharedPrefsProvider).getString('player_avatar'), '🐸');
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-avatar')),
        matching: find.text('🐸'),
      ),
      findsOneWidget,
    );

    // Name edit from the profile reuses the name form and validation.
    await t.tap(find.byKey(const Key('edit-name')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('name-field')), 'x');
    await t.tap(find.byKey(const Key('name-save')));
    await t.pumpAndSettle();
    expect(c.read(playerNameProvider), 'Георги');
    await t.enterText(find.byKey(const Key('name-field')), 'Жоро');
    await t.tap(find.byKey(const Key('name-save')));
    await t.pumpAndSettle();
    expect(text(t, find.byKey(const Key('profile-name'))), 'Жоро');

    // At the table: my avatar on my strip.
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pumpAndSettle();
    await app.startOffline(t);
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    final table = c.read(gameControllerProvider);
    expect(table.seatInfos, isNull, reason: 'names are applied by the view');
    final view = t.widget<TableView>(find.byType(TableView)).table;
    expect(view.seatInfos![0].emoji, '🐸');
    expect(view.seatInfos![0].name, 'Жоро');
    expect({for (final i in view.seatInfos!.skip(1)) i.emoji}, {kBotAvatar});
    await app.leave(t);
  });

  testWidgets('a stored robot avatar falls back to the default', (t) async {
    final c = await app.pumpApp(
      t,
      prefs: const {'player_name': 'Георги', 'player_avatar': kBotAvatar},
    );
    expect(c.read(playerAvatarProvider), kSelfAvatar);
  });

  testWidgets('offline match lands in history; its sheet reopens', (t) async {
    final c = await app.pumpApp(
      t,
      prefs: const {'player_name': 'Мария', 'bot_level': 'easy'},
    );
    await app.startOffline(t);
    final g = await playOfflineMatch(t, c);
    final history = c.read(matchHistoryProvider);
    expect(history, hasLength(1));
    final r = history.first;
    expect(r.mode.online, isFalse);
    expect(r.mode.level, BotLevel.easy);
    expect(r.won, g.winnerTeam == 0);
    expect(r.scores, g.scores);
    expect(r.deals, hasLength(g.history.length));
    // A human called Мария: the seat-2 bot gets another plain name.
    expect(r.us.first, 'Мария');
    expect([...r.us.skip(1), ...r.them], isNot(contains('Мария')));
    expect({...r.us, ...r.them}, hasLength(4));
    // Stats: all, offline and offline-hard.
    final book = c.read(statsProvider);
    for (final b in [
      StatsBucket.all,
      StatsBucket.offline,
      StatsBucket.offlineEasy,
    ]) {
      expect(book[b].matchesPlayed, 1);
      expect(book[b].dealsPlayed, g.history.length);
    }
    expect(book[StatsBucket.online].matchesPlayed, 0);
    // Persisted and reloadable.
    final raw = c.read(sharedPrefsProvider).getString('match_history_v1')!;
    final back = MatchRecord.fromJson((jsonDecode(raw) as List).first as Map);
    expect(back.scores, r.scores);
    expect(
      [for (final d in back.deals) d.scored],
      [for (final d in g.history) d.scored],
    );

    // Profile → history → the match's score sheet.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
    final c2 = await app.pumpApp(
      t,
      prefs: {
        'player_name': 'Мария',
        'match_history_v1': raw,
        'player_stats_v2': c
            .read(sharedPrefsProvider)
            .getString('player_stats_v2')!,
      },
    );
    expect(c2.read(matchHistoryProvider), hasLength(1));
    await t.tap(find.byKey(const Key('open-stats')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const Key('history-0')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-0')),
        matching: find.text('${g.scores[0]} : ${g.scores[1]}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-0')),
        matching: find.textContaining('Офлайн · Лесно'),
      ),
      findsOneWidget,
    );
    await t.ensureVisible(find.byKey(const Key('history-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('history-0')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('history-sheet')), findsOneWidget);
    expect(text(t, find.byKey(const Key('sheet-total-us'))), '${g.scores[0]}');
    expect(
      text(t, find.byKey(const Key('sheet-total-them'))),
      '${g.scores[1]}',
    );
    expect(find.byKey(const Key('sheet-row-0')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('history-sheet')),
        matching: find.textContaining(formatWhen(r.ended)),
      ),
      findsOneWidget,
    );
  });

  test('history keeps the last 50, newest first', () async {
    // Exercised through the controller with an in-memory prefs instance.
    final c = await app.containerForTest();
    final ctrl = c.read(matchHistoryProvider.notifier);
    final g = BelotEngine.newMatch(seed: 1);
    for (var i = 0; i < 55; i++) {
      ctrl.add(
        MatchRecord.of(
          g.copyWith(scores: [i, 0]),
          mode: const PlayMode.online(),
          room: 'ABCDE',
          us: const ['a', 'b'],
          them: const ['c', 'd'],
        ),
      );
    }
    final h = c.read(matchHistoryProvider);
    expect(h, hasLength(MatchHistoryController.limit));
    expect(h.first.scores, [54, 0]);
    expect(h.last.scores, [5, 0]);
  });
}
