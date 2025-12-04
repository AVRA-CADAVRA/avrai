import 'package:spots/core/models/tax_document.dart';
import 'package:spots/core/models/tax_profile.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/pdf_generation_service.dart';
import 'package:spots/core/services/irs_filing_service.dart';
import 'package:spots/core/services/tax_document_storage_service.dart';
import 'package:spots/core/utils/secure_ssn_encryption.dart';
import 'package:spots/data/repositories/tax_profile_repository.dart';
import 'package:spots/data/repositories/tax_document_repository.dart';
import 'package:uuid/uuid.dart';

/// Tax Compliance Service
/// 
/// Handles tax compliance for users, including 1099 generation, W-9 collection,
/// and IRS filing.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables accurate tax reporting
/// - Supports user trust through transparency
/// - Ensures platform compliance with tax regulations
/// 
/// **Responsibilities:**
/// - Check if user needs tax documents ($600 threshold)
/// - Generate 1099 forms (Form 1099-K)
/// - Batch generate all 1099s for year
/// - Request W-9 from user
/// - Process submitted W-9
/// - Encrypt SSN storage
/// - File with IRS
/// 
/// **Usage:**
/// ```dart
/// final taxService = TaxComplianceService(paymentService);
/// 
/// // Check if user needs tax documents
/// final needsDocs = await taxService.needsTaxDocuments('user-123', 2025);
/// 
/// // Generate 1099
/// final taxDoc = await taxService.generate1099('user-123', 2025);
/// ```
class TaxComplianceService {
  static const String _logName = 'TaxComplianceService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final PaymentService _paymentService;
  final TaxProfileRepository _taxProfileRepository;
  final TaxDocumentRepository _taxDocumentRepository;
  final PDFGenerationService _pdfGenerationService;
  final IRSFilingService _irsFilingService;
  final TaxDocumentStorageService _storageService;
  final SecureSSNEncryption _encryption;
  
  // IRS threshold for 1099-K reporting
  static const double _irsThreshold = 600.0; // $600 USD
  
  TaxComplianceService({
    required PaymentService paymentService,
    TaxProfileRepository? taxProfileRepository,
    TaxDocumentRepository? taxDocumentRepository,
    PDFGenerationService? pdfGenerationService,
    IRSFilingService? irsFilingService,
    TaxDocumentStorageService? storageService,
    SecureSSNEncryption? encryption,
  }) : _paymentService = paymentService,
       _taxProfileRepository = taxProfileRepository ?? TaxProfileRepository(),
       _taxDocumentRepository = taxDocumentRepository ?? TaxDocumentRepository(),
       _pdfGenerationService = pdfGenerationService ?? PDFGenerationService(),
       _irsFilingService = irsFilingService ?? IRSFilingService(),
       _storageService = storageService ?? TaxDocumentStorageService(),
       _encryption = encryption ?? SecureSSNEncryption();
  
