import 'package:bulgarian_bridge_belotte_app/core/agents/bot_names.dart';
import 'package:bulgarian_bridge_belotte_app/features/game/labels.dart';
import 'package:bulgarian_bridge_belotte_app/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the robot avatar is reserved for bots', () {
    expect(kHumanAvatars, isNot(contains(kBotAvatar)));
    expect(kHumanAvatars.where(isReservedAvatar), isEmpty);
    expect(isReservedAvatar(kSelfAvatar), isFalse);
    expect(humanAvatar(kBotAvatar), isNot(kBotAvatar));
    expect(humanAvatar('🦁'), '🦁');
  });

  test('bots: plain unique names per seat, always the robot avatar', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      final bots = [for (var s = 0; s < 4; s++) botSeatInfo(l, s)];
      expect(bots.map((b) => b.emoji).toSet(), {kBotAvatar});
      expect(bots.map((b) => b.name).toSet().length, 4);
      for (final b in bots) {
        expect(b.name.toLowerCase(), isNot(contains('бот')));
        expect(b.name.toLowerCase(), isNot(contains('bot')));
      }
    }
    final bg = lookupAppLocalizations(const Locale('bg'));
    // Offline opponents keep the names the app always used.
    expect(
      [for (var s = 1; s < 4; s++) seatInfo(bg, s).name],
      ['Ники', 'Мария', 'Петър'],
    );
    expect(seatInfo(bg, 0, 'Аз').emoji, isNot(kBotAvatar));
  });
}
