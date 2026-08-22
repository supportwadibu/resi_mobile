import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/clients_cubit.dart';
import '../../business_logic/clients_state.dart';
import '../../data/models/client_model.dart';

/// Ouvre le carnet pour choisir un client existant.
///
/// Renvoie le client choisi, ou `null` si la feuille est fermée sans
/// sélection. Le propriétaire qui ne trouve pas son client ferme la feuille et
/// le saisit : c'est pourquoi l'absence de résultat n'est pas une impasse.
Future<ClientModel?> showClientPicker(BuildContext context) {
  return showModalBottomSheet<ClientModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Choisir un client',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                autofocus: false,
                onChanged: (q) => context.read<ClientsCubit>().search(q),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nom ou numéro',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<ClientsCubit, ClientsState>(
                builder: (context, state) => switch (state) {
                  ClientsInitial() ||
                  ClientsLoading() => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  ClientsError(:final message) => _SheetMessage(
                    icon: Icons.error_outline,
                    text: message,
                  ),
                  ClientsLoaded(items: final items) when items.isEmpty =>
                    const _SheetMessage(
                      icon: Icons.person_search_outlined,
                      text:
                          'Aucun client trouvé.\nFermez pour en enregistrer un nouveau.',
                    ),
                  ClientsLoaded(:final items, :final isLoadingMore) =>
                    ListView.separated(
                      controller: _scrollController,
                      itemCount: items.length + (isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        if (i >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
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
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        child: Text(
          client.avatarInitials,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(
        client.fullName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        client.phone,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: client.documentsComplete
          ? null
          // Le dossier incomplet est signalé sans bloquer : les pièces sont
          // facultatives à l'enregistrement, et la relance se fait plus tard.
          : const Tooltip(
              message: 'Pièce d’identité incomplète',
              child: Icon(
                Icons.badge_outlined,
                size: 18,
                color: AppColors.warning,
              ),
            ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.grey500),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
