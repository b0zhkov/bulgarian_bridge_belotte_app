import 'package:bulgarian_bridge_belotte_app/features/feedback/sound.dart';

/// Records sound effects instead of playing them.
class FakeSoundPlayer implements SoundPlayer {
  final played = <Sfx>[];
  var unlocks = 0;

  @override
  void play(Sfx s, {double volume = 1}) => played.add(s);

  @override
  void unlock() => unlocks++;
}
