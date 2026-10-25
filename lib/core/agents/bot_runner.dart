import '../rules/rules.dart';
import 'bot_agent.dart';
import 'bot_runner_sync.dart' if (dart.library.io) 'bot_runner_io.dart' as impl;

/// Time budget for a Hard move: on native the sampling runs in a background
/// isolate; on the web (single thread) it runs on the event loop with a
/// smaller budget so animations stay fluent.
Duration get hardMoveBudget => impl.hardMoveBudget;

/// The bot's card for [seat], computed off the UI thread when the platform
/// supports isolates (Hard only; Easy/Medium take a few milliseconds).
Future<Card> chooseBotPlay(BotAgent agent, GameState s, int seat) {
  if (agent.level != BotLevel.hard) {
    return Future.value(agent.choosePlay(s, seat));
  }
  final timed = BotAgent(
    agent.level,
    seed: agent.seed,
    budget: hardMoveBudget,
    maxWorlds: agent.maxWorlds,
  );
  return impl.runPlay(timed, s, seat);
}
