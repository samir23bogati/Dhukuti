import 'dart:io';
import 'package:dhukuti/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class InvoiceService {
  Future<File> generateInvoice({
    required TransactionModel transaction,
    required String userName,
    required String userPhone,
  }) async {
    final pdf = pw.Document();
    final isBuy = transaction.type == TransactionType.buy;
    final primaryColor = isBuy ? PdfColors.green700 : PdfColors.red700;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final invoiceNumber = 'INV-${transaction.id.toUpperCase().substring(0, 8)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DHUKUTI',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official Invoice',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      transaction.type.name.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.grey600)),
                      pw.SizedBox(height: 8),
                      pw.Text('Invoice #: $invoiceNumber', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date: ${dateFormat.format(transaction.timestamp)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Customer Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.grey600)),
                      pw.SizedBox(height: 8),
                      pw.Text(userName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Phone: $userPhone', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${transaction.metalType.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildTableRow('Quantity', '${transaction.quantityTola.toStringAsFixed(2)} Tola'),
                    _buildTableRow('Rate per Tola', 'Rs. ${transaction.ratePerTola.toStringAsFixed(2)}'),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    if (!isBuy) ...[
                      _buildTableRow('Subtotal', 'Rs. ${(transaction.quantityTola * transaction.ratePerTola).toStringAsFixed(2)}'),
                      _buildTableRow('Service Fee (1%)', '- Rs. ${(transaction.quantityTola * transaction.ratePerTola * 0.01).toStringAsFixed(2)}'),
                      pw.SizedBox(height: 8),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 8),
                    ],
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'NET TOTAL',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Rs. ${transaction.totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'Thank you for choosing Dhukuti!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Dhukuti - Your Trusted Precious Metals Partner',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'This is a computer-generated invoice.',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildTableRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> shareInvoice(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Dhukuti Invoice');
  }
}
