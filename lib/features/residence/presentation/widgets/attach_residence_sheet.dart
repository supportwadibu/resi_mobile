import 'package:flutter/material.dart';

import '../../data/models/residence_model.dart';

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

/// Rattache un logement à une résidence, ou l'en détache.
///
/// La recopie de l'adresse est proposée et non imposée : un bien déjà publié
/// porte une adresse que ses annonces affichent, et l'écraser en silence
/// changerait ce que le client a vu.
class AttachResidenceSheet extends StatefulWidget {
  const AttachResidenceSheet({
    super.key,
    required this.residences,
    required this.propertyTitle,
    this.currentResidenceId,
    this.currentUnitLabel,
  });

  final List<ResidenceModel> residences;
  final String propertyTitle;
  final String? currentResidenceId;
  final String? currentUnitLabel;

  @override
  State<AttachResidenceSheet> createState() => _AttachResidenceSheetState();
}

class _AttachResidenceSheetState extends State<AttachResidenceSheet> {
  late final TextEditingController _labelController;
  String? _residenceId;
  bool _copyAddress = false;

  bool get _isAttached => widget.currentResidenceId != null;

  @override
  void initState() {
    super.initState();
    _residenceId = widget.currentResidenceId;
    _labelController = TextEditingController(text: widget.currentUnitLabel ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rattacher à une résidence',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.propertyTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),

          const SizedBox(height: 20),

          if (widget.residences.isEmpty)
            Text(
              'Créez d’abord une résidence.',
              style: TextStyle(fontSize: 13, color: theme.hintColor),
            )
          else
            DropdownButtonFormField<String?>(
              initialValue: _residenceId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Résidence',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Aucune — bien autonome'),
                ),
                for (final residence in widget.residences)
                  DropdownMenuItem(
                    value: residence.id,
                    child: Text(
                      residence.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _residenceId = value),
            ),

          // Le libellé et la recopie n'ont de sens que rattaché : détaché, le
          // bien redevient une annonce autonome.
          if (_residenceId != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Nom du logement',
                hintText: 'Studio 1',
                helperText: 'Distinct du titre de l’annonce.',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _copyAddress,
              onChanged: (value) =>
                  setState(() => _copyAddress = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Reprendre l’adresse de la résidence',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                'Remplace l’adresse actuelle du logement.',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _residenceId == null && !_isAttached
                      ? null
                      : () => Navigator.of(context).pop(
                          AttachResidenceResult(
                            residenceId: _residenceId,
                            unitLabel: _labelController.text.trim().isEmpty
                                ? null
                                : _labelController.text.trim(),
                            copyAddress: _copyAddress,
                          ),
                        ),
                  child: Text(
                    _residenceId == null ? 'Détacher' : 'Rattacher',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
