import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rounded pill button in the Offsuit style.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.leading,
    this.selected = false,
    this.outlined = false,
    this.height = 56,
    this.textColor,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final bool outlined;
  final double height;
  final Color? textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final bg = selected
        ? c.accent
        : (outlined ? Colors.transparent : c.surfaceHigh);
    final fg = selected ? c.background : (textColor ?? c.textPrimary);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: outlined
              ? BorderSide(color: c.outline, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    if (label.isNotEmpty) const SizedBox(width: 6),
                  ],
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  if (label.isNotEmpty)
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
