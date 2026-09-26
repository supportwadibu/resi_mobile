import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';

class ClientEmptyState extends StatelessWidget {
  const ClientEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Aucun client',
      message: 'Aucune fiche ne correspond à ce filtre.',
      icon: AppSectionIcons.clients,
    );
  }
}
