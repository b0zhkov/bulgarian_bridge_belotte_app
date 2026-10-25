// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Belot';

  @override
  String get homeOfflineTitle => 'Offline game';

  @override
  String get homeOfflineSubtitle => 'Play against three computer players';

  @override
  String get homeOnlineTitle => 'Play with friends';

  @override
  String get homeOnlineSubtitle => 'Room code · coming soon';

  @override
  String get homeRulesTitle => 'Rules';

  @override
  String get homeRulesSubtitle => 'As on belot.bg';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get language => 'Language';

  @override
  String get languageBulgarian => 'Bulgarian';

  @override
  String get you => 'You';

  @override
  String get us => 'Us';

  @override
  String get them => 'Them';

  @override
  String get botName1 => 'Niki';

  @override
  String get botName2 => 'Maria';

  @override
  String get botName3 => 'Peter';

  @override
  String get pass => 'Pass';

  @override
  String get clubs => 'Clubs';

  @override
  String get diamonds => 'Diamonds';

  @override
  String get hearts => 'Hearts';

  @override
  String get spades => 'Spades';

  @override
  String get noTrump => 'No trump';

  @override
  String get allTrump => 'All trump';

  @override
  String get double => 'Double';

  @override
  String get redouble => 'Redouble';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get yourBid => 'Your bid';

  @override
  String waitingFor(String name) {
    return '$name is thinking…';
  }

  @override
  String get bidding => 'Bidding';

  @override
  String get contract => 'Contract';

  @override
  String get dealer => 'D';

  @override
  String hanging(int points) {
    return 'Hanging: $points';
  }

  @override
  String get allPassed => 'Everyone passed — redealing';

  @override
  String get tierce => 'Tierce';

  @override
  String get quarte => 'Quarte';

  @override
  String get quint => 'Quint';

  @override
  String get square => 'Square';

  @override
  String get belot => 'Belot';

  @override
  String get outside => 'Made';

  @override
  String get inside => 'Inside';

  @override
  String get hangingOutcome => 'Hanging';

  @override
  String get valat => 'Valat';

  @override
  String get dealResult => 'Deal result';

  @override
  String get cardPoints => 'Cards';

  @override
  String get premiums => 'Premiums';

  @override
  String get lastTen => 'Last 10';

  @override
  String get total => 'Total';

  @override
  String get written => 'Written';

  @override
  String get nextDeal => 'Next deal';

  @override
  String get newMatch => 'New match';

  @override
  String get matchWon => 'Victory!';

  @override
  String get matchLost => 'Defeat';

  @override
  String finalScore(int us, int them) {
    return 'Final score $us : $them';
  }

  @override
  String get history => 'History';

  @override
  String get noDealsYet => 'No deals played yet';

  @override
  String deal(int n) {
    return 'Deal $n';
  }

  @override
  String get lastTrick => 'Last trick';

  @override
  String get leaveMatchTitle => 'Leave the match?';

  @override
  String get leaveMatchBody => 'The current match will be lost.';

  @override
  String get leave => 'Leave';

  @override
  String get cancel => 'Cancel';

  @override
  String get comingSoon => 'Soon';

  @override
  String get rulesBody =>
      '32 cards from 7 to ace, two against two, counter-clockwise. 3+2 cards are dealt, then bidding (clubs, diamonds, hearts, spades, no trump, all trump, double, redouble) and 3 more cards. Declarations are announced automatically with the first card. The match is played to 151. A match cannot be won with a valat.';
}
