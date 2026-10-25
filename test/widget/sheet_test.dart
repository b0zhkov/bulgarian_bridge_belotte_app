import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/core/theme/app_theme.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/deal_result_panel.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/score_sheet.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/playing_card.dart';
import 'package:bulgarian_bridge_belotte_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

import '../core/rotation_codec_test.dart' show randomStates;
import 'app_test.dart' as app;
import 'fakes.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: AppTheme.dark(),
  locale: const Locale('bg'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(body: child),
    ),
  ),
);

String text(WidgetTester t, String key) =>
    t.widget<Text>(find.byKey(Key(key))).data!;

/// Scored deals (state right after scoring) from seeded random matches.
List<GameState> scoredStates(int games) {
  final out = <GameState>[];
  GameState? prev;
  for (final s in randomStates(games)) {
    if (prev != null &&
        prev.phase == GamePhase.playing &&
        s.history.length > prev.history.length) {
      out.add(s);
    }
    prev = s;
  }
  return out;
}

DealScore deal({
  ContractType type = ContractType.hearts,
  int declarer = 0,
  Multiplier mult = Multiplier.none,
  required List<int> scored,
  DealOutcome outcome = DealOutcome.outside,
  int? valat,
  int newlyHanging = 0,
  int awarded = 0,
  int? awardedTo,
}) => DealScore(
  contract: Contract(type, declarer, mult),
  cardPoints: const [100, 52],
  declarationPoints: const [0, 0],
  belotPoints: const [0, 0],
  lastTrickTeam: 0,
  valatTeam: valat,
  rawPoints: const [110, 52],
  outcome: outcome,
  scored: scored,
  newlyHanging: newlyHanging,
  hangingAwarded: awarded,
  hangingAwardedTo: awardedTo,
  scoringDeclarations: const [],
);

/// Plays a random match to the end.
GameState finishedMatch(int seed) {
  final agent = RandomAgent(seed);
  var s = BelotEngine.newMatch(seed: seed);
  while (s.phase != GamePhase.matchOver) {
    final seat = s.currentSeat;
    s = switch (s.phase) {
      GamePhase.bidding => BelotEngine.applyBid(
        s,
        seat,
        agent.chooseBid(s, seat),
      ),
      GamePhase.playing => BelotEngine.applyPlay(
        s,
        seat,
        agent.choosePlay(s, seat),
      ),
      _ => BelotEngine.nextDeal(s),
    };
  }
  return s;
}

