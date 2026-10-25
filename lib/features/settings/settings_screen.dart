import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/widgets/pill_button.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.settings,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l.theme,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 28),
              Text(
                l.language,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: l.languageBulgarian,
                selected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
