import 'package:flutter/material.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

import '../../data/models/residence_model.dart';
import '../../data/repositories/residence_repository.dart';

/// Résultat du rattachement demandé dans la feuille.
class AttachResidenceResult {
  const AttachResidenceResult({
    required this.residenceId,
    this.unitLabel,
    this.copyAddress = false,
  });

  /// `null` détache le bien de sa résidence.
  final String? residenceId;
  final String? unitLabel;
  final bool copyAddress;
}

/// L'utilisateur demande à créer une résidence plutôt qu'à en choisir une.
///
/// Renvoyé par la feuille au lieu d'un rattachement : l'appelant seul sait
/// ouvrir le formulaire, la feuille ne connaît pas le routeur.
class AttachResidenceCreateRequested extends AttachResidenceResult {
  const AttachResidenceCreateRequested() : super(residenceId: null);
}

/// Rattachement d'un bien à une résidence.
///
/// La liste est chargée **par la feuille**, et non avant son ouverture : un
/// appel réseau en amont laissait l'écran inerte après l'appui, sans rien
/// indiquer. La feuille apparaît donc aussitôt, son squelette en place.
class AttachResidenceSheet extends StatefulWidget {
  const AttachResidenceSheet({
    super.key,
    required this.propertyTitle,
    this.currentResidenceId,
    this.currentUnitLabel,
  });

  final String propertyTitle;
  final String? currentResidenceId;
  final String? currentUnitLabel;

  static Future<AttachResidenceResult?> show(
    BuildContext context, {
    required String propertyTitle,
    String? currentResidenceId,
    String? currentUnitLabel,
  }) {
    return showModalBottomSheet<AttachResidenceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AttachResidenceSheet(
        propertyTitle: propertyTitle,
        currentResidenceId: currentResidenceId,
        currentUnitLabel: currentUnitLabel,
      ),
    );
  }

  @override
  State<AttachResidenceSheet> createState() => _AttachResidenceSheetState();
}

class _AttachResidenceSheetState extends State<AttachResidenceSheet> {
  late final TextEditingController _labelController;
  String? _residenceId;
  bool _copyAddress = false;

  List<ResidenceModel> _residences = const [];
  bool _isLoading = true;
  String? _loadError;

  bool get _isAttached => widget.currentResidenceId != null;

  /// Rien à valider : ni résidence choisie, ni rattachement à défaire.
  bool get _canSubmit => _residenceId != null || _isAttached;

  @override
  void initState() {
    super.initState();
    _residenceId = widget.currentResidenceId;
    _labelController = TextEditingController(
      text: widget.currentUnitLabel ?? '',
    );
    _load();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final residences = await sl<ResidenceRepository>().getAllResidences();
      if (!mounted) return;
      setState(() {
        _residences = residences;
        _isLoading = false;
      });
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _loadError = f.userMessage;
        _isLoading = false;
      });
    }
  }

  void _submit() {
    final label = _labelController.text.trim();
    Navigator.of(context).pop(
      AttachResidenceResult(
        residenceId: _residenceId,
        unitLabel: label.isEmpty ? null : label,
        copyAddress: _copyAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rattacher à une résidence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.propertyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Flexible(
              child: switch ((_isLoading, _loadError)) {
                (true, _) => const _LoadingList(),
                (_, final String error) => _LoadErrorView(
                  message: error,
                  onRetry: _load,
                ),
                _ => _body(),
              },
            ),

            if (_loadError == null) _actions(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_residences.isEmpty) return const _EmptyView();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // « Aucune » en tête, et non en fin de liste : c'est le choix qui
          // détache, on doit le trouver sans parcourir les résidences.
          _ResidenceOption(
            title: 'Aucune — bien autonome',
            subtitle: 'Le bien se loue pour lui-même.',
            icon: Icons.home_outlined,
            isSelected: _residenceId == null,
            onTap: () => setState(() => _residenceId = null),
          ),
          const SizedBox(height: 8),

          for (final residence in _residences) ...[
            _ResidenceOption(
              title: residence.name,
              subtitle: switch (residence.unitsCount) {
                0 => residence.address.city,
                1 => '${residence.address.city} · 1 logement',
                final count => '${residence.address.city} · $count logements',
              },
              icon: Icons.apartment_rounded,
              isSelected: _residenceId == residence.id,
              onTap: () => setState(() => _residenceId = residence.id),
            ),
            const SizedBox(height: 8),
          ],

          // Proposé même quand la liste est fournie : la résidence voulue peut
          // n'avoir jamais été créée.
          const SizedBox(height: 4),
          _CreateResidenceButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const AttachResidenceCreateRequested()),
          ),

          // Le libellé et la recopie n'ont de sens que rattaché : détaché, le
          // bien redevient une annonce autonome.
          if (_residenceId != null) ...[
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nom du logement',
              hint: 'Ex: Studio 1',
              controller: _labelController,
              prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Distinct du titre de l’annonce.',
              style: TextStyle(fontSize: 11, color: AppColors.grey500),
            ),
            const SizedBox(height: 16),
            _CopyAddressToggle(
              value: _copyAddress,
              onChanged: (value) => setState(() => _copyAddress = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                side: const BorderSide(color: AppColors.grey200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading || !_canSubmit ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                disabledBackgroundColor: AppColors.grey200,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _residenceId == null ? 'Détacher' : 'Rattacher',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une résidence — ou l'absence de résidence — telle qu'on la choisit.
class _ResidenceOption extends StatelessWidget {
  const _ResidenceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.infoBg : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : AppColors.surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.grey500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyAddressToggle extends StatelessWidget {
  const _CopyAddressToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reprendre l’adresse de la résidence',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Remplace l’adresse actuelle du logement.',
                  style: TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Accès au formulaire de création, depuis la feuille.
class _CreateResidenceButton extends StatelessWidget {
  const _CreateResidenceButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Nouvelle résidence',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.grey200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Squelette de la liste, le temps du chargement.
///
/// Trois options annoncées, et non la hauteur maximale : le nombre de
/// résidences est inconnu à cet instant, et occuper tout l'écran pour n'en
/// afficher ensuite qu'une seule ferait s'effondrer la feuille sous les doigts.
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const ShimmerEffect(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingShimmer(height: 62, radius: 14),
            SizedBox(height: 8),
            LoadingShimmer(height: 62, radius: 14),
            SizedBox(height: 8),
            LoadingShimmer(height: 62, radius: 14),
          ],
        ),
      ),
    );
  }
}

/// Aucune résidence n'existe encore.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.infoBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune résidence pour le moment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Une résidence regroupe plusieurs logements loués séparément, '
            'qui partagent une adresse.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _CreateResidenceButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const AttachResidenceCreateRequested()),
          ),
        ],
      ),
    );
  }
}

/// La liste n'a pas pu être chargée.
class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Réessayer', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
