import 'package:flutter/material.dart';

class PropertyDetailHandlers {
  // Gestionnaire pour l'édition du bien
  static void onEditProperty(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le bien'),
        content: const Text(
          'Fonctionnalité à implémenter : Navigation vers l\'écran d\'édition',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Gestionnaire pour le changement de disponibilité
  static void onAvailabilityChanged({
    required BuildContext context,
    required bool newValue,
    required Function(bool) onStateChange,
  }) {
    // Mettre à jour l'état local
    onStateChange(newValue);

    // Afficher un feedback utilisateur
    _showAvailabilitySnackBar(context, newValue);

    // _updateAvailabilityInApi(context, newValue);
  }

  // Afficher un SnackBar de feedback
  static void _showAvailabilitySnackBar(
    BuildContext context,
    bool isAvailable,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAvailable
              ? '✅ Le bien est maintenant disponible'
              : '⛔ Le bien est maintenant indisponible',
        ),
        backgroundColor: isAvailable
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF5350),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Gestionnaire d'erreur pour la mise à jour de disponibilité
  static void onAvailabilityError({
    required BuildContext context,
    required bool originalValue,
    required Function(bool) onStateRevert,
  }) {
    // Revenir à l'état précédent
    onStateRevert(originalValue);

    // Afficher l'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Erreur lors de la mise à jour de la disponibilité'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
