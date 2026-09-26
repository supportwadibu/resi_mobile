import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
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
    final t = context.tokens;
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['CI'],
      searchAutofocus: false,
      onSelect: onSelected,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.zero,
        backgroundColor: t.surface,
        inputDecoration: const InputDecoration(
          hintText: 'Rechercher un pays',
          prefixIcon: Icon(LucideIcons.search, size: 16),
        ),
        searchTextStyle: context.text.bodyMedium,
        textStyle: context.text.bodyMedium,
        bottomSheetHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.titleSmall),
        const SizedBox(height: 6),
        Material(
          color: t.background,
          shape: RoundedRectangleBorder(side: BorderSide(color: t.border)),
          child: InkWell(
            onTap: enabled ? () => _open(context) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Opacity(
                opacity: enabled ? 1 : 0.6,
                child: Row(
                  children: [
                    Text(
                      countryFlagLabel(country.countryCode),
                      style: context.text.titleLarge,
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
                        style: context.text.bodyMedium,
                      ),
                    ),
                    Icon(LucideIcons.chevronDown, color: t.muted, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
