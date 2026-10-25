import 'package:bulgarian_bridge_belotte_app/core/agents/bot_agent.dart';
import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:bulgarian_bridge_belotte_app/features/achievements/achievements.dart';
import 'package:flutter_test/flutter_test.dart';

DealScore deal({
  ContractType type = ContractType.hearts,
  int declarer = 0,
  Multiplier mult = Multiplier.none,
  DealOutcome outcome = DealOutcome.outside,
  int? valat,
  List<int> scored = const [10, 6],
  List<Declaration> decls = const [],
}) => DealScore(
  contract: Contract(type, declarer, mult),
  cardPoints: const [0, 0],
  declarationPoints: const [0, 0],
  belotPoints: const [0, 0],
  lastTrickTeam: 0,
  valatTeam: valat,
  rawPoints: const [0, 0],
  outcome: outcome,
  scored: scored,
  newlyHanging: 0,
  hangingAwarded: 0,
  hangingAwardedTo: null,
  scoringDeclarations: decls,
);

void main() {
  test('deal achievements', () {
    expect(AchievementRules.forDeal(deal()), isEmpty);
    expect(
      AchievementRules.forDeal(deal(valat: 0)),
      contains(Achievement.capot),
    );
    expect(AchievementRules.forDeal(deal(valat: 1)), isEmpty);
    expect(AchievementRules.forDeal(deal(), belots: [0]), {Achievement.belot});
    expect(AchievementRules.forDeal(deal(), belots: [2]), isEmpty);
    expect(
      AchievementRules.forDeal(
        deal(
          decls: [
            Declaration(DeclarationType.square, [
              for (final s in Suit.values) Card(s, Rank.jack),
            ], 0),
            Declaration(DeclarationType.quint, const [], 0),
          ],
        ),
      ),
      {Achievement.square, Achievement.quint},
    );
    expect(AchievementRules.forDeal(deal(type: ContractType.noTrump)), {
      Achievement.noTrumpMade,
    });
    expect(
      AchievementRules.forDeal(
        deal(type: ContractType.allTrump, outcome: DealOutcome.inside),
      ),
      isEmpty,
    );
    expect(
      AchievementRules.forDeal(
        deal(
          declarer: 1,
          mult: Multiplier.doubled,
          outcome: DealOutcome.inside,
        ),
      ),
      {Achievement.contraWon},
    );
    expect(AchievementRules.forDeal(deal(mult: Multiplier.redoubled)), {
      Achievement.recontraMade,
    });
  });

  test('match achievements', () {
    expect(
      AchievementRules.forMatch(won: false, wins: 0, history: const []),
      isEmpty,
    );
    expect(
      AchievementRules.forMatch(
        won: false,
        wins: 0,
        history: const [],
        quick: true,
      ),
      {Achievement.firstQuick},
    );
    expect(AchievementRules.forMatch(won: true, wins: 10, history: [deal()]), {
      Achievement.firstWin,
      Achievement.wins10,
    });
    expect(
      AchievementRules.forMatch(
        won: true,
        wins: 1,
        history: [deal()],
        offlineLevel: BotLevel.hard,
      ),
      contains(Achievement.beatHard),
    );
    final comeback = [
      deal(scored: [0, 30]),
      deal(scored: [0, 26]),
      deal(scored: [160, 0]),
    ];
    expect(
      AchievementRules.forMatch(won: true, wins: 2, history: comeback),
      contains(Achievement.comeback),
    );
    expect(AchievementRules.forRating(1199), isEmpty);
    expect(AchievementRules.forRating(1200), {Achievement.rankGold});
  });

  test('there are 16 achievements', () {
    expect(Achievement.values.length, 16);
  });
}
