import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'profile_controller.dart';

String? nameErrorText(AppLocalizations l, NameError? e) => switch (e) {
  null => null,
  NameError.empty => l.nameErrorEmpty,
  NameError.tooShort => l.nameErrorShort,
  NameError.tooLong => l.nameErrorLong,
  NameError.invalidChars => l.nameErrorChars,
};

/// Text field + save button for the player's name, with validation.
class NameForm extends ConsumerStatefulWidget {
  const NameForm({super.key, this.buttonLabel, this.onSaved});
  final String? buttonLabel;
  final VoidCallback? onSaved;

  @override
  ConsumerState<NameForm> createState() => _NameFormState();
}

class _NameFormState extends ConsumerState<NameForm> {
  late final TextEditingController _ctrl = TextEditingController(
    text: ref.read(playerNameProvider) ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final err = validateName(_ctrl.text);
    setState(() => _error = nameErrorText(l, err));
    if (err != null) return;
    await ref.read(playerNameProvider.notifier).set(_ctrl.text);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: c.outline, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('name-field'),
          controller: _ctrl,
          autofocus: true,
          maxLength: kNameMaxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          style: TextStyle(color: c.textPrimary, fontSize: AppText.title),
          cursorColor: c.textPrimary,
          decoration: InputDecoration(
            labelText: l.nameLabel,
            hintText: l.nameHint,
            errorText: _error,
            filled: true,
            fillColor: c.surface,
            labelStyle: TextStyle(
              color: c.textSecondary,
              fontSize: AppText.label,
            ),
            hintStyle: TextStyle(color: c.textSecondary.withValues(alpha: 0.6)),
            counterStyle: TextStyle(
              color: c.textSecondary,
              fontSize: AppText.caption,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Gap.page,
              vertical: 18,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: c.accent, width: 1.5),
            ),
            errorBorder: border.copyWith(
              borderSide: BorderSide(color: c.danger, width: 1.5),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: BorderSide(color: c.danger, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: Gap.l),
        PillButton(
          key: const Key('name-save'),
          label: widget.buttonLabel ?? l.save,
          selected: true,
          onTap: _submit,
        ),
      ],
    );
  }
}

/// Opens a bottom sheet to change the name (used from Settings).
Future<void> showNameSheet(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.page,
        0,
        Gap.page,
        Gap.page + MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.changeName,
                style: TextStyle(
                  color: ctx.colors.textPrimary,
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Gap.l),
              NameForm(onSaved: () => Navigator.of(ctx).pop()),
            ],
          ),
        ),
      ),
    ),
  );
}
