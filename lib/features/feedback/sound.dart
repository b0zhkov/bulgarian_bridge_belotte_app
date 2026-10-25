import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound effects (assets/sounds/*.wav, synthesized, CC0).
enum Sfx {
  deal('deal', 6, 0.5),
  play('play', 4, 0.8),
  collect('collect', 2, 0.7),
  turn('turn', 1, 0.6),
  announce('announce', 2, 0.8),
  belot('belot', 2, 0.8),
  contra('contra', 1, 0.9),
  recontra('recontra', 1, 0.9),
  dealMade('deal_made', 1, 0.8),
  dealFailed('deal_failed', 1, 0.8),
  matchWon('match_won', 1, 0.9),
  matchLost('match_lost', 1, 0.9);

  const Sfx(this.file, this.voices, this.volume);
  final String file;

  /// Simultaneous voices in the pool (cards are played in quick bursts).
  final int voices;
  final double volume;
}

/// Plays sound effects. Tests use a fake.
abstract class SoundPlayer {
  void play(Sfx s, {double volume = 1});

  /// Call from a user gesture: browsers only allow audio after one.
  void unlock();
}

/// audioplayers-based player with a small pool per effect so rapid sounds
/// (dealing, card plays) overlap cleanly instead of cutting each other off.
/// Mixes with other apps' audio and respects the iOS silent switch.
class PooledSoundPlayer implements SoundPlayer {
  PooledSoundPlayer() {
    unawaited(_init());
  }

  final Map<Sfx, AudioPool> _pools = {};

  /// Android SoundPool (low latency); elsewhere the media player, which
  /// returns players to the pool when a clip completes.
  static bool get _lowLatency =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool _unlocked = !kIsWeb;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    try {
      final cache = AudioCache(prefix: 'assets/sounds/');
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build(),
      );
      for (final s in Sfx.values) {
        _pools[s] = await AudioPool.create(
          source: AssetSource('${s.file}.wav'),
          audioCache: cache,
          maxPlayers: s.voices,
          minPlayers: 1,
          playerMode: _lowLatency
              ? PlayerMode.lowLatency
              : PlayerMode.mediaPlayer,
        );
      }
    } catch (e) {
      debugPrint('sound init failed: $e');
    }
  }();

  @override
  void unlock() {
    if (_unlocked) return;
    _unlocked = true;
    // Touch every pool once inside the gesture (Safari needs it per element).
    for (final p in _pools.values) {
      unawaited(p.start(volume: 0).then((stop) => stop()).catchError((_) {}));
    }
  }

  @override
  void play(Sfx s, {double volume = 1}) {
    if (!_unlocked) return;
    final pool = _pools[s];
    if (pool == null) return;
    unawaited(() async {
      try {
        final stop = await pool.start(volume: (s.volume * volume).clamp(0, 1));
        // Low-latency players don't report completion: hand them back to
        // the pool after the longest clip.
        if (_lowLatency) Timer(const Duration(milliseconds: 1500), stop);
      } catch (_) {}
    }());
  }
}

/// No sound (tests, or before init).
class SilentSoundPlayer implements SoundPlayer {
  @override
  void play(Sfx s, {double volume = 1}) {}
  @override
  void unlock() {}
}

final soundPlayerProvider = Provider<SoundPlayer>((ref) => PooledSoundPlayer());
