import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In bg, this message translates to:
  /// **'Белот'**
  String get appTitle;

  /// No description provided for @homeOfflineTitle.
  ///
  /// In bg, this message translates to:
  /// **'Офлайн игра'**
  String get homeOfflineTitle;

  /// No description provided for @homeOfflineSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Игра с ботове'**
  String get homeOfflineSubtitle;

  /// No description provided for @homeOnlineTitle.
  ///
  /// In bg, this message translates to:
  /// **'Игра с приятели'**
  String get homeOnlineTitle;

  /// No description provided for @homeOnlineSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Стая с код'**
  String get homeOnlineSubtitle;

  /// No description provided for @settings.
  ///
  /// In bg, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In bg, this message translates to:
  /// **'Тема'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In bg, this message translates to:
  /// **'Тъмна'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In bg, this message translates to:
  /// **'Светла'**
  String get themeLight;

  /// No description provided for @language.
  ///
  /// In bg, this message translates to:
  /// **'Език'**
  String get language;

  /// No description provided for @languageBulgarian.
  ///
  /// In bg, this message translates to:
  /// **'Български'**
  String get languageBulgarian;

  /// No description provided for @you.
  ///
  /// In bg, this message translates to:
  /// **'Ти'**
  String get you;

  /// No description provided for @us.
  ///
  /// In bg, this message translates to:
  /// **'Ние'**
  String get us;

  /// No description provided for @them.
  ///
  /// In bg, this message translates to:
  /// **'Вие'**
  String get them;

  /// No description provided for @botName1.
  ///
  /// In bg, this message translates to:
  /// **'Ники'**
  String get botName1;

  /// No description provided for @botName2.
  ///
  /// In bg, this message translates to:
  /// **'Мария'**
  String get botName2;

  /// No description provided for @botName3.
  ///
  /// In bg, this message translates to:
  /// **'Петър'**
  String get botName3;

  /// No description provided for @pass.
  ///
  /// In bg, this message translates to:
  /// **'Пас'**
  String get pass;

  /// No description provided for @clubs.
  ///
  /// In bg, this message translates to:
  /// **'Спатия'**
  String get clubs;

  /// No description provided for @diamonds.
  ///
  /// In bg, this message translates to:
  /// **'Каро'**
  String get diamonds;

  /// No description provided for @hearts.
  ///
  /// In bg, this message translates to:
  /// **'Купа'**
  String get hearts;

  /// No description provided for @spades.
  ///
  /// In bg, this message translates to:
  /// **'Пика'**
  String get spades;

  /// No description provided for @noTrump.
  ///
  /// In bg, this message translates to:
  /// **'Без коз'**
  String get noTrump;

  /// No description provided for @allTrump.
  ///
  /// In bg, this message translates to:
  /// **'Всичко коз'**
  String get allTrump;

  /// No description provided for @double.
  ///
  /// In bg, this message translates to:
  /// **'Контра'**
  String get double;

  /// No description provided for @redouble.
  ///
  /// In bg, this message translates to:
  /// **'Реконтра'**
  String get redouble;

  /// No description provided for @yourTurn.
  ///
  /// In bg, this message translates to:
  /// **'Твой ред'**
  String get yourTurn;

  /// No description provided for @yourBid.
  ///
  /// In bg, this message translates to:
  /// **'Твой ред за обява'**
  String get yourBid;

  /// No description provided for @waitingFor.
  ///
  /// In bg, this message translates to:
  /// **'{name} мисли…'**
  String waitingFor(String name);

  /// No description provided for @bidding.
  ///
  /// In bg, this message translates to:
  /// **'Наддаване'**
  String get bidding;

  /// No description provided for @contract.
  ///
  /// In bg, this message translates to:
  /// **'Игра'**
  String get contract;

  /// No description provided for @dealer.
  ///
  /// In bg, this message translates to:
  /// **'Р'**
  String get dealer;

  /// No description provided for @hanging.
  ///
  /// In bg, this message translates to:
  /// **'Висящи: {points}'**
  String hanging(int points);

  /// No description provided for @allPassed.
  ///
  /// In bg, this message translates to:
  /// **'Всички пасуваха — ново раздаване'**
  String get allPassed;

  /// No description provided for @tierce.
  ///
  /// In bg, this message translates to:
  /// **'Терца'**
  String get tierce;

  /// No description provided for @quarte.
  ///
  /// In bg, this message translates to:
  /// **'Кварта'**
  String get quarte;

  /// No description provided for @quint.
  ///
  /// In bg, this message translates to:
  /// **'Квинта'**
  String get quint;

  /// No description provided for @square.
  ///
  /// In bg, this message translates to:
  /// **'Каре'**
  String get square;

  /// No description provided for @belot.
  ///
  /// In bg, this message translates to:
  /// **'Белот'**
  String get belot;

  /// No description provided for @outside.
  ///
  /// In bg, this message translates to:
  /// **'Изкарана'**
  String get outside;

  /// No description provided for @inside.
  ///
  /// In bg, this message translates to:
  /// **'Вкарана'**
  String get inside;

  /// No description provided for @hangingOutcome.
  ///
  /// In bg, this message translates to:
  /// **'Висяща'**
  String get hangingOutcome;

  /// No description provided for @valat.
  ///
  /// In bg, this message translates to:
  /// **'Капо'**
  String get valat;

  /// No description provided for @dealResult.
  ///
  /// In bg, this message translates to:
  /// **'Резултат от раздаването'**
  String get dealResult;

  /// No description provided for @cardPoints.
  ///
  /// In bg, this message translates to:
  /// **'Карти'**
  String get cardPoints;

  /// No description provided for @premiums.
  ///
  /// In bg, this message translates to:
  /// **'Анонси'**
  String get premiums;

  /// No description provided for @lastTen.
  ///
  /// In bg, this message translates to:
  /// **'Последни 10'**
  String get lastTen;

  /// No description provided for @total.
  ///
  /// In bg, this message translates to:
  /// **'Общо'**
  String get total;

  /// No description provided for @written.
  ///
  /// In bg, this message translates to:
  /// **'Записани'**
  String get written;

  /// No description provided for @nextDeal.
  ///
  /// In bg, this message translates to:
  /// **'Следваща раздавка'**
  String get nextDeal;

  /// No description provided for @newMatch.
  ///
  /// In bg, this message translates to:
  /// **'Нова игра'**
  String get newMatch;

  /// No description provided for @matchWon.
  ///
  /// In bg, this message translates to:
  /// **'Победа!'**
  String get matchWon;

  /// No description provided for @matchLost.
  ///
  /// In bg, this message translates to:
  /// **'Загуба'**
  String get matchLost;

  /// No description provided for @finalScore.
  ///
  /// In bg, this message translates to:
  /// **'Краен резултат {us} : {them}'**
  String finalScore(int us, int them);

  /// No description provided for @history.
  ///
  /// In bg, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @noDealsYet.
  ///
  /// In bg, this message translates to:
  /// **'Все още няма изиграни раздавки'**
  String get noDealsYet;

  /// No description provided for @deal.
  ///
  /// In bg, this message translates to:
  /// **'Раздавка {n}'**
  String deal(int n);

  /// No description provided for @lastTrick.
  ///
  /// In bg, this message translates to:
  /// **'Последна взятка'**
  String get lastTrick;

  /// No description provided for @leaveMatchTitle.
  ///
  /// In bg, this message translates to:
  /// **'Изход от играта?'**
  String get leaveMatchTitle;

  /// No description provided for @leaveMatchBody.
  ///
  /// In bg, this message translates to:
  /// **'Текущата игра ще бъде загубена.'**
  String get leaveMatchBody;

  /// No description provided for @leave.
  ///
  /// In bg, this message translates to:
  /// **'Изход'**
  String get leave;

  /// No description provided for @cancel.
  ///
  /// In bg, this message translates to:
  /// **'Отказ'**
  String get cancel;

  /// No description provided for @comingSoon.
  ///
  /// In bg, this message translates to:
  /// **'Скоро'**
  String get comingSoon;

  /// No description provided for @partner.
  ///
  /// In bg, this message translates to:
  /// **'Партньор'**
  String get partner;

  /// No description provided for @opponent.
  ///
  /// In bg, this message translates to:
  /// **'Противник'**
  String get opponent;

  /// No description provided for @stats.
  ///
  /// In bg, this message translates to:
  /// **'Статистика'**
  String get stats;

  /// No description provided for @statsMatches.
  ///
  /// In bg, this message translates to:
  /// **'Игри'**
  String get statsMatches;

  /// No description provided for @statsWins.
  ///
  /// In bg, this message translates to:
  /// **'Победи'**
  String get statsWins;

  /// No description provided for @statsWinRate.
  ///
  /// In bg, this message translates to:
  /// **'Успеваемост'**
  String get statsWinRate;

  /// No description provided for @statsDeals.
  ///
  /// In bg, this message translates to:
  /// **'Раздавки'**
  String get statsDeals;

  /// No description provided for @statsAvgPoints.
  ///
  /// In bg, this message translates to:
  /// **'Средно точки на раздавка'**
  String get statsAvgPoints;

  /// No description provided for @statsContracts.
  ///
  /// In bg, this message translates to:
  /// **'Изкарани обяви'**
  String get statsContracts;

  /// No description provided for @statsValats.
  ///
  /// In bg, this message translates to:
  /// **'Капо'**
  String get statsValats;

  /// No description provided for @statsEmpty.
  ///
  /// In bg, this message translates to:
  /// **'Изиграй първата си игра, за да видиш статистика.'**
  String get statsEmpty;

  /// No description provided for @statsSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Твоето представяне'**
  String get statsSubtitle;

  /// No description provided for @statsReset.
  ///
  /// In bg, this message translates to:
  /// **'Нулиране на статистиката'**
  String get statsReset;

  /// No description provided for @namePromptTitle.
  ///
  /// In bg, this message translates to:
  /// **'Как да те наричаме?'**
  String get namePromptTitle;

  /// No description provided for @namePromptSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Името ти ще се вижда на масата и в статистиката.'**
  String get namePromptSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In bg, this message translates to:
  /// **'Име'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In bg, this message translates to:
  /// **'напр. Георги'**
  String get nameHint;

  /// No description provided for @nameErrorEmpty.
  ///
  /// In bg, this message translates to:
  /// **'Въведи име'**
  String get nameErrorEmpty;

  /// No description provided for @nameErrorShort.
  ///
  /// In bg, this message translates to:
  /// **'Поне 2 символа'**
  String get nameErrorShort;

  /// No description provided for @nameErrorLong.
  ///
  /// In bg, this message translates to:
  /// **'Най-много 16 символа'**
  String get nameErrorLong;

  /// No description provided for @nameErrorChars.
  ///
  /// In bg, this message translates to:
  /// **'Само букви, цифри, интервал и . - _'**
  String get nameErrorChars;

  /// No description provided for @continueLabel.
  ///
  /// In bg, this message translates to:
  /// **'Напред'**
  String get continueLabel;

  /// No description provided for @save.
  ///
  /// In bg, this message translates to:
  /// **'Запази'**
  String get save;

  /// No description provided for @playerName.
  ///
  /// In bg, this message translates to:
  /// **'Име на играча'**
  String get playerName;

  /// No description provided for @changeName.
  ///
  /// In bg, this message translates to:
  /// **'Смяна на името'**
  String get changeName;

  /// No description provided for @hints.
  ///
  /// In bg, this message translates to:
  /// **'Подсказки'**
  String get hints;

  /// No description provided for @hintsDescription.
  ///
  /// In bg, this message translates to:
  /// **'Предлага карта, ако не играеш 25 секунди'**
  String get hintsDescription;

  /// No description provided for @hintLabel.
  ///
  /// In bg, this message translates to:
  /// **'Подсказка'**
  String get hintLabel;

  /// No description provided for @greeting.
  ///
  /// In bg, this message translates to:
  /// **'Здравей, {name}'**
  String greeting(String name);

  /// No description provided for @gameplay.
  ///
  /// In bg, this message translates to:
  /// **'Игра'**
  String get gameplay;

  /// No description provided for @teamUs.
  ///
  /// In bg, this message translates to:
  /// **'Ние'**
  String get teamUs;

  /// No description provided for @teamThem.
  ///
  /// In bg, this message translates to:
  /// **'Вие'**
  String get teamThem;

  /// No description provided for @statsResetConfirm.
  ///
  /// In bg, this message translates to:
  /// **'Нулирай'**
  String get statsResetConfirm;

  /// No description provided for @readyWaiting.
  ///
  /// In bg, this message translates to:
  /// **'Чакаме останалите…'**
  String get readyWaiting;

  /// No description provided for @backToLobby.
  ///
  /// In bg, this message translates to:
  /// **'Към лобито'**
  String get backToLobby;

  /// No description provided for @autoPlay.
  ///
  /// In bg, this message translates to:
  /// **'Автоматичен ход'**
  String get autoPlay;

  /// No description provided for @autoPlayDescription.
  ///
  /// In bg, this message translates to:
  /// **'Изиграва подсказаната карта след 40 секунди (при обявяване – пас)'**
  String get autoPlayDescription;

  /// No description provided for @onlineTitle.
  ///
  /// In bg, this message translates to:
  /// **'Игра с приятели'**
  String get onlineTitle;

  /// No description provided for @createRoom.
  ///
  /// In bg, this message translates to:
  /// **'Създай стая'**
  String get createRoom;

  /// No description provided for @createRoomSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Получаваш код, който да споделиш'**
  String get createRoomSubtitle;

  /// No description provided for @joinRoom.
  ///
  /// In bg, this message translates to:
  /// **'Влез със код'**
  String get joinRoom;

  /// No description provided for @joinRoomSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Въведи кода от приятел'**
  String get joinRoomSubtitle;

  /// No description provided for @roomCode.
  ///
  /// In bg, this message translates to:
  /// **'Код на стаята'**
  String get roomCode;

  /// No description provided for @roomCodeShort.
  ///
  /// In bg, this message translates to:
  /// **'Стая'**
  String get roomCodeShort;

  /// No description provided for @joinAction.
  ///
  /// In bg, this message translates to:
  /// **'Влез'**
  String get joinAction;

  /// No description provided for @codeCopied.
  ///
  /// In bg, this message translates to:
  /// **'Поканата е копирана'**
  String get codeCopied;

  /// No description provided for @tapToCopy.
  ///
  /// In bg, this message translates to:
  /// **'Докосни, за да копираш поканата'**
  String get tapToCopy;

  /// No description provided for @shareText.
  ///
  /// In bg, this message translates to:
  /// **'Ела да играем Белот! Код на стаята: {code}\n{link}'**
  String shareText(String code, String link);

  /// No description provided for @team1.
  ///
  /// In bg, this message translates to:
  /// **'Отбор 1'**
  String get team1;

  /// No description provided for @team2.
  ///
  /// In bg, this message translates to:
  /// **'Отбор 2'**
  String get team2;

  /// No description provided for @joinTeam.
  ///
  /// In bg, this message translates to:
  /// **'Влез'**
  String get joinTeam;

  /// No description provided for @emptySlot.
  ///
  /// In bg, this message translates to:
  /// **'Свободно място'**
  String get emptySlot;

  /// No description provided for @botPlayer.
  ///
  /// In bg, this message translates to:
  /// **'Бот'**
  String get botPlayer;

  /// No description provided for @hostLabel.
  ///
  /// In bg, this message translates to:
  /// **'домакин'**
  String get hostLabel;

  /// No description provided for @youLabel.
  ///
  /// In bg, this message translates to:
  /// **'ти'**
  String get youLabel;

  /// No description provided for @addBots.
  ///
  /// In bg, this message translates to:
  /// **'Попълни с ботове'**
  String get addBots;

  /// No description provided for @startGame.
  ///
  /// In bg, this message translates to:
  /// **'Започни играта'**
  String get startGame;

  /// No description provided for @waitingForHost.
  ///
  /// In bg, this message translates to:
  /// **'Чакаме домакина да започне играта…'**
  String get waitingForHost;

  /// No description provided for @needEachTeam.
  ///
  /// In bg, this message translates to:
  /// **'Нужен е поне един човек във всеки отбор'**
  String get needEachTeam;

  /// No description provided for @needFullTeams.
  ///
  /// In bg, this message translates to:
  /// **'Попълни свободните места с ботове или изчакай още играчи'**
  String get needFullTeams;

  /// No description provided for @noTeamYet.
  ///
  /// In bg, this message translates to:
  /// **'Избери отбор'**
  String get noTeamYet;

  /// No description provided for @spectators.
  ///
  /// In bg, this message translates to:
  /// **'Без отбор'**
  String get spectators;

  /// No description provided for @leaveRoom.
  ///
  /// In bg, this message translates to:
  /// **'Напусни стаята'**
  String get leaveRoom;

  /// No description provided for @leaveRoomTitle.
  ///
  /// In bg, this message translates to:
  /// **'Да напуснеш ли стаята?'**
  String get leaveRoomTitle;

  /// No description provided for @leaveRoomBody.
  ///
  /// In bg, this message translates to:
  /// **'Ако играта тече, бот ще играе на твоето място, а то остава запазено за теб до края на мача.'**
  String get leaveRoomBody;

  /// No description provided for @roomNotFound.
  ///
  /// In bg, this message translates to:
  /// **'Няма стая с този код'**
  String get roomNotFound;

  /// No description provided for @roomClosed.
  ///
  /// In bg, this message translates to:
  /// **'Стаята е затворена'**
  String get roomClosed;

  /// No description provided for @connecting.
  ///
  /// In bg, this message translates to:
  /// **'Свързване…'**
  String get connecting;

  /// No description provided for @connectionError.
  ///
  /// In bg, this message translates to:
  /// **'Няма връзка със сървъра. Опитай отново.'**
  String get connectionError;

  /// No description provided for @invalidCode.
  ///
  /// In bg, this message translates to:
  /// **'Кодът е от 5 знака'**
  String get invalidCode;

  /// No description provided for @waitingTitle.
  ///
  /// In bg, this message translates to:
  /// **'Играта е в ход'**
  String get waitingTitle;

  /// No description provided for @waitingBody.
  ///
  /// In bg, this message translates to:
  /// **'Ще влезеш на мястото на бот, когато свърши текущото раздаване.'**
  String get waitingBody;

  /// No description provided for @waitingNoSeat.
  ///
  /// In bg, this message translates to:
  /// **'Всички места са заети от хора. Ще можеш да играеш в следващата игра.'**
  String get waitingNoSeat;

  /// No description provided for @chooseTeam.
  ///
  /// In bg, this message translates to:
  /// **'Избери отбор'**
  String get chooseTeam;

  /// No description provided for @seatsWithBots.
  ///
  /// In bg, this message translates to:
  /// **'{n, plural, =1{1 място с бот} other{{n} места с бот}}'**
  String seatsWithBots(int n);

  /// No description provided for @back.
  ///
  /// In bg, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @players.
  ///
  /// In bg, this message translates to:
  /// **'Играчи'**
  String get players;

  /// No description provided for @retry.
  ///
  /// In bg, this message translates to:
  /// **'Опитай пак'**
  String get retry;

  /// No description provided for @seatLeftBot.
  ///
  /// In bg, this message translates to:
  /// **'{name} напусна, бот пое мястото'**
  String seatLeftBot(String name);

  /// No description provided for @seatBack.
  ///
  /// In bg, this message translates to:
  /// **'{name} се върна'**
  String seatBack(String name);

  /// No description provided for @seatJoined.
  ///
  /// In bg, this message translates to:
  /// **'{name} влезе на мястото на бота'**
  String seatJoined(String name);

  /// No description provided for @leaveOnlineGameTitle.
  ///
  /// In bg, this message translates to:
  /// **'Да напуснеш ли играта?'**
  String get leaveOnlineGameTitle;

  /// No description provided for @leaveOnlineGameBody.
  ///
  /// In bg, this message translates to:
  /// **'Бот ще поеме мястото ти, а то остава запазено за теб до края на мача. Можеш да се върнеш по всяко време.'**
  String get leaveOnlineGameBody;

  /// No description provided for @botName0.
  ///
  /// In bg, this message translates to:
  /// **'Иван'**
  String get botName0;

  /// No description provided for @botLevel.
  ///
  /// In bg, this message translates to:
  /// **'Трудност на ботовете'**
  String get botLevel;

  /// No description provided for @botLevelDescription.
  ///
  /// In bg, this message translates to:
  /// **'По подразбиране за офлайн игра'**
  String get botLevelDescription;

  /// No description provided for @levelEasy.
  ///
  /// In bg, this message translates to:
  /// **'Лесно'**
  String get levelEasy;

  /// No description provided for @levelMedium.
  ///
  /// In bg, this message translates to:
  /// **'Средно'**
  String get levelMedium;

  /// No description provided for @levelHard.
  ///
  /// In bg, this message translates to:
  /// **'Трудно'**
  String get levelHard;

  /// No description provided for @levelEasyHint.
  ///
  /// In bg, this message translates to:
  /// **'Играят простичко и понякога грешат'**
  String get levelEasyHint;

  /// No description provided for @levelMediumHint.
  ///
  /// In bg, this message translates to:
  /// **'Помнят картите и играят с партньора'**
  String get levelMediumHint;

  /// No description provided for @levelHardHint.
  ///
  /// In bg, this message translates to:
  /// **'Пресмятат възможните ръце'**
  String get levelHardHint;

  /// No description provided for @chooseDifficulty.
  ///
  /// In bg, this message translates to:
  /// **'Избери трудност'**
  String get chooseDifficulty;

  /// No description provided for @play.
  ///
  /// In bg, this message translates to:
  /// **'Играй'**
  String get play;

  /// No description provided for @lobbyBotLevel.
  ///
  /// In bg, this message translates to:
  /// **'Ботове'**
  String get lobbyBotLevel;

  /// No description provided for @soundSection.
  ///
  /// In bg, this message translates to:
  /// **'Звук и усещане'**
  String get soundSection;

  /// No description provided for @sound.
  ///
  /// In bg, this message translates to:
  /// **'Звук'**
  String get sound;

  /// No description provided for @soundDescription.
  ///
  /// In bg, this message translates to:
  /// **'Меки звуци при раздаване, ход и взятка'**
  String get soundDescription;

  /// No description provided for @haptics.
  ///
  /// In bg, this message translates to:
  /// **'Вибрация'**
  String get haptics;

  /// No description provided for @hapticsDescription.
  ///
  /// In bg, this message translates to:
  /// **'Леко потрепване при ход, взятка и контра'**
  String get hapticsDescription;

  /// No description provided for @scoreSheet.
  ///
  /// In bg, this message translates to:
  /// **'Лист'**
  String get scoreSheet;

  /// No description provided for @scoreSheetTitle.
  ///
  /// In bg, this message translates to:
  /// **'Резултатен лист'**
  String get scoreSheetTitle;

  /// No description provided for @noTrumpDouble.
  ///
  /// In bg, this message translates to:
  /// **'Без коз ×2'**
  String get noTrumpDouble;

  /// No description provided for @hangingLeft.
  ///
  /// In bg, this message translates to:
  /// **'{points} висят'**
  String hangingLeft(int points);

  /// No description provided for @hangingAwardedLine.
  ///
  /// In bg, this message translates to:
  /// **'+{points} висящи'**
  String hangingAwardedLine(int points);

  /// No description provided for @outsideExplain.
  ///
  /// In bg, this message translates to:
  /// **'Изкарана — всеки записва своите точки'**
  String get outsideExplain;

  /// No description provided for @insideExplain.
  ///
  /// In bg, this message translates to:
  /// **'Вкарана — всичко отива при противника'**
  String get insideExplain;

  /// No description provided for @hangingExplain.
  ///
  /// In bg, this message translates to:
  /// **'Равенство — точките на играещите висят'**
  String get hangingExplain;

  /// No description provided for @doubledExplain.
  ///
  /// In bg, this message translates to:
  /// **'{mult} — по-силният отбор взима всичко ×{factor}'**
  String doubledExplain(String mult, int factor);

  /// No description provided for @doubledHangingExplain.
  ///
  /// In bg, this message translates to:
  /// **'{mult} при равенство — всичко виси ×{factor}'**
  String doubledHangingExplain(String mult, int factor);

  /// No description provided for @tapToSkip.
  ///
  /// In bg, this message translates to:
  /// **'Докосни, за да видиш всичко'**
  String get tapToSkip;

  /// No description provided for @tapToClose.
  ///
  /// In bg, this message translates to:
  /// **'Докосни, за да затвориш'**
  String get tapToClose;

  /// No description provided for @trickTakenBy.
  ///
  /// In bg, this message translates to:
  /// **'Взе: {name}'**
  String trickTakenBy(String name);

  /// No description provided for @recapTab.
  ///
  /// In bg, this message translates to:
  /// **'Раздавка'**
  String get recapTab;

  /// No description provided for @sheetTab.
  ///
  /// In bg, this message translates to:
  /// **'Лист'**
  String get sheetTab;

  /// No description provided for @playsContract.
  ///
  /// In bg, this message translates to:
  /// **'{name} играе'**
  String playsContract(String name);

  /// No description provided for @markInside.
  ///
  /// In bg, this message translates to:
  /// **'вкарана'**
  String get markInside;

  /// No description provided for @markHanging.
  ///
  /// In bg, this message translates to:
  /// **'висяща'**
  String get markHanging;

  /// No description provided for @markValat.
  ///
  /// In bg, this message translates to:
  /// **'капо'**
  String get markValat;

  /// No description provided for @markDouble.
  ///
  /// In bg, this message translates to:
  /// **'контра'**
  String get markDouble;

  /// No description provided for @markRedouble.
  ///
  /// In bg, this message translates to:
  /// **'реконтра'**
  String get markRedouble;

  /// No description provided for @matchScore.
  ///
  /// In bg, this message translates to:
  /// **'Резултат'**
  String get matchScore;

  /// No description provided for @emote.
  ///
  /// In bg, this message translates to:
  /// **'Емоция'**
  String get emote;

  /// No description provided for @emotesSection.
  ///
  /// In bg, this message translates to:
  /// **'Емоции'**
  String get emotesSection;

  /// No description provided for @muteEmotes.
  ///
  /// In bg, this message translates to:
  /// **'Скрий чуждите емоции'**
  String get muteEmotes;

  /// No description provided for @muteEmotesDescription.
  ///
  /// In bg, this message translates to:
  /// **'Не показва реакциите на другите играчи'**
  String get muteEmotesDescription;

  /// No description provided for @emotesCredit.
  ///
  /// In bg, this message translates to:
  /// **'Анимирани емоджита: Noto Emoji Animation, Google (CC BY 4.0)'**
  String get emotesCredit;

  /// No description provided for @phraseBravo.
  ///
  /// In bg, this message translates to:
  /// **'Браво!'**
  String get phraseBravo;

  /// No description provided for @phraseHayde.
  ///
  /// In bg, this message translates to:
  /// **'Хайде!'**
  String get phraseHayde;

  /// No description provided for @phraseOops.
  ///
  /// In bg, this message translates to:
  /// **'Упс!'**
  String get phraseOops;

  /// No description provided for @phraseGg.
  ///
  /// In bg, this message translates to:
  /// **'Добра игра'**
  String get phraseGg;

  /// Comma-separated plain first names used for bots when a default bot name equals a human player's name.
  ///
  /// In bg, this message translates to:
  /// **'Стефан,Елена,Димитър,Виктория,Калоян,Ива,Тодор,Габи,Христо,Вяра'**
  String get botNamePool;

  /// No description provided for @profile.
  ///
  /// In bg, this message translates to:
  /// **'Профил'**
  String get profile;

  /// No description provided for @chooseAvatar.
  ///
  /// In bg, this message translates to:
  /// **'Избери аватар'**
  String get chooseAvatar;

  /// No description provided for @avatarReserved.
  ///
  /// In bg, this message translates to:
  /// **'🤖 е запазен за ботовете'**
  String get avatarReserved;

  /// No description provided for @editName.
  ///
  /// In bg, this message translates to:
  /// **'Промени името'**
  String get editName;

  /// No description provided for @filterAll.
  ///
  /// In bg, this message translates to:
  /// **'Всички'**
  String get filterAll;

  /// No description provided for @filterOffline.
  ///
  /// In bg, this message translates to:
  /// **'Офлайн'**
  String get filterOffline;

  /// No description provided for @filterOnline.
  ///
  /// In bg, this message translates to:
  /// **'Онлайн'**
  String get filterOnline;

  /// No description provided for @allLevels.
  ///
  /// In bg, this message translates to:
  /// **'Всички нива'**
  String get allLevels;

  /// No description provided for @statsStreak.
  ///
  /// In bg, this message translates to:
  /// **'Серия победи'**
  String get statsStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In bg, this message translates to:
  /// **'Най-добра серия'**
  String get statsBestStreak;

  /// No description provided for @statsContractsPct.
  ///
  /// In bg, this message translates to:
  /// **'Изкарани обяви'**
  String get statsContractsPct;

  /// No description provided for @matchHistory.
  ///
  /// In bg, this message translates to:
  /// **'Последни мачове'**
  String get matchHistory;

  /// No description provided for @historyEmpty.
  ///
  /// In bg, this message translates to:
  /// **'Още няма завършени мачове.'**
  String get historyEmpty;

  /// No description provided for @historyWin.
  ///
  /// In bg, this message translates to:
  /// **'Победа'**
  String get historyWin;

  /// No description provided for @historyLoss.
  ///
  /// In bg, this message translates to:
  /// **'Загуба'**
  String get historyLoss;

  /// No description provided for @historyOffline.
  ///
  /// In bg, this message translates to:
  /// **'Офлайн · {level}'**
  String historyOffline(String level);

  /// No description provided for @historyOnline.
  ///
  /// In bg, this message translates to:
  /// **'Онлайн · стая {code}'**
  String historyOnline(String code);

  /// No description provided for @profileAndStats.
  ///
  /// In bg, this message translates to:
  /// **'Профил и статистика'**
  String get profileAndStats;

  /// No description provided for @profileAndStatsDescription.
  ///
  /// In bg, this message translates to:
  /// **'Аватар, име, статистика и история'**
  String get profileAndStatsDescription;

  /// Web app install / update (installTitle).
  ///
  /// In bg, this message translates to:
  /// **'Инсталирай Белот'**
  String get installTitle;

  /// Web app install / update (installSubtitle).
  ///
  /// In bg, this message translates to:
  /// **'На цял екран, бързо и без интернет.'**
  String get installSubtitle;

  /// Web app install / update (installButton).
  ///
  /// In bg, this message translates to:
  /// **'Инсталирай'**
  String get installButton;

  /// Web app install / update (installHow).
  ///
  /// In bg, this message translates to:
  /// **'Как?'**
  String get installHow;

  /// Web app install / update (installIosTitle).
  ///
  /// In bg, this message translates to:
  /// **'Добави Белот на началния екран'**
  String get installIosTitle;

  /// Web app install / update (installIosStep1).
  ///
  /// In bg, this message translates to:
  /// **'Натисни „Сподели“ в лентата на Safari.'**
  String get installIosStep1;

  /// Web app install / update (installIosStep2).
  ///
  /// In bg, this message translates to:
  /// **'Избери „Добави към началния екран“.'**
  String get installIosStep2;

  /// Web app install / update (installIosStep3).
  ///
  /// In bg, this message translates to:
  /// **'Натисни „Добави“ — готово.'**
  String get installIosStep3;

  /// Web app install / update (installDismiss).
  ///
  /// In bg, this message translates to:
  /// **'Скрий'**
  String get installDismiss;

  /// Web app install / update (updateAvailable).
  ///
  /// In bg, this message translates to:
  /// **'Има нова версия'**
  String get updateAvailable;

  /// Web app install / update (updateNow).
  ///
  /// In bg, this message translates to:
  /// **'Обнови'**
  String get updateNow;

  /// Beta 10: invites / score details (invite).
  ///
  /// In bg, this message translates to:
  /// **'Покани'**
  String get invite;

  /// Beta 10: invites / score details (inviteTitle).
  ///
  /// In bg, this message translates to:
  /// **'Покана за Белот'**
  String get inviteTitle;

  /// Beta 10: invites / score details (inviteFailedTitle).
  ///
  /// In bg, this message translates to:
  /// **'Поканата не може да се отвори'**
  String get inviteFailedTitle;

  /// Beta 10: invites / score details (inviteFailedBody).
  ///
  /// In bg, this message translates to:
  /// **'Стаята от поканата е затворена или вече не съществува. Създай нова стая или въведи друг код.'**
  String get inviteFailedBody;

  /// Beta 10: invites / score details (inviteInvalidBody).
  ///
  /// In bg, this message translates to:
  /// **'Кодът във връзката е грешен. Помоли приятеля си за нова покана или въведи кода ръчно.'**
  String get inviteInvalidBody;

  /// Beta 10: invites / score details (declarationUpTo).
  ///
  /// In bg, this message translates to:
  /// **'{name} {suit} до {rank}'**
  String declarationUpTo(String name, String suit, String rank);

  /// Beta 10: invites / score details (roundingTitle).
  ///
  /// In bg, this message translates to:
  /// **'Закръгляне'**
  String get roundingTitle;

  /// Beta 10: invites / score details (roundingInside).
  ///
  /// In bg, this message translates to:
  /// **'Общо {total} → {rounded} за {team}'**
  String roundingInside(int total, int rounded, String team);

  /// Beta 10: invites / score details (roundingHanging).
  ///
  /// In bg, this message translates to:
  /// **'{team}: {raw} → {rounded}; {hang} висят'**
  String roundingHanging(String team, int raw, int rounded, int hang);

  /// Beta 10: invites / score details (roundingMultiplied).
  ///
  /// In bg, this message translates to:
  /// **'Общо {total} → {rounded} ×{factor} = {result} за {team}'**
  String roundingMultiplied(
    int total,
    int rounded,
    int factor,
    int result,
    String team,
  );

  /// Beta 10: invites / score details (roundingMultipliedHanging).
  ///
  /// In bg, this message translates to:
  /// **'Общо {total} → {rounded} ×{factor} = {result} висят'**
  String roundingMultipliedHanging(
    int total,
    int rounded,
    int factor,
    int result,
  );

  /// Beta 10: invites / score details (tapRowForDetails).
  ///
  /// In bg, this message translates to:
  /// **'Докосни раздаване за подробности'**
  String get tapRowForDetails;

  /// Beta 10: invites / score details (dealNumberTitle).
  ///
  /// In bg, this message translates to:
  /// **'Раздаване {n}'**
  String dealNumberTitle(int n);

  /// Beta 10: invites / score details (contractBy).
  ///
  /// In bg, this message translates to:
  /// **'Играят: {team}'**
  String contractBy(String team);

  /// Beta 10: invites / score details (trickPoints).
  ///
  /// In bg, this message translates to:
  /// **'{points} т. във взятката'**
  String trickPoints(int points);

  /// Beta 10: invites / score details (lastTrickHides).
  ///
  /// In bg, this message translates to:
  /// **'Скрива се при следващата карта'**
  String get lastTrickHides;

  /// Beta 10: declaration top card (upTo).
  ///
  /// In bg, this message translates to:
  /// **'до {rank}'**
  String upTo(String rank);

  /// No description provided for @quickTitle.
  ///
  /// In bg, this message translates to:
  /// **'Бърза игра'**
  String get quickTitle;

  /// No description provided for @quickSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Случайни противници · рейтинг'**
  String get quickSubtitle;

  /// No description provided for @quickSearching.
  ///
  /// In bg, this message translates to:
  /// **'Търсим играчи…'**
  String get quickSearching;

  /// No description provided for @quickFound.
  ///
  /// In bg, this message translates to:
  /// **'Намерени играчи: {n}/4'**
  String quickFound(int n);

  /// No description provided for @quickBotsHint.
  ///
  /// In bg, this message translates to:
  /// **'Ако няма достатъчно хора, след {s} s започваме с ботове.'**
  String quickBotsHint(int s);

  /// No description provided for @quickStarting.
  ///
  /// In bg, this message translates to:
  /// **'Започваме…'**
  String get quickStarting;

  /// No description provided for @quickCancel.
  ///
  /// In bg, this message translates to:
  /// **'Откажи'**
  String get quickCancel;

  /// No description provided for @quickFailed.
  ///
  /// In bg, this message translates to:
  /// **'Търсенето не успя. Провери връзката.'**
  String get quickFailed;

  /// No description provided for @quickAgain.
  ///
  /// In bg, this message translates to:
  /// **'Нова бърза игра'**
  String get quickAgain;

  /// No description provided for @goHome.
  ///
  /// In bg, this message translates to:
  /// **'Начало'**
  String get goHome;

  /// No description provided for @quickWaitingStart.
  ///
  /// In bg, this message translates to:
  /// **'Подреждаме масата…'**
  String get quickWaitingStart;

  /// No description provided for @rating.
  ///
  /// In bg, this message translates to:
  /// **'Рейтинг'**
  String get rating;

  /// No description provided for @ratingNote.
  ///
  /// In bg, this message translates to:
  /// **'Рейтингът се променя само в бързи игри.'**
  String get ratingNote;

  /// No description provided for @ratingChange.
  ///
  /// In bg, this message translates to:
  /// **'Рейтинг {rating} ({delta}) · {rank}'**
  String ratingChange(int rating, String delta, String rank);

  /// No description provided for @ratingPending.
  ///
  /// In bg, this message translates to:
  /// **'Обновяваме рейтинга…'**
  String get ratingPending;

  /// No description provided for @ratingGames.
  ///
  /// In bg, this message translates to:
  /// **'Бързи игри: {n}'**
  String ratingGames(int n);

  /// No description provided for @rankNovice.
  ///
  /// In bg, this message translates to:
  /// **'Новак'**
  String get rankNovice;

  /// No description provided for @rankBronze.
  ///
  /// In bg, this message translates to:
  /// **'Бронз'**
  String get rankBronze;

  /// No description provided for @rankSilver.
  ///
  /// In bg, this message translates to:
  /// **'Сребро'**
  String get rankSilver;

  /// No description provided for @rankGold.
  ///
  /// In bg, this message translates to:
  /// **'Злато'**
  String get rankGold;

  /// No description provided for @rankPlatinum.
  ///
  /// In bg, this message translates to:
  /// **'Платина'**
  String get rankPlatinum;

  /// No description provided for @rankDiamond.
  ///
  /// In bg, this message translates to:
  /// **'Диамант'**
  String get rankDiamond;

  /// No description provided for @rankMaster.
  ///
  /// In bg, this message translates to:
  /// **'Майстор'**
  String get rankMaster;

  /// No description provided for @achievements.
  ///
  /// In bg, this message translates to:
  /// **'Постижения'**
  String get achievements;

  /// No description provided for @achievementsCount.
  ///
  /// In bg, this message translates to:
  /// **'{n} от {total}'**
  String achievementsCount(int n, int total);

  /// No description provided for @achievementUnlocked.
  ///
  /// In bg, this message translates to:
  /// **'Ново постижение'**
  String get achievementUnlocked;

  /// No description provided for @achLocked.
  ///
  /// In bg, this message translates to:
  /// **'Заключено'**
  String get achLocked;

  /// No description provided for @achFirstWin.
  ///
  /// In bg, this message translates to:
  /// **'Първа победа'**
  String get achFirstWin;

  /// No description provided for @achFirstWinDesc.
  ///
  /// In bg, this message translates to:
  /// **'Спечели мач.'**
  String get achFirstWinDesc;

  /// No description provided for @achWins10.
  ///
  /// In bg, this message translates to:
  /// **'10 победи'**
  String get achWins10;

  /// No description provided for @achWins10Desc.
  ///
  /// In bg, this message translates to:
  /// **'Спечели 10 мача.'**
  String get achWins10Desc;

  /// No description provided for @achWins50.
  ///
  /// In bg, this message translates to:
  /// **'50 победи'**
  String get achWins50;

  /// No description provided for @achWins50Desc.
  ///
  /// In bg, this message translates to:
  /// **'Спечели 50 мача.'**
  String get achWins50Desc;

  /// No description provided for @achWins100.
  ///
  /// In bg, this message translates to:
  /// **'100 победи'**
  String get achWins100;

  /// No description provided for @achWins100Desc.
  ///
  /// In bg, this message translates to:
  /// **'Спечели 100 мача.'**
  String get achWins100Desc;

  /// No description provided for @achCapot.
  ///
  /// In bg, this message translates to:
  /// **'Капо'**
  String get achCapot;

  /// No description provided for @achCapotDesc.
  ///
  /// In bg, this message translates to:
  /// **'Отборът ти взема всички взятки.'**
  String get achCapotDesc;

  /// No description provided for @achBelot.
  ///
  /// In bg, this message translates to:
  /// **'Белот!'**
  String get achBelot;

  /// No description provided for @achBelotDesc.
  ///
  /// In bg, this message translates to:
  /// **'Обяви белот.'**
  String get achBelotDesc;

  /// No description provided for @achSquare.
  ///
  /// In bg, this message translates to:
  /// **'Каре'**
  String get achSquare;

  /// No description provided for @achSquareDesc.
  ///
  /// In bg, this message translates to:
  /// **'Обяви каре, което се зачита.'**
  String get achSquareDesc;

  /// No description provided for @achQuint.
  ///
  /// In bg, this message translates to:
  /// **'Квинта'**
  String get achQuint;

  /// No description provided for @achQuintDesc.
  ///
  /// In bg, this message translates to:
  /// **'Обяви квинта, която се зачита.'**
  String get achQuintDesc;

  /// No description provided for @achNoTrump.
  ///
  /// In bg, this message translates to:
  /// **'Без коз'**
  String get achNoTrump;

  /// No description provided for @achNoTrumpDesc.
  ///
  /// In bg, this message translates to:
  /// **'Изкарай обявено от отбора ти Без коз.'**
  String get achNoTrumpDesc;

  /// No description provided for @achAllTrump.
  ///
  /// In bg, this message translates to:
  /// **'Всичко коз'**
  String get achAllTrump;

  /// No description provided for @achAllTrumpDesc.
  ///
  /// In bg, this message translates to:
  /// **'Изкарай обявено от отбора ти Всичко коз.'**
  String get achAllTrumpDesc;

  /// No description provided for @achContra.
  ///
  /// In bg, this message translates to:
  /// **'Контра на място'**
  String get achContra;

  /// No description provided for @achContraDesc.
  ///
  /// In bg, this message translates to:
  /// **'Дай контра и вкарай противниците.'**
  String get achContraDesc;

  /// No description provided for @achRecontra.
  ///
  /// In bg, this message translates to:
  /// **'Реконтра'**
  String get achRecontra;

  /// No description provided for @achRecontraDesc.
  ///
  /// In bg, this message translates to:
  /// **'Изкарай игра с реконтра.'**
  String get achRecontraDesc;

  /// No description provided for @achComeback.
  ///
  /// In bg, this message translates to:
  /// **'Обрат'**
  String get achComeback;

  /// No description provided for @achComebackDesc.
  ///
  /// In bg, this message translates to:
  /// **'Спечели мач, след като си изоставал с 50+ точки.'**
  String get achComebackDesc;

  /// No description provided for @achBeatHard.
  ///
  /// In bg, this message translates to:
  /// **'Срещу трудните'**
  String get achBeatHard;

  /// No description provided for @achBeatHardDesc.
  ///
  /// In bg, this message translates to:
  /// **'Победи трудните ботове.'**
  String get achBeatHardDesc;

  /// No description provided for @achFirstQuick.
  ///
  /// In bg, this message translates to:
  /// **'Първа бърза игра'**
  String get achFirstQuick;

  /// No description provided for @achFirstQuickDesc.
  ///
  /// In bg, this message translates to:
  /// **'Изиграй бърза игра докрай.'**
  String get achFirstQuickDesc;

  /// No description provided for @achRankGold.
  ///
  /// In bg, this message translates to:
  /// **'Златен ранг'**
  String get achRankGold;

  /// No description provided for @achRankGoldDesc.
  ///
  /// In bg, this message translates to:
  /// **'Достигни рейтинг 1200 (Злато).'**
  String get achRankGoldDesc;

  /// No description provided for @resumeTitle.
  ///
  /// In bg, this message translates to:
  /// **'Върни се в играта'**
  String get resumeTitle;

  /// No description provided for @resumeBody.
  ///
  /// In bg, this message translates to:
  /// **'Мястото ти в стая {code} те чака — ботът играе вместо теб.'**
  String resumeBody(String code);

  /// No description provided for @resumeJoin.
  ///
  /// In bg, this message translates to:
  /// **'Върни се'**
  String get resumeJoin;

  /// No description provided for @resumeDismiss.
  ///
  /// In bg, this message translates to:
  /// **'Не сега'**
  String get resumeDismiss;

  /// No description provided for @tableSection.
  ///
  /// In bg, this message translates to:
  /// **'Маса и карти'**
  String get tableSection;

  /// No description provided for @cardBack.
  ///
  /// In bg, this message translates to:
  /// **'Гръб на картите'**
  String get cardBack;

  /// No description provided for @tableColor.
  ///
  /// In bg, this message translates to:
  /// **'Цвят на масата'**
  String get tableColor;

  /// No description provided for @backClassic.
  ///
  /// In bg, this message translates to:
  /// **'Класически'**
  String get backClassic;

  /// No description provided for @backMidnight.
  ///
  /// In bg, this message translates to:
  /// **'Нощ'**
  String get backMidnight;

  /// No description provided for @backForest.
  ///
  /// In bg, this message translates to:
  /// **'Гора'**
  String get backForest;

  /// No description provided for @backMono.
  ///
  /// In bg, this message translates to:
  /// **'Минимал'**
  String get backMono;

  /// No description provided for @tableClassic.
  ///
  /// In bg, this message translates to:
  /// **'Класическа'**
  String get tableClassic;

  /// No description provided for @tableFelt.
  ///
  /// In bg, this message translates to:
  /// **'Сукно'**
  String get tableFelt;

  /// No description provided for @tableWine.
  ///
  /// In bg, this message translates to:
  /// **'Бордо'**
  String get tableWine;

  /// No description provided for @tableSlate.
  ///
  /// In bg, this message translates to:
  /// **'Графит'**
  String get tableSlate;

  /// No description provided for @languageEnglish.
  ///
  /// In bg, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @ratingUnratedBots.
  ///
  /// In bg, this message translates to:
  /// **'Без рейтинг — игра срещу ботове'**
  String get ratingUnratedBots;

  /// No description provided for @ratingUnratedShort.
  ///
  /// In bg, this message translates to:
  /// **'Без рейтинг — мачът продължи под {min} минути'**
  String ratingUnratedShort(int min);

  /// No description provided for @ratingUnratedFailed.
  ///
  /// In bg, this message translates to:
  /// **'Без рейтинг — резултатът не беше записан'**
  String get ratingUnratedFailed;

  /// No description provided for @ratingDailyCap.
  ///
  /// In bg, this message translates to:
  /// **'дневен лимит'**
  String get ratingDailyCap;

  /// No description provided for @ratingRepeat.
  ///
  /// In bg, this message translates to:
  /// **'същите съперници, игра №{n} за 24 ч → {pct}%'**
  String ratingRepeat(int n, int pct);

  /// No description provided for @ratingLimitNote.
  ///
  /// In bg, this message translates to:
  /// **'{delta} ({why})'**
  String ratingLimitNote(String delta, String why);

  /// No description provided for @ratingReducedNote.
  ///
  /// In bg, this message translates to:
  /// **'{delta} вместо {raw} ({why})'**
  String ratingReducedNote(String delta, String raw, String why);

  /// No description provided for @quickUnratedChip.
  ///
  /// In bg, this message translates to:
  /// **'Без рейтинг · срещу ботове'**
  String get quickUnratedChip;

  /// No description provided for @quickUnratedHint.
  ///
  /// In bg, this message translates to:
  /// **'Ако никой не се включи, играеш срещу ботове — без рейтинг.'**
  String get quickUnratedHint;

  /// No description provided for @ratingRules.
  ///
  /// In bg, this message translates to:
  /// **'Рейтинг дават само бързи игри с хора и в двата отбора, продължили поне {min} минути. Най-много +{cap} на ден; срещу едни и същи съперници за 24 ч промяната намалява (100%, 50%, 25%, 0%).'**
  String ratingRules(int min, int cap);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bg', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
