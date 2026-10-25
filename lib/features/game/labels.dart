import 'package:flutter/material.dart' hide Card;

import '../../core/rules/rules.dart';
import '../../core/widgets/suit_icon.dart';
import '../../l10n/generated/app_localizations.dart';

class SeatInfo {
  const SeatInfo(this.emoji, this.name);
  final String emoji;
  final String name;
}

SeatInfo seatInfo(AppLocalizations l, int seat, [String? myName]) =>
    switch (seat) {
      0 => SeatInfo('🙂', myName ?? l.you),
      1 => SeatInfo('🐼', l.botName1),
      2 => SeatInfo('🦊', l.botName2),
      _ => SeatInfo('🧙', l.botName3),
    };

String contractName(AppLocalizations l, ContractType t) => switch (t) {
  ContractType.clubs => l.clubs,
  ContractType.diamonds => l.diamonds,
  ContractType.hearts => l.hearts,
  ContractType.spades => l.spades,
  ContractType.noTrump => l.noTrump,
  ContractType.allTrump => l.allTrump,
};

/// Short symbol for chips: ♣ ♦ ♥ ♠ БК ВК.
String contractShort(AppLocalizations l, ContractType t) => switch (t) {
  ContractType.noTrump => l.localeName == 'bg' ? 'БК' : 'NT',
  ContractType.allTrump => l.localeName == 'bg' ? 'ВК' : 'AT',
  _ => t.trumpSuit!.glyph,
};

String bidLabel(AppLocalizations l, Bid b) => switch (b.kind) {
  BidKind.pass => l.pass,
  BidKind.double => l.double,
  BidKind.redouble => l.redouble,
  BidKind.contract => contractName(l, b.type!),
};

String declarationName(AppLocalizations l, Declaration d) => switch (d.type) {
  DeclarationType.tierce => l.tierce,
  DeclarationType.quarte => l.quarte,
  DeclarationType.quint => l.quint,
  DeclarationType.square => l.square,
};

String announcementText(AppLocalizations l, Announcement a) => [
  for (final d in a.declarations) declarationName(l, d),
  if (a.belot) l.belot,
].join(' · ');

String multiplierSuffix(AppLocalizations l, Multiplier m) => switch (m) {
  Multiplier.none => '',
  Multiplier.doubled => ' · ${l.double}',
  Multiplier.redoubled => ' · ${l.redouble}',
};

String outcomeLabel(AppLocalizations l, DealScore d) {
  final base = switch (d.outcome) {
    DealOutcome.outside => l.outside,
    DealOutcome.inside => l.inside,
    DealOutcome.hanging => l.hangingOutcome,
  };
  return d.isValat ? '$base · ${l.valat}' : base;
}

/// Hand sorted for display: suits alternate colour, cards strongest first.
List<Card> sortHand(List<Card> hand, ContractType? type) {
  const suitOrder = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];
  final t = type ?? ContractType.noTrump;
  final list = List.of(hand);
  list.sort((a, b) {
    final s = suitOrder.indexOf(a.suit).compareTo(suitOrder.indexOf(b.suit));
    if (s != 0) return s;
    return strengthInSuit(b, t).compareTo(strengthInSuit(a, t));
  });
  return list;
}

/// Suit icon for suit contracts, БК / ВК text otherwise.
class ContractGlyph extends StatelessWidget {
  const ContractGlyph(
    this.type, {
    super.key,
    this.size = 18,
    required this.color,
    this.red,
  });
  final ContractType type;
  final double size;
  final Color color;
  final Color? red;

  @override
  Widget build(BuildContext context) {
    final suit = type.trumpSuit;
    if (suit != null) {
      return SuitIcon(
        suit,
        size: size,
        color: suit.isRed && red != null ? red! : color,
      );
    }
    return Text(
      contractShort(AppLocalizations.of(context), type),
      style: TextStyle(
        color: color,
        fontSize: size * 0.72,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    );
  }
}