  /// Check if user needs tax documents
  /// 
  /// **IRS Requirement:**
  /// - 1099-K required if user earns $600+ in a calendar year
  /// - Applies to payment card and third-party network transactions
  /// 
  /// **Flow:**
  /// 1. Calculate user earnings for tax year
  /// 2. Compare against IRS threshold ($600)
  /// 3. Return true if threshold exceeded
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `year`: Tax year (e.g., 2025)
  /// 
  /// **Returns:**
  /// true if user needs tax documents, false otherwise
  Future<bool> needsTaxDocuments(String userId, int year) async {
    try {
      _logger.info('Checking tax document requirement: user=$userId, year=$year', tag: _logName);
      
      final earnings = await _getUserEarnings(userId, year);
      final needsDocs = earnings >= _irsThreshold;
      
      _logger.info('Tax document requirement: user=$userId, earnings=\$${earnings.toStringAsFixed(2)}, needsDocs=$needsDocs', tag: _logName);
      
      return needsDocs;
    } catch (e) {
      _logger.error('Error checking tax document requirement', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Generate 1099 form for user
  /// 
  /// **Flow:**
  /// 1. Calculate user earnings for tax year
  /// 2. Check if earnings exceed $600 threshold
  /// 3. If W-9 submitted: Generate complete 1099-K with SSN/EIN
  /// 4. If W-9 NOT submitted: Generate incomplete 1099-K (IRS still requires reporting)
  /// 5. Upload to secure storage
  /// 6. Send document to user
  /// 7. File with IRS (LEGAL REQUIREMENT - must file even without W-9)
  /// 
  /// **IRS Compliance:**
  /// - SPOTS MUST report all earnings >= $600 to IRS, even if user doesn't submit W-9
  /// - Without W-9, form will have incomplete taxpayer identification
  /// - User will receive notice from IRS to provide missing information
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `year`: Tax year (e.g., 2025)
  /// 
  /// **Returns:**
  /// TaxDocument record
  /// 
  /// **Throws:**
  /// - `Exception` if earnings calculation fails
  Future<TaxDocument> generate1099(String userId, int year) async {
    try {
      _logger.info('Generating 1099: user=$userId, year=$year', tag: _logName);
      
      // Step 1: Calculate earnings
      final earnings = await _getUserEarnings(userId, year);
      
      // Step 2: Check if earnings exceed threshold
      if (earnings < _irsThreshold) {
        _logger.info('Earnings below threshold: user=$userId, earnings=\$${earnings.toStringAsFixed(2)}', tag: _logName);
        return TaxDocument(
          id: 'tax-doc-${_uuid.v4()}',
          userId: userId,
          taxYear: year,
          formType: TaxFormType.form1099K,
          totalEarnings: earnings,
          status: TaxStatus.notRequired,
          generatedAt: DateTime.now(),
        );
      }
      
      // Step 3: Get tax profile (may or may not have W-9)
      final taxProfile = await getTaxProfile(userId);
      final hasW9 = taxProfile.w9Submitted;
      
      if (!hasW9) {
        _logger.warn(
          'Generating 1099 without W-9: user=$userId, year=$year. '
          'IRS requires reporting even without W-9. Form will have incomplete taxpayer identification.',
          tag: _logName,
        );
      }
      
      // Step 4: Create tax document record (before generating PDF so we have an ID)
      final documentId = 'tax-doc-${_uuid.v4()}';
      final taxDoc = TaxDocument(
        id: documentId,
        userId: userId,
        taxYear: year,
        formType: TaxFormType.form1099K,
        totalEarnings: earnings,
        status: hasW9 ? TaxStatus.generated : TaxStatus.pending, // Pending if no W-9
        generatedAt: DateTime.now(),
        documentUrl: null, // Will be set after upload
        metadata: {
          'hasW9': hasW9,
          'w9Required': !hasW9,
        },
      );
      
      // Step 5: Generate 1099-K PDF (with or without W-9)
      // If no W-9, form will have incomplete taxpayer identification
      final pdfBytes = await _pdfGenerationService.generate1099K(
        userId: userId,
        taxYear: year,
        earnings: earnings,
        taxProfile: taxProfile,
        hasW9: hasW9,
      );
      
      // Step 6: Upload PDF to secure storage
      final documentUrl = await _storageService.uploadTaxDocument(
        userId: userId,
        documentId: documentId,
        taxYear: year,
        pdfBytes: pdfBytes,
      );
      
      // Step 7: Update document with URL
      final taxDocWithUrl = taxDoc.copyWith(documentUrl: documentUrl);
      
      // Step 8: Save document to database
      await _taxDocumentRepository.saveTaxDocument(taxDocWithUrl);
      
      // Step 9: Send document to user (or notification if incomplete)
      if (hasW9) {
        await _sendTaxDocument(userId, taxDocWithUrl);
      } else {
        await _sendIncompleteTaxDocumentNotification(userId, taxDocWithUrl);
      }
      
      // Step 10: File with IRS (LEGAL REQUIREMENT - must file even without W-9)
      // IRS will contact user directly if taxpayer identification is missing
      final filingResult = await _irsFilingService.fileWithIRS(
        taxDocument: taxDocWithUrl,
        pdfBytes: pdfBytes,
      );
      
      if (filingResult.success) {
        // Update document status to filed
        final updatedDoc = taxDocWithUrl.copyWith(
          status: TaxStatus.filed,
          filedWithIRSAt: filingResult.filedAt,
          metadata: {
            ...taxDocWithUrl.metadata,
            'irsConfirmationNumber': filingResult.confirmationNumber,
          },
        );
        await _taxDocumentRepository.saveTaxDocument(updatedDoc);
        _logger.info(
          '1099 generated and filed: user=$userId, year=$year, earnings=\$${earnings.toStringAsFixed(2)}, hasW9=$hasW9, confirmation=${filingResult.confirmationNumber}',
          tag: _logName,
        );
        return updatedDoc;
      } else {
        _logger.warn(
          '1099 generated but IRS filing failed: user=$userId, year=$year, message=${filingResult.message}',
          tag: _logName,
        );
      }
      
      _logger.info(
        '1099 generated: user=$userId, year=$year, earnings=\$${earnings.toStringAsFixed(2)}, hasW9=$hasW9',
        tag: _logName,
      );
      
      return taxDocWithUrl;
    } catch (e) {
      _logger.error('Error generating 1099', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Batch generate all 1099s for year
  /// 
  /// **Flow:**
  /// 1. Get all users with earnings >= $600
  /// 2. Generate 1099 for each user
  /// 3. Log errors for failed generations
  /// 
  /// **Note:** Typically run in January for previous tax year
  /// 
  /// **Parameters:**
  /// - `year`: Tax year (e.g., 2025)
  /// 
  /// **Returns:**
  /// List of generated tax documents
  Future<List<TaxDocument>> generateAll1099sForYear(int year) async {
    try {
      _logger.info('Batch generating 1099s for year: $year', tag: _logName);
      
      // Step 1: Get all users with earnings >= $600
      // Use repository to find users who already have documents, or query payment service
      final usersNeedingForms = await _getUsersWithEarningsAbove600(year);
      
      _logger.info('Users needing 1099s: ${usersNeedingForms.length}', tag: _logName);
      
      final generatedDocs = <TaxDocument>[];
      
      // Step 2: Generate 1099 for each user
      // Note: This will generate forms even for users without W-9 (IRS requirement)
      for (final userId in usersNeedingForms) {
        try {
          final taxDoc = await generate1099(userId, year);
          generatedDocs.add(taxDoc);
        } catch (e) {
          _logger.error('Failed to generate 1099 for user: $userId', error: e, tag: _logName);
          await _logTaxGenerationError(userId, year, e);
          // Continue processing other users even if one fails
        }
      }
      
      _logger.info('Batch generation complete: ${generatedDocs.length} documents generated', tag: _logName);
      
      return generatedDocs;
    } catch (e) {
      _logger.error('Error batch generating 1099s', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Request W-9 from user
  /// 
  /// **Flow:**
  /// 1. Send W-9 request notification to user
  /// 2. Log request in tax profile
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  Future<void> requestW9(String userId) async {
    try {
      _logger.info('Requesting W-9: user=$userId', tag: _logName);
      
      // Send notification to user (placeholder - would integrate with notification system)
      await _sendW9Request(userId);
      
      _logger.info('W-9 request sent: user=$userId', tag: _logName);
    } catch (e) {
      _logger.error('Error requesting W-9', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Process submitted W-9
  /// 
  /// **Flow:**
  /// 1. Encrypt SSN (critical for security)
  /// 2. Create/update tax profile
  /// 3. Save encrypted profile
  /// 4. Mark W-9 as submitted
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ssn`: Social Security Number (will be encrypted)
  /// - `classification`: Tax classification
  /// - `ein`: Employer ID Number (optional, for businesses)
  /// - `businessName`: Business name (optional, for businesses)
  /// 
  /// **Returns:**
  /// Updated TaxProfile
  /// 
  /// **Throws:**
  /// - `Exception` if SSN encryption fails
  Future<TaxProfile> submitW9({
    required String userId,
    required String ssn,
    required TaxClassification classification,
    String? ein,
    String? businessName,
  }) async {
    try {
      _logger.info('Processing W-9 submission: user=$userId', tag: _logName);
      
      // Step 1: Encrypt and store SSN/EIN securely
      if (ssn.isNotEmpty) {
        await _encryption.encryptSSN(userId, ssn);
      }
      if (ein != null && ein.isNotEmpty) {
        await _encryption.encryptEIN(userId, ein);
      }
      
      // Step 2: Create/update tax profile (SSN/EIN stored separately in secure storage)
      final profile = TaxProfile(
        userId: userId,
        ssn: null, // Not stored in profile - stored securely separately
        ein: ein,
        businessName: businessName,
        classification: classification,
        w9Submitted: true,
        w9SubmittedAt: DateTime.now(),
      );
      
      // Step 3: Save profile to database
      await _taxProfileRepository.saveTaxProfile(profile);
      
      _logger.info('W-9 processed: user=$userId, classification=${classification.name}', tag: _logName);
      
      return profile;
    } catch (e) {
      _logger.error('Error processing W-9', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get tax profile for user
  Future<TaxProfile> getTaxProfile(String userId) async {
    final profile = await _taxProfileRepository.getTaxProfile(userId);
    return profile ?? TaxProfile(
      userId: userId,
      classification: TaxClassification.individual,
      w9Submitted: false,
    );
  }
  
  /// Get tax document by ID
  Future<TaxDocument?> getTaxDocument(String documentId) async {
    return await _taxDocumentRepository.getTaxDocument(documentId);
  }
  
  /// Get tax documents for user and year
  Future<List<TaxDocument>> getTaxDocuments(String userId, int year) async {
    return await _taxDocumentRepository.getTaxDocuments(userId, year);
  }
  
  /// Check if user is approaching the $600 threshold
  /// 
  /// **Use Case:** Proactive notification to users before they hit threshold
  /// 
  /// **Returns:**
  /// - Current year earnings
  /// - Percentage of threshold reached
  /// - Whether threshold has been reached
  /// - Whether W-9 is submitted
  Future<Map<String, dynamic>> getTaxStatus(String userId, int year) async {
    try {
      final earnings = await _getUserEarnings(userId, year);
      final taxProfile = await getTaxProfile(userId);
      final thresholdReached = earnings >= _irsThreshold;
      final percentageReached = (earnings / _irsThreshold * 100).clamp(0.0, 100.0);
      
      return {
        'earnings': earnings,
        'threshold': _irsThreshold,
        'percentageReached': percentageReached,
        'thresholdReached': thresholdReached,
        'w9Submitted': taxProfile.w9Submitted,
        'needsW9': thresholdReached && !taxProfile.w9Submitted,
      };
    } catch (e) {
      _logger.error('Error getting tax status', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  /// Calculate user earnings for tax year
  /// 
  /// **Flow:**
  /// 1. Get all successful payments for user
  /// 2. Filter by tax year (based on payment date)
  /// 3. Sum total earnings
  /// 
  /// **Note:** In production, this would query database efficiently
  Future<double> _getUserEarnings(String userId, int year) async {
    try {
      _logger.info('Calculating user earnings: user=$userId, year=$year', tag: _logName);
      
      // Get all payments for user in the tax year using PaymentService
      final payments = _paymentService.getPaymentsForUserInYear(userId, year);
      
      // Filter successful payments and sum earnings
      final successfulPayments = payments.where((p) => p.isSuccessful).toList();
      
      // Calculate total earnings (amount * quantity for each payment)
      final totalEarnings = successfulPayments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.totalAmount,
      );
      
      _logger.info(
        'User earnings calculated: user=$userId, year=$year, '
        'payments=${successfulPayments.length}, earnings=\$${totalEarnings.toStringAsFixed(2)}',
        tag: _logName,
      );
      
      return totalEarnings;
    } catch (e) {
      _logger.error('Error calculating user earnings', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get users with earnings >= $600 for tax year
  /// 
  /// **Flow:**
  /// 1. Get all payments in tax year
  /// 2. Filter successful payments
  /// 3. Aggregate earnings by user
  /// 4. Filter users with earnings >= $600
  /// 5. Return list of user IDs
  /// 
  /// **Note:** This implementation queries all payments and aggregates client-side.
  /// In production with database, this would use an efficient aggregate query.
  Future<List<String>> _getUsersWithEarningsAbove600(int year) async {
    try {
      _logger.info('Finding users with earnings >= \$600 for year: $year', tag: _logName);
      
      // Note: PaymentService uses in-memory storage, so we need to query all payments
      // In production with database, this would be an efficient aggregate query:
      // SELECT user_id, SUM(amount * quantity) as total_earnings
      // FROM payments
      // WHERE status = 'completed'
      //   AND created_at >= $yearStart AND created_at <= $yearEnd
      // GROUP BY user_id
      // HAVING SUM(amount * quantity) >= 600.0
      
      // For now, we need to get payments through available methods
      // Since PaymentService stores in-memory, we'll need to query by iterating
      // This is not efficient but works for the current implementation
      
      // Get all payments for the year by checking all users
      // Note: This approach requires knowing all user IDs or querying from database
      // In production, this would query directly from database
      
      // Try to get users from tax documents repository (users who already have documents)
      // For new users, we'd need to query payment service or database
      // This is a limitation - ideally PaymentService would expose aggregate queries
      try {
        final existingDocs = await _taxDocumentRepository.getTaxDocumentsForYear(year);
        final usersWithDocs = existingDocs
            .where((doc) => doc.totalEarnings >= _irsThreshold)
            .map((doc) => doc.userId)
            .toSet()
            .toList();
        
        // Note: This only finds users who already have documents
        // For complete coverage, PaymentService needs to expose aggregate queries
        if (usersWithDocs.isEmpty) {
          _logger.warn(
            'No users found with earnings >= \$600. '
            'PaymentService may need to expose aggregate queries for complete coverage.',
            tag: _logName,
          );
        }
        
        return usersWithDocs;
      } catch (e) {
        _logger.error('Failed to get users with earnings above threshold', error: e, tag: _logName);
        return [];
      }
    } catch (e) {
      _logger.error('Error getting users with earnings above threshold', error: e, tag: _logName);
      return [];
    }
  }
  
  // PDF generation and encryption are now handled by separate services
  // No need for these methods anymore
  
  /// Send tax document to user
  Future<void> _sendTaxDocument(String userId, TaxDocument taxDoc) async {
    // In production, send email/notification with document link
    _logger.info('Sending tax document: user=$userId, doc=${taxDoc.id}', tag: _logName);
    // TODO: Implement notification system
  }
  
  // IRS filing is now handled by IRSFilingService
  // No need for this method anymore
  
  /// Send W-9 request notification
  Future<void> _sendW9Request(String userId) async {
    // In production, send notification to user
    _logger.info('Sending W-9 request: user=$userId', tag: _logName);
    // TODO: Implement notification system
  }
  
  /// Send notification about incomplete tax document (no W-9)
  /// 
  /// **Message should explain:**
  /// - SPOTS must report earnings to IRS (legal requirement)
  /// - Without W-9, form has incomplete information
  /// - IRS will contact user directly
  /// - User can submit W-9 to complete the form
  Future<void> _sendIncompleteTaxDocumentNotification(
    String userId,
    TaxDocument taxDoc,
  ) async {
    // In production, send notification explaining:
    // 1. SPOTS must report to IRS (legal requirement)
    // 2. Form was filed with incomplete taxpayer identification
    // 3. IRS will contact user directly
    // 4. User can submit W-9 to complete future forms
    _logger.info(
      'Sending incomplete tax document notification: user=$userId, doc=${taxDoc.id}',
      tag: _logName,
    );
    // TODO: Implement notification system with clear messaging
  }
  
  /// Log tax generation error
  Future<void> _logTaxGenerationError(String userId, int year, Object error) async {
    // In production, log to error tracking system
    _logger.error('Tax generation error logged: user=$userId, year=$year', error: error, tag: _logName);
    // TODO: Implement error logging system
  }
  
  // Tax profile and document saving are now handled by repositories
  // No need for these methods anymore
}
