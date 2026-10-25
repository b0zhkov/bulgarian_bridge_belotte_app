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
  /// **'Стая с код · скоро'**
  String get homeOnlineSubtitle;

  /// No description provided for @homeRulesTitle.
  ///
  /// In bg, this message translates to:
  /// **'Правила'**
  String get homeRulesTitle;

  /// No description provided for @homeRulesSubtitle.
  ///
  /// In bg, this message translates to:
  /// **'Според belot.bg'**
  String get homeRulesSubtitle;

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

  /// No description provided for @rulesBody.
  ///
  /// In bg, this message translates to:
  /// **'Играе се с 32 карти от 7 до асо, двама срещу двама, обратно на часовниковата стрелка. Раздават се 3+2 карти, следва наддаване (спатия, каро, купа, пика, без коз, всичко коз, контра, реконтра) и още 3 карти. Анонсите се обявяват автоматично с първата карта. Играта е до 151 точки. С капо не се излиза.'**
  String get rulesBody;
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
