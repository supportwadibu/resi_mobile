import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../business_logic/add_client_cubit.dart';
import '../../business_logic/add_client_state.dart';
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
      create: (_) => AddClientCubit(),
      child: const _AddClientView(),
    );
  }
}

class _AddClientView extends StatelessWidget {
  const _AddClientView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddClientCubit, AddClientState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AddClientStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Client enregistré avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        }

        if (state.status == AddClientStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Une erreur est survenue'),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Nouveau client',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BlocBuilder<AddClientCubit, AddClientState>(
          builder: (context, state) {
            final cubit = context.read<AddClientCubit>();
            return SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SubmitClientButton(
                  isLoading: state.isLoading,
                  enabled: state.isValid,
                  onTap: cubit.submit,
                ),
              ),
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
                    hint: 'Ex : Mohamed Traoré',
                    prefixIcon: Icons.person_rounded,
                    onChanged: cubit.setFullName,
                    errorText: submitted && state.fullName.trim().length < 2
                        ? 'Nom trop court'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const FormSectionLabel(text: 'Numéro de téléphone'),
                  ClientTextField(
                    hint: 'Ex : +225 07 XX XX XX XX',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    onChanged: cubit.setPhone,
                    errorText: submitted && state.phone.trim().length < 8
                        ? 'Numéro invalide'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const FormSectionLabel(text: "Pièce d'identité"),
                  IdentityDocumentPicker(
                    documents: state.documents,
                    onAdd: cubit.setDocument,
                    onRemove: cubit.removeDocument,
                    showError: submitted,
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
