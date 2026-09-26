import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';

@RoutePage()
class PropertyScreen extends StatelessWidget {
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Mes biens'),
      body: SafeArea(child: Center(child: Text('Property Screen'))),
    );
  }
}
