import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';
import 'package:bulgarian_bridge_belotte_app/core/theme/app_theme.dart';
import 'package:bulgarian_bridge_belotte_app/features/feedback/sound.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_screen.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/online_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/quick/quick_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:bulgarian_bridge_belotte_app/main.dart';
import 'package:bulgarian_bridge_belotte_app/online/host_driver.dart';
import 'package:bulgarian_bridge_belotte_app/online/memory_db.dart';
import 'package:bulgarian_bridge_belotte_app/online/quick_match.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/room_screen.dart';
import 'package:bulgarian_bridge_belotte_app/l10n/generated/app_localizations.dart';
import 'package:bulgarian_bridge_belotte_app/online/rating.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Beta 12 UI: unrated notes and the limited rating line.
void main() {
  late MemoryDbServer server;
  late FakeSoundPlayer sound;
  final others = <RoomClient>[];

  setUp(() {
    debugResetInvite();
    debugLaunchUri = () => Uri.parse('http://localhost/');
    sound = FakeSoundPlayer();
    DealTiming.scale = 0;
    server = MemoryDbServer();
    others.clear();
    HostDriver.botDelay = const Duration(milliseconds: 100);
    HostDriver.trickPause = const Duration(milliseconds: 200);
    QuickMatcher.wait = const Duration(seconds: 3);
    QuickMatcher.grace = const Duration(seconds: 2);
    QuickMatcher.joinWait = const Duration(seconds: 1);
    debugQuickCodeGen = () => 'QWERT';
  });

  Future<ProviderContainer> pump(
    WidgetTester t, {
    String uid = 'me',
    Map<String, Object> prefs = const {},
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'player_name': 'Георги',
      'autoplay_enabled': false,
      ...prefs,
    });
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        soundPlayerProvider.overrideWithValue(sound),
        dbConnectorProvider.overrideWithValue(() async => server.client(uid)),
      ],
    );
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(container: container, child: const BelotApp()),
    );
    await t.pump();
    return container;
  }

  Future<void> settle(WidgetTester t, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> finish(WidgetTester t, ProviderContainer c) async {
    await c.read(quickControllerProvider.notifier).cancel();
    await c.read(onlineControllerProvider.notifier).leave();
    for (final o in others) {
      o.detach();
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  }

  testWidgets('quick vs bots: unrated hint while waiting, chip at the table', (
    t,
  ) async {
    final c = await pump(t);
    await t.tap(find.byKey(const Key('play-quick')));
    await settle(t, 6);
    expect(find.byKey(const Key('quick-unrated-hint')), findsOneWidget);
    expect(
      find.text('Ако никой не се включи, играеш срещу ботове — без рейтинг.'),
      findsOneWidget,
    );
    for (var i = 0; i < 30; i++) {
      await settle(t, 2);
      await t.pump(const Duration(milliseconds: 200));
      if (find.byType(TableView).evaluate().isNotEmpty) break;
    }
    expect(find.byType(TableView), findsOneWidget);
    expect(find.byKey(const Key('quick-unrated-chip')), findsOneWidget);
    expect(find.text('Без рейтинг · срещу ботове'), findsOneWidget);
    await finish(t, c);
  });

  Future<void> line(WidgetTester t, RatingOutcome? o, {String lang = 'bg'}) =>
      t.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: Scaffold(body: RatingChangeLine(outcome: o)),
        ),
      );

  testWidgets('rating line: unrated reasons (bg + en)', (t) async {
    await line(t, const RatingOutcome.unrated(UnratedReason.bots));
    expect(find.text('Без рейтинг — игра срещу ботове'), findsOneWidget);
    await line(t, const RatingOutcome.unrated(UnratedReason.short));
    expect(
      find.text('Без рейтинг — мачът продължи под 8 минути'),
      findsOneWidget,
    );
    await line(t, const RatingOutcome.unrated(UnratedReason.bots), lang: 'en');
    await t.pumpAndSettle();
    expect(find.text('Unrated — game against bots'), findsOneWidget);
    expect(find.byKey(const Key('rating-change')), findsNothing);
  });

  testWidgets('rating line: daily limit and repeat opponents', (t) async {
    await line(
      t,
      const RatingOutcome.changed(RatingChange(1092, 8, raw: 16, capped: true)),
    );
    expect(find.text('Рейтинг 1100 (+8) · Сребро'), findsOneWidget);
    expect(find.text('+8 (дневен лимит)'), findsOneWidget);
    await line(
      t,
      const RatingOutcome.changed(RatingChange(1032, 16, raw: 32, nth: 2)),
    );
    expect(
      find.text('+16 вместо +32 (същите съперници, игра №2 за 24 ч → 50%)'),
      findsOneWidget,
    );
    await line(
      t,
      const RatingOutcome.changed(RatingChange(1032, -4, raw: -16, nth: 3)),
      lang: 'en',
    );
    await t.pumpAndSettle();
    expect(
      find.text('−4 instead of −16 (same opponents, game #3 in 24 h → 25%)'),
      findsOneWidget,
    );
    await line(t, const RatingOutcome.changed(RatingChange(1000, 16)));
    expect(find.byKey(const Key('rating-limit')), findsNothing);
  });
}
