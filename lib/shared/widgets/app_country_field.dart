import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/utils/flag_helper.dart';

/// Champ de sélection du pays, ouvrant la liste locale de `country_picker`.
///
/// Aucune requête réseau : la liste, les indicatifs et les drapeaux sont
/// embarqués dans le paquet.
class AppCountryField extends StatelessWidget {
  const AppCountryField({
    super.key,
    required this.country,
    required this.onSelected,
    this.label = 'Pays',
    this.enabled = true,
  });

  final Country country;
  final ValueChanged<Country> onSelected;
  final String label;
  final bool enabled;

  void _open(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['CI'],
      searchAutofocus: false,
      onSelect: onSelected,
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        inputDecoration: InputDecoration(
          hintText: 'Rechercher un pays',
          filled: true,
          fillColor: AppColors.surface,
          prefixIcon: const Icon(Icons.search, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        searchTextStyle: const TextStyle(fontSize: 14),
        textStyle: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        bottomSheetHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
    );
  }

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
        GestureDetector(
          onTap: enabled ? () => _open(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF5F5F5) : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Text(
                  countryFlagLabel(country.countryCode),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // `nameLocalized` est un champ `late` que seul le
                    // sélecteur du paquet renseigne : le lire sur un pays
                    // issu de `Country.parse` lève une
                    // LateInitializationError, y compris derrière un `??`.
                    // `getTranslatedName` passe par les localisations et
                    // retombe sur le nom anglais si elles sont absentes.
                    country.getTranslatedName(context) ?? country.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.expand_more, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
