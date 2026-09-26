import 'package:flutter/material.dart';

import '../../core/theme/resi_tokens.dart';
import 'app_badge.dart';

/// Grammaire des statuts, miroir de `STATUS_TONES` du backoffice : une
/// couleur porte le même sens dans toutes les familles, si bien qu'on lit une
/// liste sans connaître son vocabulaire. Un statut se range selon ce qu'il
/// dit du cycle de vie, pas selon sa famille.
///
/// Tout badge de statut, y compris calculé dans un écran, passe par ces tons.
enum StatusTone {
  /// Abouti ou en règle : terminé, clos, validé, actif, publié.
  done(AppAccent.green),

  /// En cours d'exécution : séjour en cours, logement loué, essai.
  ongoing(AppAccent.violet),

  /// Planifié ou pris en compte, rien à faire pour l'instant.
  upcoming(AppAccent.blue),

  /// Attend une action, ou indisponible le temps d'une intervention.
  waiting(AppAccent.amber),

  /// Arrêté par une décision ou un refus : annulé, rejeté, en conflit.
  stopped(AppAccent.red),

  /// Hors circuit sans incident : brouillon, inactif, archivé, expiré.
  idle(AppAccent.neutral);

  const StatusTone(this.accent);

  final AppAccent accent;
}

/// Ton de chaque statut par famille, indexé par le code de l'API : les
/// deux énumérations de réservation (`reservation` et `clients`) partagent
/// ainsi une seule table.
abstract final class StatusTones {
  static StatusTone booking(String code) => switch (code) {
    'confirmed' => StatusTone.upcoming,
    'in_progress' => StatusTone.ongoing,
    'completed' => StatusTone.done,
    'cancelled' => StatusTone.stopped,
    _ => StatusTone.idle,
  };

  static StatusTone property(String code) => switch (code) {
    'published' => StatusTone.done,
    'reserved' => StatusTone.upcoming,
    'rented' => StatusTone.ongoing,
    'maintenance' => StatusTone.waiting,
    _ => StatusTone.idle,
  };

  static StatusTone client(String code) => switch (code) {
    'active' => StatusTone.done,
    _ => StatusTone.idle,
  };

  static StatusTone feedback(String code) => switch (code) {
    'new' => StatusTone.waiting,
    'read' => StatusTone.upcoming,
    'in_progress' => StatusTone.ongoing,
    'closed' => StatusTone.done,
    _ => StatusTone.idle,
  };

  /// File d'envoi hors ligne. Un conflit attend l'arbitrage du propriétaire,
  /// mais c'est un refus du serveur : rouge, comme un rejet.
  static StatusTone sync(String code) => switch (code) {
    'pending' => StatusTone.waiting,
    'conflict' || 'rejected' => StatusTone.stopped,
    _ => StatusTone.idle,
  };

  static StatusTone subscription(String code) => switch (code) {
    'active' => StatusTone.done,
    'trial' => StatusTone.ongoing,
    'pending' => StatusTone.waiting,
    'cancelled' || 'suspended' => StatusTone.stopped,
    _ => StatusTone.idle,
  };

  static StatusTone payment(String code) => switch (code) {
    'success' => StatusTone.done,
    'pending' => StatusTone.waiting,
    'failed' => StatusTone.stopped,
    _ => StatusTone.idle,
  };
}

/// Badge d'un statut : libellé fourni par le modèle, ton par la grammaire.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      AppBadge(label: label, tone: tone.accent, icon: icon);
}
