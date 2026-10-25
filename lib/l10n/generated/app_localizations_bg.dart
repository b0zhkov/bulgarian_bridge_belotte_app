// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'Белот';

  @override
  String get homeOfflineTitle => 'Офлайн игра';

  @override
  String get homeOfflineSubtitle => 'Игра с ботове';

  @override
  String get homeOnlineTitle => 'Игра с приятели';

  @override
  String get homeOnlineSubtitle => 'Стая с код';

  @override
  String get settings => 'Настройки';

  @override
  String get theme => 'Тема';

  @override
  String get themeDark => 'Тъмна';

  @override
  String get themeLight => 'Светла';

  @override
  String get language => 'Език';

  @override
  String get languageBulgarian => 'Български';

  @override
  String get you => 'Ти';

  @override
  String get us => 'Ние';

  @override
  String get them => 'Вие';

  @override
  String get botName1 => 'Ники';

  @override
  String get botName2 => 'Мария';

  @override
  String get botName3 => 'Петър';

  @override
  String get pass => 'Пас';

  @override
  String get clubs => 'Спатия';

  @override
  String get diamonds => 'Каро';

  @override
  String get hearts => 'Купа';

  @override
  String get spades => 'Пика';

  @override
  String get noTrump => 'Без коз';

  @override
  String get allTrump => 'Всичко коз';

  @override
  String get double => 'Контра';

  @override
  String get redouble => 'Реконтра';

  @override
  String get yourTurn => 'Твой ред';

  @override
  String get yourBid => 'Твой ред за обява';

  @override
  String waitingFor(String name) {
    return '$name мисли…';
  }

  @override
  String get bidding => 'Наддаване';

  @override
  String get contract => 'Игра';

  @override
  String get dealer => 'Р';

  @override
  String hanging(int points) {
    return 'Висящи: $points';
  }

  @override
  String get allPassed => 'Всички пасуваха — ново раздаване';

  @override
  String get tierce => 'Терца';

  @override
  String get quarte => 'Кварта';

  @override
  String get quint => 'Квинта';

  @override
  String get square => 'Каре';

  @override
  String get belot => 'Белот';

  @override
  String get outside => 'Изкарана';

  @override
  String get inside => 'Вкарана';

  @override
  String get hangingOutcome => 'Висяща';

  @override
  String get valat => 'Капо';

  @override
  String get dealResult => 'Резултат от раздаването';

  @override
  String get cardPoints => 'Карти';

  @override
  String get premiums => 'Анонси';

  @override
  String get lastTen => 'Последни 10';

  @override
  String get total => 'Общо';

  @override
  String get written => 'Записани';

  @override
  String get nextDeal => 'Следваща раздавка';

  @override
  String get newMatch => 'Нова игра';

  @override
  String get matchWon => 'Победа!';

  @override
  String get matchLost => 'Загуба';

  @override
  String finalScore(int us, int them) {
    return 'Краен резултат $us : $them';
  }

  @override
  String get history => 'История';

  @override
  String get noDealsYet => 'Все още няма изиграни раздавки';

  @override
  String deal(int n) {
    return 'Раздавка $n';
  }

  @override
  String get lastTrick => 'Последна взятка';

  @override
  String get leaveMatchTitle => 'Изход от играта?';

  @override
  String get leaveMatchBody => 'Текущата игра ще бъде загубена.';

  @override
  String get leave => 'Изход';

  @override
  String get cancel => 'Отказ';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get partner => 'Партньор';

  @override
  String get opponent => 'Противник';

  @override
  String get stats => 'Статистика';

  @override
  String get statsMatches => 'Игри';

  @override
  String get statsWins => 'Победи';

  @override
  String get statsWinRate => 'Успеваемост';

  @override
  String get statsDeals => 'Раздавки';

  @override
  String get statsAvgPoints => 'Средно точки на раздавка';

  @override
  String get statsContracts => 'Изкарани обяви';

  @override
  String get statsValats => 'Капо';

  @override
  String get statsEmpty => 'Изиграй първата си игра, за да видиш статистика.';

  @override
  String get statsSubtitle => 'Твоето представяне';

  @override
  String get statsReset => 'Нулиране на статистиката';

  @override
  String get namePromptTitle => 'Как да те наричаме?';

  @override
  String get namePromptSubtitle =>
      'Името ти ще се вижда на масата и в статистиката.';

  @override
  String get nameLabel => 'Име';

  @override
  String get nameHint => 'напр. Георги';

  @override
  String get nameErrorEmpty => 'Въведи име';

  @override
  String get nameErrorShort => 'Поне 2 символа';

  @override
  String get nameErrorLong => 'Най-много 16 символа';

  @override
  String get nameErrorChars => 'Само букви, цифри, интервал и . - _';

  @override
  String get continueLabel => 'Напред';

  @override
  String get save => 'Запази';

  @override
  String get playerName => 'Име на играча';

  @override
  String get changeName => 'Смяна на името';

  @override
  String get hints => 'Подсказки';

  @override
  String get hintsDescription => 'Предлага карта, ако не играеш 25 секунди';

  @override
  String get hintLabel => 'Подсказка';

  @override
  String greeting(String name) {
    return 'Здравей, $name';
  }

  @override
  String get gameplay => 'Игра';

  @override
  String get teamUs => 'Ние';

  @override
  String get teamThem => 'Вие';

  @override
  String get statsResetConfirm => 'Нулирай';

  @override
  String get readyWaiting => 'Чакаме останалите…';

  @override
  String get backToLobby => 'Към лобито';

  @override
  String get autoPlay => 'Автоматичен ход';

  @override
  String get autoPlayDescription =>
      'Изиграва подсказаната карта след 40 секунди (при обявяване – пас)';

  @override
  String get onlineTitle => 'Игра с приятели';

  @override
  String get createRoom => 'Създай стая';

  @override
  String get createRoomSubtitle => 'Получаваш код, който да споделиш';

  @override
  String get joinRoom => 'Влез със код';

  @override
  String get joinRoomSubtitle => 'Въведи кода от приятел';

  @override
  String get roomCode => 'Код на стаята';

  @override
  String get roomCodeShort => 'Стая';

  @override
  String get joinAction => 'Влез';

  @override
  String get codeCopied => 'Поканата е копирана';

  @override
  String get tapToCopy => 'Докосни, за да копираш поканата';

  @override
  String shareText(String code, String link) {
    return 'Ела да играем Белот! Код на стаята: $code\n$link';
  }

  @override
  String get team1 => 'Отбор 1';

  @override
  String get team2 => 'Отбор 2';

  @override
  String get joinTeam => 'Влез';

  @override
  String get emptySlot => 'Свободно място';

  @override
  String get botPlayer => 'Бот';

  @override
  String get hostLabel => 'домакин';

  @override
  String get youLabel => 'ти';

  @override
  String get addBots => 'Попълни с ботове';

  @override
  String get startGame => 'Започни играта';

  @override
  String get waitingForHost => 'Чакаме домакина да започне играта…';

  @override
  String get needEachTeam => 'Нужен е поне един човек във всеки отбор';

  @override
  String get needFullTeams =>
      'Попълни свободните места с ботове или изчакай още играчи';

  @override
  String get noTeamYet => 'Избери отбор';

  @override
  String get spectators => 'Без отбор';

  @override
  String get leaveRoom => 'Напусни стаята';

  @override
  String get leaveRoomTitle => 'Да напуснеш ли стаята?';

  @override
  String get leaveRoomBody => 'Ако играта тече, бот ще играе на твоето място.';

  @override
  String get roomNotFound => 'Няма стая с този код';

  @override
  String get roomClosed => 'Стаята е затворена';

  @override
  String get connecting => 'Свързване…';

  @override
  String get connectionError => 'Няма връзка със сървъра. Опитай отново.';

  @override
  String get invalidCode => 'Кодът е от 5 знака';

  @override
  String get waitingTitle => 'Играта е в ход';

  @override
  String get waitingBody =>
      'Ще влезеш на мястото на бот, когато свърши текущото раздаване.';

  @override
  String get waitingNoSeat =>
      'Всички места са заети от хора. Ще можеш да играеш в следващата игра.';

  @override
  String get chooseTeam => 'Избери отбор';

  @override
  String seatsWithBots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n места с бот',
      one: '1 място с бот',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Назад';

  @override
  String get players => 'Играчи';

  @override
  String get retry => 'Опитай пак';

  @override
  String seatLeftBot(String name) {
    return '$name напусна, бот пое мястото';
  }

  @override
  String seatBack(String name) {
    return '$name се върна';
  }

  @override
  String seatJoined(String name) {
    return '$name влезе на мястото на бота';
  }

  @override
  String get leaveOnlineGameTitle => 'Да напуснеш ли играта?';

  @override
  String get leaveOnlineGameBody =>
      'Бот ще поеме мястото ти. Можеш да се върнеш със същия код до края на раздаването.';

  @override
  String get botName0 => 'Иван';

  @override
  String get botLevel => 'Трудност на ботовете';

  @override
  String get botLevelDescription => 'По подразбиране за офлайн игра';

  @override
  String get levelEasy => 'Лесно';

  @override
  String get levelMedium => 'Средно';

  @override
  String get levelHard => 'Трудно';

  @override
  String get levelEasyHint => 'Играят простичко и понякога грешат';

  @override
  String get levelMediumHint => 'Помнят картите и играят с партньора';

  @override
  String get levelHardHint => 'Пресмятат възможните ръце';

  @override
  String get chooseDifficulty => 'Избери трудност';

  @override
  String get play => 'Играй';

  @override
  String get lobbyBotLevel => 'Ботове';

  @override
  String get soundSection => 'Звук и усещане';

  @override
  String get sound => 'Звук';

  @override
  String get soundDescription => 'Меки звуци при раздаване, ход и взятка';

  @override
  String get haptics => 'Вибрация';

  @override
  String get hapticsDescription => 'Леко потрепване при ход, взятка и контра';

  @override
  String get scoreSheet => 'Лист';

  @override
  String get scoreSheetTitle => 'Резултатен лист';

  @override
  String get noTrumpDouble => 'Без коз ×2';

  @override
  String hangingLeft(int points) {
    return '$points висят';
  }

  @override
  String hangingAwardedLine(int points) {
    return '+$points висящи';
  }

  @override
  String get outsideExplain => 'Изкарана — всеки записва своите точки';

  @override
  String get insideExplain => 'Вкарана — всичко отива при противника';

  @override
  String get hangingExplain => 'Равенство — точките на играещите висят';

  @override
  String doubledExplain(String mult, int factor) {
    return '$mult — по-силният отбор взима всичко ×$factor';
  }

  @override
  String doubledHangingExplain(String mult, int factor) {
    return '$mult при равенство — всичко виси ×$factor';
  }

  @override
  String get tapToSkip => 'Докосни, за да видиш всичко';

  @override
  String get tapToClose => 'Докосни, за да затвориш';

  @override
  String trickTakenBy(String name) {
    return 'Взе: $name';
  }

  @override
  String get recapTab => 'Раздавка';

  @override
  String get sheetTab => 'Лист';

  @override
  String playsContract(String name) {
    return '$name играе';
  }

  @override
  String get markInside => 'вкарана';

  @override
  String get markHanging => 'висяща';

  @override
  String get markValat => 'капо';

  @override
  String get markDouble => 'контра';

  @override
  String get markRedouble => 'реконтра';

  @override
  String get matchScore => 'Резултат';

  @override
  String get emote => 'Емоция';

  @override
  String get emotesSection => 'Емоции';

  @override
  String get muteEmotes => 'Скрий чуждите емоции';

  @override
  String get muteEmotesDescription => 'Не показва реакциите на другите играчи';

  @override
  String get emotesCredit =>
      'Анимирани емоджита: Noto Emoji Animation, Google (CC BY 4.0)';

  @override
  String get phraseBravo => 'Браво!';

  @override
  String get phraseHayde => 'Хайде!';

  @override
  String get phraseOops => 'Упс!';

  @override
  String get phraseGg => 'Добра игра';

  @override
  String get botNamePool =>
      'Стефан,Елена,Димитър,Виктория,Калоян,Ива,Тодор,Габи,Христо,Вяра';

  @override
  String get profile => 'Профил';

  @override
  String get chooseAvatar => 'Избери аватар';

  @override
  String get avatarReserved => '🤖 е запазен за ботовете';

  @override
  String get editName => 'Промени името';

  @override
  String get filterAll => 'Всички';

  @override
  String get filterOffline => 'Офлайн';

  @override
  String get filterOnline => 'Онлайн';

  @override
  String get allLevels => 'Всички нива';

  @override
  String get statsStreak => 'Серия победи';

  @override
  String get statsBestStreak => 'Най-добра серия';

  @override
  String get statsContractsPct => 'Изкарани обяви';

  @override
  String get matchHistory => 'Последни мачове';

  @override
  String get historyEmpty => 'Още няма завършени мачове.';

  @override
  String get historyWin => 'Победа';

  @override
  String get historyLoss => 'Загуба';

  @override
  String historyOffline(String level) {
    return 'Офлайн · $level';
  }

  @override
  String historyOnline(String code) {
    return 'Онлайн · стая $code';
  }

  @override
  String get profileAndStats => 'Профил и статистика';

  @override
  String get profileAndStatsDescription => 'Аватар, име, статистика и история';
}
