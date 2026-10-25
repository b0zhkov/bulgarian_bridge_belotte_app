import 'dart:isolate';

import '../rules/rules.dart';
import 'bot_agent.dart';

const hardMoveBudget = Duration(milliseconds: 250);

Future<Card> runPlay(BotAgent agent, GameState s, int seat) async {
  try {
    return await Isolate.run(() => agent.choosePlay(s, seat));
  } catch (_) {
    // Isolates unavailable (or the state could not be sent): run inline.
    return agent.choosePlay(s, seat);
  }
}
