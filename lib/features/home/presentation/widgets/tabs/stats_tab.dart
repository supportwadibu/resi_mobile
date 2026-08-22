import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/action_grid.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/kpi_row.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/occupancy_card.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/stats_header.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatsHeader(),
            const SizedBox(height: 20),
            const OccupancyCard(),
            const SizedBox(height: 20),
            const KpiRow(),
            const SizedBox(height: 24),
            const Text(
              'Gestion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const ActionGrid(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