void main() {
  setUp(() {
    app.sound = FakeSoundPlayer();
    GameController.fixedSeed = 42;
    DealTiming.scale = 0;
  });
  tearDown(() => DealTiming.scale = 1);

  testWidgets('recap numbers equal engine scoring across random deals', (
    t,
  ) async {
    t.view.physicalSize = const Size(430, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final states = scoredStates(40);
    expect(states.length, greaterThan(100));
    var checked = 0;
    for (final s in states.take(120)) {
      final d = s.lastDeal!;
      await t.pumpWidget(
        host(
          DealResultPanel(
            key: UniqueKey(),
            game: s,
            onNext: () {},
            onNewMatch: () {},
            nameOf: (seat) => 'P$seat',
          ),
        ),
      );
      if (s.phase == GamePhase.matchOver) {
        await t.tap(find.byKey(const Key('tab-recap')));
        await t.pump();
      }
      // Counting up: mid-animation the total is not final yet.
      await t.pump(const Duration(milliseconds: 60));
      if (d.rawPoints[0] > 0) {
        expect(int.parse(text(t, 'recap-raw-0')), lessThan(d.rawPoints[0]));
      }
      // Tap skips to the end.
      await t.tap(find.byKey(const Key('recap')));
      await t.pump();
      for (var team = 0; team < 2; team++) {
        for (final line in d.breakdown) {
          expect(
            text(t, 'recap-${line.step.name}-$team'),
            '${line.points[team]}',
          );
        }
        expect(text(t, 'recap-raw-$team'), '${d.rawPoints[team]}');
        expect(text(t, 'recap-written-$team'), '${d.writtenForDeal[team]}');
        if (d.hangingAwarded > 0) {
          expect(
            text(t, 'recap-awarded-$team'),
            '${d.hangingAwardedTo == team ? d.hangingAwarded : 0}',
          );
        }
      }
      checked++;
    }
    expect(checked, greaterThan(100));
  });

  testWidgets('recap: reduced motion shows the final numbers at once', (
    t,
  ) async {
    final s = scoredStates(3).first;
    await t.pumpWidget(
      host(
        DealResultPanel(game: s, onNext: () {}, onNewMatch: () {}),
        reduced: true,
      ),
    );
    await t.pump();
    final d = s.lastDeal!;
    expect(text(t, 'recap-raw-0'), '${d.rawPoints[0]}');
    expect(text(t, 'recap-written-1'), '${d.writtenForDeal[1]}');
  });

  testWidgets('sheet rows, running totals and markers', (t) async {
    t.view.physicalSize = const Size(430, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final base = BelotEngine.newMatch(seed: 1);
    final history = [
      deal(scored: const [11, 5]),
      deal(
        declarer: 1,
        mult: Multiplier.doubled,
        outcome: DealOutcome.inside,
        scored: const [32, 0],
      ),
      deal(outcome: DealOutcome.hanging, scored: const [0, 8], newlyHanging: 8),
      deal(
        type: ContractType.allTrump,
        declarer: 2,
        valat: 0,
        scored: const [52, 0],
        awarded: 8,
        awardedTo: 0,
      ),
    ];
    final g = base.copyWith(history: history, scores: const [95, 13]);
    await t.pumpWidget(host(ScoreSheetTable(game: g)));
    expect(text(t, 'sheet-us-0'), '11');
    expect(text(t, 'sheet-them-0'), '5');
    expect(text(t, 'sheet-them-1'), '–');
    expect(text(t, 'sheet-us-3'), '52');
    expect(text(t, 'sheet-total-us'), '95');
    expect(text(t, 'sheet-total-them'), '13');
    // Running totals under each row.
    expect(
      find.descendant(
        of: find.byKey(const Key('sheet-row-2')),
        matching: find.text('43'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sheet-marks-0')), findsNothing);
    expect(text(t, 'sheet-marks-1'), 'вкарана · контра');
    expect(text(t, 'sheet-marks-2'), 'висяща · 8 висят');
    expect(text(t, 'sheet-marks-3'), 'капо · +8 висящи');
    expect(
      find.descendant(
        of: find.byKey(const Key('sheet-badge-1')),
        matching: find.text('×2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('match end shows the sheet; the recap is one tap away', (
    t,
  ) async {
    t.view.physicalSize = const Size(430, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final over = finishedMatch(3);
    await t.pumpWidget(
      host(DealResultPanel(game: over, onNext: () {}, onNewMatch: () {})),
    );
    await t.pump();
    expect(find.byType(ScoreSheetTable), findsOneWidget);
    expect(text(t, 'sheet-total-us'), '${over.scores[0]}');
    expect(
      find.byKey(Key('sheet-row-${over.history.length - 1}')),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('tab-recap')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('recap')), findsOneWidget);
    expect(text(t, 'recap-raw-0'), '${over.lastDeal!.rawPoints[0]}');
  });

  testWidgets('last trick viewer and score sheet during an offline game', (
    t,
  ) async {
    GameController.botDelay = const Duration(milliseconds: 10);
    GameController.trickPause = const Duration(milliseconds: 10);
    final c = await app.pumpApp(t);
    await app.startOffline(t);
    var bidMade = false;
    for (var i = 0; i < 3000; i++) {
      await t.pump(const Duration(milliseconds: 30));
      final table = c.read(gameControllerProvider);
      if (table.game.phase == GamePhase.playing &&
          table.game.tricks.length >= 2 &&
          !table.holding) {
        break;
      }
      if (!table.isHumanTurn) continue;
      if (table.game.phase == GamePhase.bidding) {
        final key = !bidMade && table.game.contract == null
            ? 'bid-clubs'
            : 'bid-pass';
        if (find.byKey(Key(key)).evaluate().isEmpty) continue;
        bidMade = true;
        await t.tap(find.byKey(Key(key)));
      } else if (table.game.phase == GamePhase.playing) {
        final card = c
            .read(gameControllerProvider.notifier)
            .humanLegalCards()
            .first;
        await t.tap(find.byKey(Key('hand-${card.code}')));
      }
    }
    final g = c.read(gameControllerProvider).game;
    expect(g.tricks.length, greaterThanOrEqualTo(2));
    final last = g.tricks.last;
    await t.tap(find.byKey(const Key('last-trick-button')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('last-trick')), findsOneWidget);
    for (final p in last.plays) {
      final v = t.widget<PlayingCardView>(
        find.byKey(Key('last-trick-${p.seat}')),
      );
      expect(v.card, p.card);
      expect(v.highlighted, p.seat == last.winner);
    }
    expect(text(t, 'last-trick-winner'), startsWith('Взе: '));
    // Any tap closes it.
    await t.tapAt(const Offset(20, 20));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('last-trick')), findsNothing);

    // The score sheet opens from the button next to the score.
    await t.tap(find.byKey(const Key('score-sheet-button')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('score-sheet')), findsOneWidget);
    expect(find.text('Резултатен лист'), findsOneWidget);
    await app.leave(t);
  });
}
