import 'package:flutter/material.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résidence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2A5A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAttached ? Icons.apartment_rounded : Icons.home_work_outlined,
                size: 18,
                color: const Color(0xFF1E2A5A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(isAttached),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAttached
                        ? (unitLabel.isEmpty
                              ? 'Logement sans libellé'
                              : unitLabel)
                        : 'Non rattaché à une résidence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: widget.onAttachPressed,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(isAttached ? 'Modifier' : 'Rattacher'),
            ),
          ],
        ),
      ],
    );
  }

  /// Nom de la résidence, ou le repli qui convient à l'étape où l'on est.
  String _title(bool isAttached) {
    if (!isAttached) return 'Bien autonome';
    if (_isLoading) return 'Chargement…';
    return _residenceName ?? 'Résidence';
  }
}
