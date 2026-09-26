import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../subscription/presentation/widgets/plan_gate.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../../clients/data/repositories/clients_repository.dart';
import '../../../clients/presentation/screens/client_detail_screen.dart';
import '../../business_logic/stay_check_out_cubit.dart';
import '../../business_logic/stay_check_out_state.dart';
import '../../data/models/reservation_model.dart';
import '../../../home/presentation/widgets/reservations/reservation_item.dart';
import '../widgets/check_out/early_check_out_sheet.dart';

/// Fiche d'une réservation reçue.
///
/// La section « Client » n'apparaît que sur les réservations comptoir : le
/// serveur ne joint `client_snapshot` que pour celles-ci, une réservation en
/// ligne n'ayant pas de fiche au carnet du propriétaire.
@RoutePage()
class DetailsReservationScreen extends StatelessWidget {
  final ReservationModel reservation;

  const DetailsReservationScreen({super.key, required this.reservation});

  /// Ouvre la prolongation, puis referme la fiche si le séjour a changé.
  ///
  /// La fiche reçoit sa réservation en argument et ne sait pas la relire : la
  /// garder ouverte afficherait les dates et le montant d’avant. Le `true`
  /// remonte jusqu’à la liste, qui recharge.
  Future<void> _extend(BuildContext context) async {
    final router = context.router;

    final changed = await router.push<bool>(
      StayExtensionRoute(reservation: reservation),
    );

    if (changed == true) router.maybePop(true);
  }

  /// Demande si le séjour a été utilisé en entier avant de clôturer : le geste
  /// est sans retour, le serveur refusant toute prolongation d'un séjour
  /// terminé.
  ///
  /// Un séjour complet ne change que de statut ; un départ anticipé ouvre la
  /// feuille qui ramène la période et le montant à l'usage réel.
  Future<void> _confirmCheckOut(BuildContext context) async {
    final cubit = context.read<StayCheckOutCubit>();

    final fullStay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'stay_checkout.confirm_title'.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'stay_checkout.confirm_body'.tr(),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        // Trois issues : fermer la boîte sans choisir (`null`) annule, et ne
        // doit pas valoir « non ».
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(
              'stay_checkout.answer_early'.tr(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(
              'stay_checkout.answer_full'.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (fullStay == true) {
      cubit.submit(reservation.id);
      return;
    }

    if (fullStay == false && context.mounted) {
      final closed = await EarlyCheckOutSheet.show(context, reservation);
      if (closed == null || !context.mounted) return;

      AppToast.success('stay_checkout.early_success'.tr());
      // Même contrat que la clôture simple : le `true` fait recharger la liste.
      context.router.maybePop(true);
    }
  }

  void _onCheckOutChanged(BuildContext context, StayCheckOutState state) {
    switch (state) {
      case StayCheckOutSuccess():
        // Sans `context` : la fiche se referme juste après, et le toast doit
        // survivre à sa disparition pour être lu sur la liste.
        AppToast.success('stay_checkout.success'.tr());
        // Même contrat que la prolongation : le `true` fait recharger la
        // liste, qui afficherait sinon le séjour comme encore actif.
        context.router.maybePop(true);

      case StayCheckOutFailure(:final message):
        AppToast.error(message, context: context);

      case StayCheckOutIdle() || StayCheckOutSubmitting():
        break;
    }
  }

  /// Ouvre la fiche du carnet clients.
  ///
  /// Le client est relu au serveur plutôt que reconstruit depuis le résumé :
  /// `client_snapshot` est figé à la réservation — il porte le nom et le
  /// téléphone d'alors — et la fiche doit montrer le client tel qu'il est
  /// aujourd'hui, avec les champs que l'instantané ne contient pas.
  Future<void> _openClientFile(BuildContext context, String clientId) async {
    final navigator = Navigator.of(context);

    // Le chargement bloque l'écran : la lecture est courte, et un indicateur
    // dans la section laisserait le bouton actionnable une seconde fois.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const AppLoader(size: 56),
        ),
      ),
    );

    try {
      final client = await sl<ClientsRepository>().getClient(clientId);
      navigator.pop(); // referme l'indicateur

      await navigator.push(
        MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
      );
    } on AppFailure catch (f) {
      navigator.pop();
      AppToast.error(f.userMessage);
    }
  }

