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
  String get homeOfflineSubtitle => 'Play with bots';

  @override
  String get homeOnlineTitle => 'Play with friends';

  @override
  String get homeOnlineSubtitle => 'Room with a code';

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
  String get partner => 'Partner';

  @override
  String get opponent => 'Opponent';

  @override
  String get stats => 'Statistics';

  @override
  String get statsMatches => 'Matches';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsWinRate => 'Win rate';

  @override
  String get statsDeals => 'Deals';

  @override
  String get statsAvgPoints => 'Avg points per deal';

  @override
  String get statsContracts => 'Contracts made';

  @override
  String get statsValats => 'Valats';

  @override
  String get statsEmpty => 'Play your first match to see statistics.';

  @override
  String get statsSubtitle => 'Your performance';

  @override
  String get statsReset => 'Reset statistics';

  @override
  String get namePromptTitle => 'What should we call you?';

  @override
  String get namePromptSubtitle =>
      'Your name is shown at the table and in statistics.';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'e.g. George';

  @override
  String get nameErrorEmpty => 'Enter a name';

  @override
  String get nameErrorShort => 'At least 2 characters';

  @override
  String get nameErrorLong => 'At most 16 characters';

  @override
  String get nameErrorChars => 'Letters, digits, space and . - _ only';

  @override
  String get continueLabel => 'Continue';

  @override
  String get save => 'Save';

  @override
  String get playerName => 'Player name';

  @override
  String get changeName => 'Change name';

  @override
  String get hints => 'Hints';

  @override
  String get hintsDescription =>
      'Suggests a card after 25 seconds of inactivity';

  @override
  String get hintLabel => 'Hint';

  @override
  String greeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get gameplay => 'Gameplay';

  @override
  String get teamUs => 'Us';

  @override
  String get teamThem => 'Them';

  @override
  String get statsResetConfirm => 'Reset';

  @override
  String get readyWaiting => 'Waiting for the others…';

  @override
  String get backToLobby => 'Back to lobby';

  @override
  String get autoPlay => 'Auto-play';

  @override
  String get autoPlayDescription =>
      'Plays the hinted card after 40 seconds (passes when bidding)';

  @override
  String get onlineTitle => 'Play with friends';

  @override
  String get createRoom => 'Create room';

  @override
  String get createRoomSubtitle => 'Get a code to share';

  @override
  String get joinRoom => 'Join with code';

  @override
  String get joinRoomSubtitle => 'Enter a friend\'s code';

  @override
  String get roomCode => 'Room code';

  @override
  String get roomCodeShort => 'Room';

  @override
  String get joinAction => 'Join';

  @override
  String get codeCopied => 'Invite copied';

  @override
  String get tapToCopy => 'Tap to copy the invite';

  @override
  String shareText(String code, String link) {
    return 'Let\'s play Belot! Room code: $code\n$link';
  }

  @override
  String get team1 => 'Team 1';

  @override
  String get team2 => 'Team 2';

  @override
  String get joinTeam => 'Join';

  @override
  String get emptySlot => 'Free seat';

  @override
  String get botPlayer => 'Bot';

  @override
  String get hostLabel => 'host';

  @override
  String get youLabel => 'you';

  @override
  String get addBots => 'Fill with bots';

  @override
  String get startGame => 'Start game';

  @override
  String get waitingForHost => 'Waiting for the host to start…';

  @override
  String get needEachTeam => 'Each team needs at least one person';

  @override
  String get needFullTeams =>
      'Fill the free seats with bots or wait for more players';

  @override
  String get noTeamYet => 'Pick a team';

  @override
  String get spectators => 'No team';

  @override
  String get leaveRoom => 'Leave room';

  @override
  String get leaveRoomTitle => 'Leave the room?';

  @override
  String get leaveRoomBody => 'If a game is running, a bot will play for you.';

  @override
  String get roomNotFound => 'No room with this code';

  @override
  String get roomClosed => 'The room is closed';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connectionError => 'Cannot reach the server. Try again.';

  @override
  String get invalidCode => 'The code has 5 characters';

  @override
  String get waitingTitle => 'A game is running';

  @override
  String get waitingBody =>
      'You will take a bot\'s seat when the current deal ends.';

  @override
  String get waitingNoSeat =>
      'All seats are taken by people. You can play in the next game.';

  @override
  String get chooseTeam => 'Choose a team';

  @override
  String seatsWithBots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bot seats',
      one: '1 bot seat',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Back';

  @override
  String get players => 'Players';

  @override
  String get retry => 'Try again';

  @override
  String seatLeftBot(String name) {
    return '$name left, a bot took the seat';
  }

  @override
  String seatBack(String name) {
    return '$name is back';
  }

  @override
  String seatJoined(String name) {
    return '$name took the bot\'s seat';
  }

  @override
  String get leaveOnlineGameTitle => 'Leave the game?';

  @override
  String get leaveOnlineGameBody =>
      'A bot will take your seat. You can come back with the same code until the deal ends.';

  @override
  String get botName0 => 'Ivan';
}
