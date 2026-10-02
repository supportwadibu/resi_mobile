import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter/services.dart';

/// Montant de la dépense, traité comme la donnée centrale de l'écran.
///
/// Présenté en grand et en premier : c'est le seul chiffre de la saisie, et
/// le noyer dans un champ de formulaire ordinaire obligeait à le chercher
/// parmi six autres libellés de même poids.
class AmountField extends StatelessWidget {
  final TextEditingController controller;

  const AmountField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final figure = context.text.figure.copyWith(fontSize: 30);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('expense.amount'.tr(), style: context.text.titleSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  // Le clavier numérique d'iOS laisse passer la ponctuation :
                  // le filtre garde la saisie alignée sur ce que le serveur
                  // accepte.
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: figure,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: figure.copyWith(color: t.muted),
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('expense.currency'.tr(), style: context.mutedText),
            ],
          ),
        ],
      ),
    );
  }
}
