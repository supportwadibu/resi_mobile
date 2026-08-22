import 'package:flutter/material.dart';
import 'package:resi_africa/core/utils/city_service.dart';
import 'package:resi_africa/shared/widgets/app_option_picker_sheet.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

/// Champ commune, dépendant de la ville sélectionnée.
///
/// Se replie sur `SizedBox.shrink()` quand la ville n'a pas de communes — le
/// cas de toutes les villes ivoiriennes hors Abidjan et Yamoussoukro. Un
/// sélecteur vide serait une impasse pour l'utilisateur.
class AppCommuneField extends StatefulWidget {
  const AppCommuneField({
    super.key,
    required this.countryIso2,
    required this.city,
    required this.controller,
    this.label = 'Commune',
    this.validator,
  });

  final String countryIso2;

  /// Ville retenue. Vide tant qu'aucune n'est choisie : le champ reste alors
  /// masqué, la commune n'ayant pas de sens isolément.
  final String city;

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  State<AppCommuneField> createState() => _AppCommuneFieldState();
}

class _AppCommuneFieldState extends State<AppCommuneField> {
  List<String> _communes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AppCommuneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city ||
        oldWidget.countryIso2 != widget.countryIso2) {
      // La commune retenue appartenait à la ville précédente : la conserver
      // produirait un couple ville/commune incohérent.
      widget.controller.clear();
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.city.trim().isEmpty) {
      setState(() {
        _communes = const [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final communes = await CityService.instance.communesOf(
      widget.countryIso2,
      widget.city,
    );
    if (!mounted) return;
    setState(() {
      _communes = communes;
      _loading = false;
    });
  }

  Future<void> _openPicker() async {
    final selected = await showAppOptionPicker(
      context: context,
      options: _communes,
      searchHint: 'Rechercher une commune',
      emptyLabel: 'Aucune commune trouvée',
    );

    if (selected != null) {
      setState(() => widget.controller.text = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ville sans sous-découpage : le champ n'a pas lieu d'être.
    if (_loading || _communes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppTextField(
        label: widget.label,
        hint: 'Choisissez votre commune',
        controller: widget.controller,
        readOnly: true,
        onTap: _openPicker,
        prefixIcon: const Icon(Icons.apartment_outlined, size: 18),
        validator: widget.validator,
      ),
    );
  }
}
