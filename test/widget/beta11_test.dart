import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';
import 'package:bulgarian_bridge_belotte_app/core/theme/app_theme.dart';
import 'package:bulgarian_bridge_belotte_app/features/achievements/achievements.dart';
import 'package:bulgarian_bridge_belotte_app/features/feedback/sound.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_screen.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/online_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/room_code.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Beta 11 UI: quick match, rejoin prompt, rating/achievements in the
/// profile, table customisation and the language switch.
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

  testWidgets('quick match: waiting screen, then bots after the timeout', (
    t,
  ) async {
    final c = await pump(t);
    await t.tap(find.byKey(const Key('play-quick')));
    await settle(t, 6);
    expect(find.byKey(const Key('quick-screen')), findsOneWidget);
    expect(find.text('Намерени играчи: 1/4'), findsOneWidget);
    expect(find.text('Търсим играчи…'), findsOneWidget);
    expect(find.byKey(const Key('quick-cancel')), findsOneWidget);
    expect(server.read('queue/me'), isNotNull);
    for (var i = 0; i < 30; i++) {
      await settle(t, 2);
      await t.pump(const Duration(milliseconds: 200));
      if (find.byType(TableView).evaluate().isNotEmpty) break;
    }
    expect(find.byType(TableView), findsOneWidget);
    expect(find.byType(RoomCodeChip), findsNothing, reason: 'no invite UI');
    final client = c.read(onlineControllerProvider).client!;
    expect(client.meta!.quick, isTrue);
    expect(client.seats!.where((s) => s.bot).length, 3);
    expect(server.read('queue/me'), isNull);
    await finish(t, c);
  });

  testWidgets('quick match: cancel leaves the queue', (t) async {
    final c = await pump(t);
    await t.tap(find.byKey(const Key('play-quick')));
    await settle(t, 6);
    expect(server.read('queue/me'), isNotNull);
    await t.tap(find.byKey(const Key('quick-cancel')));
    await settle(t, 6);
    expect(server.read('queue/me'), isNull);
    expect(find.byKey(const Key('play-quick')), findsOneWidget);
    await finish(t, c);
  });

  testWidgets('rejoin prompt on launch takes the reserved seat back', (
    t,
  ) async {
    // Another player hosts; "me" played and dropped out.
    late RoomClient host, mine;
    await t.runAsync(() async {
      host = await RoomClient.create(
        server.client('H'),
        name: 'Иван',
        codeGen: () => 'HJKMN',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      mine = await RoomClient.join(
        server.client('me'),
        'HJKMN',
        name: 'Георги',
      );
    });
    others.add(host);
    await settle(t, 3);
    await t.runAsync(() => mine.setTeam(1));
    await settle(t, 3);
    await t.runAsync(() => host.addBots());
    await settle(t, 3);
    await t.runAsync(() => host.startMatch());
    await settle(t, 3);
    expect(host.seats![1].uid, 'me');
    mine.detach();
    server.disconnect('me');
    await settle(t, 3);
    expect(host.seats![1].heldFor, 'me');
    server.reconnect('me');
    final c = await pump(t, prefs: {'active_room': 'HJKMN'});
    await settle(t, 6);
    expect(find.byKey(const Key('resume-card')), findsOneWidget);
    expect(find.text('Върни се в играта'), findsOneWidget);
    await t.tap(find.byKey(const Key('resume-join')));
    await settle(t, 10);
    expect(find.byType(TableView), findsOneWidget);
    expect(host.seats![1].uid, 'me');
    expect(host.seats![1].bot, isFalse);
    await finish(t, c);
  });

  testWidgets('stale rejoin entry is forgotten', (t) async {
    final c = await pump(t, prefs: {'active_room': 'ZZZZZ'});
    await settle(t, 6);
    expect(find.byKey(const Key('resume-card')), findsNothing);
    expect(c.read(sharedPrefsProvider).getString('active_room'), isNull);
    await finish(t, c);
  });

  testWidgets('profile: rating, rank and achievements (locked/unlocked)', (
    t,
  ) async {
    final c = await pump(
      t,
      prefs: {
        'rating_v1': '{"r":1212,"g":5}',
        'achievements_v1': '{"firstWin":1,"belot":2}',
      },
    );
    Navigator.of(t.element(find.byType(Scaffold).first)).pushNamed('/profile');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('rating-value')), findsOneWidget);
    expect(find.text('1212'), findsOneWidget);
    expect(find.text('Злато'), findsOneWidget);
    await t.scrollUntilVisible(
      find.byKey(const Key('ach-rankGold')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2 от 16'), findsOneWidget);
    expect(find.text('🏆'), findsWidgets);
    expect(find.text('🔒'), findsNWidgets(14));
    await finish(t, c);
  });

  testWidgets('achievement toast is small and silent', (t) async {
    final c = await pump(t);
    await t.pump();
    c.read(achievementsProvider.notifier).unlock({Achievement.capot});
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('achievement-toast')), findsOneWidget);
    expect(find.textContaining('Капо'), findsOneWidget);
    expect(sound.played, isEmpty);
    await t.pump(const Duration(seconds: 4));
    expect(find.byKey(const Key('achievement-toast')), findsNothing);
    // Unlocking again does not toast.
    c.read(achievementsProvider.notifier).unlock({Achievement.capot});
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('achievement-toast')), findsNothing);
    await finish(t, c);
  });

  testWidgets('settings: card back, table colour and language persist', (
    t,
  ) async {
    final c = await pump(t);
    Navigator.of(t.element(find.byType(Scaffold).first)).pushNamed('/settings');
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const Key('table-felt')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const Key('back-midnight')));
    await t.tap(find.byKey(const Key('table-felt')));
    await t.pumpAndSettle();
    final sp = c.read(sharedPrefsProvider);
    expect(sp.getString('card_back'), 'midnight');
    expect(sp.getString('table_tint'), 'felt');
    final ctx = t.element(find.byKey(const Key('table-felt')));
    expect(ctx.colors.backStyle, CardBackStyle.midnight);
    expect(ctx.colors.table, TableTint.felt.dark);
    await t.scrollUntilVisible(
      find.byKey(const Key('lang-en')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const Key('lang-en')));
    await t.pumpAndSettle();
    expect(sp.getString('app_locale'), 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Card back'), findsOneWidget);
    await finish(t, c);
  });

  testWidgets('always starts in Bulgarian regardless of the device', (t) async {
    t.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(t.platformDispatcher.clearLocalesTestValue);
    final c = await pump(t);
    expect(find.text('Бърза игра'), findsOneWidget);
    await finish(t, c);
    final c2 = await pump(t, prefs: {'app_locale': 'en'});
    expect(find.text('Quick match'), findsOneWidget);
    await finish(t, c2);
  });

  testWidgets('English table screen renders', (t) async {
    final c = await pump(t, prefs: {'app_locale': 'en'});
    await t.tap(find.byKey(const Key('play-offline')));
    await t.pumpAndSettle();
    expect(find.text('Play'), findsWidgets);
    await finish(t, c);
  });
}
