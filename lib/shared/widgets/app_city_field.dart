import 'package:flutter/material.dart';
import 'package:resi_africa/core/utils/city_service.dart';
import 'package:resi_africa/shared/widgets/app_option_picker_sheet.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';
import 'package:resi_africa/shared/widgets/skeletons/form_skeleton.dart';

/// Champ ville, dépendant du pays sélectionné.
///
/// Deux modes selon la couverture du pays : sélection dans la liste embarquée,
/// ou saisie libre. Un pays non couvert ne doit pas bloquer l'utilisateur.
class AppCityField extends StatefulWidget {
  const AppCityField({
    super.key,
    required this.countryIso2,
    required this.controller,
    this.onChanged,
    this.label = 'Ville',
    this.validator,
  });

  /// Code ISO2 du pays choisi. Un changement recharge la liste et vide la
  /// ville précédente, restée sans rapport avec le nouveau pays.
  final String countryIso2;

  final TextEditingController controller;

  /// Notifie chaque changement de ville, y compris le vidage provoqué par un
  /// changement de pays : le champ commune en dépend et doit se recharger.
  final ValueChanged<String>? onChanged;

  final String label;
  final String? Function(String?)? validator;

  @override
  State<AppCityField> createState() => _AppCityFieldState();
}

class _AppCityFieldState extends State<AppCityField> {
  List<String> _cities = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AppCityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryIso2 != widget.countryIso2) {
      // La ville retenue appartenait au pays précédent : la conserver
      // produirait un couple pays/ville incohérent.
      widget.controller.clear();
      widget.onChanged?.call('');
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cities = await CityService.instance.citiesOf(widget.countryIso2);
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _loading = false;
    });
  }

  Future<void> _openPicker() async {
    final selected = await showAppOptionPicker(
      context: context,
      options: _cities,
      searchHint: 'Rechercher une ville',
      emptyLabel: 'Aucune ville trouvée',
    );

    if (selected != null) {
      setState(() => widget.controller.text = selected);
      widget.onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le squelette occupe la place exacte du champ à venir : un texte
    // « Chargement... » dans le champ ferait clignoter la valeur.
    if (_loading) {
      return const ShimmerEffect(child: FieldSkeleton(labelWidth: 50));
    }

    // Pays non couvert : saisie libre plutôt qu'un sélecteur vide.
    if (_cities.isEmpty) {
      return AppTextField(
        label: widget.label,
        hint: 'Saisissez votre ville',
        controller: widget.controller,
        onChanged: widget.onChanged,
        prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
        validator: widget.validator,
      );
    }

    return AppTextField(
      label: widget.label,
      hint: 'Choisissez votre ville',
      controller: widget.controller,
      readOnly: true,
      onTap: _openPicker,
      prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
      validator: widget.validator,
    );
  }
}
