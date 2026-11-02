import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.enabled = true,
    this.padding,
    this.contentPadding,
    super.key,
  }) : assert(
         !readOnly || onTap != null || controller != null,
         'readOnly nécessite soit onTap soit controller',
       );

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  /// Restreint la saisie — chiffres seuls sur un champ numérique, par exemple.
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Bordures, fond et focus viennent de `inputDecorationTheme` : un champ
    // de formulaire a la même allure qu'il passe par ce widget ou non.
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: context.text.titleSmall),
            const SizedBox(height: 6),
          ],
          GestureDetector(
            onTap: readOnly ? onTap : null,
            child: AbsorbPointer(
              absorbing: readOnly,
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                validator: validator,
                onChanged: onChanged,
                onTap: readOnly ? null : onTap,
                maxLines: maxLines,
                enabled: enabled,
                readOnly: readOnly,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: prefixIcon,
                  suffixIcon:
                      suffixIcon ??
                      (readOnly
                          ? Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: t.muted,
                            )
                          : null),
                  contentPadding: contentPadding,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
