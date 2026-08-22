import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class ClientAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const ClientAvatar({super.key, required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.valueSmall.copyWith(
            color: AppColors.black,
            fontSize: size * 0.33,
          ),
        ),
      ),
    );
  }
}
