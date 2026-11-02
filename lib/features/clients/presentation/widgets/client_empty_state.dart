import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';

class ClientEmptyState extends StatelessWidget {
  const ClientEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'clients.empty_title'.tr(),
      message: 'clients.empty_body'.tr(),
      icon: AppSectionIcons.clients,
    );
  }
}
