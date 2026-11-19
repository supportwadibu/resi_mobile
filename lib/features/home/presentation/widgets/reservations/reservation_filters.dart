import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../reservation/business_logic/reservation_cubit.dart';
import '../../../../reservation/business_logic/reservation_state.dart';
import '../../../../reservation/data/models/reservation_model.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

/// Recherche client et puces de statut, au-dessus de la liste des séjours.
class ReservationFilters extends StatefulWidget {
  const ReservationFilters({super.key});

  /// Du plus actuel au plus ancien : un séjour en cours intéresse le comptoir
  /// avant un séjour clos.
  static const _statuses = [
    ReservationStatus.inProgress,
    ReservationStatus.confirmed,
    ReservationStatus.completed,
    ReservationStatus.cancelled,
  ];

  @override
  State<ReservationFilters> createState() => _ReservationFiltersState();
}

class _ReservationFiltersState extends State<ReservationFilters> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<ReservationCubit>().setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReservationCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => TextField(
            controller: _controller,
            onChanged: cubit.setQuery,
            style: context.text.bodyMedium,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'reservation_filters.search_hint'.tr(),
              // Recherche en pilule, comme celle de « Mes biens ».
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Icon(LucideIcons.search, size: 18),
              ),
              prefixIconConstraints: const BoxConstraints(),
              border: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: context.tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: context.tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: context.tokens.primary),
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'reservation_filters.clear'.tr(),
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: _clear,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reconstruit à chaque état : le statut vit dans le cubit, et la puce
        // choisie doit basculer dès l'appui, avant la réponse du serveur.
        BlocBuilder<ReservationCubit, ReservationState>(
          builder: (context, _) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                AppChoiceChip(
                  label: 'reservation_filters.all'.tr(),
                  selected: cubit.status == null,
                  onTap: () => cubit.setStatus(null),
                ),
                for (final status in ReservationFilters._statuses)
                  AppChoiceChip(
                    label: status.label,
                    selected: cubit.status == status,
                    onTap: () => cubit.setStatus(status),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
