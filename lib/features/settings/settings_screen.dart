import '../game/difficulty_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/name_form.dart';
import '../profile/profile_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final mode = ref.watch(themeModeProvider);
    final name = ref.watch(playerNameProvider);
    final hints = ref.watch(hintsEnabledProvider);
    final autoPlay = ref.watch(autoPlayEnabledProvider);
    final sound = ref.watch(soundEnabledProvider);
    final haptics = ref.watch(hapticsEnabledProvider);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.m, left: Gap.xs),
      child: Text(
        title,
        style: TextStyle(
          color: c.textSecondary,
          fontSize: AppText.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    Widget tile({required Widget child, VoidCallback? onTap, Key? key}) =>
        Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: key,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.page,
                vertical: Gap.m,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.outline),
              ),
              child: child,
            ),
          ),
        );

    Widget switchTile({
      required Key key,
      required String title,
      required String description,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => tile(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.body,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  description,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.caption,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.m),
          Switch.adaptive(
            key: key,
            value: value,
            activeTrackColor: c.success,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            onChanged: onChanged,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.settings,
          style: const TextStyle(
            fontSize: AppText.title,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.xl),
            children: [
              section(l.playerName),
              tile(
                key: const Key('change-name'),
                onTap: () => showNameSheet(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name ?? l.you,
                        key: const Key('settings-name'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.body,
                        ),
                      ),
                    ),
                    Text(
                      l.changeName,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                    const SizedBox(width: Gap.xs),
                    Icon(Icons.edit_outlined, size: 18, color: c.textSecondary),
                  ],
                ),
              ),
              section(l.theme),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      key: const Key('theme-dark'),
                      label: l.themeDark,
                      icon: Icons.dark_mode_outlined,
                      selected: mode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .set(ThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: PillButton(
                      key: const Key('theme-light'),
                      label: l.themeLight,
                      icon: Icons.light_mode_outlined,
                      selected: mode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .set(ThemeMode.light),
                    ),
                  ),
                ],
              ),
              section(l.soundSection),
              switchTile(
                key: const Key('sound-switch'),
                title: l.sound,
                description: l.soundDescription,
                value: sound,
                onChanged: (v) =>
                    ref.read(soundEnabledProvider.notifier).set(v),
              ),
              const SizedBox(height: Gap.s),
              switchTile(
                key: const Key('haptics-switch'),
                title: l.haptics,
                description: l.hapticsDescription,
                value: haptics,
                onChanged: (v) =>
                    ref.read(hapticsEnabledProvider.notifier).set(v),
              ),
              section(l.gameplay),
              switchTile(
                key: const Key('hints-switch'),
                title: l.hints,
                description: l.hintsDescription,
                value: hints,
                onChanged: (v) =>
                    ref.read(hintsEnabledProvider.notifier).set(v),
              ),
              const SizedBox(height: Gap.s),
              switchTile(
                key: const Key('autoplay-switch'),
                title: l.autoPlay,
                description: l.autoPlayDescription,
                value: autoPlay,
                onChanged: (v) =>
                    ref.read(autoPlayEnabledProvider.notifier).set(v),
              ),
              section(l.botLevel),
              Text(
                l.botLevelDescription,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.caption,
                ),
              ),
              const SizedBox(height: Gap.s),
              DifficultyPicker(
                value: ref.watch(botLevelProvider),
                onChanged: (v) => ref.read(botLevelProvider.notifier).set(v),
              ),
              section(l.language),
              tile(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.languageBulgarian,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.body,
                        ),
                      ),
                    ),
                    Icon(Icons.check_rounded, color: c.textPrimary, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
