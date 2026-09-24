import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../business_logic/feedback_cubit.dart';
import '../../business_logic/feedback_state.dart';
import '../../data/models/feedback_model.dart';

/// Ouvre le formulaire d'avis sur l'application.
///
/// Le cubit est fourni ici et non par l'écran appelant : la feuille est son
/// seul consommateur, et le lier à la durée de vie de la feuille garantit qu'un
/// envoi en cours s'interrompt proprement à la fermeture.
Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => sl<FeedbackCubit>(),
      child: const _FeedbackSheet(),
    ),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  FeedbackType _type = FeedbackType.suggestion;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    context.read<FeedbackCubit>().submit(
      type: _type,
      title: _titleController.text,
      message: _messageController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.watch<FeedbackCubit>().state is FeedbackSubmitting;

    return BlocListener<FeedbackCubit, FeedbackState>(
      listener: (context, state) {
        switch (state) {
          case FeedbackSuccess():
            AppToast.success('feedback.success'.tr());
            Navigator.of(context).pop();
          case FeedbackError(:final message):
            AppToast.error(message);
          case FeedbackInitial():
          case FeedbackSubmitting():
            break;
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'feedback.sheet_title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'feedback.sheet_subtitle'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'feedback.type_label'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in FeedbackType.values)
                        _Chip(
                          label: 'feedback.types.${type.value}'.tr(),
                          selected: _type == type,
                          onTap: () => setState(() => _type = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'feedback.title_label'.tr(),
                    hint: 'feedback.title_hint'.tr(),
                    controller: _titleController,
                    enabled: !isSubmitting,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 3) {
                        return 'feedback.title_too_short'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'feedback.message_label'.tr(),
                    hint: 'feedback.message_hint'.tr(),
                    controller: _messageController,
                    maxLines: 5,
                    enabled: !isSubmitting,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 10) {
                        return 'feedback.message_too_short'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  AppButton(
                    label: 'feedback.submit'.tr(),
                    // `isLoading` désactive déjà l'appui : le serveur refuse
                    // deux avis rapprochés du même utilisateur, et un second
                    // appui afficherait une erreur alors que le premier envoi
                    // a abouti.
                    isLoading: isSubmitting,
                    onPressed: _submit,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Choix du type d'avis.
///
/// Une liste fermée plutôt qu'un champ libre : elle permet à l'équipe de
/// séparer les dysfonctionnements des idées, ce qu'un titre libre seul ne
/// permet pas de trier. Reprend la puce de la feuille de filtres des dépenses.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : const Color(0xffF5F5FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : const Color(0xff1D2452),
          ),
        ),
      ),
    );
  }
}
