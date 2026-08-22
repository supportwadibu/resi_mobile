import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

class HeaderPropertyWidget extends StatelessWidget {
  const HeaderPropertyWidget({super.key, this.onSeeAll});

  /// Ouvre la liste complète. `null` laisse la flèche inactive.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Mes biens',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            AppButton(
              label: '',
              onPressed: onSeeAll ?? () {},
              padding: const EdgeInsets.symmetric(horizontal: 0),
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              trailingIcon: AppButtonIcon.material(
                Icons.arrow_forward_ios,
                size: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
