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

import 'package:bulgarian_bridge_belotte_app/features/emotes/emotes.dart';

import 'package:bulgarian_bridge_belotte_app/core/agents/bot_names.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/match_history.dart';
import 'package:bulgarian_bridge_belotte_app/features/stats/stats_controller.dart';

import 'package:bulgarian_bridge_belotte_app/features/online/invite/web_bridge.dart';
import 'package:bulgarian_bridge_belotte_app/features/online/room_code.dart';
import 'package:flutter/services.dart';

import 'fakes.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Online UI against the in-memory database (no network).
/// Sounds requested by the app under test.
FakeSoundPlayer sound = FakeSoundPlayer();

void main() {
  late MemoryDbServer server;
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
  });

  Future<ProviderContainer> pumpOnline(
    WidgetTester t, {
    String uid = 'me',
    String? name = 'Георги',
    Size size = const Size(390, 844),
    Map<String, Object> prefs = const {},
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'player_name': ?name,
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

  Future<RoomClient> other(
    WidgetTester t,
    String uid,
    String name, {
    String? code,
    bool create = false,
    String? avatar,
  }) async {
    late RoomClient c;
    if (create) {
      c = await RoomClient.create(
        server.client(uid),
        name: name,
        avatar: avatar,
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
    await t.scrollUntilVisible(
      find.byKey(const Key('autoplay-switch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    // Mute others' emotes (persisted) and the animation credit.
    expect(container.read(emotesMutedProvider), isFalse);
    await t.scrollUntilVisible(
      find.byKey(const Key('mute-emotes-switch')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const Key('mute-emotes-switch')));
    await t.pumpAndSettle();
    expect(container.read(emotesMutedProvider), isTrue);
    final sp = container.read(sharedPrefsProvider);
    expect(sp.getBool('emotes_muted'), isTrue);
    expect(find.textContaining('CC BY 4.0'), findsOneWidget);
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
    await settle(t, 10); // page transition, then the deal starts
    int backs() => find
        .byWidgetPredicate((w) => w is PlayingCardView && !w.faceUp)
        .evaluate()
        .length;
    expect(backs(), greaterThan(0), reason: 'cards are flying');
    final game = container.read(onlineControllerProvider).table!.game;
    expect(game.bids, isEmpty, reason: 'bots hold during the deal');
    await settle(t, 40);
    expect(backs(), 0);
    expect(sound.played, isEmpty, reason: 'dealing is silent');
    await finish(t, container);
  });

  testWidgets('score sheet follows the host state live (rotated to my team)', (
    t,
  ) async {
    final h = await other(t, 'h', 'Мария', create: true);
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('code-field')), 'HJKMN');
    await t.tap(find.byKey(const Key('join-room')));
    await settle(t);
    await t.tap(find.byKey(const Key('join-team-1')));
    await settle(t);
    await h.addBots();
    await settle(t, 3);
    expect(await h.startMatch(), isTrue);
    await settle(t, 5);
    expect(find.byType(TableView), findsOneWidget);

    // Open the sheet while the first deal is being played.
    await t.tap(find.byKey(const Key('score-sheet-button')));
    await settle(t, 4);
    expect(find.byKey(const Key('score-sheet')), findsOneWidget);
    expect(find.text('Все още няма изиграни раздавки'), findsOneWidget);

    final ctrl = container.read(onlineControllerProvider.notifier);
    for (var i = 0; i < 1500; i++) {
      await settle(t, 1);
      final g = h.game;
      if (g != null && g.history.isNotEmpty) break;
      // The host player (team 0) bids and plays from its client.
      final seat = h.mySeat;
      if (g != null && seat != null && g.currentSeat == seat && h.handInSync) {
        if (g.phase == GamePhase.bidding) {
          final bids = BelotEngine.validBids(g, seat);
          await h.bid(
            g.contract == null
                ? bids.firstWhere((b) => b.kind == BidKind.contract)
                : Bid.pass,
          );
        } else if (g.phase == GamePhase.playing) {
          await h.play(BelotEngine.getLegalMoves(g, seat).first);
        }
      }
      // And I play through my controller (the sheet stays open).
      final table = container.read(onlineControllerProvider).table;
      if (table != null && table.isHumanTurn) {
        if (table.game.phase == GamePhase.bidding) {
          ctrl.humanBid(Bid.pass);
        } else if (table.game.phase == GamePhase.playing) {
          ctrl.humanPlay(ctrl.humanLegalCards().first);
        }
      }
    }
    await settle(t, 4);
    final hostGame = h.game!;
    expect(hostGame.history, hasLength(1));
    // I sit on team 1, so "Ние" is the host's team 1.
    final d = hostGame.history.first;
    String cell(int pts) => pts == 0 ? '–' : '$pts';
    expect(
      t.widget<Text>(find.byKey(const Key('sheet-us-0'))).data,
      cell(d.scored[1]),
    );
    expect(
      t.widget<Text>(find.byKey(const Key('sheet-them-0'))).data,
      cell(d.scored[0]),
    );
    expect(
      t.widget<Text>(find.byKey(const Key('sheet-total-us'))).data,
      '${hostGame.scores[1]}',
    );
    await finish(t, container);
  });

  testWidgets('emotes pop over the sender\'s seat for everyone; mute', (
    t,
  ) async {
    final h = await other(t, 'h', 'Мария', create: true);
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('code-field')), 'HJKMN');
    await t.tap(find.byKey(const Key('join-room')));
    await settle(t);
    await t.tap(find.byKey(const Key('join-team-1')));
    await settle(t);
    await h.addBots();
    await settle(t, 3);
    expect(await h.startMatch(), isTrue);
    await settle(t, 5);
    expect(find.byType(TableView), findsOneWidget);
    final ctrl = container.read(onlineControllerProvider.notifier);
    final me = ctrl.client!;
    final hostView = (h.mySeat! - me.mySeat!) % 4;
    expect(hostView, isNot(0));

    // Seen by the host: a fresh emote from me arrives over my seat there.
    final hostSaw = <String>[];
    h.onEmote = (uid, id) => hostSaw.add('$uid:$id');

    // I pick 👏 from the picker: it pops over my own spot right away.
    await t.tap(find.byKey(const Key('emote-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emote-picker')), findsOneWidget);
    expect(find.byKey(const Key('pick-bravo')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('emote-picker')),
        matching: find.text('🤖'),
      ),
      findsNothing,
    );
    expect(Emote.values.where((e) => e.emoji == '🤖'), isEmpty);
    await t.tap(find.byKey(const Key('pick-clap')));
    await settle(t, 3);
    expect(find.byKey(const Key('emote-over-0')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('emote-over-0')),
        matching: find.byKey(const Key('emote-clap')),
      ),
      findsOneWidget,
    );
    expect(hostSaw, ['me:clap']);

    // Client-side rate limit: a second one right away is refused.
    expect(ctrl.canEmote, isFalse);
    expect(ctrl.sendEmote(Emote.fire), isFalse);

    // The host's emote shows over the host's avatar on my (rotated) table.
    await h.sendEmote('fire');
    await settle(t, 3);
    expect(
      find.descendant(
        of: find.byKey(Key('emote-over-$hostView')),
        matching: find.byKey(const Key('emote-fire')),
      ),
      findsOneWidget,
    );
    // ...and fades after ~2.5 s.
    await t.pump(const Duration(seconds: 3));
    await settle(t, 2);
    expect(find.byKey(Key('emote-over-$hostView')), findsNothing);
    expect(find.byKey(const Key('emote-over-0')), findsNothing);

    // Muted: others' emotes are not shown, my own still are.
    container.read(emotesMutedProvider.notifier).set(true);
    await h.sendEmote('laugh');
    await settle(t, 3);
    expect(find.byKey(Key('emote-over-$hostView')), findsNothing);
    expect(ctrl.sendEmote(Emote.bravo), isTrue);
    await settle(t, 2);
    expect(find.text('Браво!'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await settle(t, 2);

    // Leaving removes my emote node.
    await finish(t, container);
    expect(await server.client('h').get('rooms/HJKMN/emotes/me'), isNull);
  });

  testWidgets('online: avatars sync, bots avoid human names, match history', (
    t,
  ) async {
    HostDriver.botDelay = const Duration(milliseconds: 5);
    HostDriver.trickPause = const Duration(milliseconds: 5);
    HostDriver.redealPause = const Duration(milliseconds: 5);
    final h = await other(t, 'h', 'ники', create: true, avatar: '🐼');
    final container = await pumpOnline(
      t,
      uid: 'me',
      name: 'Мария',
      prefs: const {'player_avatar': '🦊'},
    );
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('code-field')), 'HJKMN');
    await t.tap(find.byKey(const Key('join-room')));
    await settle(t);
    // Lobby: both picked avatars, synced through the member nodes.
    expect(t.widget<Text>(find.byKey(const Key('lobby-avatar-h'))).data, '🐼');
    expect(h.members['me']!.avatar, '🦊');
    await t.tap(find.byKey(const Key('join-team-1')));
    await settle(t);
    expect(t.widget<Text>(find.byKey(const Key('lobby-avatar-me'))).data, '🦊');
    await h.addBots();
    await settle(t, 3);
    expect(await h.startMatch(), isTrue);
    await settle(t, 5);
    final view = t.widget<TableView>(find.byType(TableView)).table;
    final infos = view.seatInfos!;
    expect(infos[0].emoji, '🦊');
    final hostView =
        (h.mySeat! - container.read(onlineControllerProvider).client!.mySeat!) %
        4;
    expect(infos[hostView].emoji, '🐼');
    expect(infos[hostView].name, 'ники');
    final bots = [
      for (final i in infos)
        if (i.emoji == kBotAvatar) i.name,
    ];
    expect(bots, hasLength(2));
    for (final b in bots) {
      expect(b.toLowerCase(), isNot('мария'));
      expect(b.toLowerCase(), isNot('ники'));
    }

    // Play the whole match (host and I bid/pass and play the first card).
    final ctrl = container.read(onlineControllerProvider.notifier);
    for (var i = 0; i < 30000; i++) {
      await settle(t, 1);
      final g = h.game;
      if (g == null) continue;
      if (g.phase == GamePhase.matchOver) break;
      final seat = h.mySeat;
      if (g.phase == GamePhase.dealScored) {
        await h.markReady();
        ctrl.nextDeal();
        continue;
      }
      if (seat != null && g.currentSeat == seat && h.handInSync) {
        if (g.phase == GamePhase.bidding) {
          final bids = BelotEngine.validBids(g, seat);
          final at = bids.where((b) => b.type == ContractType.allTrump);
          await h.bid(
            g.contract == null && at.isNotEmpty ? at.first : Bid.pass,
          );
        } else if (g.phase == GamePhase.playing) {
          await h.play(BelotEngine.getLegalMoves(g, seat).first);
        }
      }
      final table = container.read(onlineControllerProvider).table;
      if (table != null && table.isHumanTurn) {
        if (table.game.phase == GamePhase.bidding) {
          ctrl.humanBid(Bid.pass);
        } else if (table.game.phase == GamePhase.playing) {
          ctrl.humanPlay(ctrl.humanLegalCards().first);
        }
      }
    }
    await settle(t, 4);
    final end = h.game!;
    expect(end.phase, GamePhase.matchOver);
    final history = container.read(matchHistoryProvider);
    expect(history, hasLength(1));
    final r = history.first;
    expect(r.mode.online, isTrue);
    expect(r.room, 'HJKMN');
    // I sit on team 1 at the host's table: "Ние" is team 1.
    expect(r.scores, [end.scores[1], end.scores[0]]);
    expect(r.won, end.winnerTeam == 1);
    expect(r.deals, hasLength(end.history.length));
    expect(r.us.first, 'Мария');
    expect(r.them, contains('ники'));
    final book = container.read(statsProvider);
    expect(book[StatsBucket.online].matchesPlayed, 1);
    expect(book[StatsBucket.online].dealsPlayed, end.history.length);
    expect(book[StatsBucket.offline].matchesPlayed, 0);
    expect(book.all.matchesPlayed, 1);
    // The same state arriving again does not record twice.
    await settle(t, 6);
    expect(container.read(matchHistoryProvider), hasLength(1));
    await finish(t, container);
  });

  // ------------------------------------------------------------- invites

  Uri invite(String code) => Uri.parse(
    'https://b0zhkov.github.io/bulgarian_bridge_belotte_app/?room=$code',
  );

  testWidgets('invite link on first launch: name, then straight to the lobby', (
    t,
  ) async {
    final host = await other(t, 'h', 'Мария', create: true);
    debugLaunchUri = () => invite('hjkmn');
    final container = await pumpOnline(t, uid: 'me', name: null);
    await t.pumpAndSettle();
    expect(find.byType(NameScreen), findsWidgets);
    await t.enterText(find.byType(TextField).last, 'Гошо');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    await settle(t);
    expect(find.byKey(const Key('lobby')), findsOneWidget);
    expect(host.members['me']!.name, 'Гошо');
    expect(find.text('Избери отбор'), findsOneWidget);
    await finish(t, container);
  });

  testWidgets('invite link into a running game shows the waiting screen', (
    t,
  ) async {
    final host = await other(t, 'h', 'Мария', create: true);
    final b = await other(t, 'b', 'Иван', code: 'HJKMN');
    await b.setTeam(1);
    await settle(t, 3);
    await host.addBots();
    await settle(t, 3);
    expect(await host.startMatch(), isTrue);
    await settle(t, 3);
    debugLaunchUri = () => invite('HJKMN');
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await settle(t);
    expect(find.byKey(const Key('waiting-screen')), findsOneWidget);
    await finish(t, container);
  });

  testWidgets('invite link to a missing room explains it in Bulgarian', (
    t,
  ) async {
    debugLaunchUri = () => invite('QQQQQ');
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await settle(t);
    expect(find.byKey(const Key('invite-failed')), findsOneWidget);
    expect(find.text('Поканата не може да се отвори'), findsOneWidget);
    expect(find.text('Няма стая с този код'), findsOneWidget);
    // The code is filled in and the player can still create a room.
    expect(find.byKey(const Key('create-room')), findsOneWidget);
    await finish(t, container);
  });

  testWidgets('invite link with a broken code', (t) async {
    debugLaunchUri = () => invite('ab');
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await settle(t);
    expect(find.byKey(const Key('invite-failed')), findsOneWidget);
    expect(find.textContaining('Кодът във връзката е грешен'), findsOneWidget);
    await finish(t, container);
  });

  testWidgets('Покани: share sheet, or copy with a toast where there is none', (
    t,
  ) async {
    final shared = <String>[];
    var available = true;
    debugInviteSharer = (title, text, origin) async {
      if (!available) return ShareOutcome.unavailable;
      shared.add(text);
      return ShareOutcome.shared;
    };
    addTearDown(
      () => debugInviteSharer = (a, b, c) async => ShareOutcome.unavailable,
    );
    String? clip;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clip = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = await pumpOnline(t, uid: 'me', name: 'Петър');
    await t.tap(find.byKey(const Key('play-online')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('create-room')));
    await settle(t);
    final code = container.read(onlineControllerProvider).client!.code;
    expect(find.byKey(const Key('invite-button')), findsOneWidget);
    expect(find.text('Покани'), findsOneWidget);
    await t.tap(find.byKey(const Key('invite-button')));
    await t.pump();
    expect(shared, hasLength(1));
    expect(
      shared.single,
      contains(
        'https://b0zhkov.github.io/bulgarian_bridge_belotte_app/?room=$code',
      ),
    );
    expect(find.text('Поканата е копирана'), findsNothing);
    available = false;
    await t.tap(find.byKey(const Key('invite-button')));
    await t.pump();
    await t.pump();
    expect(clip, contains('?room=$code'));
    expect(find.text('Поканата е копирана'), findsWidgets);
    await finish(t, container);
  });

  test('invite codes from links', () {
    expect(inviteCodeFrom(invite('hjkmn')), 'HJKMN');
    expect(inviteCodeFrom(Uri.parse('https://x/?room=%20HJKMN%20')), 'HJKMN');
    expect(inviteCodeFrom(Uri.parse('https://x/')), isNull);
    expect(inviteCodeFrom(Uri.parse('https://x/?room=')), isNull);
    expect(inviteLink('HJKMN'), invite('HJKMN').toString());
  });
}
