import 'package:flutter/material.dart';

class ExtensionHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const ExtensionHeader({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack ?? () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xffF4F4F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              "Extensions du séjour",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}
