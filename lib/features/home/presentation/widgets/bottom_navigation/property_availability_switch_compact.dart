import 'package:flutter/material.dart';

class PropertyAvailabilitySwitchCompact extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const PropertyAvailabilitySwitchCompact({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFEF5350).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Statut',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                isAvailable ? 'Disponible' : 'Indisponible',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAvailable
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
            inactiveThumbColor: const Color(0xFFEF5350),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
