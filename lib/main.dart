import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/online/online_entry_screen.dart';
import 'features/online/room_screen.dart';
import 'features/profile/name_screen.dart';
import 'features/profile/profile_controller.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const BelotApp(),
    ),
  );
}

class BelotApp extends ConsumerWidget {
  const BelotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // Bulgarian first; English strings exist and can be enabled later.
      locale: const Locale('bg'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routes: {
        '/': (_) => const _RootGate(),
        '/game': (_) => const GameScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/room': (_) => const RoomScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/online') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                OnlineEntryScreen(initialCode: settings.arguments as String?),
          );
        }
        return null;
      },
    );
  }
}

/// Shows the name prompt on first launch, the home screen afterwards.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(playerNameProvider);
    if (name != null) _openInviteLinkOnce(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: name == null ? const NameScreen() : const HomeScreen(),
    );
  }
}

bool _inviteHandled = false;

/// Web invite links (`?room=CODE`) open the join screen with the code.
void _openInviteLinkOnce(BuildContext context) {
  if (_inviteHandled) return;
  _inviteHandled = true;
  final code = Uri.base.queryParameters['room'];
  if (code == null || code.isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.of(context).pushNamed('/online', arguments: code);
    }
  });
}
