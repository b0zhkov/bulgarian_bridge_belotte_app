import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Set<Card> legal(String hand, Trick trick, ContractType t, int seat) =>
    legalMoves(hand: cs(hand), trick: trick, type: t, seat: seat).toSet();

void main() {
  const sp = ContractType.spades;
  group('any contract', () {
    test('leader may play any card', () {
      for (final t in ContractType.values) {
        expect(legal('7H 8S AC', Trick(0), t, 0), cs('7H 8S AC').toSet());
      }
    });
  });

  group('suit contract (spades trump)', () {
    test('must follow led suit', () {
      expect(
        legal('7H KH 9S AC', trickOf(1, 'AH'), sp, 2),
        cs('7H KH').toSet(),
      );
    });
    test('following non-trump suit does not require raising', () {
      expect(legal('7H KH', trickOf(1, '10H'), sp, 2), cs('7H KH').toSet());
    });
    test('following non-trump suit even if someone trumped', () {
      expect(
        legal('7H KH 9S', trickOf(1, '10H 7S'), sp, 3),
        cs('7H KH').toSet(),
      );
    });
    test('trump led: must raise with a higher trump', () {
      expect(
        legal('7S 9S AS AC', trickOf(1, '10S'), sp, 2),
        cs('9S AS').toSet(),
      );
    });
    test('trump led: cannot raise -> any trump', () {
      expect(legal('7S 8S AC', trickOf(1, 'JS'), sp, 2), cs('7S 8S').toSet());
    });
    test('void, opponent winning -> must trump (any trump)', () {
      expect(
        legal('7S JS AC 8D', trickOf(1, 'AH'), sp, 2),
        cs('7S JS').toSet(),
      );
    });
    test('void, partner winning -> any card', () {
      expect(
        legal('7S JS AC 8D', trickOf(0, 'AH 7H'), sp, 2),
        cs('7S JS AC 8D').toSet(),
      );
    });
    test('void, partner winning with trump -> any card', () {
      expect(
        legal('7S AC', trickOf(1, 'AH 8S 7H'), sp, 0),
        cs('7S AC').toSet(),
      );
    });
    test('void, opponent trumped -> must over-trump', () {
      expect(
        legal('7S AS JS 8D', trickOf(3, 'AH 10S'), sp, 1),
        cs('AS JS').toSet(),
      );
    });
    test('void, opponent trumped and cannot over-trump -> any card', () {
      expect(
        legal('7S 8S 8D', trickOf(3, 'AH JS'), sp, 1),
        cs('7S 8S 8D').toSet(),
      );
    });
    test('void without trumps -> any card', () {
      expect(legal('8D AC', trickOf(1, 'AH'), sp, 2), cs('8D AC').toSet());
    });
    test('opponent over-trumps partner -> must over-trump opponent', () {
      // seat 1 leads AH, seat 2 trumps 8S, seat 3 over-trumps 10S, seat 0 void
      expect(
        legal('9S QS 7D', trickOf(1, 'AH 8S 10S'), sp, 0),
        cs('9S').toSet(),
      );
    });
  });

  group('No Trump', () {
    test('must follow suit, no raise required', () {
      expect(
        legal('7H AH 9S', trickOf(1, '10H'), ContractType.noTrump, 2),
        cs('7H AH').toSet(),
      );
    });
    test('void -> any card (no trumping obligation)', () {
      expect(
        legal('9S AC', trickOf(1, '10H'), ContractType.noTrump, 2),
        cs('9S AC').toSet(),
      );
    });
  });

  group('All Trump', () {
    const at = ContractType.allTrump;
    test('must raise in led suit when possible', () {
      expect(
        legal('7H 9H JH AC', trickOf(1, 'AH'), at, 2),
        cs('9H JH').toSet(),
      );
    });
    test('must raise even when partner is winning', () {
      expect(legal('7H 9H AC', trickOf(0, '10H 8H'), at, 2), cs('9H').toSet());
    });
    test('cannot raise -> any card of led suit', () {
      expect(legal('7H 8H AC', trickOf(1, 'JH'), at, 2), cs('7H 8H').toSet());
    });
    test('void -> any card', () {
      expect(legal('7C 8D', trickOf(1, 'JH'), at, 2), cs('7C 8D').toSet());
    });
    test('raise is measured against highest card of led suit only', () {
      expect(legal('QH KH', trickOf(1, '8H JC'), at, 3), cs('QH KH').toSet());
    });
  });
}
