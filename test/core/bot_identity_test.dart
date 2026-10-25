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

  test('bot names never match a human in the room (trimmed, any case)', () {
    final bg = lookupAppLocalizations(const Locale('bg'));
    expect(botNames(bg), ['Иван', 'Ники', 'Мария', 'Петър']);
    final names = botNames(bg, ['  мАрИя ', 'Петър']);
    expect(names, hasLength(4));
    expect(names.toSet(), hasLength(4));
    expect(names[0], 'Иван');
    expect(names[1], 'Ники');
    expect(names.map(normalizeName), isNot(contains('мария')));
    expect(names.map(normalizeName), isNot(contains('петър')));
    // Plain names from the pool, never "Бот …".
    for (final n in [...names, ...bg.botNamePool.split(',')]) {
      expect(n.toLowerCase(), isNot(contains('бот')));
      expect(n.trim(), n);
    }
    // Every default taken: still four distinct non-human names.
    final all = botNames(bg, ['Иван', 'ники', 'МАРИЯ', 'Петър', 'Стефан']);
    expect(all.toSet(), hasLength(4));
    expect(
      all.map(normalizeName).toSet().intersection({
        'иван',
        'ники',
        'мария',
        'петър',
        'стефан',
      }),
      isEmpty,
    );
    // Offline: the player's own name is avoided too.
    expect(seatInfo(bg, 2, 'мария').name, isNot('Мария'));
    expect({
      for (var s = 0; s < 4; s++) seatInfo(bg, s, 'Ники').name,
    }, hasLength(4));
    // Every client computes the same names.
    expect(botNames(bg, ['Мария', 'Иван']), botNames(bg, ['Иван', 'Мария']));
  });

  test('the avatar pool: 24 picks, no robot, sanitized input', () {
    expect(kHumanAvatars.toSet(), hasLength(kHumanAvatars.length));
    expect(kHumanAvatars.length, greaterThanOrEqualTo(16));
    expect(sanitizeAvatar('🦊'), '🦊');
    expect(sanitizeAvatar(kBotAvatar), isNull);
    expect(sanitizeAvatar('x'), isNull);
    expect(sanitizeAvatar(5), isNull);
  });
}
