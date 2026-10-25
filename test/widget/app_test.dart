import 'package:bulgarian_bridge_belotte_app/core/agents/bot_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/profile_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/stats/stats_controller.dart';
import 'package:bulgarian_bridge_belotte_app/main.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/trick_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester t, {
  Map<String, Object> prefs = const {'player_name': 'Георги'},
  Size size = const Size(390, 844),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({'autoplay_enabled': false, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(sp)],
  );
  addTearDown(container.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(container: container, child: const BelotApp()),
  );
  await t.pump();
  return container;
}

Future<void> leave(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 45));
}

void main() {
  setUp(() {
    GameController.botDelay = const Duration(milliseconds: 10);
    GameController.trickPause = const Duration(milliseconds: 10);
    GameController.redealPause = const Duration(milliseconds: 10);
    GameController.hintDelay = const Duration(seconds: 25);
    GameController.fixedSeed = 42;
  });

  group('name prompt', () {
    testWidgets('shown on first launch, validates and persists the name', (
      t,
    ) async {
      final container = await pumpApp(t, prefs: const {});
      expect(find.byKey(const Key('name-title')), findsOneWidget);
      expect(find.text('Как да те наричаме?'), findsOneWidget);

      await t.tap(find.byKey(const Key('name-save')));
      await t.pump();
      expect(find.text('Въведи име'), findsOneWidget);

      await t.enterText(find.byKey(const Key('name-field')), 'А');
      await t.tap(find.byKey(const Key('name-save')));
      await t.pump();
      expect(find.text('Поне 2 символа'), findsOneWidget);

      await t.enterText(find.byKey(const Key('name-field')), 'Гошо<3');
      await t.tap(find.byKey(const Key('name-save')));
      await t.pump();
      expect(find.textContaining('Само букви'), findsOneWidget);

      await t.enterText(
        find.byKey(const Key('name-field')),
        'Много дълго име за игра',
      );
      final field = t.widget<TextField>(find.byKey(const Key('name-field')));
      expect(field.controller!.text.length, kNameMaxLength);

      await t.enterText(find.byKey(const Key('name-field')), '  Георги  ');
      await t.tap(find.byKey(const Key('name-save')));
      await t.pumpAndSettle();
      expect(container.read(playerNameProvider), 'Георги');
      expect(
        container.read(sharedPrefsProvider).getString('player_name'),
        'Георги',
      );
      expect(find.byKey(const Key('greeting')), findsOneWidget);
      expect(find.text('Здравей, Георги'), findsOneWidget);
    });

    testWidgets('not shown when a name is stored; can be changed in settings', (
      t,
    ) async {
      final container = await pumpApp(t);
      expect(find.byKey(const Key('name-title')), findsNothing);
      await t.tap(find.byKey(const Key('open-settings')));
      await t.pumpAndSettle();
      expect(find.text('Георги'), findsOneWidget);
      await t.tap(find.byKey(const Key('change-name')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('name-field')), 'Жоро');
      await t.tap(find.byKey(const Key('name-save')));
      await t.pumpAndSettle();
      expect(container.read(playerNameProvider), 'Жоро');
      expect(find.byKey(const Key('settings-name')), findsOneWidget);
      expect(find.text('Жоро'), findsOneWidget);
    });
  });

  group('validateName', () {
    test('rules', () {
      expect(validateName(''), NameError.empty);
      expect(validateName('   '), NameError.empty);
      expect(validateName('Я'), NameError.tooShort);
      expect(validateName('x' * 17), NameError.tooLong);
      expect(validateName('Ники<script>'), NameError.invalidChars);
      expect(validateName('Иван Петров'), isNull);
      expect(validateName('b0zhigol'), isNull);
      expect(validateName("D'Artagnan-2"), isNull);
    });
  });

  group('stats', () {
    testWidgets('home card and stats screen show persisted stats', (t) async {
      final stored = const PlayerStats(
        matchesPlayed: 4,
        matchesWon: 3,
        dealsPlayed: 37,
        pointsWritten: 370,
        contractsDeclared: 10,
        contractsMade: 7,
        valats: 1,
      );
      await pumpApp(
        t,
        prefs: {'player_name': 'Георги', 'player_stats_v1': _json(stored)},
      );
      expect(find.text('Статистика'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      await t.tap(find.byKey(const Key('open-stats')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('stats-screen')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-matches')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-wins')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-winrate')),
          matching: find.text('75%'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-deals')),
          matching: find.text('37'),
        ),
        findsOneWidget,
      );
      expect(find.text('10.0'), findsOneWidget); // avg points per deal
      expect(find.text('7/10'), findsOneWidget);
    });

    test('PlayerStats records deals and matches', () {
      var s = const PlayerStats();
      final d = scoreDeal(
        contract: const Contract(ContractType.spades, 0),
        tricks: [
          for (var i = 0; i < 8; i++)
            Trick(0, [
              for (var k = 0; k < 4; k++) Play(k, fullDeck[i * 4 + k]),
            ], i < 6 ? 0 : 1),
        ],
        declarations: const [],
        belots: const [],
      );
      s = s.withDeal(d);
      expect(s.dealsPlayed, 1);
      expect(s.pointsWritten, d.scored[0]);
      expect(s.contractsDeclared, 1);
      s = s.withMatch(won: true).withMatch(won: false);
      expect(s.matchesPlayed, 2);
      expect(s.matchesWon, 1);
      expect(s.winRate, 0.5);
      expect(PlayerStats.fromJson(s.toJson()).toJson(), s.toJson());
    });
  });

  testWidgets('theme toggle switches to light and back (dark default)', (
    t,
  ) async {
    final container = await pumpApp(t);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await t.tap(find.byKey(const Key('open-settings')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('theme-light')));
    await t.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    await t.tap(find.byKey(const Key('theme-dark')));
    await t.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('offline start: pick bot difficulty, bots use it', (t) async {
    final container = await pumpApp(t);
    await t.tap(find.byKey(const Key('play-offline')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('offline-sheet')), findsOneWidget);
    expect(find.text('Средно'), findsOneWidget);
    await t.tap(find.byKey(const Key('level-easy')));
    await t.pumpAndSettle();
    expect(container.read(botLevelProvider), BotLevel.easy);
    expect(find.text('Играят простичко и понякога грешат'), findsOneWidget);
    await t.tap(find.byKey(const Key('start-offline')));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('seat-1')), findsOneWidget);
    await leave(t);
  });

  testWidgets('table shows partner opposite and opponents on the sides', (
    t,
  ) async {
    await pumpApp(t);
    await startOffline(t);
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    final top = t.getCenter(find.byKey(const Key('seat-2')));
    final left = t.getCenter(find.byKey(const Key('seat-3')));
    final right = t.getCenter(find.byKey(const Key('seat-1')));
    expect(top.dy, lessThan(left.dy));
    expect(left.dx, lessThan(top.dx));
    expect(right.dx, greaterThan(top.dx));
    expect(find.text('Партньор'), findsNothing);
    expect(find.text('Противник'), findsNothing);
    await leave(t);
  });

  testWidgets('a full deal can be played through the UI and stats update', (
    t,
  ) async {
    final container = await pumpApp(t);
    await startOffline(t);
    await t.pump(const Duration(milliseconds: 50));
    var bidMade = false;
    var cardsPlayed = 0;
    for (var i = 0; i < 3000; i++) {
      await t.pump(const Duration(milliseconds: 30));
      final table = container.read(gameControllerProvider);
      if (find.byKey(const Key('result-continue')).evaluate().isNotEmpty) break;
      if (!table.isHumanTurn) continue;
      if (table.game.phase == GamePhase.bidding) {
        final key = !bidMade && table.game.contract == null
            ? 'bid-clubs'
            : 'bid-pass';
        bidMade = true;
        await t.tap(find.byKey(Key(key)));
      } else if (table.game.phase == GamePhase.playing) {
        final card = container
            .read(gameControllerProvider.notifier)
            .humanLegalCards()
            .first;
        final f = find.byKey(Key('hand-${card.code}'));
        await t.tapAt(t.getTopLeft(f) + const Offset(8, 40));
        cardsPlayed++;
      }
    }
    expect(find.byKey(const Key('result-continue')), findsOneWidget);
    expect(cardsPlayed, 8);
    expect(container.read(statsProvider).dealsPlayed, 1);
    await t.tap(find.byKey(const Key('result-continue')));
    await t.pump(const Duration(milliseconds: 50));
    expect(
      container.read(gameControllerProvider).game.dealNumber,
      greaterThanOrEqualTo(2),
    );
    await leave(t);
  });

  Future<ProviderContainer> toHumanPlayTurn(
    WidgetTester t, {
    Map<String, Object>? prefs,
  }) async {
    final container = await pumpApp(
      t,
      prefs: prefs ?? const {'player_name': 'Георги'},
    );
    await startOffline(t);
    await t.pump(const Duration(milliseconds: 50));
    var bidMade = false;
    for (var i = 0; i < 3000; i++) {
      await t.pump(const Duration(milliseconds: 30));
      final table = container.read(gameControllerProvider);
      if (!table.isHumanTurn) continue;
      if (table.game.phase == GamePhase.playing) break;
      if (table.game.phase == GamePhase.bidding) {
        final key = !bidMade && table.game.contract == null
            ? 'bid-clubs'
            : 'bid-pass';
        bidMade = true;
        await t.tap(find.byKey(Key(key)));
      }
    }
    expect(container.read(gameControllerProvider).isHumanTurn, isTrue);
    return container;
  }

  testWidgets('hint appears after 25 s on the human turn and is legal', (
    t,
  ) async {
    final container = await toHumanPlayTurn(t);
    await t.pump(const Duration(seconds: 24));
    expect(container.read(gameControllerProvider).hint, isNull);
    await t.pump(const Duration(seconds: 2));
    final table = container.read(gameControllerProvider);
    expect(table.hint, isNotNull);
    expect(
      container.read(gameControllerProvider.notifier).humanLegalCards(),
      contains(table.hint),
    );
    expect(find.textContaining('Подсказка'), findsOneWidget);
    // playing clears the hint
    final f = find.byKey(Key('hand-${table.hint!.code}'));
    await t.tapAt(t.getTopLeft(f) + const Offset(8, 40));
    await t.pump();
    expect(container.read(gameControllerProvider).hint, isNull);
    await leave(t);
  });

  testWidgets('auto-play plays the hinted card after 40 s', (t) async {
    final container = await toHumanPlayTurn(
      t,
      prefs: const {'player_name': 'Георги', 'autoplay_enabled': true},
    );
    final before = container.read(gameControllerProvider).game.hands[0].length;
    await t.pump(const Duration(seconds: 26));
    final hint = container.read(gameControllerProvider).hint;
    expect(hint, isNotNull);
    await t.pump(const Duration(seconds: 13));
    expect(container.read(gameControllerProvider).game.hands[0].length, before);
    await t.pump(const Duration(seconds: 2));
    final g = container.read(gameControllerProvider).game;
    expect(g.hands[0].length, before - 1);
    expect(g.hands[0], isNot(contains(hint)));
    container.read(autoPlayEnabledProvider.notifier).set(false);
    await leave(t);
  });

  testWidgets('auto-play off: nothing is played for the human', (t) async {
    final container = await toHumanPlayTurn(t);
    final before = container.read(gameControllerProvider).game.hands[0].length;
    await t.pump(const Duration(seconds: 60));
    expect(container.read(gameControllerProvider).game.hands[0].length, before);
    await leave(t);
  });

  testWidgets('no hint when hints are disabled', (t) async {
    final container = await toHumanPlayTurn(
      t,
      prefs: const {'player_name': 'Георги', 'hints_enabled': false},
    );
    await t.pump(const Duration(seconds: 45));
    expect(container.read(gameControllerProvider).hint, isNull);
    await leave(t);
  });

  group('responsive layout (no overflow)', () {
    for (final size in const [
      Size(360, 780),
      Size(430, 932),
      Size(1280, 800),
    ]) {
      testWidgets(
        'home, settings, stats, table at ${size.width.toInt()}x${size.height.toInt()}',
        (t) async {
          await pumpApp(t, size: size, prefs: const {});
          expect(t.takeException(), isNull); // name prompt
          await t.enterText(find.byKey(const Key('name-field')), 'Александра');
          await t.tap(find.byKey(const Key('name-save')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.tap(find.byKey(const Key('open-stats')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.tap(find.byIcon(Icons.arrow_back_rounded));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('open-settings')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.tap(find.byIcon(Icons.arrow_back_rounded));
          await t.pumpAndSettle();
          await startOffline(t);
          for (var i = 0; i < 200; i++) {
            await t.pump(const Duration(milliseconds: 40));
          }
          expect(t.takeException(), isNull);
          await leave(t);
        },
      );
    }
  });

  group('cards are straight and aligned', () {
    setUp(() {
      // Hold the finished trick long enough to inspect it.
      GameController.trickPause = const Duration(milliseconds: 1100);
      GameController.botDelay = const Duration(milliseconds: 50);
    });
    for (final size in const [
      Size(360, 780),
      Size(430, 932),
      Size(1280, 800),
    ]) {
      testWidgets(
        'trick cross and hand at ${size.width.toInt()}x${size.height.toInt()}',
        (t) async {
          final container = await pumpApp(t, size: size);
          await startOffline(t);
          await t.pump(const Duration(milliseconds: 50));
          var bidMade = false;
          var checkedFull = false;
          var checkedHand = false;
          for (var i = 0; i < 3000 && !(checkedFull && checkedHand); i++) {
            await t.pump(const Duration(milliseconds: 30));
            final table = container.read(gameControllerProvider);
            if (table.game.phase == GamePhase.bidding && table.isHumanTurn) {
              await t.tap(
                find.byKey(
                  Key(
                    !bidMade && table.game.contract == null
                        ? 'bid-clubs'
                        : 'bid-pass',
                  ),
                ),
              );
              bidMade = true;
              continue;
            }
            if (table.game.phase != GamePhase.playing) continue;
            if (table.isHumanTurn && !checkedHand) {
              await t.pump(const Duration(milliseconds: 400));
              final tops = <double>{
                for (final c in table.game.hands[0])
                  t.getTopLeft(find.byKey(Key('hand-${c.code}'))).dy,
              };
              expect(tops.length, 1, reason: 'hand cards share one baseline');
              checkedHand = true;
            }
            if (table.holding &&
                table.visibleTrick.plays.length == 4 &&
                !checkedFull) {
              // Let the last card finish flying in (320 ms) while the trick is held.
              await t.pump(const Duration(milliseconds: 350));
              final r = [
                for (var s = 0; s < 4; s++)
                  t.getRect(find.byKey(Key('trick-$s'))),
              ];
              expect(
                find.descendant(
                  of: find.byType(TrickArea),
                  matching: find.byType(Transform),
                ),
                findsNothing,
              );
              expect(r[0].center.dx, r[2].center.dx);
              expect(r[1].center.dy, r[3].center.dy);
              expect(
                (r[1].center.dx + r[3].center.dx) / 2,
                closeTo(r[0].center.dx, 0.51),
              );
              expect(
                (r[0].center.dy + r[2].center.dy) / 2,
                closeTo(r[1].center.dy, 0.51),
              );
              for (final x in r) {
                expect(x.left, x.left.roundToDouble());
                expect(x.top, x.top.roundToDouble());
                expect(x.size, r[0].size);
              }
              checkedFull = true;
            }
            if (table.isHumanTurn) {
              final card = container
                  .read(gameControllerProvider.notifier)
                  .humanLegalCards()
                  .first;
              await t.tapAt(
                t.getTopLeft(find.byKey(Key('hand-${card.code}'))) +
                    const Offset(8, 40),
              );
            }
          }
          expect(
            (
              checkedFull,
              checkedHand,
              container.read(gameControllerProvider).game.phase,
            ),
            (true, true, GamePhase.playing),
          );
          expect(t.takeException(), isNull);
          await leave(t);
        },
      );
    }
  });
}

String _json(PlayerStats s) =>
    '{${s.toJson().entries.map((e) => '"${e.key}":${e.value}').join(',')}}';

/// Home → offline card → difficulty sheet → Играй.
Future<void> startOffline(WidgetTester t) async {
  await t.tap(find.byKey(const Key('play-offline')));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('start-offline')));
}
