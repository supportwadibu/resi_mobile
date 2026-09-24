import 'package:flutter/material.dart';

class PaymentLinkButton extends StatelessWidget {
  /// `null` désactive le bouton — pendant l'envoi, notamment.
  final VoidCallback? onPressed;

  /// Remplace le libellé par un indicateur de progression.
  ///
  /// Sans lui, rien ne distinguerait un envoi en cours d'un appui sans effet,
  /// et le propriétaire réappuierait en croyant que rien ne s'est passé.
  final bool isLoading;

  const PaymentLinkButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Prolonger le séjour",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
