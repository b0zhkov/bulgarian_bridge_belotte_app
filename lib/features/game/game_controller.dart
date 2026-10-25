import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agents/player_agent.dart';
import '../../core/rules/rules.dart';

const int kHumanSeat = 0;

/// What the table shows. Wraps the immutable engine state with transient
/// presentation state (trick pauses, speech bubbles).
class TableState {
  const TableState({
    required this.game,
    this.displayTrick,
    this.bubbles = const {},
  });

  final GameState game;

  /// A just-completed trick kept on the table for a moment.
  final Trick? displayTrick;

  /// Short-lived announcements per seat (declarations, belot).
  final Map<int, Announcement> bubbles;

  bool get holding => displayTrick != null;
  Trick get visibleTrick => displayTrick ?? game.currentTrick;
  bool get isHumanTurn =>
      !holding &&
      game.currentSeat == kHumanSeat &&
      (game.phase == GamePhase.bidding || game.phase == GamePhase.playing);

  TableState copyWith({
    GameState? game,
    Trick? displayTrick,
    bool clearDisplayTrick = false,
    Map<int, Announcement>? bubbles,
  }) => TableState(
    game: game ?? this.game,
    displayTrick: clearDisplayTrick
        ? null
        : (displayTrick ?? this.displayTrick),
    bubbles: bubbles ?? this.bubbles,
  );
}

/// Drives a local match: the human plays seat 0, placeholder agents play
/// the other seats (to be replaced by real bots behind [PlayerAgent]).
class GameController extends Notifier<TableState> {
  final List<Timer> _timers = [];
  late Map<int, PlayerAgent> _agents;

  static Duration botDelay = const Duration(milliseconds: 650);
  static Duration trickPause = const Duration(milliseconds: 1100);
  static Duration redealPause = const Duration(milliseconds: 1600);
  static int? fixedSeed;

  @override
  TableState build() {
    ref.onDispose(_cancelTimers);
    return _start();
  }

  TableState _start() {
    final seed = fixedSeed ?? Random().nextInt(1 << 31);
    _agents = {
      for (final s in [1, 2, 3]) s: RandomAgent(seed + s),
    };
    final initial = TableState(game: BelotEngine.newMatch(seed: seed));
    Future.microtask(_schedule);
    return initial;
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _after(Duration d, void Function() f) {
    late Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      f();
    });
    _timers.add(t);
  }

  void _schedule() {
    final s = state;
    if (s.holding) return;
    final g = s.game;
    switch (g.phase) {
      case GamePhase.bidding:
        if (g.currentSeat != kHumanSeat) {
          _after(botDelay, () {
            final seat = state.game.currentSeat;
            if (state.game.phase != GamePhase.bidding || seat == kHumanSeat) {
              return;
            }
            _bid(seat, _agents[seat]!.chooseBid(state.game, seat));
          });
        }
      case GamePhase.playing:
        if (g.currentSeat != kHumanSeat) {
          _after(botDelay, () {
            final seat = state.game.currentSeat;
            if (state.game.phase != GamePhase.playing ||
                seat == kHumanSeat ||
                state.holding) {
              return;
            }
            _play(seat, _agents[seat]!.choosePlay(state.game, seat));
          });
        }
      case GamePhase.allPassed:
        _after(redealPause, () {
          if (state.game.phase == GamePhase.allPassed) {
            state = state.copyWith(
              game: BelotEngine.nextDeal(state.game),
              bubbles: const {},
            );
            _schedule();
          }
        });
      case GamePhase.dealScored:
      case GamePhase.matchOver:
        break;
    }
  }

  void _bid(int seat, Bid bid) {
    state = state.copyWith(game: BelotEngine.applyBid(state.game, seat, bid));
    _schedule();
  }

  void _play(int seat, Card card) {
    final before = state.game;
    final after = BelotEngine.applyPlay(before, seat, card);
    var bubbles = state.bubbles;
    final a = after.lastAnnouncement;
    if (a != null) {
      bubbles = {...bubbles, a.seat: a};
      _after(const Duration(milliseconds: 2200), () {
        if (state.bubbles[a.seat] == a) {
          state = state.copyWith(bubbles: {...state.bubbles}..remove(a.seat));
        }
      });
    }
    if (after.tricks.length > before.tricks.length) {
      state = state.copyWith(
        game: after,
        displayTrick: after.tricks.last,
        bubbles: bubbles,
      );
      _after(trickPause, () {
        state = state.copyWith(clearDisplayTrick: true);
        _schedule();
      });
    } else {
      state = state.copyWith(game: after, bubbles: bubbles);
      _schedule();
    }
  }

  // ------------------------------------------------------------ human API

  List<Bid> humanBids() => state.isHumanTurn
      ? BelotEngine.validBids(state.game, kHumanSeat)
      : const [];

  Set<Card> humanLegalCards() => state.isHumanTurn
      ? BelotEngine.getLegalMoves(state.game, kHumanSeat).toSet()
      : const {};

  void humanBid(Bid bid) {
    if (!humanBids().contains(bid)) return;
    HapticFeedback.selectionClick();
    _bid(kHumanSeat, bid);
  }

  void humanPlay(Card card) {
    if (!humanLegalCards().contains(card)) return;
    HapticFeedback.lightImpact();
    _play(kHumanSeat, card);
  }

  void nextDeal() {
    if (state.game.phase != GamePhase.dealScored) return;
    state = state.copyWith(
      game: BelotEngine.nextDeal(state.game),
      bubbles: const {},
    );
    _schedule();
  }

  void newMatch() {
    _cancelTimers();
    state = _start();
  }
}

final gameControllerProvider =
    NotifierProvider.autoDispose<GameController, TableState>(
      GameController.new,
    );
