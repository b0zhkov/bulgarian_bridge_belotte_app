import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:bulgarian_bridge_belotte_app/main.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpApp(WidgetTester t) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  await t.pumpWidget(UncontrolledProviderScope(container: container, child: const BelotApp()));
  await t.pump();
  return container;
}

void main() {
  setUp(() {
    GameController.botDelay = const Duration(milliseconds: 10);
    GameController.trickPause = const Duration(milliseconds: 10);
    GameController.redealPause = const Duration(milliseconds: 10);
    GameController.fixedSeed = 42;
  });

  testWidgets('home screen shows Bulgarian title and offline mode', (t) async {
    await pumpApp(t);
    expect(find.text('Белот'), findsOneWidget);
    expect(find.text('Офлайн игра'), findsOneWidget);
  });

  testWidgets('theme toggle switches to light and back (dark default)', (t) async {
    final container = await pumpApp(t);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    await t.tap(find.byKey(const Key('open-settings')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('theme-light')));
    await t.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(Theme.of(t.element(find.byKey(const Key('theme-light')))).brightness, Brightness.light);
    await t.tap(find.byKey(const Key('theme-dark')));
    await t.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('a full deal can be played through the UI', (t) async {
    final container = await pumpApp(t);
    await t.tap(find.byKey(const Key('play-offline')));
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    var bidMade = false;
    var cardsPlayed = 0;
    for (var i = 0; i < 2000; i++) {
      await t.pump(const Duration(milliseconds: 30));
      final table = container.read(gameControllerProvider);
      if (find.byKey(const Key('result-continue')).evaluate().isNotEmpty) break;
      if (!table.isHumanTurn) continue;
      if (table.game.phase == GamePhase.bidding) {
        final key = !bidMade && table.game.contract == null ? 'bid-clubs' : 'bid-pass';
        bidMade = true;
        await t.tap(find.byKey(Key(key)));
      } else if (table.game.phase == GamePhase.playing) {
        final card = container.read(gameControllerProvider.notifier).humanLegalCards().first;
        final f = find.byKey(Key('hand-${card.code}'));
        await t.tapAt(t.getTopLeft(f) + const Offset(8, 40));
        cardsPlayed++;
      }
    }
    expect(find.byKey(const Key('result-continue')), findsOneWidget);
    expect(cardsPlayed, 8);
    final g = container.read(gameControllerProvider).game;
    expect(g.history.length, 1);
    await t.tap(find.byKey(const Key('result-continue')));
    await t.pump(const Duration(milliseconds: 50));
    expect(container.read(gameControllerProvider).game.dealNumber, greaterThanOrEqualTo(2));
    // leave cleanly
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 3));
  });
}
