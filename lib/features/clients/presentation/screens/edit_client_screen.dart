import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

import '../../business_logic/client_detail_cubit.dart';
import '../../business_logic/client_detail_state.dart';
import '../../data/models/client_model.dart';
import '../../data/models/identity_document_model.dart';
import '../widgets/create/client_text_field.dart';
import '../widgets/create/form_section_label.dart';
import '../widgets/create/identity_document_picker.dart';
import '../widgets/create/submit_client_button.dart';

/// Modification d'une fiche du carnet.
///
/// Reçoit le cubit de la fiche plutôt que d'en créer un : l'écran de détail
/// doit refléter la modification sans relire le serveur, et deux cubits sur la
/// même fiche divergeraient à la première erreur d'enregistrement.
@RoutePage()
class EditClientScreen extends StatefulWidget {
  const EditClientScreen({
    super.key,
    required this.client,
    required this.cubit,
  });

  final ClientModel client;
  final ClientDetailCubit cubit;

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _documentNumber;

  late ClientIdDocumentType? _documentType;

  /// Pièces nouvellement choisies, à téléverser à l'enregistrement.
  ///
  /// Une pièce déjà déposée n'est pas rechargée ici : le serveur ne livre que
  /// des URLs signées expirantes, pas de fichier. L'absence d'entrée signifie
  /// donc « inchangée », jamais « à supprimer ».
  final Map<DocumentSlot, IdentityDocumentModel> _documents = {};

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.client.fullName);
    _phone = TextEditingController(text: widget.client.phone);
    _whatsapp = TextEditingController(text: widget.client.whatsapp ?? '');
    _documentNumber = TextEditingController(
      text: widget.client.idDocumentNumber ?? '',
    );
    _documentType = widget.client.idDocumentType;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _documentNumber.dispose();
    super.dispose();
  }

  bool get _nameValid => _fullName.text.trim().length >= 2;
  bool get _phoneValid => _phone.text.trim().length >= 8;
  bool get _isValid => _nameValid && _phoneValid;

  /// Une valeur retouchée, ou `null` si elle n'a pas bougé.
  ///
  /// Seuls les champs modifiés partent au serveur : envoyer l'intégralité du
  /// formulaire réécrirait des valeurs que le propriétaire n'a pas touchées,
  /// et ferait échouer la mise à jour sur un numéro inchangé que le contrôle
  /// de doublon prendrait pour une collision.
  String? _changed(TextEditingController field, String? original) {
    final value = field.text.trim();
    if (value == (original ?? '').trim()) return null;
    return value;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_isValid) return;

    final client = widget.client;
    final message = await widget.cubit.save(
      client.id,
      fullName: _changed(_fullName, client.fullName),
      phone: _changed(_phone, client.phone),
      whatsapp: _changed(_whatsapp, client.whatsapp),
      idDocumentType: _documentType == client.idDocumentType
          ? null
          : _documentType,
      idDocumentNumber: _changed(_documentNumber, client.idDocumentNumber),
      documentFrontPath: _documents[DocumentSlot.recto]?.file.path,
      documentBackPath: _documents[DocumentSlot.verso]?.file.path,
    );

    if (!mounted) return;

    if (message != null) {
      AppToast.error(message, context: context);
      return;
    }

    // Sans `context` : l'écran se referme dans la foulée, et le toast doit
    // survivre à sa disparition.
    AppToast.success('Fiche mise à jour');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        appBar: AppTopBar(title: 'Modifier le client'),
        bottomNavigationBar: BlocBuilder<ClientDetailCubit, ClientDetailState>(
          builder: (context, state) {
            final isSaving = state is ClientDetailLoaded && state.isSaving;
            return SubmitClientButton(
              isLoading: isSaving,
              enabled: !isSaving,
              label: 'Enregistrer',
              onTap: _save,
            );
          },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormSectionLabel(text: 'Nom complet'),
              ClientTextField(
                hint: 'Ex : Mohamed Traoré',
                prefixIcon: LucideIcons.user,
                controller: _fullName,
                onChanged: (_) => setState(() {}),
                errorText: _submitted && !_nameValid ? 'Nom trop court' : null,
              ),
              const SizedBox(height: 20),

              const FormSectionLabel(text: 'Numéro de téléphone'),
              ClientTextField(
                hint: 'Ex : +225 07 XX XX XX XX',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                controller: _phone,
                onChanged: (_) => setState(() {}),
                errorText: _submitted && !_phoneValid
                    ? 'Numéro invalide'
                    : null,
              ),
              const SizedBox(height: 20),

              const FormSectionLabel(text: 'WhatsApp (facultatif)'),
              ClientTextField(
                hint: 'Si différent du téléphone',
                prefixIcon: LucideIcons.messageCircle,
                keyboardType: TextInputType.phone,
                controller: _whatsapp,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              const FormSectionLabel(text: "Type de pièce"),
              _DocumentTypeSelector(
                selected: _documentType,
                onSelect: (type) => setState(() => _documentType = type),
              ),
              const SizedBox(height: 20),

              const FormSectionLabel(text: "Numéro de pièce"),
              ClientTextField(
                hint: 'Ex : CI-0012345678',
                prefixIcon: LucideIcons.idCard,
                controller: _documentNumber,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              const FormSectionLabel(text: "Pièce d'identité"),
              // Les pièces déjà déposées restent en place tant qu'aucune
              // nouvelle n'est choisie : le serveur ne réécrit que ce qu'il
              // reçoit.
              if (widget.client.documentsComplete && _documents.isEmpty)
                const _ExistingDocumentsNotice(),
              IdentityDocumentPicker(
                documents: _documents,
                onAdd: (slot, file) => setState(() {
                  _documents[slot] = IdentityDocumentModel(
                    slot: slot,
                    file: file,
                  );
                }),
                onRemove: (slot) => setState(() => _documents.remove(slot)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTypeSelector extends StatelessWidget {
  const _DocumentTypeSelector({required this.selected, required this.onSelect});

  final ClientIdDocumentType? selected;
  final ValueChanged<ClientIdDocumentType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ClientIdDocumentType.values
          .map((type) {
            final isSelected = type == selected;
            return GestureDetector(
              onTap: () => onSelect(type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.tokens.foreground
                      : context.tokens.surface,
                  border: Border.all(
                    color: isSelected
                        ? context.tokens.foreground
                        : context.tokens.border,
                  ),
                ),
                child: Text(
                  type.label,
                  style: context.text.titleSmall!.copyWith(
                    color: isSelected ? context.tokens.background : null,
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ExistingDocumentsNotice extends StatelessWidget {
  const _ExistingDocumentsNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            LucideIcons.circleCheck,
            size: 16,
            color: context.tokens.accentGreen,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pièces déjà déposées. En ajouter une nouvelle la remplacera.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
