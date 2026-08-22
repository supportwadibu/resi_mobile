import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

class PropertyEditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PropertyEditButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Modifier ce bien',
      onPressed: () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      fontSize: 14,
      backgroundColor: AppColors.black,
      trailingIcon: AppButtonIcon.fa(FontAwesomeIcons.penToSquare, size: 14),
      borderRadius: BorderRadius.circular(10),
    );
  }
}
