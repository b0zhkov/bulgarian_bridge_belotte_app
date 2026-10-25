import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/deal_timing.dart';
import '../../../core/perf/perf_log.dart';
import '../../../core/rules/rules.dart';
import '../../feedback/sound.dart';
import '../../profile/profile_controller.dart';
import '../game_controller.dart';
import 'playing_card.dart';

/// What the table needs to know about the dealing animation.
class DealView {
  const DealView({
    required this.anchors,
    this.hiddenHand = const {},
    this.dealing = false,
  });

  /// Anchors per view seat (0 = the player's hand, 1-3 = avatars).
  final List<GlobalKey> anchors;

  /// Cards of the player's hand that are still in flight.
  final Set<Card> hiddenHand;

  /// Cards are being dealt (input stays disabled meanwhile).
  final bool dealing;
}

/// Haptic strengths used for table events.
enum Haptic { light, medium, heavy, selection }

/// Wraps the table: plays the dealing animation (cards fly from the dealer
/// counter-clockwise, 3 + 2 and later 3 each, the player's hand fans in),
/// and turns state changes into haptics and the deal / match result sound
/// (card swooshes come from [TrickArea]). Everything is derived
/// from consecutive [TableState]s, so online clients stay in sync and a
/// client that (re)joins mid-deal just shows the current state.
class TableEffects extends ConsumerStatefulWidget {
  const TableEffects({super.key, required this.table, required this.builder});

  final TableState table;
  final Widget Function(BuildContext context, DealView deal) builder;

  @override
  ConsumerState<TableEffects> createState() => _TableEffectsState();
}

class _Flight {
  const _Flight(this.seat, this.delay);
  final int seat;
  final Duration delay;
}

