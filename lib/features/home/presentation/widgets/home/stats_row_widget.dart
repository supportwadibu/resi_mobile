import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

class StatsRowWidget extends StatelessWidget {
  const StatsRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            StatBoxWidget(
              value: '50',
              label: 'Mes biens',
              icon: FontAwesomeIcons.building,
            ),
            SizedBox(width: 10),
            StatBoxWidget(
              value: '1',
              label: 'Réservations',
              icon: FontAwesomeIcons.calendarCheck,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const StatBoxWidget(
              value: '13 450F',
              label: 'Mon solde',
              icon: FontAwesomeIcons.moneyBillWave,
            ),
            const SizedBox(width: 10),
            StatBoxWidget(
              value: 'Générer',
              label: 'Liens de paiement',
              icon: FontAwesomeIcons.link,
              isAction: true,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class StatBoxWidget extends StatelessWidget {
  const StatBoxWidget({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.isAction = false,
    this.onTap,
  });

  final String value;
  final String label;
  final FaIconData? icon;
  final bool isAction;
  final VoidCallback? onTap;

  Color get _color => isAction ? AppColors.primary : AppColors.black;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.grey200.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Icône
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAction
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: FaIcon(icon, size: 18, color: _color)),
                ),

              if (icon != null) const SizedBox(width: 12),

              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
