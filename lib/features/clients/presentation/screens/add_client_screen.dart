import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/add_client_cubit.dart';
import '../../business_logic/add_client_state.dart';
import '../../data/repositories/clients_repository.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import '../../data/models/identity_document_model.dart';
import '../../data/services/id_card_reading.dart';
import '../../data/services/id_scan_service.dart';
import '../widgets/create/client_identity_controller.dart';
import '../widgets/create/client_identity_fields.dart';
import '../widgets/create/id_scan_button.dart';
import '../widgets/create/client_text_field.dart';
import '../widgets/create/form_section_label.dart';
import '../widgets/create/identity_document_picker.dart';
import '../widgets/create/submit_client_button.dart';

@RoutePage()
class AddClientScreen extends StatelessWidget {
  const AddClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddClientCubit(sl<ClientsRepository>()),
      child: const _AddClientView(),
    );
  }
}

class _AddClientView extends StatefulWidget {
  const _AddClientView();

  @override
  State<_AddClientView> createState() => _AddClientViewState();
}

class _AddClientViewState extends State<_AddClientView> {
  /// Tenu ici pour que le nom lu sur la pièce apparaisse dans le champ.
  final _nameController = TextEditingController();

  /// Pièce et identité, préremplies par la lecture et remises au cubit à
  /// l'envoi.
  final _identity = ClientIdentityController();

  @override
  void dispose() {
    _nameController.dispose();
    _identity.dispose();
    super.dispose();
  }

  /// Reporte une lecture dans le formulaire. Le nom suit la même règle que les
  /// autres champs : remplacé par un scan, comblé s'il est vide sinon.
  void _applyReading(IdCardReading reading, {required bool overwrite}) {
    _identity.apply(reading, overwrite: overwrite);

    final name = reading.fullName;
    if (name != null && (overwrite || _nameController.text.trim().isEmpty)) {
      _nameController.text = name;
      context.read<AddClientCubit>().setFullName(name);
    }
  }

  /// Lit une face déposée dans le sélecteur, en arrière-plan : la lecture est
  /// un confort, son échec ne se signale pas.
  Future<void> _readDocument(File file) async {
    final reading = await const IdScanService().scan(file.path);
    if (reading == null || !mounted) return;
    _applyReading(reading, overwrite: false);
  }

  void _submit() {
    context.read<AddClientCubit>().submit(
      documentType: _identity.documentType,
      documentNumber: _identity.documentNumberValue,
      identity: _identity.identity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddClientCubit, AddClientState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AddClientStatus.success) {
          // Sans `context` : l'écran se referme dans la foulée, et le toast
          // doit survivre à sa disparition.
          AppToast.success(
            state.alreadyExisted
                ? 'Ce client était déjà au carnet'
                : 'Client enregistré avec succès',
          );
          Navigator.pop(context);
        }

        if (state.status == AddClientStatus.error) {
          AppToast.error(
            state.errorMessage ?? 'Une erreur est survenue',
            context: context,
          );
        }
      },
      child: Scaffold(
        appBar: AppTopBar(title: 'Nouveau client'),
        bottomNavigationBar: BlocBuilder<AddClientCubit, AddClientState>(
          builder: (context, state) {
            return SubmitClientButton(
              isLoading: state.isLoading,
              enabled: state.isValid,
              onTap: _submit,
            );
          },
        ),
        body: BlocBuilder<AddClientCubit, AddClientState>(
          builder: (context, state) {
            final cubit = context.read<AddClientCubit>();
            final submitted = state.status == AddClientStatus.error;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FormSectionLabel(text: 'Nom complet'),
                  ClientTextField(
                    controller: _nameController,
                    hint: 'Ex : Mohamed Traoré',
                    prefixIcon: LucideIcons.user,
                    onChanged: cubit.setFullName,
                    errorText: submitted && state.fullName.trim().length < 2
                        ? 'Nom trop court'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const FormSectionLabel(text: 'Numéro de téléphone'),
                  ClientTextField(
                    hint: 'Ex : +225 07 XX XX XX XX',
                    prefixIcon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
                    onChanged: cubit.setPhone,
                    errorText: submitted && state.phone.trim().length < 8
                        ? 'Numéro invalide'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const FormSectionLabel(text: "Pièce d'identité"),
                  // Un scan est explicite : ce qu'il lit remplace la saisie.
                  // La photo devient le verso, face de la bande MRZ.
                  IdScanButton(
                    onScanned: (path, reading) {
                      cubit.setDocument(DocumentSlot.verso, File(path));
                      if (reading != null) _applyReading(reading, overwrite: true);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Pièces facultatives : aucun manque n'est signalé comme une
                  // erreur, la fiche se complète plus tard. Une face déposée
                  // est lue elle aussi, mais ne comble que les champs vides.
                  IdentityDocumentPicker(
                    documents: state.documents,
                    onAdd: (slot, file) {
                      cubit.setDocument(slot, file);
                      if (slot != DocumentSlot.photo) _readDocument(file);
                    },
                    onRemove: cubit.removeDocument,
                  ),
                  const SizedBox(height: 20),
                  ClientIdentityFields(controller: _identity),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
