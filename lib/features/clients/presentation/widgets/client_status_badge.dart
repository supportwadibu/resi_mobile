import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import '../../data/models/client_model.dart';

/// Statut d'une fiche du carnet : actif en règle (vert), archivé hors
/// circuit (neutre).
class ClientStatusBadge extends StatelessWidget {
  final ClientStatus status;

  const ClientStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: status.label,
      tone: StatusTones.client(status.code),
    );
  }
}
