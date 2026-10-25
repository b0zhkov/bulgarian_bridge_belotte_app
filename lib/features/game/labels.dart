import 'package:flutter/material.dart' hide Card;

import '../../core/agents/bot_names.dart';
import '../../core/constants/game_constants.dart';
import '../../core/rules/rules.dart';
import '../../core/widgets/suit_icon.dart';
import '../../l10n/generated/app_localizations.dart';

class SeatInfo {
  const SeatInfo(this.emoji, this.name, [this.tag]);
  final String emoji;
  final String name;

  /// Small extra shown after the name (quick match: the rating).
  final String? tag;
}

String _stringsLocale = 'bg';

/// Keeps [appStrings] in the app's language (set by `main.dart`).
void setAppStringsLocale(String code) => _stringsLocale = code;

/// Strings outside a widget tree (controllers), in the app's language.
AppLocalizations appStrings() => lookupAppLocalizations(Locale(_stringsLocale));

/// Bot names for the four absolute seats, avoiding [humans]' names.
List<String> botNames(
  AppLocalizations l, [
  Iterable<String> humans = const [],
]) => pickBotNames(
  [l.botName0, l.botName1, l.botName2, l.botName3],
  l.botNamePool.split(','),
  humans,
);

/// THE single place that decides what a bot is called and how it looks
/// (offline opponents, lobby bots, bots holding an online seat), by
/// absolute [seat]: plain names, unique per seat and never a human's name
/// in the room ([humans]), always the robot avatar.
SeatInfo botSeatInfo(
  AppLocalizations l,
  int seat, [
  Iterable<String> humans = const [],
]) => SeatInfo(kBotAvatar, botNames(l, humans)[seat % 4]);

SeatInfo seatInfo(
  AppLocalizations l,
  int seat, [
  String? myName,
  String? myAvatar,
]) => switch (seat) {
  0 => SeatInfo(humanAvatar(myAvatar ?? kSelfAvatar), myName ?? l.you),
  _ => botSeatInfo(l, seat, [?myName]),
};

/// Offline table: me at seat 0, bots elsewhere.
List<SeatInfo> offlineSeatInfos(
  AppLocalizations l,
  String? myName,
  String? myAvatar,
) => [for (var s = 0; s < 4; s++) seatInfo(l, s, myName, myAvatar)];

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

/// One declaration with its cards: "Терца ♥ до A", "Каре J".
String declarationDetail(AppLocalizations l, Declaration d) {
  final name = declarationName(l, d);
  if (d.type == DeclarationType.square) {
    return '$name ${d.cards.isEmpty ? '' : d.cards.first.rank.label}'.trim();
  }
  if (d.cards.isEmpty) return name;
  return l.declarationUpTo(name, d.suit!.glyph, d.highRank.label);
}

String teamName(AppLocalizations l, int team) => team == 0 ? l.us : l.them;

/// How the raw points were rounded into match points (belot.bg):
/// "Ние 96 → 9 · Вие 66 → 7", "Общо 162 → 16 за Вие", …
String roundingText(AppLocalizations l, DealScore d) {
  final r = d.rounding;
  final dt = d.contract.declarerTeam;
  final ot = 1 - dt;
  if (r.multiplied) {
    final res = r.roundedTotal * r.factor;
    if (r.outcome == DealOutcome.hanging) {
      return l.roundingMultipliedHanging(
        r.total,
        r.roundedTotal,
        r.factor,
        res,
      );
    }
    final winner = r.raw[0] > r.raw[1] ? 0 : 1;
    return l.roundingMultiplied(
      r.total,
      r.roundedTotal,
      r.factor,
      res,
      teamName(l, winner),
    );
  }
  return switch (r.outcome) {
    DealOutcome.outside => [
      for (var t = 0; t < 2; t++)
        '${teamName(l, t)} ${r.raw[t]} → ${r.rounded[t]}',
    ].join(' · '),
    DealOutcome.inside => l.roundingInside(
      r.total,
      r.roundedTotal,
      teamName(l, ot),
    ),
    DealOutcome.hanging => l.roundingHanging(
      teamName(l, ot),
      r.raw[ot],
      r.rounded[ot],
      r.hanging,
    ),
  };
}

