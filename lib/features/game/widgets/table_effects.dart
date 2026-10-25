import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/deal_timing.dart';
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
/// and turns state changes into sounds and haptics. Everything is derived
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
  late final AnimationController _ctrl = AnimationController(vsync: this)
    ..addListener(_tick)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finishDeal();
    });

  List<_Flight> _flights = const [];
  int _dealer = 0;
  List<Card> _myCards = const [];
  int _myArrived = 0;
  int _launched = 0;
  Object? _turnKey;

  @override
  void initState() {
    super.initState();
    final g = widget.table.game;
    // A fresh deal (match start): animate it. Mid-deal joins show the
    // state as is.
    if (g.phase == GamePhase.bidding &&
        g.bids.isEmpty &&
        g.hands[0].length == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startDeal(g, const [3, 2], g.hands[0]);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
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

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _startDeal(GameState g, List<int> rounds, List<Card> myCards) {
    if (_reducedMotion || DealTiming.scale == 0) {
      _finishDeal();
      return;
    }
    final order = DealTiming.order(g.dealer, rounds);
    setState(() {
      _dealer = g.dealer;
      _flights = [
        for (var i = 0; i < order.length; i++)
          _Flight(order[i], DealTiming.stagger * i),
      ];
      _myCards = myCards;
      _myArrived = 0;
      _launched = 0;
    });
    _ctrl
      ..duration = DealTiming.total(order.length)
      ..forward(from: 0);
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

  Duration get _elapsed => (_ctrl.duration ?? Duration.zero) * _ctrl.value;

  void _tick() {
    final e = _elapsed;
    var launched = 0, mine = 0;
    for (final f in _flights) {
      if (e >= f.delay) launched++;
      if (f.seat == 0 && e >= f.delay + DealTiming.flight) mine++;
    }
    for (var i = _launched; i < launched; i++) {
      _sound(Sfx.deal, volume: 0.7);
    }
    _launched = launched;
    if (mine != _myArrived) setState(() => _myArrived = mine);
  }

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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final from = _centerOf(_dealer);
        if (from == null) return const SizedBox.shrink();
        final e = _elapsed;
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

  void _sound(Sfx s, {double volume = 1}) {
    if (!ref.read(soundEnabledProvider)) return;
    ref.read(soundPlayerProvider).play(s, volume: volume);
  }

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
        // One tap per card (state updates can coalesce several plays).
        for (var i = 0; i < after - before; i++) {
          if (i == 0) {
            _sound(Sfx.play);
          } else {
            Future.delayed(const Duration(milliseconds: 90) * i, () {
              if (mounted) _sound(Sfx.play);
            });
          }
        }
        final plays = [
          for (final t in [...n.tricks, n.currentTrick]) ...t.plays,
        ];
        if (plays.skip(before).any((p) => p.seat == kHumanSeat)) {
          _haptic(Haptic.light);
        }
      }
      // Bids.
      for (final b in n.bids.skip(o.bids.length)) {
        if (b.bid.kind == BidKind.double) {
          _sound(Sfx.contra);
          _haptic(Haptic.heavy);
        } else if (b.bid.kind == BidKind.redouble) {
          _sound(Sfx.recontra);
          _haptic(Haptic.heavy);
        } else if (b.seat == kHumanSeat) {
          _haptic(Haptic.selection);
        }
      }
      // Declarations / belot.
      final a = n.lastAnnouncement;
      if (a != null && !identical(a, o.lastAnnouncement) && after > before) {
        _sound(a.belot && a.declarations.isEmpty ? Sfx.belot : Sfx.announce);
        if (a.belot && a.declarations.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 260), () {
            if (mounted) _sound(Sfx.belot);
          });
        }
        _haptic(Haptic.light);
      }
      // Trick collected (the held trick leaves the table).
      final held = old.displayTrick;
      if (held != null && now.displayTrick == null) {
        _sound(Sfx.collect);
        if (held.winner != null && teamOf(held.winner!) == 0) {
          _haptic(Haptic.medium);
        }
      }
      // Deal / match result.
      if (n.history.length > o.history.length) {
        final d = n.history.last;
        if (n.phase == GamePhase.matchOver) {
          final won = n.winnerTeam == 0;
          _sound(won ? Sfx.matchWon : Sfx.matchLost);
          _haptic(Haptic.heavy);
        } else {
          _sound(
            d.outcome == DealOutcome.outside ? Sfx.dealMade : Sfx.dealFailed,
          );
          _haptic(Haptic.medium);
        }
      }
    }
    _checkTurn();
  }

  /// Quiet chime when a decision becomes the player's (not while dealing;
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
    _sound(Sfx.turn);
    _haptic(Haptic.selection);
  }

  bool get _dealingNow => _ctrl.isAnimating;

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
