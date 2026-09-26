import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/reservation_model.dart';

/// Émetteur de la facture : le propriétaire, tel qu'il se présente au client.
class InvoiceIssuer {
  const InvoiceIssuer({required this.name, this.phone});

  final String name;
  final String? phone;
}

/// Ligne chiffrée de la facture : une clé de traduction et un montant ou un
/// texte déjà mis en forme.
typedef InvoiceLine = ({String labelKey, String value, bool strong});

/// Facture d'un séjour, générée sur le téléphone et partagée par la feuille
/// de partage du système — le propriétaire y choisit WhatsApp et le client.
///
/// Générée sur l'appareil plutôt que servie par l'API : la facture doit
/// partir au comptoir, réseau ou non, et le séjour porte déjà tout ce qu'elle
/// affiche. Le lien `wa.me` a été écarté : il n'accepte que du texte, pas de
/// pièce jointe.
class InvoicePdfService {
  const InvoicePdfService();

  static final _amountFormat = NumberFormat.decimalPattern('fr');

  static String _fcfa(double amount) =>
      '${_amountFormat.format(amount.round())} F';

  /// Numéro stable, dérivé de l'identifiant : deux envois de la même facture
  /// portent le même numéro, et le client peut s'y référer.
  static String invoiceNumber(ReservationModel reservation) {
    final id = reservation.id.toUpperCase();
    return 'RESI-${id.length > 8 ? id.substring(0, 8) : id}';
  }

  /// Lignes chiffrées, dans l'ordre de lecture.
  ///
  /// Extraites du rendu pour être éprouvées sans PDF : c'est un document
  /// d'argent remis au client, et une ligne manquante ne se voit qu'à la
  /// lecture.
  static List<InvoiceLine> lines(ReservationModel reservation) {
    final dateTime = DateFormat('d MMM y, HH:mm', 'fr');

    return [
      (
        labelKey: 'invoice.check_in',
        value: dateTime.format(reservation.checkInAt.toLocal()),
        strong: false,
      ),
      (
        labelKey: 'invoice.check_out',
        value: dateTime.format(reservation.checkOutAt.toLocal()),
        strong: false,
      ),
      (
        labelKey: 'invoice.duration',
        value: reservation.durationLabel,
        strong: false,
      ),
      if (reservation.dailyPrice > 0)
        (
          labelKey: 'invoice.daily_price',
          value: _fcfa(reservation.dailyPrice),
          strong: false,
        ),
      if (reservation.discountAmount > 0)
        (
          labelKey: 'invoice.discount',
          value: '- ${_fcfa(reservation.discountAmount)}',
          strong: false,
        ),
      (
        labelKey: 'invoice.total',
        value: _fcfa(reservation.totalAmount),
        strong: true,
      ),
      if (reservation.refundedAmount > 0)
        (
          labelKey: 'invoice.refunded',
          value: _fcfa(reservation.refundedAmount),
          strong: false,
        ),
      if (reservation.depositAmount > 0) ...[
        (
          labelKey: 'invoice.deposit',
          value: _fcfa(reservation.depositAmount),
          strong: false,
        ),
        (
          labelKey: 'invoice.balance',
          value: _fcfa(reservation.balanceDue),
          strong: true,
        ),
      ],
    ];
  }

  Future<void> share({
    required ReservationModel reservation,
    InvoiceIssuer? issuer,
  }) async {
    final bytes = await build(reservation: reservation, issuer: issuer);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${invoiceNumber(reservation).toLowerCase()}.pdf',
    );
  }

  Future<Uint8List> build({
    required ReservationModel reservation,
    InvoiceIssuer? issuer,
    DateTime? issuedAt,
  }) async {
    final pdf = pw.Document();
    final number = invoiceNumber(reservation);
    final issued = DateFormat(
      'd MMMM y',
      'fr',
    ).format(issuedAt ?? DateTime.now());
    final client = reservation.client;
    final property = reservation.property;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'invoice.title'.tr(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('invoice.number'.tr(args: [number])),
                    pw.Text(
                      'invoice.issued'.tr(args: [issued]),
                      style: const pw.TextStyle(color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (issuer != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        issuer.name,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      if (issuer.phone case final phone? when phone.isNotEmpty)
                        pw.Text(phone),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _block('invoice.client'.tr(), [
                    // Instantané figé à la réservation : la facture montre le
                    // client tel qu'il a été enregistré pour ce séjour.
                    client?.fullName ?? '-',
                    if (client != null && client.phone.isNotEmpty) client.phone,
                  ]),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _block('invoice.lodging'.tr(), [
                    property?.title ?? '-',
                    if (property != null && property.city.isNotEmpty)
                      property.city,
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            for (final line in lines(reservation))
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      line.labelKey.tr(),
                      style: line.strong
                          ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                          : const pw.TextStyle(color: PdfColors.grey800),
                    ),
                    pw.Text(
                      line.value,
                      style: line.strong
                          ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                          : null,
                    ),
                  ],
                ),
              ),
            pw.Divider(color: PdfColors.grey400),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'invoice.thanks'.tr(),
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _block(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        for (final line in lines) pw.Text(line),
      ],
    );
  }
}
