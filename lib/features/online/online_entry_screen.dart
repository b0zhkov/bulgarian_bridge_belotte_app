import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../online/room_models.dart';
import 'online_controller.dart';

String onlineErrorText(AppLocalizations l, OnlineError e) => switch (e) {
  OnlineError.notFound => l.roomNotFound,
  OnlineError.closed => l.roomClosed,
  OnlineError.connection => l.connectionError,
};

/// "Play with friends": create a room or join one by code.
class OnlineEntryScreen extends ConsumerStatefulWidget {
  const OnlineEntryScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends ConsumerState<OnlineEntryScreen> {
  late final TextEditingController _code = TextEditingController(
    text: normalizeCode(widget.initialCode ?? ''),
  );
  bool _invalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final ok = await ref.read(onlineControllerProvider.notifier).create();
    if (ok && mounted) Navigator.of(context).pushReplacementNamed('/room');
  }

  Future<void> _join() async {
    final code = normalizeCode(_code.text);
    if (!isValidCode(code)) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    final ok = await ref.read(onlineControllerProvider.notifier).join(code);
    if (ok && mounted) Navigator.of(context).pushReplacementNamed('/room');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(onlineControllerProvider);
    final busy = s.busy;
    final error = s.error;

    Widget card({
      required Key key,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback? onTap,
    }) => Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.l + 2),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: c.textPrimary),
              ),
              const SizedBox(width: Gap.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: AppText.title - 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.label,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(Gap.page),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: Gap.xs),
                    Expanded(
                      child: Text(
                        l.onlineTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: AppText.title,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.xl),
                card(
                  key: const Key('create-room'),
                  icon: Icons.add_rounded,
                  title: l.createRoom,
                  subtitle: l.createRoomSubtitle,
                  onTap: busy ? null : _create,
                ),
                const SizedBox(height: Gap.xl),
                Text(
                  l.joinRoom,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppText.title - 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  l.joinRoomSubtitle,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: AppText.label,
                  ),
                ),
                const SizedBox(height: Gap.m),
                TextField(
                  key: const Key('code-field'),
                  controller: _code,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: kCodeLength,
                  inputFormatters: [
                    TextInputFormatter.withFunction(
                      (old, v) => v.copyWith(text: v.text.toUpperCase()),
                    ),
                  ],
                  onSubmitted: (_) => _join(),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'ABCDE',
                    hintStyle: TextStyle(
                      color: c.textSecondary.withValues(alpha: 0.4),
                      letterSpacing: 10,
                    ),
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    errorText: _invalid ? l.invalidCode : null,
                  ),
                ),
                const SizedBox(height: Gap.m),
                PillButton(
                  key: const Key('join-room'),
                  label: l.joinAction,
                  selected: true,
                  onTap: busy ? null : _join,
                ),
                const SizedBox(height: Gap.l),
                if (busy)
                  Center(
                    child: Text(
                      l.connecting,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.label,
                      ),
                    ),
                  ),
                if (error != null)
                  Text(
                    onlineErrorText(l, error),
                    key: const Key('online-error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.danger, fontSize: AppText.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
