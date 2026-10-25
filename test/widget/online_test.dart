import 'package:bulgarian_bridge_belotte_app/core/agents/bot_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_screen.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/playing_card.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/online_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/name_screen.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/profile_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:bulgarian_bridge_belotte_app/main.dart';
import 'package:bulgarian_bridge_belotte_app/online/host_driver.dart';
import 'package:bulgarian_bridge_belotte_app/online/memory_db.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_client.dart';
import 'package:bulgarian_bridge_belotte_app/online/room_models.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulgarian_bridge_belotte_app/features/feedback/sound.dart';
import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';

import 'fakes.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Online UI against the in-memory database (no network).
/// Sounds requested by the app under test.
FakeSoundPlayer sound = FakeSoundPlayer();

void main() {
  late MemoryDbServer server;
  final others = <RoomClient>[];

  setUp(() {
    sound = FakeSoundPlayer();
    DealTiming.scale = 0;
    server = MemoryDbServer();
    others.clear();
    HostDriver.botDelay = const Duration(milliseconds: 100);
    HostDriver.trickPause = const Duration(milliseconds: 200);
  });

  Future<ProviderContainer> pumpOnline(
    WidgetTester t, {
    String uid = 'me',
    String name = 'Георги',
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'player_name': name,
      'autoplay_enabled': false,
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

  Future<RoomClient> other(
    WidgetTester t,
    String uid,
    String name, {
    String? code,
    bool create = false,
  }) async {
    late RoomClient c;
    if (create) {
      c = await RoomClient.create(
        server.client(uid),
        name: name,
        codeGen: () => 'HJKMN',
      );
    } else {
      c = await RoomClient.join(server.client(uid), code!, name: name);
    }
    others.add(c);
    await settle(t, 3);
    return c;
  }

  Future<void> finish(WidgetTester t, ProviderContainer container) async {
    await container.read(onlineControllerProvider.notifier).leave();
    for (final c in others) {
      c.detach();
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 100));
  }

  testWidgets('create a room: code, neutral teams, host controls, start', (
    t,
  ) async {
    final container = await pumpOnline(t);
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('create-room')));
    await settle(t);
    expect(find.byKey(const Key('lobby')), findsOneWidget);
    final code = container.read(onlineControllerProvider).client!.code;
    expect(isValidCode(code), isTrue);
    for (final ch in code.split('')) {
      expect(
        find.descendant(
          of: find.byKey(const Key('room-code')),
          matching: find.text(ch),
        ),
        findsWidgets,
      );
    }
    expect(find.text('Отбор 1'), findsOneWidget);
    expect(find.text('Отбор 2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('team-0')),
        matching: find.text('Георги (ти)'),
      ),
      findsOneWidget,
    );

    // A friend joins team 2 with a Cyrillic name.
    final b = await other(t, 'b', 'Иванка', code: code);
    await b.setTeam(1);
    await settle(t);
    expect(
      find.descendant(
        of: find.byKey(const Key('team-1')),
        matching: find.text('Иванка'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('join-team-1')),
      findsOneWidget,
      reason: 'team 2 has a free slot',
    );

    // Host picks the bots' difficulty; everybody sees it.
    await t.ensureVisible(find.byKey(const Key('level-hard')));
    await t.tap(find.byKey(const Key('level-hard')));
    await settle(t, 20);
    expect(b.meta!.botLevel, BotLevel.hard);
    await t.tap(find.byKey(const Key('level-medium')));
    await settle(t, 20);
    expect(b.meta!.botLevel, BotLevel.medium);
    await t.ensureVisible(find.byKey(const Key('add-bots')));
    await t.tap(find.byKey(const Key('add-bots')));
    await settle(t);
    // Lobby bots already use their table names (seats 2 and 3), robot only.
    expect(find.text('Мария'), findsOneWidget);
    expect(find.text('Петър'), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('start-game')));
    await t.tap(find.byKey(const Key('start-game')));
    await settle(t, 20);
    // In game: partner is a bot opposite, Иванка is an opponent, code is shown.
    expect(find.byKey(const Key('room-code-chip')), findsOneWidget);
    expect(find.text(code), findsOneWidget);
    expect(find.text('Иванка'), findsOneWidget);
    expect(b.mySeat, 1);
    expect(find.text('🤖'), findsNWidgets(2));

    // Иванка drops: her seat becomes a plainly named bot with the robot
    // avatar, and a toast tells the table.
    server.disconnect('b');
    await settle(t);
    String notice() =>
        t.widget<Text>(find.byKey(const Key('seat-notice'))).data!;
    expect(notice(), 'Иванка напусна, бот пое мястото');
    // The toast sits between the table and the player's own cards and never
    // covers an avatar.
    final toast = t.getRect(find.byKey(const Key('seat-notice')));
    for (final k in ['seat-1', 'seat-2', 'seat-3']) {
      final r = t.getRect(find.byKey(Key(k)));
      expect(r.overlaps(toast), isFalse, reason: '$k vs toast');
    }
    // (The bidding centre may also name her seat as declarer.)
    expect(
      find.descendant(
        of: find.byKey(const Key('seat-1')),
        matching: find.text('Ники'),
      ),
      findsOneWidget,
    );
    expect(find.text('🤖'), findsNWidgets(3));
    // The name/avatar crossfade out leaves no trace of the human.
    await t.pump(const Duration(milliseconds: 600));
    expect(
      find.descendant(
        of: find.byType(TableView),
        matching: find.text('Иванка'),
      ),
      findsNothing,
    );

    // She comes back within the deal and gets her seat and name back.
    server.reconnect('b');
    await settle(t);
    expect(notice(), 'Иванка се върна');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Ники'), findsNothing);
    expect(find.text('🤖'), findsNWidgets(2));
    // The toast goes away by itself.
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('seat-notice')), findsNothing);
    await finish(t, container);
  });

  testWidgets('join by code, pick team, wait for host', (t) async {
    final host = await other(t, 'h', 'Мария', create: true);
    expect(host.isHost, isTrue);
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('code-field')), 'zzz');
    await t.tap(find.byKey(const Key('join-room')));
    await t.pump();
    expect(find.text('Кодът е от 5 знака'), findsOneWidget);
    await t.enterText(find.byKey(const Key('code-field')), 'QQQQQ');
    await t.tap(find.byKey(const Key('join-room')));
    await settle(t);
    expect(find.byKey(const Key('online-error')), findsOneWidget);
    expect(find.text('Няма стая с този код'), findsOneWidget);
    await t.enterText(find.byKey(const Key('code-field')), 'hjkmn');
    await t.tap(find.byKey(const Key('join-room')));
    await settle(t);
    expect(find.byKey(const Key('lobby')), findsOneWidget);
    expect(find.text('Избери отбор'), findsOneWidget);
    await t.tap(find.byKey(const Key('join-team-1')));
    await settle(t);
    expect(host.members['me']!.team, 1);
    expect(find.text('Чакаме домакина да започне играта…'), findsOneWidget);
    expect(
      find.byKey(const Key('start-game')),
      findsNothing,
      reason: 'only the host starts',
    );
    await finish(t, container);
  });

  testWidgets('joining during a game shows the waiting screen', (t) async {
    final host = await other(t, 'h', 'Мария', create: true);
    final b = await other(t, 'b', 'Иван', code: 'HJKMN');
    await b.setTeam(1);
    await settle(t, 3);
    await host.addBots();
    await settle(t, 3);
    expect(await host.startMatch(), isTrue);
    await settle(t, 3);
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('code-field')), 'HJKMN');
    await t.tap(find.byKey(const Key('join-room')));
    await settle(t);
    expect(find.byKey(const Key('waiting-screen')), findsOneWidget);
    expect(find.text('Играта е в ход'), findsOneWidget);
    await t.tap(find.byKey(const Key('wait-team-0')));
    await settle(t);
    expect(host.members['me']!.team, 0);
    expect(find.byKey(const Key('room-code-chip')), findsOneWidget);
    expect(
      host.game!.phase == GamePhase.bidding ||
          host.game!.phase == GamePhase.playing,
      isTrue,
    );
    await finish(t, container);
  });

  testWidgets('opening #/online without a name asks for the name first', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        soundPlayerProvider.overrideWithValue(sound),
      ],
    );
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(container: container, child: const BelotApp()),
    );
    await t.pump();
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/online');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('create-room')), findsNothing);
    expect(find.byType(NameScreen), findsWidgets);
    await t.enterText(find.byType(TextField).last, 'Гошо');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(container.read(playerNameProvider), 'Гошо');
    expect(find.byKey(const Key('create-room')), findsOneWidget);
  });

  testWidgets('settings has separate hint and auto-play toggles', (t) async {
    final container = await pumpOnline(t);
    await t.tap(find.byKey(const Key('open-settings')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('hints-switch')), findsOneWidget);
    expect(find.byKey(const Key('autoplay-switch')), findsOneWidget);
    expect(container.read(autoPlayEnabledProvider), isFalse);
    await t.ensureVisible(find.byKey(const Key('autoplay-switch')));
    await t.tap(find.byKey(const Key('autoplay-switch')));
    await t.pumpAndSettle();
    expect(container.read(autoPlayEnabledProvider), isTrue);
    expect(container.read(hintsEnabledProvider), isTrue);
    expect(container.read(themeModeProvider), isNotNull);
    // Default bot difficulty.
    expect(container.read(botLevelProvider), BotLevel.medium);
    await t.ensureVisible(find.byKey(const Key('level-easy')));
    await t.tap(find.byKey(const Key('level-easy')));
    await t.pumpAndSettle();
    expect(container.read(botLevelProvider), BotLevel.easy);
  });

  testWidgets('online deal is animated from state; bots wait for it', (
    t,
  ) async {
    DealTiming.scale = 1;
    addTearDown(() => DealTiming.scale = 0);
    HostDriver.botDelay = const Duration(milliseconds: 10);
    final container = await pumpOnline(t);
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('create-room')));
    await settle(t);
    final code = container.read(onlineControllerProvider).client!.code;
    final b = await other(t, 'b', 'Иванка', code: code);
    await b.setTeam(1);
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('add-bots')));
    await t.tap(find.byKey(const Key('add-bots')));
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('start-game')));
    await t.tap(find.byKey(const Key('start-game')));
    await settle(t, 4);
    int backs() => find
        .byWidgetPredicate((w) => w is PlayingCardView && !w.faceUp)
        .evaluate()
        .length;
    expect(backs(), greaterThan(0), reason: 'cards are flying');
    final game = container.read(onlineControllerProvider).table!.game;
    expect(game.bids, isEmpty, reason: 'bots hold during the deal');
    await settle(t, 40);
    expect(backs(), 0);
    expect(sound.played.where((s) => s == Sfx.deal).length, 20);
    await finish(t, container);
  });
}
