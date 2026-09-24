import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
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

  /// Paliers présentés, toujours ordonnés par durée croissante.
  ///
  /// Le tri est appliqué à l'affichage plutôt qu'au chargement : une annonce
  /// enregistrée avant cette normalisation peut porter ses paliers en
  /// désordre, et les indices manipulés ici doivent désigner ce qu'on voit.
  List<PriceTier> get _tiers => PriceTierList.sorted(widget.priceTiers);

  void _addTier() {
    final tiers = _tiers;
    if (!PriceTierList.canAppend(tiers)) return;
    widget.onTiersChanged(PriceTierList.appended(tiers));
  }

  void _removeTier(int index) {
    widget.onTiersChanged(PriceTierList.removed(_tiers, index));
  }

  void _updateTier(int index, PriceTier tier) {
    // Les bornes sont appliquées ici, pas dans le widget de ligne : un palier
    // ne se juge qu'au regard de ses voisins.
    widget.onTiersChanged(PriceTierList.replace(_tiers, index, tier));
  }

  @override
  Widget build(BuildContext context) {
    final tiers = _tiers;
    final canAdd = PriceTierList.canAppend(tiers);

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
            prefixIcon: const Icon(Icons.payments_outlined, size: 18),
            onChanged: (v) => setState(() {
              widget.onDailyChanged(double.tryParse(v) ?? 0);
            }),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Réductions par durée',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Facultatif · modifiable à tout moment',
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            if (tiers.isNotEmpty)
              TextButton.icon(
                // Désactivé plutôt que masqué : la remise maximale est
                // atteinte, et disparaître laisserait croire à un bug.
                onPressed: canAdd ? _addTier : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Palier'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  disabledForegroundColor: AppColors.grey400,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (tiers.isEmpty)
          _EmptyTiers(onAdd: _addTier)
        else
          for (final (index, tier) in tiers.indexed) ...[
            _TierRow(
              // Clé portée par le contenu du palier, jamais par son rang :
              // retirer une ligne décalerait l'état de toutes les suivantes.
              key: ValueKey('tier_${tier.minDays}_${tier.discountPercent}'),
              tier: tier,
              rank: index,
              dailyPrice: widget.dailyPrice,
              daysBounds: PriceTierList.minDaysBounds(tiers, index),
              discountBounds: PriceTierList.discountBounds(tiers, index),
              isIneffective: PriceTierList.isIneffective(tiers, index),
              onChanged: (value) => _updateTier(index, value),
              onRemove: () => _removeTier(index),
            ),
            const SizedBox(height: 10),
          ],

        if (tiers.isNotEmpty && widget.dailyPrice > 0) ...[
          const SizedBox(height: 12),
          _StaySimulator(
            pricing: PropertyPricing(
              dailyPrice: widget.dailyPrice,
              priceTiers: tiers,
            ),
          ),
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

/// Invitation à créer un premier palier.
///
/// Le bloc est une cible d'appui à part entière : à ce stade, il n'y a aucun
/// autre geste à faire dans cette zone, et chercher un bouton ailleurs serait
/// du travail inutile.
class _EmptyTiers extends StatelessWidget {
  const _EmptyTiers({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.percent_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ajouter un palier de remise',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Encourage les séjours longs. Sans palier, le prix par jour '
                's’applique quelle que soit la durée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un palier de remise, réglable et chiffré.
///
/// La ligne montre ce que le palier change réellement — prix au jour remisé et
/// total du séjour au seuil — parce qu'un pourcentage seul ne dit rien au
/// propriétaire de ce qu'il encaissera.
class _TierRow extends StatelessWidget {
  const _TierRow({
    super.key,
    required this.tier,
    required this.rank,
    required this.dailyPrice,
    required this.daysBounds,
    required this.discountBounds,
    required this.isIneffective,
    required this.onChanged,
    required this.onRemove,
  });

  final PriceTier tier;

  /// Rang dans la liste, affiché pour situer le palier parmi les autres.
  final int rank;

  final double dailyPrice;
  final TierBounds daysBounds;
  final TierBounds discountBounds;

  /// Palier hérité qui ne s'appliquera jamais : un palier plus court est déjà
  /// au moins aussi avantageux.
  final bool isIneffective;

  final ValueChanged<PriceTier> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPrice = dailyPrice > 0;
    final effective = dailyPrice * (1 - tier.discountPercent / 100);
    final total = effective * tier.minDays;
    final saved = dailyPrice * tier.minDays - total;

    final accent = isIneffective ? AppColors.warning : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isIneffective
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 0),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${rank + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dès ${tier.minDays} jours',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _DiscountBadge(percent: tier.discountPercent, color: accent),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 19),
                  color: AppColors.grey500,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Supprimer ce palier',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: 'Durée',
                    value: '${tier.minDays} j',
                    // Les bornes viennent des voisins : l'écran n'a pas à
                    // savoir qu'un palier ne peut pas en rejoindre un autre.
                    onDecrement: tier.minDays > daysBounds.min
                        ? () => onChanged(
                            tier.copyWith(minDays: tier.minDays - 1),
                          )
                        : null,
                    onIncrement:
                        daysBounds.max == null || tier.minDays < daysBounds.max!
                        ? () => onChanged(
                            tier.copyWith(minDays: tier.minDays + 1),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stepper(
                    label: 'Remise',
                    value: '${tier.discountPercent} %',
                    onDecrement: tier.discountPercent > discountBounds.min
                        ? () => onChanged(
                            tier.copyWith(
                              discountPercent: tier.discountPercent - 1,
                            ),
                          )
                        : null,
                    onIncrement:
                        discountBounds.max == null ||
                            tier.discountPercent < discountBounds.max!
                        ? () => onChanged(
                            tier.copyWith(
                              discountPercent: tier.discountPercent + 1,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          if (hasPrice) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Figure(
                      label: 'Prix / jour',
                      value: CurrencyFormatter.fcfa(effective.round()),
                    ),
                  ),
                  Expanded(
                    child: _Figure(
                      label: '${tier.minDays} jours',
                      value: CurrencyFormatter.fcfa(total.round()),
                    ),
                  ),
                  Expanded(
                    child: _Figure(
                      label: 'Le client économise',
                      value: CurrencyFormatter.fcfa(saved.round()),
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),

          if (isIneffective)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sans effet : un palier plus court accorde déjà autant. '
                      'Augmentez la remise ou supprimez ce palier.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pastille de remise, lue d'un coup d'œil dans la liste.
class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '−$percent %',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Un chiffre et son intitulé, dans le bandeau de calcul d'un palier.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: AppColors.grey500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Ce que paiera un client, pour quelques durées de séjour typiques.
///
/// Le barème se lit en pourcentages ; ce tableau le traduit en francs. C'est
/// la seule vue qui montre l'effet combiné du prix et des paliers — et donc la
/// seule qui permette de juger si le barème tient.
class _StaySimulator extends StatelessWidget {
  const _StaySimulator({required this.pricing});

  final PropertyPricing pricing;

  /// Durées présentées : une nuitée de passage, la semaine, le mois.
  ///
  /// Les seuils déclarés s'y ajoutent, sans quoi un palier réglé sur une durée
  /// inhabituelle — 45 jours — n'apparaîtrait dans aucune ligne.
  List<int> get _durations {
    final days = <int>{
      2,
      7,
      30,
      for (final tier in pricing.priceTiers) tier.minDays,
    }.toList()..sort();
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
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
              const FaIcon(
                FontAwesomeIcons.receipt,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ce que paiera le client',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final days in _durations)
            _SimulatorRow(days: days, pricing: pricing),
        ],
      ),
    );
  }
}

class _SimulatorRow extends StatelessWidget {
  const _SimulatorRow({required this.days, required this.pricing});

  final int days;
  final PropertyPricing pricing;

  @override
  Widget build(BuildContext context) {
    // `subtotalFor` reproduit le calcul du serveur : la simulation ne réinvente
    // pas la règle, elle la rejoue.
    final total = pricing.subtotalFor(days);
    final discount = pricing.discountPercentFor(days);
    final full = days * pricing.dailyPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              '$days jours',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: discount > 0
                ? Row(
                    children: [
                      Text(
                        CurrencyFormatter.fcfa(full.round()),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 11,
                        color: AppColors.grey400,
                      ),
                    ],
                  )
                : Text(
                    'plein tarif',
                    style: TextStyle(fontSize: 11, color: AppColors.grey400),
                  ),
          ),
          Text(
            CurrencyFormatter.fcfa(total.round()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: discount > 0 ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

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
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              _RoundButton(icon: Icons.remove, onTap: onDecrement),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _RoundButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                // Retour tactile : le réglage se fait par appuis répétés, et
                // sans réponse physique on ne sait pas si le geste a porté.
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          // 40 dp : seuil en deçà duquel la cible devient difficile à viser
          // au pouce, sur un réglage qu'on répète.
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 17,
            color: enabled ? AppColors.textPrimary : AppColors.grey400,
          ),
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
