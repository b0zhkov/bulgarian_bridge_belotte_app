import 'package:bulgarian_bridge_belotte_app/core/agents/player_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/constants/deal_timing.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/core/theme/app_theme.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/game_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/deal_result_panel.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/score_sheet.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/playing_card.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/widgets/last_trick.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/labels.dart';
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
          if (line.step == ScoreStep.declarations) {
            // One line per declaration, in its owner's column.
            var sum = 0;
            for (var i = 0; i < d.scoringDeclarations.length; i++) {
              sum += int.parse(text(t, 'recap-decl$i-$team'));
            }
            expect(sum, line.points[team]);
          } else if (line.step == ScoreStep.belot) {
            expect(
              find.byKey(Key('recap-belot$team-$team')).evaluate().isEmpty
                  ? 0
                  : int.parse(text(t, 'recap-belot$team-$team')),
              line.points[team],
            );
          } else {
            expect(
              text(t, 'recap-${line.step.name}-$team'),
              '${line.points[team]}',
            );
          }
        }
        expect(find.byKey(const Key('recap-rounding')), findsOneWidget);
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
    // Any tap closes it (unless the next card already did).
    if (find.byKey(const Key('last-trick')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const Key('last-trick')), warnIfMissed: false);
    }
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('last-trick')), findsNothing);

    // The score sheet opens from the button next to the score.
    await t.tap(find.byKey(const Key('score-sheet-button')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('score-sheet')), findsOneWidget);
    expect(find.text('Резултатен лист'), findsOneWidget);
    await app.leave(t);
  });

  test('shownScore holds the last deal until the recap is done', () {
    final g = scoredStates(1).first;
    final d = g.history.last;
    final held = shownScore(g, g.history.length - 1);
    expect(held.scores, [g.scores[0] - d.scored[0], g.scores[1] - d.scored[1]]);
    expect(shownScore(g, g.history.length).scores, g.scores);
    expect(shownScore(g, g.history.length).hanging, g.hanging);
  });

  testWidgets('top score waits for the recap; no emote button offline', (
    t,
  ) async {
    GameController.botDelay = const Duration(milliseconds: 10);
    GameController.trickPause = const Duration(milliseconds: 10);
    final c = await app.pumpApp(t);
    await app.startOffline(t);
    expect(find.byKey(const Key('emote-button')), findsNothing);
    var bidMade = false;
    for (var i = 0; i < 6000; i++) {
      await t.pump(const Duration(milliseconds: 30));
      final table = c.read(gameControllerProvider);
      if (table.game.phase == GamePhase.dealScored) break;
      if (table.game.phase == GamePhase.allPassed) bidMade = false;
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
    expect(g.phase, GamePhase.dealScored);
    final d = g.history.last;
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('recap')), findsOneWidget);
    // Counting: the top score still shows the total before this deal.
    expect(text(t, 'score-us'), '${g.scores[0] - d.scored[0]}');
    expect(text(t, 'score-them'), '${g.scores[1] - d.scored[1]}');
    await t.pump(const Duration(milliseconds: 300));
    expect(text(t, 'score-us'), '${g.scores[0] - d.scored[0]}');
    // Skipping the count-up releases it.
    await t.tap(find.byKey(const Key('recap')));
    await t.pump();
    await t.pump();
    expect(text(t, 'score-us'), '${g.scores[0]}');
    expect(text(t, 'score-them'), '${g.scores[1]}');
    await app.leave(t);
  });

  testWidgets('score sheet: tap a deal for its full breakdown', (t) async {
    t.view.physicalSize = const Size(430, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final l = lookupAppLocalizations(const Locale('bg'));
    var checked = 0;
    for (var seed = 1; seed < 40 && checked < 3; seed++) {
      final g = finishedMatch(seed);
      final i = g.history.indexWhere((d) => d.scoringDeclarations.isNotEmpty);
      if (i < 0) continue;
      final d = g.history[i];
      await t.pumpWidget(
        host(
          SingleChildScrollView(
            child: ScoreSheetTable(
              game: g,
              shrinkWrap: true,
              nameOf: (s) => 'P$s',
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final row = find.byKey(Key('sheet-tap-$i'));
      await t.scrollUntilVisible(
        row,
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await t.pumpAndSettle();
      expect(find.byKey(Key('sheet-details-$i')), findsNothing);
      await t.tap(row);
      await t.pumpAndSettle();
      final details = find.byKey(Key('sheet-details-$i'));
      expect(details, findsOneWidget);
      String cell(String key) => t
          .widget<Text>(
            find.descendant(of: details, matching: find.byKey(Key(key))),
          )
          .data!;
      for (var team = 0; team < 2; team++) {
        expect(cell('detail-raw-$team'), '${d.rawPoints[team]}');
        expect(cell('detail-written-$team'), '${d.writtenForDeal[team]}');
      }
      for (final (k, x) in d.scoringDeclarations.indexed) {
        final team = teamOf(x.seat);
        expect(cell('detail-decl$k-$team'), '${x.points}');
        expect(cell('detail-decl$k-${1 - team}'), '–');
        final label = t.widget<Text>(
          find
              .descendant(
                of: find.byKey(Key('detail-label-decl$k')),
                matching: find.byType(Text),
              )
              .first,
        );
        final plain = label.textSpan!.toPlainText();
        expect(plain, startsWith(declarationName(l, x)));
        expect(
          plain,
          contains(
            x.type == DeclarationType.square
                ? x.cards.first.rank.label
                : 'до ${x.highRank.label}',
          ),
        );
        expect(plain, contains('P${x.seat}'));
      }
      expect(
        cell('detail-rounding'),
        '${l.roundingTitle}: ${roundingText(l, d)}',
      );
      expect(cell('detail-outcome'), outcomeExplain(l, d));
      // Tap again (on the row's header) to fold it.
      await t.ensureVisible(find.byKey(Key('sheet-badge-$i')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key('sheet-badge-$i')));
      await t.pumpAndSettle();
      expect(find.byKey(Key('sheet-details-$i')), findsNothing);
      checked++;
    }
    expect(checked, greaterThan(0));
  });

  testWidgets('score sheet details for контра and вкарана deals', (t) async {
    t.view.physicalSize = const Size(430, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final g = BelotEngine.newMatch(seed: 1);
    final doubled = deal(mult: Multiplier.doubled, scored: const [32, 0]);
    final inside = DealScore(
      contract: const Contract(ContractType.spades, 0, Multiplier.none),
      cardPoints: const [71, 71],
      declarationPoints: const [0, 0],
      belotPoints: const [0, 20],
      lastTrickTeam: 0,
      valatTeam: null,
      rawPoints: const [81, 101],
      outcome: DealOutcome.inside,
      scored: const [0, 18],
      newlyHanging: 0,
      hangingAwarded: 0,
      hangingAwardedTo: null,
      scoringDeclarations: const [],
    );
    final game = g.copyWith(history: [doubled, inside], scores: [32, 18]);
    await t.pumpWidget(host(ScoreSheetTable(game: game, shrinkWrap: true)));
    await t.tap(find.byKey(const Key('sheet-tap-0')));
    await t.pumpAndSettle();
    expect(find.textContaining('Общо 162 → 16 ×2 = 32 за Ние'), findsOneWidget);
    expect(find.textContaining('Контра — по-силният'), findsOneWidget);
    await t.tap(find.byKey(const Key('sheet-tap-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sheet-tap-1')));
    await t.pumpAndSettle();
    expect(find.textContaining('Общо 182 → 18 за Вие'), findsOneWidget);
    expect(text(t, 'detail-belot1-1'), '20');
  });

  testWidgets('last trick hides when the next card is played', (t) async {
    final g = finishedMatch(3);
    final live = ValueNotifier<GameState>(
      g.copyWith(
        phase: GamePhase.playing,
        tricks: g.history.isEmpty ? g.tricks : g.tricks.take(3).toList(),
        currentTrick: const Trick(0),
      ),
    );
    addTearDown(live.dispose);
    final trick = live.value.tricks.last;
    await t.pumpWidget(
      host(
        Builder(
          builder: (context) => Center(
            child: LastTrickButton(
              trick: trick,
              nameOf: (s) => 'P$s',
              live: live,
              contract: live.value.contract?.type ?? ContractType.hearts,
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('last-trick-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('last-trick')), findsOneWidget);
    expect(find.byKey(const Key('last-trick-points')), findsOneWidget);
    expect(
      find.textContaining('Скрива се при следващата карта'),
      findsOneWidget,
    );
    // A new card on the table closes it; the screen under it stays.
    live.value = live.value.copyWith(
      currentTrick: live.value.currentTrick.add(
        Play(0, live.value.tricks.first.plays.first.card),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('last-trick')), findsNothing);
    expect(find.byKey(const Key('last-trick-button')), findsOneWidget);
    // Reopen and close it with a tap.
    await t.tap(find.byKey(const Key('last-trick-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('last-trick')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('last-trick')), findsNothing);
    expect(find.byKey(const Key('last-trick-button')), findsOneWidget);
  });
}
