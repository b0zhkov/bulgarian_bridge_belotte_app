import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('deck', () {
    test('has 32 distinct cards 7..A', () {
      expect(fullDeck.length, 32);
      expect(fullDeck.toSet().length, 32);
    });
    test('parse round trip', () {
      expect(c('10H'), const Card(Suit.hearts, Rank.ten));
      expect(c('TH'), const Card(Suit.hearts, Rank.ten));
      expect(c('JS').code, 'JS');
    });
  });

  group('ranking', () {
    test('trump order J>9>A>10>K>Q>8>7', () {
      final order = cs('JS 9S AS 10S KS QS 8S 7S');
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          strengthInSuit(order[i], ContractType.spades) >
              strengthInSuit(order[i + 1], ContractType.spades),
          isTrue,
        );
      }
    });
    test('plain order A>10>K>Q>J>9>8>7 for non-trump and No Trump', () {
      final order = cs('AH 10H KH QH JH 9H 8H 7H');
      for (final t in [ContractType.spades, ContractType.noTrump]) {
        for (var i = 0; i < order.length - 1; i++) {
          expect(
            strengthInSuit(order[i], t) > strengthInSuit(order[i + 1], t),
            isTrue,
          );
        }
      }
    });
    test('All Trump uses trump order in every suit', () {
      expect(
        strengthInSuit(c('JH'), ContractType.allTrump) >
            strengthInSuit(c('AH'), ContractType.allTrump),
        isTrue,
      );
      expect(
        strengthInSuit(c('9C'), ContractType.allTrump) >
            strengthInSuit(c('10C'), ContractType.allTrump),
        isTrue,
      );
    });
  });

  group('card points', () {
    int total(ContractType t) =>
        fullDeck.fold(0, (a, x) => a + cardPoints(x, t));
    test('suit contract totals 152 (+10 last = 162)', () {
      for (final t in [
        ContractType.clubs,
        ContractType.diamonds,
        ContractType.hearts,
        ContractType.spades,
      ]) {
        expect(total(t), 152);
      }
    });
    test(
      'All Trump totals 248 (+10 = 258)',
      () => expect(total(ContractType.allTrump), 248),
    );
    test(
      'No Trump totals 120 (+10 = 130, doubled 260)',
      () => expect(total(ContractType.noTrump), 120),
    );
    test('values per belot.bg table', () {
      expect(cardPoints(c('9S'), ContractType.spades), 14);
      expect(cardPoints(c('JS'), ContractType.spades), 20);
      expect(cardPoints(c('9H'), ContractType.spades), 0);
      expect(cardPoints(c('JH'), ContractType.spades), 2);
      expect(cardPoints(c('AH'), ContractType.noTrump), 11);
      expect(cardPoints(c('KH'), ContractType.allTrump), 4);
    });
  });

  group('trick winner', () {
    test('highest of led suit wins, off-suit cannot win (No Trump)', () {
      expect(
        currentWinner(trickOf(0, '10H AS KH 7H'), ContractType.noTrump),
        0,
      );
      expect(
        currentWinner(trickOf(0, '10H AS AH 7H'), ContractType.noTrump),
        2,
      );
    });
    test('trump beats led suit, highest trump wins', () {
      expect(currentWinner(trickOf(0, 'AH 7S KH 9S'), ContractType.spades), 3);
      expect(currentWinner(trickOf(0, 'AH 7S KH 10H'), ContractType.spades), 1);
    });
    test('All Trump: J of led suit beats ace; off-suit J does not', () {
      expect(
        currentWinner(trickOf(1, 'AH JH 9C 10H'), ContractType.allTrump),
        2,
      );
      expect(
        currentWinner(trickOf(1, 'AH JC 9C 10H'), ContractType.allTrump),
        1,
      );
    });
    test('suit contract: J of non-trump ranks below 10', () {
      expect(currentWinner(trickOf(0, 'JH 10H 7H 8H'), ContractType.clubs), 1);
    });
  });
}
