/// Bot identity, kept in one place so the scheme is easy to change.
///
/// * Bots are named with plain first names (the same ones the app has
///   always used for computer players), one per absolute seat, so names are
///   unique within a room/match and never equal to a human's name there
///   (then a name from `botNamePool` is used). The localized names are
///   `botName0..3` + `botNamePool` in the ARB files; see `botSeatInfo` in
///   `features/game/labels.dart`.
/// * The robot avatar marks a bot. It is reserved: humans never get it.
library;

/// The avatar shown for every bot. Never assignable to a human.
const kBotAvatar = '🤖';

/// Avatars humans may pick (the first eight are also the fallback for
/// players who never picked one, by seat). Must never contain [kBotAvatar].
const kHumanAvatars = [
  '🦁', '🐯', '🐨', '🐸', '🦊', '🐼', '🐻', '🐵', //
  '🙂', '😎', '🤠', '🥳', '🤓', '😇', '🧐', '😺', //
  '🐰', '🐶', '🦉', '🐧', '🦄', '🐙', '🐢', '🐺',
];

/// The player's own avatar.
const kSelfAvatar = '🙂';

/// A human avatar, falling back to [kSelfAvatar] if [emoji] is reserved
/// (e.g. a future picker or stored value trying to use the robot).
String humanAvatar(String emoji) =>
    isReservedAvatar(emoji) ? kSelfAvatar : emoji;

bool isReservedAvatar(String emoji) => emoji.contains(kBotAvatar);

/// A stored/received avatar: only picker values are accepted (never the
/// robot); anything else is null so callers fall back to a default.
String? sanitizeAvatar(Object? v) =>
    v is String && kHumanAvatars.contains(v) && !isReservedAvatar(v) ? v : null;

/// Names are compared trimmed and case-insensitively.
String normalizeName(String name) => name.trim().toLowerCase();

/// Bot names for the four absolute seats: each seat's usual name
/// ([defaults]) unless a human in the room/match has it (or another seat
/// keeps it), then the next free plain name from [pool]. Deterministic, so
/// every client shows the same names.
List<String> pickBotNames(
  List<String> defaults,
  List<String> pool,
  Iterable<String> humans,
) {
  final taken = {for (final h in humans) normalizeName(h)};
  final out = <String>[];
  for (var s = 0; s < 4; s++) {
    final keep = {for (var k = s + 1; k < 4; k++) normalizeName(defaults[k])};
    String? pick;
    for (final n in [defaults[s], ...pool]) {
      final k = normalizeName(n);
      if (k.isEmpty || taken.contains(k) || keep.contains(k)) continue;
      pick = n.trim();
      break;
    }
    pick ??= '${defaults[s]} ${s + 1}';
    taken.add(normalizeName(pick));
    out.add(pick);
  }
  return out;
}
