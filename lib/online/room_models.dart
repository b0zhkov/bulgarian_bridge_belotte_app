import '../core/agents/bot_names.dart';
import '../core/agents/bot_agent.dart';

import 'dart:convert';
import 'dart:math';

/// Room code alphabet without look-alikes (no 0/O, 1/I/L).
const kCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const kCodeLength = 5;

String generateRoomCode([Random? rnd]) {
  final r = rnd ?? Random.secure();
  return List.generate(
    kCodeLength,
    (_) => kCodeAlphabet[r.nextInt(kCodeAlphabet.length)],
  ).join();
}

/// Upper-cases and drops characters outside the alphabet.
String normalizeCode(String raw) => raw
    .toUpperCase()
    .replaceAll('O', '0')
    .split('')
    .where(kCodeAlphabet.contains)
    .join();

bool isValidCode(String code) =>
    code.length == kCodeLength && code.split('').every(kCodeAlphabet.contains);

/// A player in the room (`rooms/{code}/members/{uid}`), written by the
/// player themselves (team) and the host (team normalisation).
class Member {
  const Member({
    required this.uid,
    required this.name,
    required this.joinedAt,
    this.team,
    this.teamAt = 0,
    this.online = true,
    this.avatar,
  });

  final String uid;
  final String name;

  /// The avatar the player picked (never the robot); null = seat default.
  final String? avatar;
  final int joinedAt;

  /// 0 or 1; null when the player has not picked a team.
  final int? team;

  /// When the team was picked (used to resolve races for the last slot).
  final int teamAt;
  final bool online;

  static Member fromMap(String uid, Map m) => Member(
    uid: uid,
    name: (m['n'] as String?) ?? '?',
    joinedAt: (m['j'] as num?)?.toInt() ?? 0,
    team: switch ((m['t'] as num?)?.toInt()) {
      0 => 0,
      1 => 1,
      _ => null,
    },
    teamAt: (m['ta'] as num?)?.toInt() ?? 0,
    online: m['o'] == true,
    avatar: sanitizeAvatar(m['a']),
  );

  static Map<String, Member> parseAll(Object? v) {
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        if (e.value is Map)
          e.key as String: fromMap(e.key as String, e.value as Map),
    };
  }

  Member copyWith({int? team, bool clearTeam = false, bool? online}) => Member(
    uid: uid,
    name: name,
    joinedAt: joinedAt,
    team: clearTeam ? null : (team ?? this.team),
    teamAt: teamAt,
    online: online ?? this.online,
  );
}

/// One of the four seats during a match. Seats 0/2 are team 0, 1/3 team 1.
class Seat {
  const Seat.human(String this.uid, this.name)
    : bot = false,
      heldFor = null,
      heldDeal = null;
  const Seat.bot({this.name, this.heldFor, this.heldDeal})
    : uid = null,
      bot = true;

  final String? uid;

  /// Human's name; for a bot holding a seat, the absent player's name.
  final String? name;
  final bool bot;

  /// For a bot that took over a disconnected player: whose seat it holds
  /// and in which deal (the player may reclaim it within that deal).
  final String? heldFor;
  final int? heldDeal;

  Map<String, Object?> toJson() => {
    'u': uid,
    'n': name,
    'b': bot,
    'h': heldFor,
    'd': heldDeal,
  };

  static Seat fromJson(Map m) => m['b'] == true
      ? Seat.bot(
          name: m['n'] as String?,
          heldFor: m['h'] as String?,
          heldDeal: (m['d'] as num?)?.toInt(),
        )
      : Seat.human(m['u'] as String, (m['n'] as String?) ?? '?');

  static String encodeAll(List<Seat> seats) =>
      jsonEncode([for (final s in seats) s.toJson()]);

  static List<Seat>? decodeAll(Object? v) {
    if (v is! String) return null;
    final l = jsonDecode(v) as List;
    return [for (final m in l) Seat.fromJson(m as Map)];
  }

  @override
  bool operator ==(Object other) =>
      other is Seat &&
      other.uid == uid &&
      other.name == name &&
      other.bot == bot &&
      other.heldFor == heldFor &&
      other.heldDeal == heldDeal;

  @override
  int get hashCode => Object.hash(uid, name, bot, heldFor, heldDeal);

  @override
  String toString() => bot ? 'Bot(${heldFor ?? ''})' : 'Human($uid)';
}

enum RoomStatus { lobby, playing }

/// `rooms/{code}/meta`, readable by any signed-in user so a joiner can
/// check the room before becoming a member.
class RoomMeta {
  const RoomMeta({
    required this.host,
    required this.status,
    this.bots = const [0, 0],
    this.onlineCount = 0,
    this.matchNo = 0,
    this.botLevel = BotLevel.medium,
    this.quick = false,
    this.createdAt = 0,
    this.startedAt,
    this.unrated,
  });

  /// Server time the current match started (`meta/st`).
  final int? startedAt;

  /// `"{matchId}:{reason}"` when the host marked a quick match unrated.
  final String? unrated;

  /// A quick-match room (public matchmaking, no invite UI, rated).
  final bool quick;

  /// Server time the room was created (ms).
  final int createdAt;

  /// Identifies the current match of this room (for rating results).
  String get matchId => 'm${matchNo}_$createdAt';

  final String host;

  /// Difficulty of the bots in this room (chosen by the host).
  final BotLevel botLevel;
  final RoomStatus status;

  /// Bots added in the lobby per team.
  final List<int> bots;
  final int onlineCount;
  final int matchNo;

  static RoomMeta? fromMap(Object? v) {
    if (v is! Map || v['host'] is! String) return null;
    final b = v['bots'];
    return RoomMeta(
      host: v['host'] as String,
      status: v['status'] == 'playing' ? RoomStatus.playing : RoomStatus.lobby,
      bots: b is List
          ? [
              for (var i = 0; i < 2; i++)
                i < b.length ? ((b[i] as num?)?.toInt() ?? 0) : 0,
            ]
          : b is Map
          ? [
              ((b['0'] ?? b[0]) as num?)?.toInt() ?? 0,
              ((b['1'] ?? b[1]) as num?)?.toInt() ?? 0,
            ]
          : const [0, 0],
      onlineCount: (v['onlineCount'] as num?)?.toInt() ?? 0,
      matchNo: (v['matchNo'] as num?)?.toInt() ?? 0,
      botLevel: BotLevel.parse(v['lvl'] as String?),
      quick: v['qm'] == true,
      createdAt: (v['createdAt'] as num?)?.toInt() ?? 0,
      startedAt: (v['st'] as num?)?.toInt(),
      unrated: v['ur'] as String?,
    );
  }
}

/// A player's action request (`rooms/{code}/intents/{uid}`).
class Intent {
  const Intent({
    required this.nonce,
    required this.kind,
    this.version = 0,
    this.value,
  });
  final int nonce;

  /// 'bid', 'play' or 'ready'.
  final String kind;

  /// Public state version the action was chosen on (bid/play), or the
  /// deal number for 'ready'.
  final int version;
  final String? value;

  Map<String, Object?> toMap() => {
    'n': nonce,
    'k': kind,
    'v': version,
    'x': value,
  };

  static Intent? fromMap(Object? v) {
    if (v is! Map || v['n'] is! num || v['k'] is! String) return null;
    return Intent(
      nonce: (v['n'] as num).toInt(),
      kind: v['k'] as String,
      version: (v['v'] as num?)?.toInt() ?? 0,
      value: v['x'] as String?,
    );
  }
}
