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
  String get leaveRoomBody =>
      'If a game is running, a bot plays for you and your seat stays reserved until the match ends.';

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
      'A bot will take your seat, which stays reserved for you until the match ends. You can come back any time.';

  @override
  String get botName0 => 'Ivan';

  @override
  String get botLevel => 'Bot difficulty';

  @override
  String get botLevelDescription => 'Default for offline games';

  @override
  String get levelEasy => 'Easy';

  @override
  String get levelMedium => 'Medium';

  @override
  String get levelHard => 'Hard';

  @override
  String get levelEasyHint => 'Simple play, sometimes wrong';

  @override
  String get levelMediumHint => 'Remember cards, play with partner';

  @override
  String get levelHardHint => 'Calculate the possible hands';

  @override
  String get chooseDifficulty => 'Choose difficulty';

  @override
  String get play => 'Play';

  @override
  String get lobbyBotLevel => 'Bots';

  @override
  String get soundSection => 'Sound & feel';

  @override
  String get sound => 'Sound';

  @override
  String get soundDescription => 'Soft sounds for dealing, plays and tricks';

  @override
  String get haptics => 'Haptics';

  @override
  String get hapticsDescription => 'Gentle taps on plays, tricks and contra';

  @override
  String get scoreSheet => 'Sheet';

  @override
  String get scoreSheetTitle => 'Score sheet';

  @override
  String get noTrumpDouble => 'No trumps ×2';

  @override
  String hangingLeft(int points) {
    return '$points hanging';
  }

  @override
  String hangingAwardedLine(int points) {
    return '+$points hanging';
  }

  @override
  String get outsideExplain => 'Made — both teams write their points';

  @override
  String get insideExplain => 'Failed — everything goes to the defenders';

  @override
  String get hangingExplain => 'Tie — the declarers\' points hang';

  @override
  String doubledExplain(String mult, int factor) {
    return '$mult — the stronger team takes all ×$factor';
  }

  @override
  String doubledHangingExplain(String mult, int factor) {
    return '$mult and a tie — everything hangs ×$factor';
  }

  @override
  String get tapToSkip => 'Tap to show everything';

  @override
  String get tapToClose => 'Tap to close';

  @override
  String trickTakenBy(String name) {
    return 'Won by $name';
  }

  @override
  String get recapTab => 'Deal';

  @override
  String get sheetTab => 'Sheet';

  @override
  String playsContract(String name) {
    return '$name plays';
  }

  @override
  String get markInside => 'failed';

  @override
  String get markHanging => 'hanging';

  @override
  String get markValat => 'valat';

  @override
  String get markDouble => 'contra';

  @override
  String get markRedouble => 'recontra';

  @override
  String get matchScore => 'Score';

  @override
  String get emote => 'Emote';

  @override
  String get emotesSection => 'Emotes';

  @override
  String get muteEmotes => 'Hide others\' emotes';

  @override
  String get muteEmotesDescription => 'Don\'t show other players\' reactions';

  @override
  String get emotesCredit =>
      'Animated emoji: Noto Emoji Animation, Google (CC BY 4.0)';

  @override
  String get phraseBravo => 'Bravo!';

  @override
  String get phraseHayde => 'Come on!';

  @override
  String get phraseOops => 'Oops!';

  @override
  String get phraseGg => 'Good game';

  @override
  String get botNamePool =>
      'Stefan,Elena,Dimitar,Victoria,Kaloyan,Iva,Todor,Gabi,Hristo,Vera';

  @override
  String get profile => 'Profile';

  @override
  String get chooseAvatar => 'Choose avatar';

  @override
  String get avatarReserved => '🤖 is reserved for bots';

  @override
  String get editName => 'Edit name';

  @override
  String get filterAll => 'All';

  @override
  String get filterOffline => 'Offline';

  @override
  String get filterOnline => 'Online';

  @override
  String get allLevels => 'All levels';

  @override
  String get statsStreak => 'Win streak';

  @override
  String get statsBestStreak => 'Best streak';

  @override
  String get statsContractsPct => 'Contracts made';

  @override
  String get matchHistory => 'Recent matches';

  @override
  String get historyEmpty => 'No finished matches yet.';

  @override
  String get historyWin => 'Win';

  @override
  String get historyLoss => 'Loss';

  @override
  String historyOffline(String level) {
    return 'Offline · $level';
  }

  @override
  String historyOnline(String code) {
    return 'Online · room $code';
  }

  @override
  String get profileAndStats => 'Profile and stats';

  @override
  String get profileAndStatsDescription => 'Avatar, name, stats and history';

  @override
  String get installTitle => 'Install Belot';

  @override
  String get installSubtitle => 'Full screen, fast and offline.';

  @override
  String get installButton => 'Install';

  @override
  String get installHow => 'How?';

  @override
  String get installIosTitle => 'Add Belot to your Home Screen';

  @override
  String get installIosStep1 => 'Tap “Share” in Safari\'s toolbar.';

  @override
  String get installIosStep2 => 'Choose “Add to Home Screen”.';

  @override
  String get installIosStep3 => 'Tap “Add” — done.';

  @override
  String get installDismiss => 'Hide';

  @override
  String get updateAvailable => 'A new version is available';

  @override
  String get updateNow => 'Update';

  @override
  String get invite => 'Invite';

  @override
  String get inviteTitle => 'Belot invite';

  @override
  String get inviteFailedTitle => 'Can\'t open this invite';

  @override
  String get inviteFailedBody =>
      'The room from this invite is closed or no longer exists. Create a new room or enter another code.';

  @override
  String get inviteInvalidBody =>
      'The code in this link is wrong. Ask your friend for a new invite or type the code.';

  @override
  String declarationUpTo(String name, String suit, String rank) {
    return '$name $suit to $rank';
  }

  @override
  String get roundingTitle => 'Rounding';

  @override
  String roundingInside(int total, int rounded, String team) {
    return 'All $total → $rounded to $team';
  }

  @override
  String roundingHanging(String team, int raw, int rounded, int hang) {
    return '$team: $raw → $rounded; $hang hanging';
  }

  @override
  String roundingMultiplied(
    int total,
    int rounded,
    int factor,
    int result,
    String team,
  ) {
    return 'All $total → $rounded ×$factor = $result to $team';
  }

  @override
  String roundingMultipliedHanging(
    int total,
    int rounded,
    int factor,
    int result,
  ) {
    return 'All $total → $rounded ×$factor = $result hanging';
  }

  @override
  String get tapRowForDetails => 'Tap a deal for details';

  @override
  String dealNumberTitle(int n) {
    return 'Deal $n';
  }

  @override
  String contractBy(String team) {
    return 'Playing: $team';
  }

  @override
  String trickPoints(int points) {
    return '$points points in this trick';
  }

  @override
  String get lastTrickHides => 'Hides when the next card is played';

  @override
  String upTo(String rank) {
    return 'to $rank';
  }

  @override
  String get quickTitle => 'Quick match';

  @override
  String get quickSubtitle => 'Random opponents · rated';

  @override
  String get quickSearching => 'Looking for players…';

  @override
  String quickFound(int n) {
    return 'Players found: $n/4';
  }

  @override
  String quickBotsHint(int s) {
    return 'If not enough people join, bots fill in after $s s.';
  }

  @override
  String get quickStarting => 'Starting…';

  @override
  String get quickCancel => 'Cancel';

  @override
  String get quickFailed => 'Matchmaking failed. Check your connection.';

  @override
  String get quickAgain => 'New quick match';

  @override
  String get goHome => 'Home';

  @override
  String get quickWaitingStart => 'Setting up the table…';

  @override
  String get rating => 'Rating';

  @override
  String get ratingNote => 'Only quick matches change your rating.';

  @override
  String ratingChange(int rating, String delta, String rank) {
    return 'Rating $rating ($delta) · $rank';
  }

  @override
  String get ratingPending => 'Updating rating…';

  @override
  String ratingGames(int n) {
    return 'Quick matches: $n';
  }

  @override
  String get rankNovice => 'Novice';

  @override
  String get rankBronze => 'Bronze';

  @override
  String get rankSilver => 'Silver';

  @override
  String get rankGold => 'Gold';

  @override
  String get rankPlatinum => 'Platinum';

  @override
  String get rankDiamond => 'Diamond';

  @override
  String get rankMaster => 'Master';

  @override
  String get achievements => 'Achievements';

  @override
  String achievementsCount(int n, int total) {
    return '$n of $total';
  }

  @override
  String get achievementUnlocked => 'Achievement unlocked';

  @override
  String get achLocked => 'Locked';

  @override
  String get achFirstWin => 'First win';

  @override
  String get achFirstWinDesc => 'Win a match.';

  @override
  String get achWins10 => '10 wins';

  @override
  String get achWins10Desc => 'Win 10 matches.';

  @override
  String get achWins50 => '50 wins';

  @override
  String get achWins50Desc => 'Win 50 matches.';

  @override
  String get achWins100 => '100 wins';

  @override
  String get achWins100Desc => 'Win 100 matches.';

  @override
  String get achCapot => 'Capot';

  @override
  String get achCapotDesc => 'Your team takes every trick.';

  @override
  String get achBelot => 'Belot!';

  @override
  String get achBelotDesc => 'Announce a belot.';

  @override
  String get achSquare => 'Four of a kind';

  @override
  String get achSquareDesc => 'Declare a square that scores.';

  @override
  String get achQuint => 'Quint';

  @override
  String get achQuintDesc => 'Declare a quint that scores.';

  @override
  String get achNoTrump => 'No trumps';

  @override
  String get achNoTrumpDesc => 'Make a no-trump contract your team called.';

  @override
  String get achAllTrump => 'All trumps';

  @override
  String get achAllTrumpDesc => 'Make an all-trump contract your team called.';

  @override
  String get achContra => 'Well doubled';

  @override
  String get achContraDesc => 'Double the opponents and beat their contract.';

  @override
  String get achRecontra => 'Redoubled';

  @override
  String get achRecontraDesc => 'Make a redoubled contract.';

  @override
  String get achComeback => 'Comeback';

  @override
  String get achComebackDesc => 'Win a match after trailing by 50+ points.';

  @override
  String get achBeatHard => 'Beat the best';

  @override
  String get achBeatHardDesc => 'Beat the hard bots.';

  @override
  String get achFirstQuick => 'First quick match';

  @override
  String get achFirstQuickDesc => 'Finish a quick match.';

  @override
  String get achRankGold => 'Gold rank';

  @override
  String get achRankGoldDesc => 'Reach a 1200 rating (Gold).';

  @override
  String get resumeTitle => 'Back to your game';

  @override
  String resumeBody(String code) {
    return 'Your seat in room $code is waiting — a bot is playing for you.';
  }

  @override
  String get resumeJoin => 'Rejoin';

  @override
  String get resumeDismiss => 'Not now';

  @override
  String get tableSection => 'Table & cards';

  @override
  String get cardBack => 'Card back';

  @override
  String get tableColor => 'Table colour';

  @override
  String get backClassic => 'Classic';

  @override
  String get backMidnight => 'Midnight';

  @override
  String get backForest => 'Forest';

  @override
  String get backMono => 'Minimal';

  @override
  String get tableClassic => 'Classic';

  @override
  String get tableFelt => 'Felt';

  @override
  String get tableWine => 'Burgundy';

  @override
  String get tableSlate => 'Slate';

  @override
  String get languageEnglish => 'English';

  @override
  String get ratingUnratedBots => 'Unrated — game against bots';

  @override
  String ratingUnratedShort(int min) {
    return 'Unrated — the match lasted less than $min minutes';
  }

  @override
  String get ratingUnratedFailed => 'Unrated — the result could not be saved';

  @override
  String get ratingDailyCap => 'daily limit';

  @override
  String ratingRepeat(int n, int pct) {
    return 'same opponents, game #$n in 24 h → $pct%';
  }

  @override
  String ratingLimitNote(String delta, String why) {
    return '$delta ($why)';
  }

  @override
  String ratingReducedNote(String delta, String raw, String why) {
    return '$delta instead of $raw ($why)';
  }

  @override
  String get quickUnratedChip => 'Unrated · vs bots';

  @override
  String get quickUnratedHint => 'If nobody joins, you play bots — unrated.';

  @override
  String ratingRules(int min, int cap) {
    return 'Only quick matches with humans on both teams that last at least $min minutes are rated. At most +$cap per day; against the same opponents within 24 h the change shrinks (100%, 50%, 25%, 0%).';
  }
}
