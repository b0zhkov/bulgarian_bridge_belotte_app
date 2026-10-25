import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/rules/rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../feedback/sound.dart';
import '../game_controller.dart';
import '../labels.dart';
import 'playing_card.dart';

/// Centre of the table: the four cards of the current trick arranged in a
/// cross (you at the bottom, partner at the top). Cards fly in from their
/// owner's side (with a swoosh as each one starts to move, whoever played
/// it); a won trick slides off toward the winner's seat.
class TrickArea extends ConsumerStatefulWidget {
  const TrickArea({super.key, required this.table});
  final TableState table;

  /// Gap between cards that arrive in one state update (online updates can
  /// coalesce several plays), so each flies and swooshes on its own.
  static const coalescedGap = Duration(milliseconds: 110);

  @override
  ConsumerState<TrickArea> createState() => _TrickAreaState();
}

class _TrickAreaState extends ConsumerState<TrickArea>
    with SingleTickerProviderStateMixin {
  TableState get table => widget.table;

  /// Cards already on the table when this view appeared (e.g. rejoining
  /// mid-trick) don't swoosh.
  late final Set<String> _silent;

  /// Start delays of cards that arrived together.
  final Map<String, Duration> _delays = {};

  static Set<String> _keysOf(TableState t) => {
    for (final p in t.visibleTrick.plays) _key(t.visibleTrick, p),
  };
  static String _key(Trick t, Play p) => '${t.leader}-${p.card.code}';

  /// The trick being collected (animating toward its winner).
  Trick? _leaving;
  late final AnimationController _collect =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _leaving = null);
        }
      });

  @override
  void initState() {
    super.initState();
    _silent = _keysOf(widget.table);
  }

  @override
  void didUpdateWidget(TrickArea old) {
    super.didUpdateWidget(old);
    final seen = _keysOf(old.table);
    var i = 0;
    for (final p in widget.table.visibleTrick.plays) {
      final k = _key(widget.table.visibleTrick, p);
      if (seen.contains(k) || _delays.containsKey(k)) continue;
      _delays[k] = TrickArea.coalescedGap * i++;
    }
    if (_delays.length > 16) {
      final live = _keysOf(widget.table);
      _delays.removeWhere((k, _) => !live.contains(k));
    }
    final held = old.table.displayTrick;
    if (held != null &&
        held.winner != null &&
        widget.table.displayTrick == null &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _leaving = held;
      _collect.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _collect.dispose();
    super.dispose();
  }

  static Offset _dir(int seat) => switch (seat) {
    0 => const Offset(0, 1),
    1 => const Offset(1, 0),
    2 => const Offset(0, -1),
    _ => const Offset(-1, 0),
  };

  @override
  Widget build(BuildContext context) {
    final trick = table.visibleTrick;
    final winnerSeat = table.displayTrick?.winner;
    return LayoutBuilder(
      builder: (context, box) {
        final cw = math
            .min(76.0, math.min(box.maxWidth / 3.3, box.maxHeight / 2.75))
            .floorToDouble();
        final ch = cw * PlayingCardView.aspect;
        final center = Offset(box.maxWidth / 2, box.maxHeight / 2);
        final spreadX = cw * 1.15;
        final spreadY = ch * 0.63;
        Offset slot(int seat) => Offset(
          (center.dx + _dir(seat).dx * spreadX - cw / 2).roundToDouble(),
          (center.dy + _dir(seat).dy * spreadY - ch / 2).roundToDouble(),
        );
        final leaving = _leaving;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (leaving != null)
              for (final p in leaving.plays)
                AnimatedBuilder(
                  key: ValueKey('leaving-${leaving.leader}-${p.card.code}'),
                  animation: _collect,
                  builder: (context, child) {
                    final t = Curves.easeInCubic.transform(_collect.value);
                    final to =
                        center -
                        Offset(cw / 2, ch / 2) +
                        _dir(leaving.winner!) *
                            (box.maxWidth * 0.55 + cw * 0.5);
                    final o = Offset.lerp(slot(p.seat), to, t)!;
                    return Positioned(
                      left: o.dx,
                      top: o.dy,
                      child: Opacity(
                        opacity: (1 - t * t).clamp(0, 1),
                        child: Transform.scale(
                          scale: 1 - 0.35 * t,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: PlayingCardView(card: p.card, width: cw),
                ),
            for (final p in trick.plays)
              _FlyingCard(
                key: ValueKey(_key(trick, p)),
                delay: _delays[_key(trick, p)] ?? Duration.zero,
                onLaunch: _silent.contains(_key(trick, p))
                    ? null
                    : () => playSfx(ref, Sfx.swoosh),
                from: _dir(p.seat) * (box.maxWidth * 0.6),
                // Straight, symmetric cross snapped to whole pixels.
                target: Offset(
                  (center.dx + _dir(p.seat).dx * spreadX - cw / 2)
                      .roundToDouble(),
                  (center.dy + _dir(p.seat).dy * spreadY - ch / 2)
                      .roundToDouble(),
                ),
                child: PlayingCardView(
                  key: Key('trick-${p.seat}'),
                  card: p.card,
                  width: cw,
                  highlighted: winnerSeat == p.seat,
                  dimmed: winnerSeat != null && winnerSeat != p.seat,
                ),
              ),
            if (table.game.phase == GamePhase.bidding)
              Positioned.fill(child: _BiddingCenter(table: table)),
          ],
        );
      },
    );
  }
}

/// A card flying in from its owner's side. [onLaunch] fires on the frame
/// its flight starts (after [delay]), so the swoosh matches the motion.
class _FlyingCard extends StatefulWidget {
  const _FlyingCard({
    super.key,
    required this.from,
    required this.target,
    required this.child,
    this.delay = Duration.zero,
    this.onLaunch,
  });
  final Offset from;
  final Offset target;
  final Widget child;
  final Duration delay;
  final VoidCallback? onLaunch;

  @override
  State<_FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<_FlyingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    if (widget.delay > Duration.zero) {
      _wait = Timer(widget.delay, _launch);
    } else {
      _launch();
    }
  }

  void _launch() {
    if (!mounted) return;
    widget.onLaunch?.call();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _wait?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        final o = widget.target + widget.from * (1 - t);
        return Positioned(
          left: o.dx,
          top: o.dy,
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _BiddingCenter extends StatelessWidget {
  const _BiddingCenter({required this.table});
  final TableState table;
  GameState get game => table.game;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final contract = game.contract;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.bidding,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: contract == null
                  ? Text(
                      '—',
                      key: const ValueKey('none'),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                      ),
                    )
                  : Column(
                      key: ValueKey(contract),
                      children: [
                        ContractGlyph(
                          contract.type,
                          size: 56,
                          color: c.textPrimary,
                          red: c.cardRed,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${contractName(l, contract.type)}${multiplierSuffix(l, contract.multiplier)}',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: AppText.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          table.infoFor(l, contract.declarer).name,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: AppText.caption,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
