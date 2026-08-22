import 'package:flutter/material.dart';
import 'property_edit_button.dart';

class PropertyBottomNavigationBar extends StatelessWidget {
  final VoidCallback onEditPressed;

  const PropertyBottomNavigationBar({super.key, required this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(child: PropertyEditButton(onPressed: onEditPressed)),
            ],
          ),
        ),
      ),
    );
  }
}
