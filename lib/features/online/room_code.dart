import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../online/room_models.dart';
import 'invite/web_bridge.dart';

const kAppUrl = 'https://b0zhkov.github.io/bulgarian_bridge_belotte_app/';

String inviteLink(String code) => '$kAppUrl?room=$code';

/// The room code carried by an invite link (`?room=CODE`), normalised, or
/// null when there is none. A malformed code is returned as typed so the
/// join screen can say it is invalid.
String? inviteCodeFrom(Uri uri) {
  final raw = uri.queryParameters['room']?.trim();
  if (raw == null || raw.isEmpty) return null;
  final code = normalizeCode(raw);
  return code.isEmpty ? raw.toUpperCase() : code;
}

/// Opens the platform share sheet with [text]; tests replace it.
@visibleForTesting
Future<ShareOutcome> Function(String title, String text, Rect? origin)
debugInviteSharer = _platformShare;

Future<ShareOutcome> _platformShare(
  String title,
  String text,
  Rect? origin,
) async {
  if (kIsWeb) return webShare(title: title, text: text);
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return ShareOutcome.unavailable;
  }
  try {
    final r = await SharePlus.instance.share(
      ShareParams(text: text, subject: title, sharePositionOrigin: origin),
    );
    return r.status == ShareResultStatus.unavailable
        ? ShareOutcome.unavailable
        : ShareOutcome.shared;
  } catch (_) {
    return ShareOutcome.unavailable;
  }
}

/// "Покани": the native / Web Share sheet with the invite text and link;
/// where there is none, the invite is copied with a toast.
Future<void> shareInvite(BuildContext context, String code) async {
  final l = AppLocalizations.of(context);
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  final outcome = await debugInviteSharer(
    l.inviteTitle,
    l.shareText(code, inviteLink(code)),
    origin,
  );
  if (outcome == ShareOutcome.shared || !context.mounted) return;
  await copyInvite(context, code);
}

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

/// Small "Покани" pill (share icon + label).
class InviteButton extends StatelessWidget {
  const InviteButton({super.key, required this.code, this.compact = false});
  final String code;

  /// In-game: a smaller pill next to the code.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Material(
      color: compact ? c.surface : c.accent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Builder(
        builder: (context) => InkWell(
          key: Key(compact ? 'invite-chip' : 'invite-button'),
          onTap: () => shareInvite(context, code),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? Gap.m : Gap.l + 2,
              vertical: compact ? Gap.xs + 2 : Gap.s + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  size: compact ? 16 : 20,
                  color: compact ? c.textPrimary : c.background,
                ),
                const SizedBox(width: Gap.xs + 2),
                Text(
                  l.invite,
                  style: TextStyle(
                    color: compact ? c.textPrimary : c.background,
                    fontSize: compact ? AppText.label : AppText.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
              const SizedBox(height: Gap.m),
              Row(
                children: [
                  Icon(Icons.copy_rounded, size: 16, color: c.textSecondary),
                  const SizedBox(width: Gap.xs + 2),
                  Expanded(
                    child: Text(
                      l.tapToCopy,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.s),
                  InviteButton(code: code),
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Gap.s,
        runSpacing: Gap.xs,
        children: [
          _chip(context, l, c),
          InviteButton(code: code, compact: true),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, AppLocalizations l, BelotColors c) {
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('room-code-chip'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => copyInvite(context, code),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.m,
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
    );
  }
}

/// Arguments for `/online` opened from an invite link or the "back to your
/// game" card: join right away.
class InviteArgs {
  const InviteArgs(this.code);
  final String code;
}
