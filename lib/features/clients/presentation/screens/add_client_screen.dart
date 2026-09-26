import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/add_client_cubit.dart';
import '../../business_logic/add_client_state.dart';
import '../../data/repositories/clients_repository.dart';
import 'package:resi_africa/core/di/service_locator.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
            final cubit = context.read<AddClientCubit>();
            return SubmitClientButton(
              isLoading: state.isLoading,
              enabled: state.isValid,
              onTap: cubit.submit,
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
                  IdScanButton(
                    onScanned: (path, result) {
                      cubit.applyIdScan(path, result);
                      if (result != null) {
                        _nameController.text = result.fullName;
                      }
                    },
                  ),
                  if (state.idDocumentNumber case final number?) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        state.idDocumentType?.label,
                        number,
                      ].whereType<String>().join(' · '),
                      style: context.mutedText,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Pièces facultatives : aucun manque n'est signalé comme une
                  // erreur, la fiche se complète plus tard.
                  IdentityDocumentPicker(
                    documents: state.documents,
                    onAdd: cubit.setDocument,
                    onRemove: cubit.removeDocument,
                  ),
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
