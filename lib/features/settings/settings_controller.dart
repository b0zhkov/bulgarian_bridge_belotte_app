import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

/// Theme mode setting; dark by default, persisted locally.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final v = ref.read(sharedPrefsProvider).getString(_key);
    return v == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref
        .read(sharedPrefsProvider)
        .setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
  }

  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// A string-valued setting persisted under [key].
class _PrefController<T> extends Notifier<T> {
  _PrefController(this.key, this.parse, this.encode);
  final String key;
  final T Function(String? v) parse;
  final String Function(T v) encode;

  @override
  T build() => parse(ref.read(sharedPrefsProvider).getString(key));

  void set(T v) {
    state = v;
    ref.read(sharedPrefsProvider).setString(key, encode(v));
  }
}

/// Card back design.
final cardBackProvider =
    NotifierProvider<_PrefController<CardBackStyle>, CardBackStyle>(
      () => _PrefController('card_back', CardBackStyleX.parse, (v) => v.name),
    );

/// Table colour.
final tableTintProvider =
    NotifierProvider<_PrefController<TableTint>, TableTint>(
      () => _PrefController('table_tint', TableTint.parse, (v) => v.name),
    );

/// App language: Bulgarian by default (the phone's locale is ignored).
final appLocaleProvider = NotifierProvider<_PrefController<String>, String>(
  () => _PrefController('app_locale', (v) => v == 'en' ? 'en' : 'bg', (v) => v),
);
