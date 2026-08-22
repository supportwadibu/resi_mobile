import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import '../../../../data/models/property_model.dart';

/// Tarification : un prix par jour, remisé selon la durée du séjour.
///
/// Une journée court de l'heure d'arrivée à la même heure le lendemain. Les
/// paliers sont facultatifs et modifiables à tout moment depuis l'édition du
/// bien.
class StepPricingWidget extends StatefulWidget {
  const StepPricingWidget({
    super.key,
    required this.dailyPrice,
    required this.priceTiers,
    required this.onDailyChanged,
    required this.onTiersChanged,
  });

  final double dailyPrice;
  final List<PriceTier> priceTiers;
  final void Function(double) onDailyChanged;
  final void Function(List<PriceTier>) onTiersChanged;

  @override
  State<StepPricingWidget> createState() => _StepPricingWidgetState();
}

class _StepPricingWidgetState extends State<StepPricingWidget> {
  late final TextEditingController _dailyCtrl = TextEditingController(
    text: widget.dailyPrice > 0 ? widget.dailyPrice.toInt().toString() : '',
  );

  @override
  void dispose() {
    _dailyCtrl.dispose();
    super.dispose();
  }

  /// Ajoute un palier après le dernier, en laissant de la place à la saisie.
  void _addTier() {
    final tiers = [...widget.priceTiers];
    final lastDays = tiers.isEmpty ? 0 : tiers.last.minDays;

    tiers.add(
      PriceTier(
        // Suggestions usuelles : la semaine, puis le mois, puis un pas d'une
        // semaine. Le propriétaire reste libre de corriger.
        minDays: switch (lastDays) {
          0 => 7,
          < 7 => 7,
          < 30 => 30,
          _ => lastDays + 7,
        },
        discountPercent: 10,
      ),
    );

    widget.onTiersChanged(tiers);
  }

  void _removeTier(int index) {
    final tiers = [...widget.priceTiers]..removeAt(index);
    widget.onTiersChanged(tiers);
  }

  void _updateTier(int index, PriceTier tier) {
    final tiers = [...widget.priceTiers];
    tiers[index] = tier;
    widget.onTiersChanged(tiers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Définissez votre tarif',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 20),

        _PricingCard(
          icon: FontAwesomeIcons.calendarDay,
          title: 'Tarif par jour',
          subtitle: 'De l’arrivée à la même heure le lendemain',
          color: AppColors.primary,
          child: AppTextField(
            label: 'Prix / jour (FCFA)',
            hint: 'Ex: 15000',
            controller: _dailyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixIcon: const Icon(Icons.money, size: 18),
            onChanged: (v) => setState(() {
              widget.onDailyChanged(double.tryParse(v) ?? 0);
            }),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Réductions par durée',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addTier,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Facultatif : accordez une remise à partir d’un certain nombre de '
          'jours. Modifiable à tout moment.',
          style: TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        const SizedBox(height: 12),

        if (widget.priceTiers.isEmpty)
          _EmptyTiers(onAdd: _addTier)
        else
          for (final (index, tier) in widget.priceTiers.indexed) ...[
            _TierRow(
              key: ValueKey('tier_$index'),
              tier: tier,
              dailyPrice: widget.dailyPrice,
              onChanged: (value) => _updateTier(index, value),
              onRemove: () => _removeTier(index),
            ),
            const SizedBox(height: 10),
          ],

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Un séjour est facturé au prix par jour. Si sa durée atteint '
                  'un palier, la remise correspondante s’applique à tout le '
                  'séjour — la plus avantageuse en cas de chevauchement.',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Encart affiché tant qu'aucune remise n'est configurée.
class _EmptyTiers extends StatelessWidget {
  const _EmptyTiers({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Icon(Icons.percent, size: 22, color: AppColors.grey400),
            const SizedBox(height: 8),
            Text(
              'Aucune réduction',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Le prix par jour s’applique quelle que soit la durée',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un palier : durée déclenchante et pourcentage de remise.
class _TierRow extends StatelessWidget {
  const _TierRow({
    super.key,
    required this.tier,
    required this.dailyPrice,
    required this.onChanged,
    required this.onRemove,
  });

  final PriceTier tier;
  final double dailyPrice;
  final ValueChanged<PriceTier> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Prix au jour une fois la remise appliquée : c'est le montant que le
    // propriétaire a en tête, plus parlant qu'un pourcentage seul.
    final effective = dailyPrice * (1 - tier.discountPercent / 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  label: 'À partir de',
                  value: '${tier.minDays} j',
                  // Un palier à 1 jour remiserait tous les séjours : c'est le
                  // rôle du prix de base. L'API refuse `min_days` < 2.
                  onDecrement: tier.minDays > 2
                      ? () => onChanged(tier.copyWith(minDays: tier.minDays - 1))
                      : null,
                  onIncrement: () =>
                      onChanged(tier.copyWith(minDays: tier.minDays + 1)),
                ),
              ),
              Expanded(
                child: _Stepper(
                  label: 'Remise',
                  value: '${tier.discountPercent} %',
                  onDecrement: tier.discountPercent > 1
                      ? () => onChanged(
                          tier.copyWith(
                            discountPercent: tier.discountPercent - 1,
                          ),
                        )
                      : null,
                  // Plafond aligné sur le validateur serveur.
                  onIncrement: tier.discountPercent < 90
                      ? () => onChanged(
                          tier.copyWith(
                            discountPercent: tier.discountPercent + 1,
                          ),
                        )
                      : null,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                tooltip: 'Supprimer ce palier',
              ),
            ],
          ),
          if (dailyPrice > 0) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'soit ${effective.round()} F / jour dès ${tier.minDays} jours',
                style: TextStyle(fontSize: 11, color: AppColors.grey500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Incrémenteur compact — les paliers se règlent au doigt, sans clavier.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.grey500)),
        const SizedBox(height: 2),
        Row(
          children: [
            _RoundButton(icon: Icons.remove, onTap: onDecrement),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            _RoundButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? AppColors.black : AppColors.grey400,
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: FaIcon(icon, size: 15, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
