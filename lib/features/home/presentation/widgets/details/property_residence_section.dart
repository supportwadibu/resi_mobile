import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/error/failures.dart';

import '../../../../residence/data/repositories/residence_repository.dart';

/// Résidence à laquelle le bien est rattaché, et bouton pour la changer.
///
/// Le nom de la résidence n'est pas porté par le bien — l'API ne renvoie que
/// `residence_id` — il est donc chargé ici. L'appel échoue en silence : le
/// rattachement reste modifiable même si le nom manque à l'affichage, et une
/// erreur sur une information secondaire n'a pas à barrer la fiche.
class PropertyResidenceSection extends StatefulWidget {
  const PropertyResidenceSection({
    super.key,
    required this.residenceId,
    required this.unitLabel,
    required this.onAttachPressed,
  });

  /// `null` pour un bien autonome.
  final String? residenceId;
  final String? unitLabel;
  final VoidCallback onAttachPressed;

  @override
  State<PropertyResidenceSection> createState() =>
      _PropertyResidenceSectionState();
}

class _PropertyResidenceSectionState extends State<PropertyResidenceSection> {
  String? _residenceName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadResidenceName();
  }

  @override
  void didUpdateWidget(PropertyResidenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un rattachement vers une autre résidence rend le nom en cache caduc.
    if (oldWidget.residenceId != widget.residenceId) _loadResidenceName();
  }

  Future<void> _loadResidenceName() async {
    final id = widget.residenceId;

    if (id == null) {
      setState(() {
        _residenceName = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final residence = await sl<ResidenceRepository>().getResidence(id);
      if (!mounted) return;
      setState(() {
        _residenceName = residence.name;
        _isLoading = false;
      });
    } on AppFailure {
      // Le bien reste rattaché : seul son nom manque, et la section se replie
      // sur un libellé générique plutôt que d'afficher une erreur.
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAttached = widget.residenceId != null;
    final unitLabel = widget.unitLabel?.trim() ?? '';

    return Section(
      title: 'property_detail.residence'.tr(),
      icon: AppSectionIcons.residences,
      actions: [
        AppButton(
          label: isAttached
              ? 'common.edit'.tr()
              : 'property_detail.attach'.tr(),
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
          onPressed: widget.onAttachPressed,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(isAttached),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            isAttached
                ? (unitLabel.isEmpty
                      ? 'property_detail.unit_no_label'.tr()
                      : unitLabel)
                : 'property_detail.not_attached'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Nom de la résidence, ou le repli qui convient à l'étape où l'on est.
  String _title(bool isAttached) {
    if (!isAttached) return 'property_detail.standalone'.tr();
    if (_isLoading) return 'common.loading_ellipsis'.tr();
    return _residenceName ?? 'property_detail.residence'.tr();
  }
}
