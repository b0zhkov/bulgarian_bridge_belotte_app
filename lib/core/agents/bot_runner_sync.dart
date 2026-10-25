import '../rules/rules.dart';
import 'bot_agent.dart';

/// Web: no isolates; a smaller budget keeps frames smooth.
const hardMoveBudget = Duration(milliseconds: 150);

Future<Card> runPlay(BotAgent agent, GameState s, int seat) async {
  // Let the current frame finish first.
  await Future<void>.delayed(Duration.zero);
  return agent.choosePlay(s, seat);
}
