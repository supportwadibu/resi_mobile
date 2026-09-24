import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Montant', style: AppTextStyles.labelMedium),
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
                  style: AppTextStyles.valueMedium.copyWith(fontSize: 30),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTextStyles.valueMedium.copyWith(
                      fontSize: 30,
                      color: AppColors.textLight,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Fcfa',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
