import 'package:bulgarian_bridge_belotte_app/features/emotes/emotes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one emote per interval', () {
    final l = EmoteLimiter();
    final t0 = DateTime(2026, 10, 25, 12);
    expect(l.tryUse(t0), isTrue);
    expect(l.canSend(t0.add(const Duration(milliseconds: 500))), isFalse);
    expect(l.tryUse(t0.add(const Duration(milliseconds: 2199))), isFalse);
    // Refused attempts do not extend the wait.
    expect(l.tryUse(t0.add(const Duration(milliseconds: 2200))), isTrue);
    expect(l.tryUse(t0.add(const Duration(milliseconds: 3000))), isFalse);
    expect(l.tryUse(t0.add(const Duration(milliseconds: 4400))), isTrue);
  });

  test('client interval is at least the 2 s the rules enforce', () {
    expect(
      EmoteLimiter().interval,
      greaterThanOrEqualTo(const Duration(seconds: 2)),
    );
  });

  test('ids match the database rules; no robot emoji', () {
    expect(
      Emote.values.map((e) => e.name).join('|'),
      'clap|laugh|wow|huff|thumbs|pray|think|fire|bravo|hayde|oops|gg',
    );
    expect(Emote.values.where((e) => !e.isPhrase), hasLength(8));
    expect(Emote.values.where((e) => e.isPhrase), hasLength(4));
    expect(Emote.values.any((e) => e.emoji == '🤖'), isFalse);
    expect(Emote.parse('robot'), isNull);
    expect(Emote.parse('fire'), Emote.fire);
  });
}
