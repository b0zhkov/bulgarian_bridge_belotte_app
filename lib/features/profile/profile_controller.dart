import '../../core/agents/bot_agent.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';

const int kNameMinLength = 2;
const int kNameMaxLength = 16;

/// Returns null when [raw] is a valid player name, otherwise an error code.
NameError? validateName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return NameError.empty;
  if (name.runes.length < kNameMinLength) return NameError.tooShort;
  if (name.runes.length > kNameMaxLength) return NameError.tooLong;
  if (!RegExp(r"^[\p{L}\p{N} ._'\-]+$", unicode: true).hasMatch(name)) {
    return NameError.invalidChars;
  }
  return null;
}

enum NameError { empty, tooShort, tooLong, invalidChars }

/// The local player's name (null until chosen on first launch).
class PlayerNameController extends Notifier<String?> {
  static const _key = 'player_name';

  @override
  String? build() => ref.read(sharedPrefsProvider).getString(_key);

  Future<void> set(String raw) async {
    final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (validateName(name) != null) return;
    state = name;
    await ref.read(sharedPrefsProvider).setString(_key, name);
  }
}

final playerNameProvider = NotifierProvider<PlayerNameController, String?>(
  PlayerNameController.new,
);

/// Whether card hints are enabled (default on).
class HintsController extends Notifier<bool> {
  static const _key = 'hints_enabled';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? true;

  void set(bool v) {
    state = v;
    ref.read(sharedPrefsProvider).setBool(_key, v);
  }
}

final hintsEnabledProvider = NotifierProvider<HintsController, bool>(
  HintsController.new,
);

/// Whether the hinted card is played automatically after 40 s (default on).
class AutoPlayController extends Notifier<bool> {
  static const _key = 'autoplay_enabled';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? true;

  void set(bool v) {
    state = v;
    ref.read(sharedPrefsProvider).setBool(_key, v);
  }
}

final autoPlayEnabledProvider = NotifierProvider<AutoPlayController, bool>(
  AutoPlayController.new,
);

/// Default bot difficulty for offline games (also preselected when a new
/// offline game starts).
class BotLevelController extends Notifier<BotLevel> {
  static const _key = 'bot_level';

  @override
  BotLevel build() =>
      BotLevel.parse(ref.read(sharedPrefsProvider).getString(_key));

  void set(BotLevel v) {
    state = v;
    ref.read(sharedPrefsProvider).setString(_key, v.name);
  }
}

final botLevelProvider = NotifierProvider<BotLevelController, BotLevel>(
  BotLevelController.new,
);
