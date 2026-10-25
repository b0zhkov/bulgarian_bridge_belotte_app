/// Bot identity, kept in one place so the scheme is easy to change.
///
/// * Bots are named with plain first names (the same ones the app has
///   always used for computer players), one per absolute seat, so names are
///   unique within a room/match. The localized names are `botName0..3` in
///   the ARB files; see `botSeatInfo` in `features/game/labels.dart`.
/// * The robot avatar marks a bot. It is reserved: humans never get it.
library;

/// The avatar shown for every bot. Never assignable to a human.
const kBotAvatar = '🤖';

/// Avatars humans may get (seat-based today; the pool for a future avatar
/// picker). Must never contain [kBotAvatar].
const kHumanAvatars = ['🦁', '🐯', '🐨', '🐸', '🦊', '🐼', '🐻', '🐵'];

/// The player's own avatar.
const kSelfAvatar = '🙂';

/// A human avatar, falling back to [kSelfAvatar] if [emoji] is reserved
/// (e.g. a future picker or stored value trying to use the robot).
String humanAvatar(String emoji) =>
    isReservedAvatar(emoji) ? kSelfAvatar : emoji;

bool isReservedAvatar(String emoji) => emoji.contains(kBotAvatar);