class _TableEffectsState extends ConsumerState<TableEffects>
    with SingleTickerProviderStateMixin {
  final _anchors = List.generate(4, (_) => GlobalKey());
  final _stackKey = GlobalKey();

  /// Deal clock. Advances with the frames but at most [_maxStep] per frame,
  /// so a slow frame (first paint of the table) never makes cards jump or
  /// land unseen: they keep flying smoothly from the first frame instead.
  late final Ticker _ticker = createTicker(_onTick);
  final _clock = ValueNotifier<Duration>(Duration.zero);
  static const _maxStep = Duration(milliseconds: 50);
  Duration _lastTick = Duration.zero;
  Duration _total = Duration.zero;

  List<_Flight> _flights = const [];
  int _dealer = 0;
  List<Card> _myCards = const [];
  int _myArrived = 0;
  Object? _turnKey;

  /// A deal waiting for the page transition to finish (the table is still
  /// sliding in; its first frames are the most expensive ones).
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    final g = widget.table.game;
    // A fresh deal (match start): animate it. Mid-deal joins show the
    // state as is.
    if (g.phase == GamePhase.bidding &&
        g.bids.isEmpty &&
        g.hands[0].length == 5) {
      _prepareDeal(g, const [3, 2], g.hands[0]);
      _waiting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _whenSettled());
    }
  }

  /// Starts the clock once the route is fully in and one settled frame
  /// has been drawn.
  void _whenSettled() {
    if (!mounted || !_waiting) return;
    if (_skipAnimation) {
      _waiting = false;
      _finishDeal();
      return;
    }
    final anim = ModalRoute.of(context)?.animation;
    if (anim != null && !anim.isCompleted) {
      void listener(AnimationStatus s) {
        if (s != AnimationStatus.completed) return;
        anim.removeStatusListener(listener);
        WidgetsBinding.instance.addPostFrameCallback((_) => _whenSettled());
      }

      anim.addStatusListener(listener);
      return;
    }
    _waiting = false;
    _run();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TableEffects old) {
    super.didUpdateWidget(old);
    final o = old.table.game, n = widget.table.game;
    final mine = n.hands[0].length, had = o.hands[0].length;
    final newDeal = n.dealNumber != o.dealNumber || had != 5;
    if (n.phase == GamePhase.bidding &&
        n.bids.isEmpty &&
        mine == 5 &&
        newDeal) {
      // First five cards (online the hand may arrive a moment after the
      // public state, so this also fires when it shows up).
      _startDeal(n, const [3, 2], n.hands[0]);
    } else if (n.dealNumber == o.dealNumber &&
        n.phase == GamePhase.playing &&
        n.tricks.isEmpty &&
        mine == 8 &&
        had == 5) {
      // The remaining three after the contract.
      _startDeal(
        n,
        const [3],
        [
          for (final c in n.hands[0])
            if (!o.hands[0].contains(c)) c,
        ],
      );
    }
    _effects(old.table, widget.table);
  }

  // ------------------------------------------------------------- dealing

  bool get _skipAnimation =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      DealTiming.scale == 0;

  void _startDeal(GameState g, List<int> rounds, List<Card> myCards) {
    _waiting = false;
    _prepareDeal(g, rounds, myCards);
    _run();
  }

  void _prepareDeal(GameState g, List<int> rounds, List<Card> myCards) {
    final order = DealTiming.order(g.dealer, rounds);
    _ticker.stop();
    _clock.value = Duration.zero;
    _total = DealTiming.total(order.length);
    // Called from initState / didUpdateWidget: a build follows anyway.
    _dealer = g.dealer;
    _flights = [
      for (var i = 0; i < order.length; i++)
        _Flight(order[i], DealTiming.stagger * i),
    ];
    _myCards = myCards;
    _myArrived = 0;
  }

  void _run() {
    if (_skipAnimation) {
      _finishDeal();
      return;
    }
    PerfLog.mark('deal clock start (${_flights.length} cards)');
    _firstTickLogged = false;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration now) {
    final step = now - _lastTick;
    _lastTick = now;
    final e = _clock.value + (step > _maxStep ? _maxStep : step);
    if (PerfLog.enabled && !_firstTickLogged && e > Duration.zero) {
      _firstTickLogged = true;
      PerfLog.mark('deal first moving tick, clock ${e.inMilliseconds}ms');
    }
    _clock.value = e;
    var mine = 0;
    for (final f in _flights) {
      if (f.seat == 0 && e >= f.delay + DealTiming.flight) mine++;
    }
    if (mine != _myArrived) setState(() => _myArrived = mine);
    if (e >= _total) {
      _ticker.stop();
      _finishDeal();
    }
  }

  void _finishDeal() {
    if (_flights.isEmpty && _myCards.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _flights = const [];
      _myCards = const [];
      _myArrived = 0;
    });
    _checkTurn();
  }

  bool _firstTickLogged = false;

  Offset? _centerOf(int seat) {
    final box = _anchors[seat].currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.hasSize || !box.attached) {
      return null;
    }
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  Widget _overlay() {
    const w = 34.0;
    const h = w * PlayingCardView.aspect;
    final back = RepaintBoundary(
      child: PlayingCardView(card: null, faceUp: false, width: w),
    );
    return ValueListenableBuilder<Duration>(
      valueListenable: _clock,
      builder: (context, e, _) {
        final from = _centerOf(_dealer);
        // Nothing on the table until the clock runs (no frozen pile).
        if (from == null || !_ticker.isActive) return const SizedBox.shrink();
        final flightUs = DealTiming.flight.inMicroseconds;
        final children = <Widget>[];
        // The undealt pile at the dealer.
        final pile = _flights.where((f) => e < f.delay).length;
        for (var i = 0; i < pile.clamp(0, 4); i++) {
          children.add(
            Transform.translate(
              offset:
                  from - const Offset(w / 2, h / 2) + Offset(i * 1.5, -i * 1.5),
              child: back,
            ),
          );
        }
        for (final f in _flights) {
          final dt = (e - f.delay).inMicroseconds / flightUs;
          if (dt <= 0 || dt >= 1) continue;
          final to = _centerOf(f.seat) ?? from;
          final t = Curves.easeOutCubic.transform(dt);
          final p = Offset.lerp(from, to, t)!;
          final grow = f.seat == 0 ? 1 + 0.8 * t : 1.0;
          children.add(
            Transform.translate(
              offset: p - const Offset(w / 2, h / 2),
              child: Transform.scale(
                scale: grow,
                child: Opacity(
                  opacity: f.seat == 0 || dt < 0.8 ? 1 : (1 - dt) / 0.2,
                  child: back,
                ),
              ),
            ),
          );
        }
        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }

  // ------------------------------------------------------ sound & haptics

  void _sound(Sfx s) => playSfx(ref, s);

  void _haptic(Haptic h) {
    if (kIsWeb || !ref.read(hapticsEnabledProvider)) return;
    switch (h) {
      case Haptic.light:
        HapticFeedback.lightImpact();
      case Haptic.medium:
        HapticFeedback.mediumImpact();
      case Haptic.heavy:
        HapticFeedback.heavyImpact();
      case Haptic.selection:
        HapticFeedback.selectionClick();
    }
  }

  void _effects(TableState old, TableState now) {
    final o = old.game, n = now.game;
    if (n.dealNumber == o.dealNumber) {
      // Cards played.
      final before = o.tricks.length * 4 + o.currentTrick.plays.length;
      final after = n.tricks.length * 4 + n.currentTrick.plays.length;
      if (after > before) {
        // (The swoosh is played by the trick area when the card starts
        // flying.)
        final plays = [
          for (final t in [...n.tricks, n.currentTrick]) ...t.plays,
        ];
        if (plays.skip(before).any((p) => p.seat == kHumanSeat)) {
          _haptic(Haptic.light);
        }
      }
      // Bids.
      for (final b in n.bids.skip(o.bids.length)) {
        if (b.bid.kind == BidKind.double || b.bid.kind == BidKind.redouble) {
          _haptic(Haptic.heavy);
        } else if (b.seat == kHumanSeat) {
          _haptic(Haptic.selection);
        }
      }
      // Declarations / belot.
      final a = n.lastAnnouncement;
      if (a != null && !identical(a, o.lastAnnouncement) && after > before) {
        _haptic(Haptic.light);
      }
      // Trick collected (the held trick leaves the table).
      final held = old.displayTrick;
      if (held != null && now.displayTrick == null) {
        if (held.winner != null && teamOf(held.winner!) == 0) {
          _haptic(Haptic.medium);
        }
      }
      // Deal / match result (after the last card's swoosh when they
      // arrive together).
      if (n.history.length > o.history.length) {
        final d = n.history.last;
        final Sfx result;
        if (n.phase == GamePhase.matchOver) {
          result = n.winnerTeam == 0 ? Sfx.matchWon : Sfx.matchLost;
          _haptic(Haptic.heavy);
        } else {
          result = d.outcome == DealOutcome.outside
              ? Sfx.dealMade
              : Sfx.dealFailed;
          _haptic(Haptic.medium);
        }
        if (after > before) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) _sound(result);
          });
        } else {
          _sound(result);
        }
      }
    }
    _checkTurn();
  }

  /// Haptic tick when a decision becomes the player's (not while dealing;
  /// checked again when the deal animation ends).
  void _checkTurn() {
    final now = widget.table, n = now.game;
    if (!now.isHumanTurn || _dealingNow) return;
    final key = (
      n.dealNumber,
      n.bids.length,
      n.tricks.length,
      n.currentTrick.plays.length,
    );
    if (key == _turnKey) return;
    _turnKey = key;
    _haptic(Haptic.selection);
  }

  bool get _dealingNow => _waiting || _ticker.isActive;

  @override
  Widget build(BuildContext context) {
    final dealing = _flights.isNotEmpty;
    final view = DealView(
      anchors: _anchors,
      hiddenHand: dealing ? _myCards.skip(_myArrived).toSet() : const {},
      dealing: dealing,
    );
    return Stack(
      key: _stackKey,
      children: [
        widget.builder(context, view),
        if (dealing) Positioned.fill(child: IgnorePointer(child: _overlay())),
      ],
    );
  }
}
