import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/utils/flag_helper.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';

/// Champ téléphone dont l'indicatif suit le pays sélectionné.
///
/// L'indicatif est affiché mais non saisissable : il découle du pays choisi à
/// l'étape précédente. Le contrôleur ne contient que le numéro national, la
/// forme E.164 étant recomposée à la soumission via [PhoneHelper.toE164].
///
/// L'indicatif n'est jamais utilisé en sens inverse pour deviner le pays :
/// plusieurs pays partagent le même (+1 pour US/CA, +7 pour RU/KZ).
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.countryIso2,
    required this.phoneCode,
    required this.controller,
    this.label = 'Numéro de téléphone',
  });

  final String countryIso2;

  /// Indicatif du pays, sans le `+`.
  final String phoneCode;

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.titleSmall),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: context.text.bodyMedium,
          inputFormatters: [
            // Chiffres et séparateurs de lisibilité uniquement : le `+` et
            // l'indicatif sont portés par le préfixe, les redoubler produirait
            // un numéro invalide.
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-]')),
          ],
          validator: (value) => PhoneHelper.validate(value, countryIso2),
          decoration: InputDecoration(
            hintText: PhoneHelper.hintFor(countryIso2),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    countryFlagLabel(countryIso2),
                    style: context.text.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$phoneCode',
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: t.border),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
      ],
    );
  }
}
