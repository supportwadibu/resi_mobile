import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import '../../../clients/presentation/widgets/client_avatar.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../subscription/presentation/widgets/plan_gate.dart';
import '../../../subscription/presentation/widgets/plan_style.dart';
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

  /// Ouvre la modification, puis referme la fiche si la réservation a changé —
  /// même contrat que la prolongation : la fiche ne sait pas se relire.
  Future<void> _edit(BuildContext context) async {
    final router = context.router;

    final changed = await router.push<bool>(
      EditReservationRoute(reservation: reservation),
    );

    if (changed == true) router.maybePop(true);
  }

  /// Seule une réservation comptoir non terminée se modifie : le serveur
  /// refuse de réécrire un séjour clos ou une réservation payée en ligne.
  bool get _isEditable =>
      reservation.status.isActive &&
      reservation.source == ReservationSource.offline;

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
        title: Text('stay_checkout.confirm_title'.tr()),
        content: Text('stay_checkout.confirm_body'.tr()),
        // Trois issues : fermer la boîte sans choisir (`null`) annule, et ne
        // doit pas valoir « non ». Les deux réponses s'empilent en pleine
        // largeur : côte à côte, leurs libellés ne tiennent pas.
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: 'stay_checkout.answer_full'.tr(),
                expand: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'stay_checkout.answer_early'.tr(),
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'common.cancel'.tr(),
                variant: AppButtonVariant.ghost,
                expand: true,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
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
            color: context.tokens.surface,
            borderRadius: AppRadius.md,
            border: Border.all(color: context.tokens.border),
          ),
          child: const AppLoader(),
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
    if (!ensureFullPlan(context, PremiumFeature.invoices)) return;

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
    final t = context.tokens;

    final stay = <DetailItem>[
      DetailItem('Date d’entrée', _longDate(reservation.startDate)),
      DetailItem('Date de sortie', _longDate(reservation.endDate)),
      DetailItem('Durée', reservation.durationLabel),
    ];

    // Les libellés disent ce que les champs portent : `totalAmount` est le
    // prix convenu du séjour, pas l'argent reçu, et la remise est l'écart au
    // tarif. « Montant total 15 000 F / Remise − 205 000 F », sans le tarif,
    // ne se lisait pas.
    //
    // En ligne, la remise vient d'un code promo et `expected_amount` n'existe
    // pas — le modèle le replie sur le total : pas de tarif grille à montrer.
    final isCounter = reservation.source == ReservationSource.offline;
    final amounts = <DetailItem>[
      if (isCounter && reservation.discountAmount > 0)
        DetailItem(
          'booking_amounts.grid_price'.tr(),
          formatAmount(reservation.expectedAmount),
        ),
      if (reservation.discountAmount > 0)
        DetailItem(
          (isCounter
                  ? 'booking_amounts.negotiated_discount'
                  : 'booking_amounts.promo_discount')
              .tr(),
          '- ${formatAmount(reservation.discountAmount)}',
        ),
      DetailItem(
        'booking_amounts.stay_amount'.tr(),
        formatAmount(reservation.totalAmount),
      ),
      if (reservation.depositAmount > 0) ...[
        DetailItem(
          'booking_amounts.deposit_label'.tr(),
          formatAmount(reservation.depositAmount),
        ),
        DetailItem(
          'booking_amounts.balance_due'.tr(),
          formatAmount(reservation.balanceDue),
        ),
      ],
      // Séjour écourté : les dates et le montant ci-dessus portent l'usage
      // réel, la vente d'origine reste lisible pour un litige.
      if (reservation.plannedTotalAmount case final planned?)
        DetailItem('stay_checkout.planned_amount'.tr(), formatAmount(planned)),
      if (reservation.refundedAmount > 0)
        DetailItem(
          'stay_checkout.refunded'.tr(),
          formatAmount(reservation.refundedAmount),
        ),
      // Commission due à l'apporteur, au taux figé à la réservation et
      // recalculée par le serveur quand le montant du séjour change.
      if (reservation.referrer case final referrer?) ...[
        DetailItem(
          'referrer.label'.tr(),
          referrer.phone == null || referrer.phone!.isEmpty
              ? referrer.name
              : '${referrer.name} · ${referrer.phone}',
        ),
        DetailItem(
          'referrer.commission'.tr(
            args: ['${(reservation.referrerCommissionRate * 100).round()}'],
          ),
          formatAmount(reservation.referrerCommissionAmount),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppTopBar(
        title: 'Réservation',
        actions: [
          if (_isEditable)
            AppIconButton(
              icon: LucideIcons.pencil,
              label: 'booking_edit.action'.tr(),
              onPressed: () => _edit(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: AppRadius.md,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.md,
              child: _Cover(image: property?.image),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property?.title ?? 'Bien supprimé',
                      style: context.text.headlineSmall,
                    ),
                    if (property != null && property.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: t.muted),
                          const SizedBox(width: 4),
                          Text(property.city, style: context.mutedText),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                label: reservation.status.label,
                tone: StatusTones.booking(reservation.status.code),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Section(
            title: 'Séjour',
            icon: AppSectionIcons.bookings,
            child: DetailList(items: stay),
          ),
          const SizedBox(height: 12),
          Section(
            title: 'Montants',
            icon: LucideIcons.banknote,
            child: DetailList(items: amounts),
          ),

          // Le résumé vient de `client_snapshot` : le serveur ne le joint
          // qu'aux réservations comptoir, celles du carnet du propriétaire.
          // Une réservation en ligne n'a pas de fiche à ouvrir.
          if (reservation.client case final client?) ...[
            const SizedBox(height: 12),
            Section(
              title: 'Client',
              icon: AppSectionIcons.clients,
              child: _ClientSummary(
                client: client,
                // La fiche client relève du forfait 5 000 F.
                onOpenFile: () {
                  if (ensureFullPlan(context, PremiumFeature.clients)) {
                    _openClientFile(context, client.id);
                  }
                },
              ),
            ),
          ],

          if (reservation.message case final message?
              when message.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Section(
              title: 'Message du client',
              icon: AppSectionIcons.reviews,
              child: Text(
                message,
                style: context.mutedText.copyWith(height: 1.5),
              ),
            ),
          ],

          // Un séjour annulé n'a rien à facturer.
          if (reservation.status != ReservationStatus.cancelled) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sendInvoice(context),
                // Logo de marque : WhatsApp reste reconnaissable, là où une
                // bulle générique ne dirait pas où part la facture.
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('invoice.send'.tr()),
                    if (!hasFullPlan()) ...[
                      const SizedBox(width: 8),
                      const PremiumBadge(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      // Barre fixe plutôt que des boutons en fin de liste : clôture et
      // prolongation restent atteignables sans dérouler tout le détail.
      //
      // `null` quand le séjour n'est plus actif : un `if` de collection ne
      // vaut que dans une liste, et n'a pas sa place sur un argument nommé.
      bottomNavigationBar: reservation.status.isActive
          ? _buildActions(context, isSubmitting: isSubmitting)
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
}

/// Identité du client, telle qu'elle était au moment de la réservation.
class _ClientSummary extends StatelessWidget {
  const _ClientSummary({required this.client, required this.onOpenFile});

  final ReservationClient client;
  final VoidCallback onOpenFile;

  @override
  Widget build(BuildContext context) {
    final name = client.fullName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Le carnet accepte un nom en une seule partie : l'initiale est
            // tirée du nom entier, sans supposer un prénom.
            ClientAvatar(initials: name.isEmpty ? '?' : name[0].toUpperCase()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Client sans nom' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (client.phone.trim().isNotEmpty)
                    Text(client.phone, style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Voir la fiche client',
          icon: LucideIcons.user,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: onOpenFile,
        ),
      ],
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

    if (source == null || source.isEmpty) return _placeholder(context);

    return CachedNetworkImage(
      imageUrl: source,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      placeholder: (_, _) => _loading(context),
      // Distinct du chargement : une photo injoignable garde l'icône de repli,
      // là où l'animation tournerait sans fin.
      errorWidget: (_, _, _) => _placeholder(context),
    );
  }

  Widget _loading(BuildContext context) => Container(
    width: double.infinity,
    height: 200,
    color: context.tokens.background,
    child: const Center(child: AppLoader()),
  );

  Widget _placeholder(BuildContext context) => Container(
    width: double.infinity,
    height: 200,
    color: context.tokens.background,
    child: Icon(LucideIcons.bedDouble, size: 32, color: context.tokens.muted),
  );
}
