import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

const kAppUrl = 'https://b0zhkov.github.io/bulgarian_bridge_belotte_app/';

String inviteLink(String code) => '$kAppUrl?room=$code';

Future<void> copyInvite(BuildContext context, String code) async {
  final l = AppLocalizations.of(context);
  await Clipboard.setData(
    ClipboardData(text: l.shareText(code, inviteLink(code))),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l.codeCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Big room code card for the lobby (tap to copy the invite).
class RoomCodeCard extends StatelessWidget {
  const RoomCodeCard({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const Key('room-code'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => copyInvite(context, code),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.l,
            vertical: Gap.l,
          ),
          child: Column(
            children: [
              Text(
                l.roomCode,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: AppText.label,
                ),
              ),
              const SizedBox(height: Gap.s),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final ch in code.split(''))
                      Container(
                        width: 46,
                        height: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ch,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 16, color: c.textSecondary),
                  const SizedBox(width: Gap.xs + 2),
                  Flexible(
                    child: Text(
                      l.tapToCopy,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact code pill shown below the cards during a game.
class RoomCodeChip extends StatelessWidget {
  const RoomCodeChip({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Center(
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const Key('room-code-chip'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => copyInvite(context, code),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.l,
              vertical: Gap.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l.roomCodeShort} ',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.label,
                  ),
                ),
                Text(
                  code,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: Gap.s),
                Icon(Icons.copy_rounded, size: 16, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
