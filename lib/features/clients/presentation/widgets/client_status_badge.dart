import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../data/models/client_model.dart';

class ClientStatusBadge extends StatelessWidget {
  final ClientStatus status;

  const ClientStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == ClientStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.green.withOpacity(0.10)
            : AppColors.textSecondary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Actif' : 'Archivé',
        style: AppTextStyles.labelSmall.copyWith(
          color: isActive ? AppColors.green : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
