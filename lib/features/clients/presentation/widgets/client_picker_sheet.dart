import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/clients_cubit.dart';
import '../../business_logic/clients_state.dart';
import '../../data/models/client_model.dart';
import 'client_avatar.dart';

/// Ouvre le carnet pour choisir un client existant.
///
/// Renvoie le client choisi, ou `null` si la feuille est fermée sans
/// sélection. Le propriétaire qui ne trouve pas son client ferme la feuille et
/// le saisit : c'est pourquoi l'absence de résultat n'est pas une impasse.
Future<ClientModel?> showClientPicker(BuildContext context) {
  return showAppSheet<ClientModel>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => sl<ClientsCubit>()..load(),
      child: const _ClientPickerSheet(),
    ),
  );
}

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet();

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Charge la suite avant d'atteindre le bas, pour que le défilement ne
  /// marque pas d'arrêt.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ClientsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            AppSheetHeader(title: 'clients.pick_client'.tr()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                autofocus: false,
                onChanged: (q) => context.read<ClientsCubit>().search(q),
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'clients.name_or_number'.tr(),
                  prefixIcon: Icon(LucideIcons.search, size: 16),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ClientsCubit, ClientsState>(
                builder: (context, state) => switch (state) {
                  ClientsInitial() ||
                  ClientsLoading() => const Center(child: AppLoader()),
                  ClientsError(:final message) => ErrorState(
                    message: message,
                    onRetry: () => context.read<ClientsCubit>().load(),
                  ),
                  ClientsLoaded(items: final items) when items.isEmpty =>
                    EmptyState(
                      icon: LucideIcons.userSearch,
                      title: 'clients.none_found'.tr(),
                      message: 'clients.none_found_hint'.tr(),
                    ),
                  ClientsLoaded(:final items, :final isLoadingMore) =>
                    ListView.separated(
                      controller: _scrollController,
                      itemCount: items.length + (isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        if (i >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: AppLoader(size: 24)),
                          );
                        }
                        return _ClientTile(client: items[i]);
                      },
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(client),
      leading: ClientAvatar(initials: client.avatarInitials),
      title: Text(client.fullName, style: context.text.titleSmall),
      subtitle: Text(client.phone, style: context.text.bodySmall),
      trailing: client.documentsComplete
          ? null
          // Le dossier incomplet est signalé sans bloquer : les pièces sont
          // facultatives à l'enregistrement, et la relance se fait plus tard.
          : Tooltip(
              message: 'booking_form.id_incomplete'.tr(),
              child: Icon(
                LucideIcons.idCard,
                size: 18,
                color: context.tokens.accentAmber,
              ),
            ),
    );
  }
}
