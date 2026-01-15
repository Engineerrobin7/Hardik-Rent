// Sprint 1: PDF Receipt Service
// File: lib/data/services/pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class PdfService {
  /// Generate a rent receipt PDF
  Future<dynamic> generateRentReceipt({
    required String receiptNumber,
    required String tenantName,
    required String tenantPhone,
    required String propertyAddress,
    required double rentAmount,
    required double maintenanceCharges,
    required double otherCharges,
    required double totalAmount,
    required DateTime paymentDate,
    required String paymentMode,
    required String ownerName,
    required String ownerPhone,
    String? transactionId,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 2, color: PdfColors.blue700),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RENT RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Receipt #$receiptNumber',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Date: ${DateFormat('dd MMM yyyy').format(paymentDate)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Payment Mode: $paymentMode',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Tenant & Owner Details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Tenant Details
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'RECEIVED FROM',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              tenantName,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Phone: $tenantPhone',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),

                    pw.SizedBox(width: 20),

                    // Owner Details
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'RECEIVED BY',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              ownerName,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Phone: $ownerPhone',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Property Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROPERTY ADDRESS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        propertyAddress,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Payment Breakdown
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      // Header
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue700,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'DESCRIPTION',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              'AMOUNT',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rent
                      _buildPaymentRow('Monthly Rent', rentAmount),
                      pw.Divider(color: PdfColors.grey300),

                      // Maintenance
                      if (maintenanceCharges > 0) ...[
                        _buildPaymentRow('Maintenance Charges', maintenanceCharges),
                        pw.Divider(color: PdfColors.grey300),
                      ],

                      // Other Charges
                      if (otherCharges > 0) ...[
                        _buildPaymentRow('Other Charges', otherCharges),
                        pw.Divider(color: PdfColors.grey300),
                      ],

                      // Total
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL AMOUNT',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Transaction ID (if available)
                if (transactionId != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'Transaction ID: ',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          transactionId,
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(width: 1, color: PdfColors.grey400),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'This is a computer-generated receipt and does not require a signature.',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Generated by Hardik Rent Management System',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Generate PDF bytes
    final bytes = await pdf.save();

    if (kIsWeb) {
      // On web we return the bytes directly
      return bytes;
    } else {
      // On mobile/desktop we save to a file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_$receiptNumber.pdf');
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  pw.Widget _buildPaymentRow(String description, double amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            description,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Share the PDF receipt
  Future<void> shareReceipt(dynamic pdfSource) async {
    if (kIsWeb) {
      // On web, sharing a file is different, usually downloading or using printing
      await Printing.sharePdf(bytes: pdfSource as Uint8List, filename: 'receipt.pdf');
    } else {
      final file = pdfSource as File;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Rent Receipt',
        text: 'Please find attached your rent receipt.',
      );
    }
  }

  /// Print the PDF receipt
  Future<void> printReceipt(dynamic pdfSource) async {
    final Uint8List bytes = kIsWeb ? (pdfSource as Uint8List) : await (pdfSource as File).readAsBytes();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }
}
