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
  /// **'Играй срещу трима компютърни играчи'**
  String get homeOfflineSubtitle;

  /// No description provided for @homeOnlineTitle.
  ///
  /// In bg, this message translates to:
  /// **'Игра с приятели'**
  String get homeOnlineTitle;

  /// No description provided for @homeOnlineSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Стая с код за четирима играчи'**
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
  /// **'Ако играта тече, бот ще играе на твоето място.'**
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
