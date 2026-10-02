import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter/services.dart';
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
        Text('property_form.set_price'.tr(), style: context.text.titleMedium),
        const SizedBox(height: 20),

        _PricingCard(
          icon: LucideIcons.calendarDays,
          title: 'property_form.daily_rate'.tr(),
          subtitle: 'property_form.daily_rate_hint'.tr(),
          color: context.tokens.primary,
          child: AppTextField(
            label: 'property_form.price_per_day_label'.tr(),
            hint: 'property_form.price_hint'.tr(),
            controller: _dailyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixIcon: const Icon(LucideIcons.banknote, size: 18),
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
                  Text(
                    'property_form.duration_discounts'.tr(),
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'property_form.optional_editable'.tr(),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            if (tiers.isNotEmpty)
              AppButton(
                // Désactivé plutôt que masqué : la remise maximale est
                // atteinte, et disparaître laisserait croire à un bug.
                onPressed: canAdd ? _addTier : null,
                icon: LucideIcons.plus,
                label: 'property_form.tier'.tr(),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
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

        AppCallout(
          icon: LucideIcons.info,
          tone: AppAccent.blue,
          message: 'property_form.pricing_rule'.tr(),
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
    return AppCard(
      onTap: onAdd,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const IconChip(icon: LucideIcons.percent),
            const SizedBox(height: 10),
            Text(
              'property_form.add_tier'.tr(),
              style: context.text.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'property_form.add_tier_hint'.tr(),
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
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

    // Palier sans effet : ambre, comme tout ce qui attend une correction.
    final tone = isIneffective ? AppAccent.amber : AppAccent.neutral;

    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: isIneffective
              ? context.tokens.accentAmber
              : context.tokens.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 0),
            child: Row(
              children: [
                AppBadge(label: '${rank + 1}', tone: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'property_detail.from_days'.tr(args: ['${tier.minDays}']),
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppBadge(
                  label: '−${tier.discountPercent} %',
                  tone: isIneffective ? AppAccent.amber : AppAccent.green,
                ),
                AppIconButton(
                  icon: LucideIcons.trash2,
                  label: 'property_form.remove_tier'.tr(),
                  danger: true,
                  onPressed: onRemove,
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
                    label: 'property_form.duration'.tr(),
                    value: 'property_form.days_short'.tr(
                      args: ['${tier.minDays}'],
                    ),
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
                    label: 'property_form.discount'.tr(),
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
                color: context.tokens.background,
                border: Border(top: BorderSide(color: context.tokens.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Figure(
                      label: 'property_form.price_day_short'.tr(),
                      value: CurrencyFormatter.fcfa(effective.round()),
                    ),
                  ),
                  Expanded(
                    child: _Figure(
                      label: 'property_form.days'.tr(args: ['${tier.minDays}']),
                      value: CurrencyFormatter.fcfa(total.round()),
                    ),
                  ),
                  Expanded(
                    child: _Figure(
                      label: 'property_form.client_saves'.tr(),
                      value: CurrencyFormatter.fcfa(saved.round()),
                      color: context.tokens.accentGreen,
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
                  Icon(
                    LucideIcons.triangleAlert,
                    size: 15,
                    color: context.tokens.accentAmber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'property_form.tier_no_effect'.tr(),
                      style: context.text.bodySmall!.copyWith(
                        color: context.tokens.accentAmber,
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
          style: context.text.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelMedium!.copyWith(
            color: color ?? context.tokens.foreground,
            fontWeight: FontWeight.w600,
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
        color: context.tokens.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 13, color: context.tokens.muted),
              const SizedBox(width: 8),
              Text(
                'property_form.client_pays'.tr(),
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
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
              'property_form.days'.tr(args: ['$days']),
              style: context.text.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
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
                          color: context.tokens.muted,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: context.tokens.muted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        LucideIcons.arrowRight,
                        size: 11,
                        color: context.tokens.muted,
                      ),
                    ],
                  )
                : Text(
                    'property_form.full_price'.tr(),
                    style: context.text.bodySmall,
                  ),
          ),
          Text(
            CurrencyFormatter.fcfa(total.round()),
            style: context.text.titleSmall!.copyWith(
              color: discount > 0
                  ? context.tokens.accentGreen
                  : context.tokens.foreground,
              fontWeight: FontWeight.w600,
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
        Text(label, style: context.text.bodySmall),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: context.tokens.background,
            borderRadius: AppRadius.md,
            border: Border.all(color: context.tokens.border),
          ),
          child: Row(
            children: [
              _RoundButton(icon: LucideIcons.minus, onTap: onDecrement),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _RoundButton(icon: LucideIcons.plus, onTap: onIncrement),
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
        child: SizedBox(
          // 40 dp : seuil en deçà duquel la cible devient difficile à viser
          // au pouce, sur un réglage qu'on répète.
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 17,
            color: enabled ? context.tokens.foreground : context.tokens.muted,
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

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconChip(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(subtitle, style: context.text.bodySmall),
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
