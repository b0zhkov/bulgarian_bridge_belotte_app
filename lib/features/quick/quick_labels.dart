import '../../l10n/generated/app_localizations.dart';
import '../../online/rating.dart';
import '../achievements/achievements.dart';

String rankName(AppLocalizations l, RatingRank r) => switch (r) {
  RatingRank.novice => l.rankNovice,
  RatingRank.bronze => l.rankBronze,
  RatingRank.silver => l.rankSilver,
  RatingRank.gold => l.rankGold,
  RatingRank.platinum => l.rankPlatinum,
  RatingRank.diamond => l.rankDiamond,
  RatingRank.master => l.rankMaster,
};

/// "+12", "−8", "±0".
String signed(int d) => d > 0 ? '+$d' : (d < 0 ? '−${-d}' : '±0');

String achievementName(AppLocalizations l, Achievement a) => switch (a) {
  Achievement.firstWin => l.achFirstWin,
  Achievement.wins10 => l.achWins10,
  Achievement.wins50 => l.achWins50,
  Achievement.wins100 => l.achWins100,
  Achievement.capot => l.achCapot,
  Achievement.belot => l.achBelot,
  Achievement.square => l.achSquare,
  Achievement.quint => l.achQuint,
  Achievement.noTrumpMade => l.achNoTrump,
  Achievement.allTrumpMade => l.achAllTrump,
  Achievement.contraWon => l.achContra,
  Achievement.recontraMade => l.achRecontra,
  Achievement.comeback => l.achComeback,
  Achievement.beatHard => l.achBeatHard,
  Achievement.firstQuick => l.achFirstQuick,
  Achievement.rankGold => l.achRankGold,
};

String achievementDesc(AppLocalizations l, Achievement a) => switch (a) {
  Achievement.firstWin => l.achFirstWinDesc,
  Achievement.wins10 => l.achWins10Desc,
  Achievement.wins50 => l.achWins50Desc,
  Achievement.wins100 => l.achWins100Desc,
  Achievement.capot => l.achCapotDesc,
  Achievement.belot => l.achBelotDesc,
  Achievement.square => l.achSquareDesc,
  Achievement.quint => l.achQuintDesc,
  Achievement.noTrumpMade => l.achNoTrumpDesc,
  Achievement.allTrumpMade => l.achAllTrumpDesc,
  Achievement.contraWon => l.achContraDesc,
  Achievement.recontraMade => l.achRecontraDesc,
  Achievement.comeback => l.achComebackDesc,
  Achievement.beatHard => l.achBeatHardDesc,
  Achievement.firstQuick => l.achFirstQuickDesc,
  Achievement.rankGold => l.achRankGoldDesc,
};
