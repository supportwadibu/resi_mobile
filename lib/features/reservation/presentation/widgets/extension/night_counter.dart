import 'package:flutter/material.dart';

class NightCounter extends StatelessWidget {
  final int value;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const NightCounter({
    super.key,
    required this.value,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Nombre de jours supplémentaires",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F4F8),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(Icons.remove, color: Colors.grey),
              ),
            ),

            const SizedBox(width: 28),

            Column(
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff252B5C),
                  ),
                ),
                Text(
                  value > 1 ? "jours" : "jour",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(width: 28),

            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Color(0xff34C759),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
