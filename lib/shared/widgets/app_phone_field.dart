import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          inputFormatters: [
            // Chiffres et séparateurs de lisibilité uniquement : le `+` et
            // l'indicatif sont portés par le préfixe, les redoubler produirait
            // un numéro invalide.
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-]')),
          ],
          validator: (value) => PhoneHelper.validate(value, countryIso2),
          decoration: InputDecoration(
            hintText: PhoneHelper.hintFor(countryIso2),
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    countryFlagLabel(countryIso2),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$phoneCode',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: AppColors.grey200),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5B4FCF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
