import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

import 'client_identity_controller.dart';
import 'client_text_field.dart';
import 'document_type_selector.dart';
import 'form_section_label.dart';

/// Pièce et identité d'une fiche : ce que le registre de police demande.
///
/// Tous les champs sont facultatifs, comme les pièces : un client venu sans
/// sa pièce s'enregistre quand même, et sa fiche se complète plus tard.
class ClientIdentityFields extends StatelessWidget {
  const ClientIdentityFields({required this.controller, super.key});

  final ClientIdentityController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSectionLabel(text: 'client_identity.document_type'.tr()),
          DocumentTypeSelector(
            selected: controller.documentType,
            onSelect: (type) => controller.documentType = type,
          ),
          const SizedBox(height: 20),
          FormSectionLabel(text: 'client_identity.document_number'.tr()),
          ClientTextField(
            hint: 'client_identity.document_number_hint'.tr(),
            prefixIcon: LucideIcons.idCard,
            controller: controller.documentNumber,
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          FormSectionLabel(text: 'client_identity.issued_at'.tr()),
          _DateField(
            value: controller.issuedAt,
            onChanged: (value) => controller.issuedAt = value,
          ),
          const SizedBox(height: 20),
          FormSectionLabel(text: 'client_identity.birth_date'.tr()),
          _DateField(
            value: controller.birthDate,
            onChanged: (value) => controller.birthDate = value,
          ),
          const SizedBox(height: 20),
          FormSectionLabel(text: 'client_identity.birth_place'.tr()),
          ClientTextField(
            hint: 'client_identity.birth_place_hint'.tr(),
            prefixIcon: LucideIcons.mapPin,
            controller: controller.birthPlace,
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          FormSectionLabel(text: 'client_identity.nationality'.tr()),
          ClientTextField(
            hint: 'client_identity.nationality_hint'.tr(),
            prefixIcon: LucideIcons.flag,
            controller: controller.nationality,
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          FormSectionLabel(text: 'client_identity.address'.tr()),
          ClientTextField(
            hint: 'client_identity.address_hint'.tr(),
            prefixIcon: LucideIcons.house,
            controller: controller.address,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

/// Date calendaire, choisie au sélecteur et effaçable.
class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      // Naissance comme délivrance sont passées : une date future serait une
      // faute de saisie.
      lastDate: now,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = value;
    final text = date == null ? '' : DateFormat('dd/MM/yyyy').format(date);

    return TextField(
      readOnly: true,
      controller: TextEditingController(text: text),
      onTap: () => _pick(context),
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: 'jj/mm/aaaa',
        prefixIcon: const Icon(LucideIcons.calendar, size: 16),
        suffixIcon: date == null
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                tooltip: 'common.clear'.tr(),
                onPressed: () => onChanged(null),
              ),
      ),
    );
  }
}
