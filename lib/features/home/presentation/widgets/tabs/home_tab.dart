import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import '../home/header_propertys_widget.dart';
import '../home/property_grid_widget.dart';
import '../home/search_bar_widget.dart';
import '../home/stats_row_widget.dart';
import '../home/top_bar_widget.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, this.onSeeAllProperties});

  final VoidCallback? onSeeAllProperties;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PropertyCubit>()..load(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBarWidget(),
            const SizedBox(height: 24),
            const SearchBarWidget(),
            const SizedBox(height: 24),
            const StatsRowWidget(),
            const SizedBox(height: 32),
            HeaderPropertyWidget(onSeeAll: onSeeAllProperties),
            const SizedBox(height: 16),
            const PropertyGridWidget(),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}
