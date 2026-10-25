import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_controller.dart';

/// Sound effects (assets/sounds/*.wav, synthesized, CC0). Deliberately few:
/// a swoosh when any card is played (started together with its flight to
/// the table) and the deal / match result.
enum Sfx {
  swoosh('swoosh', 4, 0.8),
  dealMade('deal_made', 1, 0.8),
  dealFailed('deal_failed', 1, 0.8),
  matchWon('match_won', 1, 0.9),
  matchLost('match_lost', 1, 0.9);

  const Sfx(this.file, this.voices, this.volume);
  final String file;

  /// Simultaneous voices in the pool (several cards can land together).
  final int voices;
  final double volume;
}

/// Plays sound effects. Tests use a fake.
abstract class SoundPlayer {
  void play(Sfx s, {double volume = 1});

  /// Call from a user gesture: browsers only allow audio after one.
  void unlock();
}

/// audioplayers-based player with a small preloaded pool per effect, so a
/// sound starts the moment it is asked for. Created at app start (see
/// `main.dart`), not on the first sound. Mixes with other apps' audio and
/// respects the iOS silent switch.
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
        // Every voice preloaded: no source loading when a card is played
        // (and on web every element can be unlocked by the first tap).
        _pools[s] = await AudioPool.create(
          source: AssetSource('${s.file}.wav'),
          audioCache: cache,
          maxPlayers: s.voices,
          minPlayers: s.voices,
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
    // Before the pools exist there is nothing to unlock: the next tap
    // tries again.
    if (_unlocked || _pools.length < Sfx.values.length) return;
    _unlocked = true;
    // Touch every voice once inside the gesture (Safari unlocks per
    // element).
    for (final s in Sfx.values) {
      final pool = _pools[s]!;
      for (var i = 0; i < s.voices; i++) {
        unawaited(
          pool.start(volume: 0).then((stop) => stop()).catchError((_) {}),
        );
      }
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

/// Plays [s] if sounds are enabled in the settings.
void playSfx(WidgetRef ref, Sfx s) {
  if (!ref.read(soundEnabledProvider)) return;
  ref.read(soundPlayerProvider).play(s);
}
