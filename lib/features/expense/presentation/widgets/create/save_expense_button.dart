import 'package:flutter/material.dart';

class SaveExpenseButton extends StatelessWidget {
  /// `null` désactive le bouton — pendant l'envoi, par exemple.
  final VoidCallback? onPressed;

  /// Libellé de remplacement, pour signaler un envoi en cours.
  final String? label;

  const SaveExpenseButton({super.key, required this.onPressed, this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label ?? "Enregistrer la dépense",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
