import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Reactions players can send in online games. Animated ones use Noto
/// Emoji Animation (Google, CC BY 4.0, see assets/emotes/LICENSE.md); the
/// phrases are short Bulgarian quick lines. No 🤖 (reserved for bots).
enum Emote {
  clap('👏'),
  laugh('😂'),
  wow('😮'),
  huff('😤'),
  thumbs('👍'),
  pray('🙏'),
  think('🤔'),
  fire('🔥'),
  bravo(null),
  hayde(null),
  oops(null),
  gg(null);

  const Emote(this.emoji);

  /// The emoji (animated asset available) or null for a phrase.
  final String? emoji;

  bool get isPhrase => emoji == null;
  String get asset => 'assets/emotes/$name.webp';

  static Emote? parse(Object? id) {
    for (final e in values) {
      if (e.name == id) return e;
    }
    return null;
  }

  String phrase(AppLocalizations l) => switch (this) {
    bravo => l.phraseBravo,
    hayde => l.phraseHayde,
    oops => l.phraseOops,
    gg => l.phraseGg,
    _ => emoji!,
  };
}

/// An emote currently shown over a (view) seat; [nonce] restarts the
/// animation when the same emote is sent again.
class EmoteShow {
  const EmoteShow(this.emote, this.nonce);
  final Emote emote;
  final int nonce;
}

/// Client-side rate limit (the database rules enforce the same interval
/// with server timestamps; the client keeps a small margin).
class EmoteLimiter {
  EmoteLimiter({this.interval = const Duration(milliseconds: 2200)});
  final Duration interval;
  DateTime? _last;

  bool canSend([DateTime? now]) {
    final n = now ?? clock.now();
    final last = _last;
    return last == null || n.difference(last) >= interval;
  }

  /// Records a send if allowed; returns whether it was.
  bool tryUse([DateTime? now]) {
    final n = now ?? clock.now();
    if (!canSend(n)) return false;
    _last = n;
    return true;
  }
}

/// How long an emote stays over the avatar.
const kEmoteDuration = Duration(milliseconds: 2500);

/// The emote popping over an avatar: bounces in, floats, fades out.
class EmoteBurst extends StatefulWidget {
  const EmoteBurst({super.key, required this.show, this.size = 64});
  final EmoteShow show;
  final double size;

  @override
  State<EmoteBurst> createState() => _EmoteBurstState();
}

class _EmoteBurstState extends State<EmoteBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: kEmoteDuration,
  )..forward();

  @override
  void didUpdateWidget(EmoteBurst old) {
    super.didUpdateWidget(old);
    if (old.show.nonce != widget.show.nonce) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final child = EmoteFace(emote: widget.show.emote, size: widget.size);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        child: child,
        builder: (context, child) {
          final ms = _c.value * kEmoteDuration.inMilliseconds;
          final pop = reduced
              ? 1.0
              : Curves.elasticOut.transform((ms / 450).clamp(0.0, 1.0));
          final fade = ms > 2100
              ? (1 - (ms - 2100) / 400).clamp(0.0, 1.0)
              : 1.0;
          final rise = reduced ? 0.0 : -10.0 * math.min(1.0, ms / 2500);
          return Opacity(
            opacity: math.min(fade, (ms / 120).clamp(0.0, 1.0)),
            child: Transform.translate(
              offset: Offset(0, rise),
              child: Transform.scale(scale: 0.4 + 0.6 * pop, child: child),
            ),
          );
        },
      ),
    );
  }
}

/// The emote itself: animated Noto emoji, or a phrase bubble.
class EmoteFace extends StatelessWidget {
  const EmoteFace({super.key, required this.emote, this.size = 64});
  final Emote emote;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (emote.isPhrase) {
      return Container(
        key: Key('emote-${emote.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.cardFace,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          emote.phrase(AppLocalizations.of(context)),
          maxLines: 1,
          style: TextStyle(
            color: c.cardInk,
            fontSize: AppText.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return SizedBox(
      key: Key('emote-${emote.name}'),
      width: size,
      height: size,
      child: Image.asset(
        emote.asset,
        width: size,
        height: size,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        // Fallback: the static emoji if the asset can't be decoded.
        errorBuilder: (_, _, _) => Center(
          child: Text(emote.emoji!, style: TextStyle(fontSize: size * 0.7)),
        ),
      ),
    );
  }
}

/// Round emote button (online only) opening a compact picker.
class EmoteButton extends StatelessWidget {
  const EmoteButton({super.key, required this.onPick, this.canSend});
  final void Function(Emote e) onPick;

  /// Whether sending is allowed right now (rate limit); greys the picker.
  final bool Function()? canSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Tooltip(
      message: l.emote,
      child: Material(
        color: c.surfaceHigh,
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('emote-button'),
          customBorder: const CircleBorder(),
          onTap: () async {
            final e = await showEmotePicker(
              context,
              enabled: canSend?.call() ?? true,
            );
            if (e != null) onPick(e);
          },
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              Icons.emoji_emotions_outlined,
              size: 20,
              color: c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact picker: 8 animated emoji and 4 phrases.
Future<Emote?> showEmotePicker(BuildContext context, {bool enabled = true}) {
  final c = context.colors;
  return showModalBottomSheet<Emote>(
    context: context,
    backgroundColor: c.surface,
    showDragHandle: true,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      Widget item(Emote e) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          key: Key('pick-${e.name}'),
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? () => Navigator.of(ctx).pop(e) : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: e.isPhrase
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceHigh,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      e.phrase(l),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: AppText.label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : EmoteFace(emote: e, size: 52),
          ),
        ),
      );
      return SafeArea(
        child: Padding(
          key: const Key('emote-picker'),
          padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final e in Emote.values)
                    if (!e.isPhrase) item(e),
                ],
              ),
              const SizedBox(height: Gap.s),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final e in Emote.values)
                    if (e.isPhrase) item(e),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
