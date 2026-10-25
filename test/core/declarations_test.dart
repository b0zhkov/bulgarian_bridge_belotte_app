import 'package:bulgarian_bridge_belotte_app/core/rules/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

List<Declaration> find(
  String hand, [
  ContractType t = ContractType.hearts,
  int seat = 0,
]) => findDeclarations(cs(hand), t, seat);

int pts(List<Declaration> ds) => ds.fold(0, (a, d) => a + d.points);

void main() {
  group('finding declarations', () {
    test('tierce / quarte / quint', () {
      expect(
        find('7C 8C 9C AD KH 10S QS 8D').single.type,
        DeclarationType.tierce,
      );
      expect(
        find('10C JC QC KC AD 8H 10S 7D').single.type,
        DeclarationType.quarte,
      );
      expect(
        find('10C JC QC KC AC 8H 10S 7D').single.type,
        DeclarationType.quint,
      );
      expect(pts(find('10C JC QC KC AC 8H 10S 7D')), 100);
    });
    test(
      'sequence uses natural order 7-8-9-10-J-Q-K-A (9-10-J is a tierce)',
      () {
        expect(
          find('9D 10D JD 7C AH KS 8S QH').single.type,
          DeclarationType.tierce,
        );
      },
    );
    test('non-consecutive or mixed suits are not sequences', () {
      expect(find('7C 8D 9C JC QH KS AS 8H'), isEmpty);
    });
    test('six-card run counts as a quint', () {
      final d = find('9S 10S JS QS KS AS 7H 8D');
      expect(d.single.type, DeclarationType.quint);
      expect(d.single.highRank, Rank.ace);
    });
    test('eight-card run is a quint plus a tierce', () {
      final d = find('7S 8S 9S 10S JS QS KS AS');
      expect(d.map((e) => e.type).toSet(), {
        DeclarationType.quint,
        DeclarationType.tierce,
      });
      expect(pts(d), 120);
    });
    test('two sequences in different suits', () {
      expect(pts(find('7C 8C 9C 10H JH QH KH 7D')), 70);
    });
    test('squares: J=200, 9=150, A/10/K/Q=100', () {
      expect(pts(find('JC JD JH JS 7C 8D 10H QS')), 200);
      expect(pts(find('9C 9D 9H 9S 7C 8D QH AS')), 150);
      for (final r in ['A', '10', 'K', 'Q']) {
        expect(
          pts(find('${r}C ${r}D ${r}H ${r}S 7C 8D 7H 8S')),
          100,
          reason: r,
        );
      }
    });
    test('four 7s or 8s are not a square', () {
      expect(
        find('7C 7D 7H 7S 8C 8D 8H 8S').where((d) => !d.isSequence),
        isEmpty,
      );
    });
    test('No Trump allows no declarations', () {
      expect(find('JC JD JH JS 7C 8C 9C 10C', ContractType.noTrump), isEmpty);
    });
    test('All Trump allows declarations', () {
      expect(pts(find('JC JD JH JS 7D 8D 10H QS', ContractType.allTrump)), 200);
    });
    test('card in both square and sequence: best total chosen (square)', () {
      // JC JD JH JS + QC KC: square of J (200) beats tierce J-Q-K (20).
      final d = find('JC JD JH JS QC KC 7H 8S');
      expect(d.single.type, DeclarationType.square);
      expect(pts(d), 200);
    });
    test('card in both: quint + ... vs square chooses higher total', () {
      // 9C..KC quint (100) vs square of Qs (100) using QC: quint 9-K = 100,
      // square Q + tierce 9-10-J = 120 -> square + tierce chosen.
      final d = find('9C 10C JC QC KC QD QH QS');
      expect(pts(d), 120);
      expect(d.any((x) => x.type == DeclarationType.square), isTrue);
    });
    test('non-overlapping square and sequence both declared', () {
      expect(pts(find('AC AD AH AS 7C 8C 9C 10D')), 120);
    });
  });

  Declaration seq(String cards, int seat) {
    final list = cs(cards);
    final t = {
      3: DeclarationType.tierce,
      4: DeclarationType.quarte,
      5: DeclarationType.quint,
    }[list.length]!;
    return Declaration(t, list, seat);
  }

  Declaration sq(String rank, int seat) => Declaration(
    DeclarationType.square,
    cs('${rank}C ${rank}D ${rank}H ${rank}S'),
    seat,
  );

  group('comparing declarations between teams', () {
    test('longer sequence wins, only that team scores sequences', () {
      final r = resolveDeclarations([
        seq('7C 8C 9C 10C', 0),
        seq('JH QH KH', 1),
        seq('7D 8D 9D', 2),
      ]);
      expect(r.every((d) => teamOf(d.seat) == 0), isTrue);
      expect(pts(r), 70); // team 0 also scores the second tierce
    });
    test('equal length: higher top card wins', () {
      final r = resolveDeclarations([seq('7C 8C 9C', 0), seq('QH KH AH', 1)]);
      expect(r.single.seat, 1);
    });
    test('quarte beats a higher tierce', () {
      final r = resolveDeclarations([
        seq('7C 8C 9C 10C', 1),
        seq('QH KH AH', 0),
      ]);
      expect(r.single.seat, 1);
    });
    test('equal best sequences cancel all sequences of both teams', () {
      final r = resolveDeclarations([
        seq('QC KC AC', 0),
        seq('7D 8D 9D', 2),
        seq('QH KH AH', 1),
      ]);
      expect(r, isEmpty);
    });
    test('team with stronger square scores all its squares', () {
      final r = resolveDeclarations([sq('A', 0), sq('9', 1), sq('K', 2)]);
      expect(r.single.seat, 1);
      expect(pts(r), 150);
    });
    test('square of J beats square of 9; among 100s A > 10 > K > Q', () {
      expect(resolveDeclarations([sq('9', 0), sq('J', 1)]).single.seat, 1);
      expect(resolveDeclarations([sq('10', 0), sq('A', 1)]).single.seat, 1);
      expect(resolveDeclarations([sq('10', 0), sq('K', 1)]).single.seat, 0);
      expect(resolveDeclarations([sq('Q', 0), sq('K', 1)]).single.seat, 1);
    });
    test('squares do not cancel sequences', () {
      final r = resolveDeclarations([sq('A', 0), seq('7C 8C 9C', 1)]);
      expect(pts(r), 120);
      expect(r.map((d) => d.seat).toSet(), {0, 1});
    });
    test('partners sequences do not compete with each other', () {
      final r = resolveDeclarations([seq('7C 8C 9C', 0), seq('QH KH AH', 2)]);
      expect(r.length, 2);
    });
  });

  group('belot', () {
    test('trump K with Q in hand, on lead', () {
      expect(
        isBelotPlay(
          card: c('KS'),
          hand: cs('KS QS 7H'),
          trick: Trick(0),
          type: ContractType.spades,
        ),
        isTrue,
      );
    });
    test('requires the other card in hand', () {
      expect(
        isBelotPlay(
          card: c('KS'),
          hand: cs('KS 7H'),
          trick: Trick(0),
          type: ContractType.spades,
        ),
        isFalse,
      );
    });
    test('non-trump K+Q is not belot in a suit contract', () {
      expect(
        isBelotPlay(
          card: c('KH'),
          hand: cs('KH QH'),
          trick: Trick(0),
          type: ContractType.spades,
        ),
        isFalse,
      );
    });
    test('suit contract: counts when trumping', () {
      expect(
        isBelotPlay(
          card: c('QS'),
          hand: cs('KS QS'),
          trick: trickOf(1, 'AH'),
          type: ContractType.spades,
        ),
        isTrue,
      );
    });
    test('All Trump: any suit, when leading or following', () {
      expect(
        isBelotPlay(
          card: c('QH'),
          hand: cs('KH QH'),
          trick: Trick(0),
          type: ContractType.allTrump,
        ),
        isTrue,
      );
      expect(
        isBelotPlay(
          card: c('QH'),
          hand: cs('KH QH'),
          trick: trickOf(1, '7H'),
          type: ContractType.allTrump,
        ),
        isTrue,
      );
    });
    test('All Trump: discarding on another suit is not belot', () {
      expect(
        isBelotPlay(
          card: c('QH'),
          hand: cs('KH QH'),
          trick: trickOf(1, '7C'),
          type: ContractType.allTrump,
        ),
        isFalse,
      );
    });
    test('No Trump: never belot', () {
      expect(
        isBelotPlay(
          card: c('QH'),
          hand: cs('KH QH'),
          trick: Trick(0),
          type: ContractType.noTrump,
        ),
        isFalse,
      );
    });
  });
}
