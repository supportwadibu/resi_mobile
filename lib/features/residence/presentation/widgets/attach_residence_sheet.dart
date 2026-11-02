import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/error/failures.dart';
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
    return showAppSheet<AttachResidenceResult>(
      context: context,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: 'residence.attach_to'.tr(),
            description: widget.propertyTitle,
          ),
          Flexible(
            child: switch ((_isLoading, _loadError)) {
              (true, _) => const _LoadingList(),
              (_, final String error) => ErrorState(
                message: error,
                onRetry: _load,
              ),
              _ => _body(),
            },
          ),
          if (_loadError == null) _actions(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_residences.isEmpty) return const _EmptyView();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // « Aucune » en tête, et non en fin de liste : c'est le choix qui
          // détache, on doit le trouver sans parcourir les résidences.
          AppOptionTile(
            title: 'residence.none_standalone'.tr(),
            description: 'residence.none_standalone_hint'.tr(),
            icon: LucideIcons.house,
            selected: _residenceId == null,
            onTap: () => setState(() => _residenceId = null),
          ),
          const SizedBox(height: 8),

          for (final residence in _residences) ...[
            AppOptionTile(
              title: residence.name,
              description: switch (residence.unitsCount) {
                0 => residence.address.city,
                final count => 'residence.city_units'.plural(
                  count,
                  namedArgs: {
                    'city': residence.address.city,
                    'count': '$count',
                  },
                ),
              },
              icon: AppSectionIcons.residences,
              selected: _residenceId == residence.id,
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
              label: 'residence.unit_name'.tr(),
              hint: 'residence.unit_name_hint'.tr(),
              controller: _labelController,
              prefixIcon: const Icon(LucideIcons.doorOpen, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'residence.unit_name_note'.tr(),
              style: context.text.bodySmall,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'common.cancel'.tr(),
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: _residenceId == null
                      ? 'residence.detach'.tr()
                      : 'property_detail.attach'.tr(),
                  expand: true,
                  onPressed: _isLoading || !_canSubmit ? null : _submit,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.tokens.background,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'residence.use_residence_address'.tr(),
                  style: context.text.titleSmall,
                ),
                SizedBox(height: 2),
                Text(
                  'residence.use_residence_address_hint'.tr(),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
    return AppButton(
      label: 'residence.new_title'.tr(),
      icon: LucideIcons.plus,
      variant: AppButtonVariant.secondary,
      expand: true,
      onPressed: onPressed,
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
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingShimmer(height: 62),
            SizedBox(height: 8),
            LoadingShimmer(height: 62),
            SizedBox(height: 8),
            LoadingShimmer(height: 62),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          EmptyState(
            icon: AppSectionIcons.residences,
            title: 'residence.empty_yet'.tr(),
            message: 'residence.empty_yet_body'.tr(),
          ),
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