  /// Génère la facture et ouvre la feuille de partage, où le propriétaire
  /// choisit WhatsApp et son client.
  ///
  /// Réservée au forfait 5 000 F : c'est un document PDF.
  Future<void> _sendInvoice(BuildContext context) async {
    if (!ensureFullPlan(context)) return;

    // Le dossier du propriétaire, mis en cache à la connexion, sert d'en-tête.
    // Absent — un gérant, un cache vidé —, la facture part sans émetteur
    // plutôt que de ne pas partir.
    final owner = await sl<LocalStorage>().getPropertyManager();

    try {
      await const InvoicePdfService().share(
        reservation: reservation,
        issuer: owner == null
            ? null
            : InvoiceIssuer(name: owner.name, phone: owner.phoneNumber),
      );
    } catch (_) {
      AppToast.error('invoice.error'.tr());
    }
  }

  /// Date longue : « 12 mai 2026 ».
  static String _longDate(DateTime date) =>
      DateFormat('d MMMM y', 'fr').format(date);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StayCheckOutCubit>(),
      child: BlocConsumer<StayCheckOutCubit, StayCheckOutState>(
        listener: _onCheckOutChanged,
        builder: (context, state) => _buildScaffold(
          context,
          isSubmitting: state is StayCheckOutSubmitting,
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, {required bool isSubmitting}) {
    final property = reservation.property;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Détails de réservation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _Cover(image: property?.image),
            ),
            const SizedBox(height: 24),
            Text(
              property?.title ?? 'Bien supprimé',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (property != null && property.city.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    property.city,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
            _buildDetailRow('Date d’entrée', _longDate(reservation.startDate)),
            const SizedBox(height: 20),
            _buildDetailRow('Date de sortie', _longDate(reservation.endDate)),
            const SizedBox(height: 20),
            _buildDetailRow('Durée', reservation.durationLabel),
            const SizedBox(height: 20),
            _buildDetailRow(
              'Montant total',
              formatAmount(reservation.totalAmount),
            ),
            // Séjour écourté : les dates et le montant ci-dessus portent
            // l'usage réel, la vente d'origine reste lisible pour un litige.
            if (reservation.plannedTotalAmount case final planned?) ...[
              const SizedBox(height: 20),
              _buildDetailRow(
                'stay_checkout.planned_amount'.tr(),
                formatAmount(planned),
              ),
            ],
            if (reservation.refundedAmount > 0) ...[
              const SizedBox(height: 20),
              _buildDetailRow(
                'stay_checkout.refunded'.tr(),
                formatAmount(reservation.refundedAmount),
              ),
            ],
            if (reservation.discountAmount > 0) ...[
              const SizedBox(height: 20),
              _buildDetailRow(
                'Remise',
                '- ${formatAmount(reservation.discountAmount)}',
              ),
            ],
            // Commission due à l'apporteur, au taux figé à la réservation et
            // recalculée par le serveur quand le montant du séjour change.
            if (reservation.referrer case final referrer?) ...[
              const SizedBox(height: 20),
              _buildDetailRow(
                'referrer.label'.tr(),
                referrer.phone == null || referrer.phone!.isEmpty
                    ? referrer.name
                    : '${referrer.name} · ${referrer.phone}',
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                'referrer.commission'.tr(
                  args: [
                    '${(reservation.referrerCommissionRate * 100).round()}',
                  ],
                ),
                formatAmount(reservation.referrerCommissionAmount),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statut',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                _StatusBadge(status: reservation.status),
              ],
            ),

            // Le résumé vient de `client_snapshot` : le serveur ne le joint
            // qu'aux réservations comptoir, celles du carnet du propriétaire.
            // Une réservation en ligne n'a pas de fiche à ouvrir.
            if (reservation.client case final client?) ...[
              const SizedBox(height: 32),
              const Text(
                'Client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ClientSummary(
                client: client,
                // La fiche client relève du forfait 5 000 F.
                onOpenFile: () {
                  if (ensureFullPlan(context)) {
                    _openClientFile(context, client.id);
                  }
                },
              ),
            ],

            // Un séjour annulé n'a rien à facturer.
            if (reservation.status != ReservationStatus.cancelled) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _sendInvoice(context),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  label: Text('invoice.send'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            if (reservation.message case final message?
                when message.trim().isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Message du client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
      // Barre fixe plutôt que des boutons en fin de liste : clôture et
      // prolongation restent atteignables sans dérouler tout le détail.
      //
      // `null` quand le séjour n'est plus actif : un `if` de collection ne
      // vaut que dans une liste, et n'a pas sa place sur un argument nommé.
      bottomNavigationBar: reservation.status.isActive
          ? SafeArea(child: _buildActions(context, isSubmitting: isSubmitting))
          : null,
    );
  }

  /// Avant l'entrée du client, seule la prolongation est proposée : le
  /// serveur refuse de clôturer un séjour qui n'a pas commencé — il s'annule.
  Widget _buildActions(BuildContext context, {required bool isSubmitting}) {
    if (!reservation.hasStarted(DateTime.now())) {
      return AppBottomActionBar(
        primaryLabel: 'stay_checkout.extend_alone'.tr(),
        onPrimary: () => _extend(context),
      );
    }

    return AppBottomActionBar(
      primaryLabel: 'stay_checkout.action'.tr(),
      onPrimary: isSubmitting ? null : () => _confirmCheckOut(context),
      secondaryLabel: 'stay_checkout.extend'.tr(),
      onSecondary: () => _extend(context),
      isLoading: isSubmitting,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

/// Identité du client, telle qu'elle était au moment de la réservation.
class _ClientSummary extends StatelessWidget {
  const _ClientSummary({required this.client, required this.onOpenFile});

  final ReservationClient client;
  final VoidCallback onOpenFile;

  @override
  Widget build(BuildContext context) {
    final name = client.fullName.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.black,
                child: Text(
                  // Le carnet accepte un nom en une seule partie : l'initiale
                  // est tirée du nom entier, sans supposer un prénom.
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Client sans nom' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.phone.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenFile,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Voir la fiche client'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visuel du bien réservé, tolérant à l'absence de photo.
class _Cover extends StatelessWidget {
  const _Cover({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final source = image;

    if (source == null || source.isEmpty) return _placeholder();

    return CachedNetworkImage(
      imageUrl: source,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      placeholder: (_, _) => _loading(),
      // Distinct du chargement : une photo injoignable garde l'icône de repli,
      // là où l'animation tournerait sans fin.
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _loading() => Container(
    width: double.infinity,
    height: 200,
    color: Colors.grey.shade200,
    child: const Center(child: AppLoader(size: 56)),
  );

  Widget _placeholder() => Container(
    width: double.infinity,
    height: 200,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported_outlined, size: 40),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ReservationStatus.confirmed => (
        'Confirmée',
        const Color(0xFFD1FAE5),
        const Color(0xFF059669),
      ),
      // Le client occupe le logement : distinct de « confirmée », qui décrit
      // un séjour encore à venir.
      ReservationStatus.inProgress => (
        'En cours',
        const Color(0xFFDBEAFE),
        const Color(0xFF2563EB),
      ),
      ReservationStatus.cancelled => (
        'Annulée',
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
      ),
      ReservationStatus.completed => (
        'Terminée',
        Colors.grey.shade100,
        Colors.grey,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
