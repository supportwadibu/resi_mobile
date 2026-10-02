import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_state.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/property_card.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import 'package:resi_africa/shared/utils/ensure_online.dart';

/// Onglet « Mes biens » : les annonces du propriétaire connecté.
class PropertyTab extends StatelessWidget {
  const PropertyTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Le cubit vient de l'écran d'accueil, partagé avec l'onglet du même parc.
    return const _PropertyTabView();
  }
}

class _PropertyTabView extends StatefulWidget {
  const _PropertyTabView();

  @override
  State<_PropertyTabView> createState() => _PropertyTabViewState();
}

class _PropertyTabViewState extends State<_PropertyTabView> {
  bool _isGrid = true;
  String _query = '';

  /// Relance la liste au retour de l'écran de dépôt, pour que l'annonce
  /// tout juste créée y figure sans que l'utilisateur ait à rafraîchir.
  Future<void> _openAddProperty() async {
    if (!await ensureOnline(context) || !mounted) return;
    await context.router.push(AddPropertyRoute());
    if (mounted) context.read<PropertyCubit>().load();
  }

  /// Ouvre la liste des résidences.
  ///
  /// Doublon assumé de la carte de l'onglet « Statistiques » : les résidences
  /// se gèrent en même temps que le parc, et non en consultant des chiffres.
  /// La liste des biens est rechargée au retour, un rattachement ou une
  /// suppression de résidence ayant pu y changer le nom affiché.
  Future<void> _openResidences() async {
    await context.router.push(const ResidenceRoute());
    if (mounted) context.read<PropertyCubit>().load();
  }

  /// Recherche locale sur le nom et la ville : la liste est déjà chargée en
  /// entier, et la filtrer sur place répond aussi hors ligne.
  List<PropertyModel> _filter(List<PropertyModel> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.address.city.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Un `Scaffold` comme les autres onglets : le `Column` nu que rendait
    // cette vue n'avait pas de hauteur bornée dans l'`IndexedStack` de
    // l'écran d'accueil, d'où l'échec de mise en page (`hasSize`).
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // L'encoche est déjà traitée par le `SafeArea` de l'écran hôte.
          PageHeader(
            title: 'home.my_properties'.tr(),
            actions: [
              AppIconButton(
                icon: AppSectionIcons.residences,
                label: 'property_tab.my_residences'.tr(),
                bordered: true,
                onPressed: _openResidences,
              ),
              AppButton(
                label: 'common.add'.tr(),
                icon: LucideIcons.plus,
                onPressed: _openAddProperty,
              ),
            ],
          ),
          Expanded(
            child: BlocBuilder<PropertyCubit, PropertyState>(
              builder: (context, state) => switch (state) {
                PropertyInitial() ||
                PropertyLoading() => const PropertyListSkeleton(),
                PropertyError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context.read<PropertyCubit>().load(),
                ),
                PropertyLoaded(:final items) when items.isEmpty => EmptyState(
                  title: 'property_tab.empty_title'.tr(),
                  message: 'property_tab.empty_body'.tr(),
                  icon: AppSectionIcons.properties,
                  actionLabel: 'home_actions.add_property'.tr(),
                  actionIcon: LucideIcons.plus,
                  onAction: _openAddProperty,
                ),
                PropertyLoaded(:final items) => _buildContent(items),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<PropertyModel> all) {
    final items = _filter(all);
    final t = context.tokens;
    return RefreshIndicator(
      onRefresh: () => context.read<PropertyCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Marge basse : hauteur de la barre flottante, voir `HomeTab`.
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: context.text.bodyMedium,
            decoration: InputDecoration(
              hintText: 'property_tab.search_hint'.tr(),
              prefixIcon: Icon(LucideIcons.search, size: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'property_tab.count'.plural(items.length),
                  style: context.text.bodyMedium!.copyWith(color: t.muted),
                ),
              ),
              _ViewToggle(
                isGrid: _isGrid,
                onChanged: (grid) => setState(() => _isGrid = grid),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(
                message: 'property_tab.no_match'.tr(),
                icon: LucideIcons.searchX,
              ),
            )
          else
            _isGrid ? _buildGrid(items) : _buildList(items),
        ],
      ),
    );
  }

  Widget _buildGrid(List<PropertyModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PropertyCard(
        data: propertyCardData(items[i]),
        onTap: () => _openDetail(items[i]),
      ),
    );
  }

  Widget _buildList(List<PropertyModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => PropertyCard(
        data: propertyCardData(items[i]),
        isListMode: true,
        onTap: () => _openDetail(items[i]),
      ),
    );
  }

  /// Ouvre la fiche du bien, puis recharge la liste.
  ///
  /// Le détail porte la modification, la publication et le rattachement à une
  /// résidence : le nom, le tarif ou la visibilité affichés ici ont pu changer
  /// pendant la consultation.
  Future<void> _openDetail(PropertyModel property) async {
    await context.router.push(PropertyDetailRoute(property: property));
    if (mounted) context.read<PropertyCubit>().load();
  }
}

/// Bascule grille / liste, deux boutons accolés dans un même cadre.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.isGrid, required this.onChanged});

  final bool isGrid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget button(IconData icon, String label, bool active, bool value) =>
        Tooltip(
          message: label,
          child: Material(
            color: active ? t.primary : t.surface,
            child: InkWell(
              onTap: () => onChanged(value),
              child: SizedBox.square(
                dimension: 32,
                child: Icon(
                  icon,
                  size: 16,
                  color: active ? t.primaryForeground : t.muted,
                ),
              ),
            ),
          ),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(LucideIcons.layoutGrid, 'property_tab.grid'.tr(), isGrid, true),
          button(LucideIcons.list, 'property_tab.list'.tr(), !isGrid, false),
        ],
      ),
    );
  }
}
