import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
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
  return showAppSheet<void>(
    context: context,
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
      child: AppSheet(
        title: 'feedback.sheet_title'.tr(),
        description: 'feedback.sheet_subtitle'.tr(),
        footer: AppButton(
          label: 'feedback.submit'.tr(),
          icon: LucideIcons.send,
          // `isLoading` désactive déjà l'appui : le serveur refuse deux avis
          // rapprochés du même utilisateur, et un second appui afficherait une
          // erreur alors que le premier envoi a abouti.
          isLoading: isSubmitting,
          onPressed: _submit,
          expand: true,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('feedback.type_label'.tr(), style: context.text.titleSmall),
              const SizedBox(height: 8),
              // Une liste fermée plutôt qu'un champ libre : elle permet à
              // l'équipe de séparer les dysfonctionnements des idées, ce qu'un
              // titre libre seul ne permet pas de trier.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in FeedbackType.values)
                    AppChoiceChip(
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
            ],
          ),
        ),
      ),
    );
  }
}
