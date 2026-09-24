import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

import '../../../property/data/models/property_model.dart';

/// Choix d'un logement à rattacher à la résidence.
///
/// Inverse d'`AttachResidenceSheet`, qui part d'un bien pour lui choisir une
/// résidence : ici le lieu est connu, et c'est l'unité qu'on désigne.
class AttachUnitSheet extends StatelessWidget {
  const AttachUnitSheet({
    super.key,
    required this.residenceName,
    required this.candidates,
  });

  final String residenceName;

  /// Biens rattachables — ceux qui n'appartiennent à aucune résidence.
  final List<PropertyModel> candidates;

  static Future<PropertyModel?> show(
    BuildContext context, {
    required String residenceName,
    required List<PropertyModel> candidates,
  }) {
    return showModalBottomSheet<PropertyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AttachUnitSheet(
        residenceName: residenceName,
        candidates: candidates,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Rattacher un logement',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'À $residenceName. Le logement gardera son tarif et son '
              'calendrier ; seule son adresse suivra celle du lieu.',
              style: AppTextStyles.labelMedium.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            if (candidates.isEmpty)
              _NoCandidates()
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final property = candidates[index];
                    return _CandidateTile(
                      property: property,
                      onTap: () => Navigator.of(context).pop(property),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tous les biens sont déjà rattachés, ou le parc est vide.
class _NoCandidates extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Aucun logement disponible. Créez un bien, ou détachez-en un '
        'd’une autre résidence.',
        style: AppTextStyles.labelMedium.copyWith(height: 1.5),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.property, required this.onTap});

  final PropertyModel property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.valueSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.address.city,
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
