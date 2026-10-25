import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'pwa_controller.dart';

/// Home-screen hints for the web app: "install" (a button on Android /
/// Chrome, short instructions on iOS Safari; never when already installed)
/// and "a new version is ready".
class PwaBanners extends ConsumerWidget {
  const PwaBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(pwaProvider);
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(pwaProvider.notifier);
    return Column(
      children: [
        if (s.updateReady)
          _Banner(
            key: const Key('pwa-update'),
            icon: Icons.system_update_alt_rounded,
            title: l.updateAvailable,
            action: l.updateNow,
            actionKey: const Key('pwa-update-now'),
            onAction: ctrl.applyUpdate,
          ),
        if (s.install != InstallHint.none)
          _Banner(
            key: const Key('pwa-install'),
            icon: Icons.install_mobile_rounded,
            title: l.installTitle,
            subtitle: l.installSubtitle,
            action: s.install == InstallHint.prompt
                ? l.installButton
                : l.installHow,
            actionKey: const Key('pwa-install-action'),
            onAction: s.install == InstallHint.prompt
                ? ctrl.install
                : () => showIosInstallSheet(context),
            onClose: ctrl.dismissInstall,
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.action,
    required this.actionKey,
    required this.onAction,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String action;
  final Key actionKey;
  final VoidCallback onAction;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: Gap.m),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.xs, Gap.m),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.textPrimary, size: 28),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                  const SizedBox(height: Gap.s),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IntrinsicWidth(
                      child: PillButton(
                        key: actionKey,
                        label: action,
                        selected: true,
                        height: 38,
                        fontSize: AppText.label,
                        onTap: onAction,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onClose != null)
              Align(
                alignment: Alignment.topCenter,
                child: IconButton(
                  key: const Key('pwa-install-close'),
                  tooltip: AppLocalizations.of(context).installDismiss,
                  icon: Icon(Icons.close, color: c.textSecondary, size: 20),
                  onPressed: onClose,
                ),
              )
            else
              const SizedBox(width: Gap.m),
          ],
        ),
      ),
    );
  }
}

/// iOS Safari has no install dialog: how to add the app via Share.
Future<void> showIosInstallSheet(BuildContext context) {
  final c = context.colors;
  final l = AppLocalizations.of(context);
  Widget step(int n, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.s),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: c.surfaceHigh,
          child: Text(
            '$n',
            style: TextStyle(color: c.textPrimary, fontSize: AppText.label),
          ),
        ),
        const SizedBox(width: Gap.m),
        Icon(icon, color: c.teamUs, size: 26),
        const SizedBox(width: Gap.m),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: c.textPrimary, fontSize: AppText.body),
          ),
        ),
      ],
    ),
  );
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: c.surface,
    builder: (ctx) => SafeArea(
      child: Padding(
        key: const Key('ios-install-sheet'),
        padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.installIosTitle,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppText.title,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Gap.m),
            step(1, Icons.ios_share, l.installIosStep1),
            step(2, Icons.add_box_outlined, l.installIosStep2),
            step(3, Icons.check_circle_outline, l.installIosStep3),
          ],
        ),
      ),
    ),
  );
}
