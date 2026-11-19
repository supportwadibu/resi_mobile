import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/router/app_router.gr.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/resi_tokens.dart';
import '../../../../property/business_logic/property_cubit.dart';
import '../../../../property/business_logic/property_state.dart';
import '../home/stats_row_widget.dart';
import '../home/top_bar_widget.dart';

/// Accueil du propriétaire, d'après les maquettes : en-tête, grand titre,
/// puces des résidences, puis les chiffres du mois.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, this.onSeeAllProperties});

  final VoidCallback? onSeeAllProperties;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // La barre des onglets flotte au-dessus du dernier bloc : l'accueil en
      // `extendBody` reporte sa hauteur dans la marge basse.
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TopBarWidget(),
          const SizedBox(height: 22),
          Text(
            'home.week_title'.tr(),
            style: context.text.displayMedium!.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _PropertyChips(onSeeAll: onSeeAllProperties),
          const SizedBox(height: 18),
          // Ouverte à tous les paliers : le tableau de bord fait partie de
          // RESI Basic. La rangée remplace d'elle-même le bénéfice par les
          // revenus et l'occupation quand le palier ne suit pas les charges.
          const StatsRowWidget(),
        ],
      ),
    );
  }
}

/// « Toutes N » mène à la liste des biens ; chaque puce ouvre sa résidence.
class _PropertyChips extends StatelessWidget {
  const _PropertyChips({this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return BlocBuilder<PropertyCubit, PropertyState>(
      builder: (context, state) {
        final items = state is PropertyLoaded ? state.items : const [];
        Widget chip(String label, VoidCallback? onTap, {int? count}) {
          final primary = count != null;
          final fg = primary ? t.primaryForeground : t.foreground;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: primary ? t.primary : t.surface,
              shape: StadiumBorder(
                side: primary ? BorderSide.none : BorderSide(color: t.border),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, primary ? 6 : 16, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: context.text.labelLarge!.copyWith(color: fg),
                      ),
                      if (primary) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 26),
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.16),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            '$count',
                            style: context.text.labelMedium!.copyWith(
                              color: fg,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              chip('home.all_properties'.tr(), onSeeAll, count: items.length),
              for (final p in items)
                chip(
                  p.title,
                  () => context.router.push(PropertyDetailRoute(property: p)),
                ),
            ],
          ),
        );
      },
    );
  }
}
