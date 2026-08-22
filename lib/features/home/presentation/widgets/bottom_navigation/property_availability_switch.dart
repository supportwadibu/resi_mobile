import 'package:flutter/material.dart';

class PropertyAvailabilitySwitch extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const PropertyAvailabilitySwitch({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF4CAF50)
              : const Color(0xFFEF5350),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isAvailable
                ? const Color(0xFF4CAF50)
                : const Color(0xFFEF5350),
          ),
          const SizedBox(width: 12),
          Text(
            isAvailable ? 'Disponible' : 'Indisponible',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
            inactiveThumbColor: const Color(0xFFEF5350),
            activeTrackColor: const Color(0xFFA5D6A7),
            inactiveTrackColor: const Color(0xFFFFCDD2),
          ),
        ],
      ),
    );
  }
}
