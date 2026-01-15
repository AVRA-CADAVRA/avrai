import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:avrai/core/models/tax_profile.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai/core/utils/secure_ssn_encryption.dart';

/// PDF Generation Service
///
/// Generates 1099-K tax forms as PDF documents.
///
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables accurate tax reporting
/// - Supports user trust through transparency
class PDFGenerationService {
  static const AppLogger _logger =
      AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final SecureSSNEncryption _encryption = SecureSSNEncryption();

  /// Generate 1099-K PDF document
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `taxYear`: Tax year (e.g., 2025)
  /// - `earnings`: Total earnings for the year
  /// - `taxProfile`: Tax profile (may or may not have W-9)
  /// - `hasW9`: Whether W-9 is submitted
  /// - `payerName`: SPOTS company name
  /// - `payerAddress`: SPOTS company address
  /// - `payerTIN`: SPOTS Tax Identification Number
  ///
  /// **Returns:**
  /// PDF document as bytes
  Future<Uint8List> generate1099K({
    required String userId,
    required int taxYear,
    required double earnings,
    required TaxProfile taxProfile,
    required bool hasW9,
    String payerName = 'SPOTS, Inc.',
    String payerAddress = '123 Main St, City, State 12345',
    String payerTIN = '12-3456789', // SPOTS EIN
  }) async {
    try {
      _logger.info(
        'Generating 1099-K PDF: user=$userId, year=$taxYear, earnings=\$${earnings.toStringAsFixed(2)}, hasW9=$hasW9',
        tag: 'PDFGenerationService',
      );

      final pdf = pw.Document();

      // Get taxpayer information (if W-9 submitted)
      String? taxpayerName;
      String? taxpayerTIN;
      String? taxpayerAddress;

      if (hasW9) {
        taxpayerName = taxProfile.businessName ??
            'Individual'; // Would get from user profile
        if (taxProfile.ein != null) {
          final ein = await _encryption.decryptEIN(userId);
          taxpayerTIN = ein;
        } else {
          final ssn = await _encryption.decryptSSN(userId);
          taxpayerTIN = ssn;
        }
        taxpayerAddress = 'User Address'; // Would get from user profile
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(72),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(taxYear),
                pw.SizedBox(height: 20),

                // Payer Information
                _buildPayerSection(
                  payerName: payerName,
                  payerAddress: payerAddress,
                  payerTIN: payerTIN,
                ),
                pw.SizedBox(height: 20),

                // Recipient Information
                _buildRecipientSection(
                  taxpayerName: taxpayerName,
                  taxpayerTIN: taxpayerTIN,
                  taxpayerAddress: taxpayerAddress,
                  hasW9: hasW9,
                ),
                pw.SizedBox(height: 20),

                // Earnings Information
                _buildEarningsSection(
                  earnings: earnings,
                  taxYear: taxYear,
                ),
                pw.SizedBox(height: 20),

                // Footer
                _buildFooter(hasW9: hasW9),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      _logger.info('1099-K PDF generated successfully',
          tag: 'PDFGenerationService');

      return pdfBytes;
    } catch (e) {
      _logger.error('Failed to generate 1099-K PDF',
          error: e, tag: 'PDFGenerationService');
      rethrow;
    }
  }

  // Private helper methods for PDF building

  pw.Widget _buildHeader(int taxYear) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Form 1099-K',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Payment Card and Third Party Network Transactions',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Copy B for Recipient',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Tax Year: $taxYear',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildPayerSection({
    required String payerName,
    required String payerAddress,
    required String payerTIN,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYER\'S name, street address, city, state, ZIP code, and telephone no.',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(payerName, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(payerAddress, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text(
            'PAYER\'S TIN: $payerTIN',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRecipientSection({
    String? taxpayerName,
    String? taxpayerTIN,
    String? taxpayerAddress,
    required bool hasW9,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RECIPIENT\'S name',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            hasW9 ? (taxpayerName ?? 'N/A') : '[INCOMPLETE - IRS WILL CONTACT]',
            style: pw.TextStyle(
              fontSize: 10,
              color: hasW9 ? PdfColors.black : PdfColors.red,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'RECIPIENT\'S TIN',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            hasW9 ? (taxpayerTIN ?? 'N/A') : '[INCOMPLETE - IRS WILL CONTACT]',
            style: pw.TextStyle(
              fontSize: 10,
              color: hasW9 ? PdfColors.black : PdfColors.red,
            ),
          ),
          if (taxpayerAddress != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'RECIPIENT\'S address',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(taxpayerAddress, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEarningsSection({
    required double earnings,
    required int taxYear,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Gross amount of payment card/third party network transactions',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '\$${earnings.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tax Year: $taxYear',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({required bool hasW9}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (!hasW9) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.yellow100,
              border: pw.Border.all(color: PdfColors.orange, width: 1),
            ),
            child: pw.Text(
              'NOTICE: This form was filed with incomplete taxpayer information. '
              'The IRS will contact you directly to obtain your tax identification number.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.red),
            ),
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Text(
          'This form is provided for your records. You may need this information when filing your tax return.',
          style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'For questions, contact avrai support or visit avrai.app/support',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }
}
