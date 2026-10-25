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
  String get homeOfflineSubtitle => 'Играй срещу трима компютърни играчи';

  @override
  String get homeOnlineTitle => 'Игра с приятели';

  @override
  String get homeOnlineSubtitle => 'Стая с код · скоро';

  @override
  String get homeRulesTitle => 'Правила';

  @override
  String get homeRulesSubtitle => 'Според belot.bg';

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
  String get rulesBody =>
      'Играе се с 32 карти от 7 до асо, двама срещу двама, обратно на часовниковата стрелка. Раздават се 3+2 карти, следва наддаване (спатия, каро, купа, пика, без коз, всичко коз, контра, реконтра) и още 3 карти. Анонсите се обявяват автоматично с първата карта. Играта е до 151 точки. С капо не се излиза.';
}