/// One line explaining the outcome (изкарана / вкарана / висяща, контра…).
String outcomeExplain(AppLocalizations l, DealScore d) {
  final mult = d.contract.multiplier;
  if (mult != Multiplier.none) {
    final name = mult == Multiplier.doubled ? l.double : l.redouble;
    return d.outcome == DealOutcome.hanging
        ? l.doubledHangingExplain(name, mult.factor)
        : '${outcomeLabel(l, d)} · ${l.doubledExplain(name, mult.factor)}';
  }
  return switch (d.outcome) {
    DealOutcome.outside => l.outsideExplain,
    DealOutcome.inside => l.insideExplain,
    DealOutcome.hanging => l.hangingExplain,
  };
}

/// A row of a deal's breakdown: label, optional sub-label, points per team.
class BreakdownRow {
  const BreakdownRow(
    this.key,
    this.label,
    this.points, {
    this.sub,
    this.subTeam,
    this.suit,
    this.tail,
  });
  final String key;
  final String label;
  final List<int> points;
  final String? sub;

  /// Declarations: the suit (drawn as an icon after [label]) and the top
  /// card ("до A") or the square's rank.
  final Suit? suit;
  final String? tail;

  /// Colours [sub] (e.g. the declaration's owner) in that team's colour.
  final int? subTeam;
}

/// The engine's breakdown as display rows, with every scoring declaration on
/// its own line in its owner's column. Rows add up to the raw points.
List<BreakdownRow> breakdownRows(
  AppLocalizations l,
  DealScore d, {
  String Function(int seat)? nameOf,
}) {
  final rows = <BreakdownRow>[];
  for (final line in d.breakdown) {
    switch (line.step) {
      case ScoreStep.cards:
        rows.add(BreakdownRow('cards', l.cardPoints, line.points));
      case ScoreStep.lastTen:
        rows.add(BreakdownRow('lastTen', l.lastTen, line.points));
      case ScoreStep.declarations:
        for (final (i, x) in d.scoringDeclarations.indexed) {
          final team = teamOf(x.seat);
          final square = x.type == DeclarationType.square;
          rows.add(
            BreakdownRow(
              'decl$i',
              declarationName(l, x),
              suit: square ? null : x.suit,
              tail: x.cards.isEmpty
                  ? null
                  : (square
                        ? x.cards.first.rank.label
                        : l.upTo(x.highRank.label)),
              [for (var t = 0; t < 2; t++) t == team ? x.points : 0],
              sub: nameOf?.call(x.seat) ?? teamName(l, team),
              subTeam: team,
            ),
          );
        }
      case ScoreStep.belot:
        for (var t = 0; t < 2; t++) {
          final n = d.belotPoints[t] ~/ kBelotBonus;
          if (n == 0) continue;
          rows.add(
            BreakdownRow(
              'belot$t',
              n > 1 ? '${l.belot} ×$n' : l.belot,
              [for (var u = 0; u < 2; u++) u == t ? d.belotPoints[t] : 0],
              sub: teamName(l, t),
              subTeam: t,
            ),
          );
        }
      case ScoreStep.noTrumpDouble:
        rows.add(BreakdownRow('noTrumpDouble', l.noTrumpDouble, line.points));
      case ScoreStep.valat:
        rows.add(BreakdownRow('valat', l.valat, line.points));
    }
  }
  return rows;
}

/// A breakdown row's label: text, the suit icon and the top card.
class BreakdownLabel extends StatelessWidget {
  const BreakdownLabel(
    this.row, {
    super.key,
    required this.style,
    required this.color,
    required this.red,
    this.trailing,
  });
  final BreakdownRow row;
  final TextStyle style;
  final Color color;
  final Color red;

  /// Extra span after the label (e.g. the owner's name).
  final InlineSpan? trailing;

  @override
  Widget build(BuildContext context) {
    final suit = row.suit;
    final size = (style.fontSize ?? 14) * 0.95;
    return Text.rich(
      TextSpan(
        text: row.label,
        children: [
          if (suit != null) ...[
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SuitIcon(
                suit,
                size: size,
                color: suit.isRed ? red : color,
              ),
            ),
          ],
          if (row.tail != null) TextSpan(text: ' ${row.tail}'),
          ?trailing,
        ],
      ),
      style: style,
    );
  }
}
