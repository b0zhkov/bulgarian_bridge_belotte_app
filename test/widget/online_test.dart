import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/online_controller.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

/// Online UI against the in-memory database (no network).
void main() {
  late MemoryDbServer server;
  final others = <RoomClient>[];

  setUp(() {
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

    await t.ensureVisible(find.byKey(const Key('add-bots')));
    await t.tap(find.byKey(const Key('add-bots')));
    await settle(t);
    expect(find.text('Бот'), findsNWidgets(2));
    await t.ensureVisible(find.byKey(const Key('start-game')));
    await t.tap(find.byKey(const Key('start-game')));
    await settle(t, 20);
    // In game: partner is a bot opposite, Иванка is an opponent, code is shown.
    expect(find.byKey(const Key('room-code-chip')), findsOneWidget);
    expect(find.text(code), findsOneWidget);
    expect(find.text('Иванка'), findsOneWidget);
    expect(b.mySeat, 1);
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
  });
}
