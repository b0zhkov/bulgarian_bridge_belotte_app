import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'name_form.dart';

/// First-launch screen asking for the player's name.
class NameScreen extends StatelessWidget {
  const NameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🙂',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: Gap.xl),
                  Text(
                    l.namePromptTitle,
                    key: const Key('name-title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: Gap.s),
                  Text(
                    l.namePromptSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: AppText.label,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: Gap.xxl),
                  NameForm(buttonLabel: l.continueLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
