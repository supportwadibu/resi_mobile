import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

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
import '../../data/services/id_card_reading.dart';
import '../../data/services/id_scan_service.dart';
import '../widgets/create/client_identity_controller.dart';
import '../widgets/create/client_identity_fields.dart';
import '../widgets/create/client_text_field.dart';
import '../widgets/create/id_scan_button.dart';
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

  /// Pièce et identité, préremplissables par la lecture de la pièce.
  late final ClientIdentityController _identity;

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
    _identity = ClientIdentityController(
      documentType: widget.client.idDocumentType,
      documentNumber: widget.client.idDocumentNumber,
      identity: widget.client.identity,
    );
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _identity.dispose();
    super.dispose();
  }

  /// Reporte une lecture de la pièce. Le nom d'une fiche existante n'est
  /// remplacé que par un scan explicite : il figure déjà sur les
  /// réservations, et une photo déposée ne doit pas le réécrire en douce.
  void _applyReading(IdCardReading reading, {required bool overwrite}) {
    setState(() {
      _identity.apply(reading, overwrite: overwrite);
      final name = reading.fullName;
      if (name != null && overwrite) _fullName.text = name;
    });
  }

  /// Lit une face déposée, en arrière-plan : son échec ne se signale pas.
  Future<void> _readDocument(File file) async {
    final reading = await const IdScanService().scan(file.path);
    if (reading == null || !mounted) return;
    _applyReading(reading, overwrite: false);
  }

  /// L'identité part entière dès qu'un de ses champs a bougé : aucun contrôle
  /// de doublon ne pèse sur elle, et l'envoyer d'un bloc permet d'effacer un
  /// champ vidé.
  ClientIdentity? get _changedIdentity {
    final before = widget.client.identity;
    final after = _identity.identity;
    final changed =
        before.birthDate != after.birthDate ||
        before.birthPlace != after.birthPlace ||
        before.nationality != after.nationality ||
        before.address != after.address ||
        before.idDocumentIssuedAt != after.idDocumentIssuedAt;
    return changed ? after : null;
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
      idDocumentType: _identity.documentType == client.idDocumentType
          ? null
          : _identity.documentType,
      idDocumentNumber: _changed(
        _identity.documentNumber,
        client.idDocumentNumber,
      ),
      identity: _changedIdentity,
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
    AppToast.success(
      widget.cubit.lastSaveQueued
          ? 'offline_queue.saved'.tr()
          : 'clients.record_updated'.tr(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        appBar: AppTopBar(title: 'clients.edit_title'.tr()),
        bottomNavigationBar: BlocBuilder<ClientDetailCubit, ClientDetailState>(
          builder: (context, state) {
            final isSaving = state is ClientDetailLoaded && state.isSaving;
            return SubmitClientButton(
              isLoading: isSaving,
              enabled: !isSaving,
              label: 'common.save'.tr(),
              onTap: _save,
            );
          },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSectionLabel(text: 'clients.full_name'.tr()),
              ClientTextField(
                hint: 'clients.name_hint'.tr(),
                prefixIcon: LucideIcons.user,
                controller: _fullName,
                onChanged: (_) => setState(() {}),
                errorText: _submitted && !_nameValid
                    ? 'clients.name_too_short'.tr()
                    : null,
              ),
              const SizedBox(height: 20),

              FormSectionLabel(text: 'clients.phone'.tr()),
              ClientTextField(
                hint: 'clients.phone_hint'.tr(),
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                controller: _phone,
                onChanged: (_) => setState(() {}),
                errorText: _submitted && !_phoneValid
                    ? 'clients.phone_invalid'.tr()
                    : null,
              ),
              const SizedBox(height: 20),

              FormSectionLabel(text: 'clients.whatsapp_optional'.tr()),
              ClientTextField(
                hint: 'clients.whatsapp_hint'.tr(),
                prefixIcon: LucideIcons.messageCircle,
                keyboardType: TextInputType.phone,
                controller: _whatsapp,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              FormSectionLabel(text: 'clients.id_document'.tr()),
              IdScanButton(
                onScanned: (path, reading) {
                  setState(() {
                    _documents[DocumentSlot.verso] = IdentityDocumentModel(
                      slot: DocumentSlot.verso,
                      file: File(path),
                    );
                  });
                  if (reading != null) _applyReading(reading, overwrite: true);
                },
              ),
              const SizedBox(height: 12),
              // Les pièces déjà déposées restent en place tant qu'aucune
              // nouvelle n'est choisie : le serveur ne réécrit que ce qu'il
              // reçoit.
              if (widget.client.documentsComplete && _documents.isEmpty)
                const _ExistingDocumentsNotice(),
              IdentityDocumentPicker(
                documents: _documents,
                onAdd: (slot, file) {
                  setState(() {
                    _documents[slot] = IdentityDocumentModel(
                      slot: slot,
                      file: file,
                    );
                  });
                  if (slot != DocumentSlot.photo) _readDocument(file);
                },
                onRemove: (slot) => setState(() => _documents.remove(slot)),
              ),
              const SizedBox(height: 20),
              ClientIdentityFields(controller: _identity),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
              'clients.documents_already'.tr(),
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
