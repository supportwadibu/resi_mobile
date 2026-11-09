import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/app_text_field.dart';

/// Champ de mot de passe avec son bouton « afficher », tel que la connexion
/// le présente — repris par la réinitialisation et le changement de mot de
/// passe, pour qu'un mot de passe se saisisse partout de la même façon.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.label,
    required this.controller,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: '••••••••',
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      prefixIcon: const Icon(LucideIcons.lock, size: 16),
      suffixIcon: IconButton(
        tooltip: _obscure
            ? 'auth.show_password'.tr()
            : 'auth.hide_password'.tr(),
        icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 16),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      validator: widget.validator,
    );
  }
}

/// Règles communes d'un nouveau mot de passe : celles de l'API (8 à 64
/// caractères à la réinitialisation, 72 au changement — la plus stricte
/// s'applique ici).
abstract final class PasswordRules {
  static const minLength = 8;
  static const maxLength = 64;

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'common.field_required'.tr();
    if (value.length < minLength) return 'auth.password_too_short'.tr();
    if (value.length > maxLength) return 'auth.password_too_long'.tr();
    return null;
  }

  static String? Function(String?) confirmation(
    TextEditingController password,
  ) =>
      (value) => value != password.text ? 'auth.passwords_mismatch'.tr() : null;
}
