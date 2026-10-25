import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/feedback/sound.dart';
import 'features/game/game_controller.dart';
import 'features/game/game_screen.dart';
import 'features/game/widgets/warm_up.dart';
import 'features/home/home_screen.dart';
import 'features/online/online_entry_screen.dart';
import 'features/online/room_screen.dart';
import 'features/profile/name_screen.dart';
import 'features/profile/profile_controller.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _applyDemoTiming();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const BelotApp(),
    ),
  );
}

/// Development builds only (`--dart-define=DEMO_AUTOPLAY_MS=…`, used for
/// screenshots): faster auto-play and bots. Release builds keep defaults.
void _applyDemoTiming() {
  const autoplay = int.fromEnvironment('DEMO_AUTOPLAY_MS');
  if (autoplay <= 0) return;
  TurnTimers.autoPlayDelay = const Duration(milliseconds: autoplay);
  TurnTimers.hintDelay = const Duration(milliseconds: autoplay ~/ 2);
  GameController.botDelay = const Duration(milliseconds: 300);
  GameController.trickPause = const Duration(milliseconds: 700);
}

class BelotApp extends ConsumerWidget {
  const BelotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the sound pools now, not on the first sound mid-game.
    ref.read(soundPlayerProvider);
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
      // Browsers only allow audio after a user gesture: unlock on the
      // first tap anywhere.
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => ref.read(soundPlayerProvider).unlock(),
        // The warm-up paints underneath the (opaque) screens.
        child: Stack(
          children: [
            const Positioned(left: 0, top: 0, child: TableWarmUp()),
            ?child,
          ],
        ),
      ),
      routes: {
        '/': (_) => const _RootGate(),
        '/game': (_) => const _NameGate(child: GameScreen()),
        '/settings': (_) => const SettingsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/room': (_) => const _NameGate(child: RoomScreen()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/online') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _NameGate(
              child: OnlineEntryScreen(
                initialCode: settings.arguments as String?,
              ),
            ),
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

/// Routes that need a player name (e.g. `#/online` opened directly) ask
/// for it first.
class _NameGate extends ConsumerWidget {
  const _NameGate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(playerNameProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: name == null ? const NameScreen() : child,
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
