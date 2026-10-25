import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/feedback/sound.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/playing_card.dart';
import 'package:bulgarian_bridge_belotte_app/features/profile/profile_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' as app;
import 'fakes.dart';

/// Hand cards currently shown face up for the player.
int handShown() => find
    .byWidgetPredicate((w) {
      return w is GestureDetector &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('hand-');
    })
    .evaluate()
    .length;

/// Card backs flying in the dealing overlay.
int backsFlying() => find
    .byWidgetPredicate((w) => w is PlayingCardView && !w.faceUp)
    .evaluate()
    .length;

/// Plays one whole deal through the UI (taps only when input is accepted).
Future<void> playDeal(WidgetTester t, ProviderContainer c) async {
  var bidMade = false;
  var plays = 0;
  for (var i = 0; i < 4000; i++) {
    await t.pump(const Duration(milliseconds: 30));
    if (find.byKey(const Key('result-continue')).evaluate().isNotEmpty) break;
    final table = c.read(gameControllerProvider);
    if (!table.isHumanTurn) continue;
    if (table.game.phase == GamePhase.bidding) {
      final before = table.game.bids.length;
      final key = !bidMade && table.game.contract == null
          ? 'bid-clubs'
          : 'bid-pass';
      if (find.byKey(Key(key)).evaluate().isEmpty) continue;
      await t.tap(find.byKey(Key(key)), warnIfMissed: false);
      await t.pump();
      if (c.read(gameControllerProvider).game.bids.length > before) {
        bidMade = true;
      }
    } else if (table.game.phase == GamePhase.playing) {
      final card = c
          .read(gameControllerProvider.notifier)
          .humanLegalCards()
          .first;
      final f = find.byKey(Key('hand-${card.code}'));
      if (f.evaluate().isEmpty) continue;
      final swooshes = app.sound.played.where((s) => s == Sfx.swoosh).length;
      await t.tapAt(t.getTopLeft(f) + const Offset(8, 40));
      await t.pump();
      if (!c.read(gameControllerProvider).game.hands[0].contains(card)) {
        plays++;
        // The swoosh starts on the frame the card starts flying.
        if (c.read(soundEnabledProvider)) {
          expect(
            app.sound.played.where((s) => s == Sfx.swoosh).length,
            swooshes + 1,
          );
        }
      }
    }
  }
  expect(find.byKey(const Key('result-continue')), findsOneWidget);
  expect(plays, 8);
}

void main() {
  setUp(() {
    app.sound = FakeSoundPlayer();
    DealTiming.scale = 1;
    GameController.botDelay = const Duration(milliseconds: 10);
    GameController.trickPause = const Duration(milliseconds: 300);
    GameController.redealPause = const Duration(milliseconds: 10);
    GameController.hintDelay = const Duration(seconds: 25);
    GameController.fixedSeed = 42;
  });
  tearDown(() => DealTiming.scale = 1);

  test('deal order: counter-clockwise from the dealer, 3 + 2, then 3', () {
    expect(DealTiming.order(0, const [3, 2]), [
      1, 1, 1, 2, 2, 2, 3, 3, 3, 0, 0, 0, //
      1, 1, 2, 2, 3, 3, 0, 0,
    ]);
    expect(DealTiming.order(2, const [3]), [
      3,
      3,
      3,
      0,
      0,
      0,
      1,
      1,
      1,
      2,
      2,
      2,
    ]);
    expect(DealTiming.total(20), const Duration(milliseconds: 70 * 19 + 300));
  });

  testWidgets('animated deal completes; hand fans in; input waits for it', (
    t,
  ) async {
    final c = await app.pumpApp(t);
    await app.startOffline(t);
    // The deal starts once the page transition is over, then advances
    // frame by frame.
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(backsFlying(), greaterThan(0));
    expect(handShown(), lessThan(5));
    // Bots wait for the animation: nobody has bid yet.
    expect(c.read(gameControllerProvider).game.bids, isEmpty);
    for (var i = 0; i < 120; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(backsFlying(), 0);
    expect(handShown(), 5);
    // Dealing is silent now (only card plays swoosh).
    expect(app.sound.played, isEmpty);

    await playDeal(t, c);
    await t.pump(const Duration(seconds: 1));
    final played = app.sound.played;
    // One swoosh per played card (all four seats), then the result.
    expect(played.where((s) => s == Sfx.swoosh).length, 32);
    expect(played.last, anyOf(Sfx.dealMade, Sfx.dealFailed));
    expect(played.toSet(), {Sfx.swoosh, played.last});
    expect(t.takeException(), isNull);
    await app.leave(t);
  });

  testWidgets('sound off: silent, and the game stays playable', (t) async {
    final c = await app.pumpApp(
      t,
      prefs: const {'player_name': 'Георги', 'sound_enabled': false},
    );
    await app.startOffline(t);
    await playDeal(t, c);
    expect(app.sound.played, isEmpty);
    await app.leave(t);
  });

  testWidgets('reduced motion skips the deal animation', (t) async {
    final c = await app.pumpApp(t);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await app.startOffline(t);
    await t.pumpAndSettle();
    expect(backsFlying(), 0);
    expect(handShown(), 5);
    await playDeal(t, c);
    await app.leave(t);
  });

  testWidgets('sound and haptics toggles persist', (t) async {
    final c = await app.pumpApp(t);
    expect(c.read(soundEnabledProvider), isTrue);
    expect(c.read(hapticsEnabledProvider), isTrue);
    Navigator.of(t.element(find.byType(Scaffold).first)).pushNamed('/settings');
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const Key('sound-switch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const Key('sound-switch')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('haptics-switch')));
    await t.tap(find.byKey(const Key('haptics-switch')));
    await t.pumpAndSettle();
    expect(c.read(soundEnabledProvider), isFalse);
    expect(c.read(hapticsEnabledProvider), isFalse);
    final sp = await SharedPreferences.getInstance();
    expect(sp.getBool('sound_enabled'), isFalse);
    expect(sp.getBool('haptics_enabled'), isFalse);
    // A fresh app reads them back.
    final c2 = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(sp)],
    );
    addTearDown(c2.dispose);
    expect(c2.read(soundEnabledProvider), isFalse);
    expect(c2.read(hapticsEnabledProvider), isFalse);
  });
}
