import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Frame-timing log for measuring the deal start (`--dart-define=PERF_LOG=true`,
/// development/profiling builds only). Prints to the console:
/// `[perf] <event>` marks and, for 3 s after each mark, every frame's
/// build/raster times and the gap since the previous frame.
class PerfLog {
  static const enabled = bool.fromEnvironment('PERF_LOG');
  static final _watch = Stopwatch()..start();
  static int _until = 0;
  static int? _lastEnd;
  static bool _hooked = false;

  static int get nowMs => _watch.elapsedMilliseconds;

  static void mark(String event) {
    if (!enabled) return;
    if (!_hooked) {
      _hooked = true;
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
    _until = nowMs + 3000;
    debugPrint('[perf] ${nowMs}ms $event');
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (nowMs > _until) return;
    for (final t in timings) {
      final end = t.timestampInMicroseconds(FramePhase.rasterFinish) ~/ 1000;
      final gap = _lastEnd == null ? 0 : end - _lastEnd!;
      _lastEnd = end;
      debugPrint(
        '[perf] frame build=${t.buildDuration.inMicroseconds / 1000}ms '
        'raster=${t.rasterDuration.inMicroseconds / 1000}ms '
        'total=${t.totalSpan.inMicroseconds / 1000}ms gap=${gap}ms',
      );
    }
  }
}
