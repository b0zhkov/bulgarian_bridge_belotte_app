import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/feedback/sound.dart';
import 'features/game/game_controller.dart';
import 'features/game/game_screen.dart';
import 'features/game/labels.dart';
import 'features/game/widgets/warm_up.dart';
import 'features/home/home_screen.dart';
import 'features/online/online_entry_screen.dart';
import 'features/online/online_controller.dart';
import 'online/host_driver.dart';
import 'online/memory_db.dart';
import 'features/online/invite/web_bridge.dart';
import 'features/online/room_code.dart';
import 'features/online/room_screen.dart';
import 'features/quick/quick_screen.dart';
import 'features/achievements/achievement_toast.dart';
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
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        if (_demoMemoryDb)
          dbConnectorProvider.overrideWithValue(
            () async => _demoServer.client('demo-player'),
          ),
      ],
      child: const BelotApp(),
    ),
  );
}

/// Development builds only (`--dart-define=DEMO_MEMORY_DB=true`, used for
/// screenshots): online features run against an in-memory backend, so
/// nothing is written to the real database.
const _demoMemoryDb = bool.fromEnvironment('DEMO_MEMORY_DB');
final _demoServer = MemoryDbServer();

/// Development builds only (`--dart-define=DEMO_AUTOPLAY_MS=…`, used for
/// screenshots): faster auto-play and bots. Release builds keep defaults.
void _applyDemoTiming() {
  const autoplay = int.fromEnvironment('DEMO_AUTOPLAY_MS');
  if (autoplay <= 0) return;
  TurnTimers.autoPlayDelay = const Duration(milliseconds: autoplay);
  TurnTimers.hintDelay = const Duration(milliseconds: autoplay ~/ 2);
  GameController.botDelay = const Duration(milliseconds: 300);
  GameController.trickPause = const Duration(milliseconds: 700);
  HostDriver.botDelay = const Duration(milliseconds: 300);
  HostDriver.trickPause = const Duration(milliseconds: 700);
  HostDriver.dealEndTimeout = const Duration(seconds: 3);
  OnlineController.trickPause = const Duration(milliseconds: 700);
}

class BelotApp extends ConsumerWidget {
  const BelotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the sound pools now, not on the first sound mid-game.
    ref.read(soundPlayerProvider);
    final tint = ref.watch(tableTintProvider);
    final back = ref.watch(cardBackProvider);
    final lang = ref.watch(appLocaleProvider);
    setAppStringsLocale(lang);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(table: tint, back: back),
      darkTheme: AppTheme.dark(table: tint, back: back),
      themeMode: ref.watch(themeModeProvider),
      // Always Bulgarian unless English is picked in the settings (the
      // phone's language is deliberately ignored).
      locale: Locale(lang),
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
            const AchievementToastHost(),
          ],
        ),
      ),
      routes: {
        '/': (_) => const _RootGate(),
        '/game': (_) => const _NameGate(child: GameScreen()),
        '/settings': (_) => const SettingsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/room': (_) => const _NameGate(child: RoomScreen()),
        '/quick': (_) => const _NameGate(child: QuickMatchScreen()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/online') {
          final args = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _NameGate(
              child: OnlineEntryScreen(
                initialCode: args is InviteArgs ? args.code : args as String?,
                fromInvite: args is InviteArgs,
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

/// The address the app was opened with (tests replace it).
@visibleForTesting
Uri Function() debugLaunchUri = () => Uri.base;

@visibleForTesting
void debugResetInvite() => _inviteHandled = false;

/// Web invite links (`?room=CODE`): once the player has a name, go straight
/// to joining that room. The query is then removed from the address bar so a
/// reload does not join again.
void _openInviteLinkOnce(BuildContext context) {
  if (_inviteHandled) return;
  _inviteHandled = true;
  final code = inviteCodeFrom(debugLaunchUri());
  if (code == null) return;
  clearInviteFromUrl();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.of(context).pushNamed('/online', arguments: InviteArgs(code));
    }
  });
}
