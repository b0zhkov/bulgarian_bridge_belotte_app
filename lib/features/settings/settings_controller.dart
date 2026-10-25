import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
