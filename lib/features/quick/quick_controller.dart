import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/quick_match.dart';
import '../../online/rating.dart';
import '../../online/room_client.dart';
import '../online/online_controller.dart';
import '../profile/profile_controller.dart';
import 'rating_controller.dart';

enum QuickStatus { idle, searching, starting, ready, failed }

class QuickState {
  const QuickState({
    this.status = QuickStatus.idle,
    this.found = 1,
    this.secondsLeft = 30,
  });
  final QuickStatus status;

  /// Players found so far, this one included (1–4).
  final int found;
  final int secondsLeft;
}

/// Room codes for quick rooms (tests make them predictable).
@visibleForTesting
String Function()? debugQuickCodeGen;

/// Runs a [QuickMatcher] and hands the room over to the
/// [OnlineController] once matched (then the UI opens `/room`).
class QuickController extends Notifier<QuickState> {
  QuickMatcher? _m;
  bool _handled = false;

  @override
  QuickState build() {
    ref.onDispose(() => _m?.dispose());
    return const QuickState();
  }

  Future<void> start() async {
    await cancel();
    _handled = false;
    state = QuickState(
      status: QuickStatus.searching,
      secondsLeft: QuickMatcher.wait.inSeconds,
    );
    try {
      final db = await ref.read(dbConnectorProvider)();
      await ref.read(onlineControllerProvider.notifier).leave();
      final r = await RatingService(db).load(db.uid);
      ref.read(myRatingProvider.notifier).set(r);
      if (state.status != QuickStatus.searching) return;
      final m = QuickMatcher(
        db,
        name: ref.read(playerNameProvider) ?? '?',
        avatar: ref.read(playerAvatarProvider),
        rating: r.value,
        codeGen: debugQuickCodeGen,
      );
      m.onChange = () => _changed(m);
      _m = m;
      await m.start();
    } catch (_) {
      state = const QuickState(status: QuickStatus.failed);
    }
  }

  Future<void> _changed(QuickMatcher m) async {
    if (_m != m) return;
    switch (m.phase) {
      case QuickPhase.searching:
        state = QuickState(
          status: QuickStatus.searching,
          found: m.found,
          secondsLeft: m.secondsLeft,
        );
      case QuickPhase.starting:
        state = QuickState(
          status: QuickStatus.starting,
          found: m.found,
          secondsLeft: 0,
        );
      case QuickPhase.matched:
        if (_handled) return;
        _handled = true;
        final online = ref.read(onlineControllerProvider.notifier);
        final RoomClient? host = m.hostClient;
        final ok = host != null
            ? await online.adopt(host)
            : await online.join(m.matchedCode!);
        state = QuickState(
          status: ok ? QuickStatus.ready : QuickStatus.failed,
          found: m.found,
          secondsLeft: 0,
        );
      case QuickPhase.failed:
        state = const QuickState(status: QuickStatus.failed);
      case QuickPhase.cancelled:
        break;
    }
  }

  Future<void> cancel() async {
    final m = _m;
    _m = null;
    if (m != null) {
      await m.cancel();
      m.dispose();
    }
    state = const QuickState();
  }

  /// After a match: done with this one.
  void reset() {
    _m?.dispose();
    _m = null;
    state = const QuickState();
  }
}

final quickControllerProvider = NotifierProvider<QuickController, QuickState>(
  QuickController.new,
);
