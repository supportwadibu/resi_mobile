import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/expense_model.dart';

class ExpensePdfService {
  const ExpensePdfService();

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'fr');
  static final _longDate = DateFormat('d MMMM y', 'fr');
  static final _amountFormat = NumberFormat.decimalPattern('fr');

  String _fcfa(double amount) => '${_amountFormat.format(amount.round())} F';

  Future<void> share({
    required List<ExpenseModel> expenses,
    required ExpenseSummary summary,
    String? scopeLabel,
  }) async {
    final document = await build(
      expenses: expenses,
      summary: summary,
      scopeLabel: scopeLabel,
    );

    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.sharePdf(bytes: document, filename: 'depenses-$stamp.pdf');
  }

  Future<Uint8List> build({
    required List<ExpenseModel> expenses,
    required ExpenseSummary summary,
    String? scopeLabel,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(context, scopeLabel),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _totals(summary),
          pw.SizedBox(height: 20),
          if (summary.byCategory.isNotEmpty) ...[
            _breakdown(summary),
            pw.SizedBox(height: 20),
          ],
          _detail(expenses),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(pw.Context context, String? scopeLabel) {
    if (context.pageNumber > 1) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rapport de dépenses',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          scopeLabel ?? 'Toutes les dépenses',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Text(
          'Édité le ${_longDate.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _totals(ExpenseSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Total des dépenses',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _fcfa(summary.total),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Écritures',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${summary.count}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _breakdown(ExpenseSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Répartition par catégorie',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Catégorie', 'Écritures', 'Montant', 'Part'],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          data: [
            for (final bucket in summary.byCategory)
              [
                bucket.category.label,
                '${bucket.count}',
                _fcfa(bucket.amount),
                '${bucket.sharePercent} %',
              ],
          ],
        ),
      ],
    );
  }

  pw.Widget _detail(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return pw.Text(
        'Aucune dépense sur la période.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détail',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Date', 'Bien', 'Catégorie', 'Note', 'Montant'],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellStyle: const pw.TextStyle(fontSize: 9),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(2.2),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(2.4),
            4: const pw.FlexColumnWidth(1.6),
          },
          cellAlignments: {4: pw.Alignment.centerRight},
          data: [
            for (final expense in expenses)
              [
                _dateFormat.format(expense.spentAt),
                expense.property?.title ?? 'Bien supprimé',
                expense.category.label,
                expense.note?.trim() ?? '',
                _fcfa(expense.amount),
              ],
          ],
        ),
      ],
    );
  }
}
