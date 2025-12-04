import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_verification.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Business Service
/// 
/// Manages business accounts and verification for partnerships.
/// 
/// **Responsibilities:**
/// - Create business accounts
/// - Verify businesses
/// - Update business info
/// - Find businesses
/// - Check business eligibility
class BusinessService {
  static const String _logName = 'BusinessService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final BusinessAccountService _accountService;
  
  // In-memory storage for verifications (in production, use database)
  final Map<String, BusinessVerification> _verifications = {};
  
  BusinessService({
    required BusinessAccountService accountService,
  }) : _accountService = accountService;
  
  /// Create a new business account
  /// 
  /// **Parameters:**
  /// - `name`: Business name
  /// - `email`: Business email
  /// - `businessType`: Business type (e.g., "Restaurant", "Retail")
  /// - `createdBy`: User ID who created this business
  /// - Other optional fields
  /// 
  /// **Returns:**
  /// BusinessAccount
  Future<BusinessAccount> createBusinessAccount({
    required String name,
    required String email,
    required String businessType,
    required String createdBy,
    String? description,
    String? website,
    String? location,
    String? phone,
    List<String>? categories,
  }) async {
    try {
      _logger.info('Creating business account: $name', tag: _logName);
      
      // Create a UnifiedUser for the creator (simplified - in production, get from user service)
      // For now, we'll use a placeholder
      final creator = UnifiedUser(
        id: createdBy,
        email: email,
        displayName: 'Business Creator',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final business = await _accountService.createBusinessAccount(
        creator: creator,
        name: name,
        email: email,
        businessType: businessType,
        description: description,
        website: website,
        location: location,
        phone: phone,
        categories: categories,
      );
      
      _logger.info('Created business account: ${business.id}', tag: _logName);
      return business;
    } catch (e) {
      _logger.error('Error creating business account', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Verify a business account
  /// 
  /// **Flow:**
  /// 1. Get business account
  /// 2. Create BusinessVerification record
  /// 3. Submit for review (status: `pending`)
  /// 
  /// **Parameters:**
  /// - `businessId`: Business ID
  /// - `documents`: Verification documents
  /// 
  /// **Returns:**
  /// BusinessVerification with status `pending`
  Future<BusinessVerification> verifyBusiness({
    required String businessId,
    String? businessLicenseUrl,
    String? taxIdDocumentUrl,
    String? proofOfAddressUrl,
    String? websiteVerificationUrl,
    String? socialMediaVerificationUrl,
    String? legalBusinessName,
    String? taxId,
    String? businessAddress,
    String? phoneNumber,
    String? websiteUrl,
  }) async {
    try {
      _logger.info('Verifying business: $businessId', tag: _logName);
      
      // Get business account
      final business = await getBusinessById(businessId);
      if (business == null) {
        throw Exception('Business not found: $businessId');
      }
      
      // Create verification record
      final verification = BusinessVerification(
        id: _generateVerificationId(),
        businessAccountId: businessId,
        status: VerificationStatus.pending,
        method: VerificationMethod.hybrid,
        businessLicenseUrl: businessLicenseUrl,
        taxIdDocumentUrl: taxIdDocumentUrl,
        proofOfAddressUrl: proofOfAddressUrl,
        websiteVerificationUrl: websiteVerificationUrl,
        socialMediaVerificationUrl: socialMediaVerificationUrl,
        legalBusinessName: legalBusinessName,
        taxId: taxId,
        businessAddress: businessAddress,
        phoneNumber: phoneNumber,
        websiteUrl: websiteUrl,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save verification
      await _saveVerification(verification);
      
      _logger.info('Created verification: ${verification.id}', tag: _logName);
      return verification;
    } catch (e) {
      _logger.error('Error verifying business', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Update business account information
  /// 
  /// **Parameters:**
  /// - `businessId`: Business ID
  /// - Update fields
  /// 
  /// **Returns:**
  /// Updated BusinessAccount
  Future<BusinessAccount> updateBusinessInfo({
    required String businessId,
    String? name,
    String? description,
    String? website,
    String? location,
    String? phone,
    List<String>? categories,
  }) async {
    try {
      _logger.info('Updating business info: $businessId', tag: _logName);
      
      final business = await getBusinessById(businessId);
      if (business == null) {
        throw Exception('Business not found: $businessId');
      }
      
      final updated = await _accountService.updateBusinessAccount(
        business,
        name: name,
        description: description,
        website: website,
        location: location,
        phone: phone,
        categories: categories,
      );
      
      _logger.info('Updated business info: $businessId', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating business info', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Find businesses by filters
  /// 
  /// **Parameters:**
  /// - `category`: Business category filter
  /// - `location`: Location filter
  /// - `verifiedOnly`: Only return verified businesses
  /// - `maxResults`: Maximum number of results
  /// 
  /// **Returns:**
  /// List of BusinessAccount
  Future<List<BusinessAccount>> findBusinesses({
    String? category,
    String? location,
    bool verifiedOnly = false,
    int maxResults = 20,
  }) async {
    try {
      _logger.info('Finding businesses: category=$category, location=$location, verifiedOnly=$verifiedOnly', tag: _logName);
      
      final allBusinesses = await _getAllBusinesses();
      
      var filtered = allBusinesses.where((business) {
        // Filter by category
        if (category != null) {
          if (!business.categories.contains(category)) {
            return false;
          }
        }
        
        // Filter by location
        if (location != null && business.location != null) {
          if (!business.location!.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }
        
        // Filter by verification status
        if (verifiedOnly && !business.isVerified) {
          return false;
        }
        
        return true;
      }).toList();
      
      return filtered.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding businesses', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Check if business is eligible for partnerships
  /// 
  /// **Flow:**
  /// 1. Get business account
  /// 2. Check verification status (must be `verified`)
  /// 3. Check business is active
  /// 
  /// **Parameters:**
  /// - `businessId`: Business ID
  /// 
  /// **Returns:**
  /// true if eligible, false otherwise
  Future<bool> checkBusinessEligibility(String businessId) async {
    try {
      final business = await getBusinessById(businessId);
      if (business == null) {
        _logger.info('Business not found: $businessId', tag: _logName);
        return false;
      }
      
      // Check verification status
      if (!business.isVerified) {
        _logger.info('Business not verified: $businessId', tag: _logName);
        return false;
      }
      
      // Check business is active
      if (!business.isActive) {
        _logger.info('Business not active: $businessId', tag: _logName);
        return false;
      }
      
      return true;
    } catch (e) {
      _logger.error('Error checking business eligibility', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Get business by ID
  /// 
  /// **Parameters:**
  /// - `businessId`: Business ID
  /// 
  /// **Returns:**
  /// BusinessAccount if found, null otherwise
  Future<BusinessAccount?> getBusinessById(String businessId) async {
    try {
      return await _accountService.getBusinessAccount(businessId);
    } catch (e) {
      _logger.error('Error getting business by ID', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get verification for business
  /// 
  /// **Parameters:**
  /// - `businessId`: Business ID
  /// 
  /// **Returns:**
  /// BusinessVerification if found, null otherwise
  Future<BusinessVerification?> getVerification(String businessId) async {
    try {
      final allVerifications = await _getAllVerifications();
      try {
        return allVerifications.firstWhere(
          (v) => v.businessAccountId == businessId,
        );
      } catch (e) {
        return null;
      }
    } catch (e) {
      _logger.error('Error getting verification', error: e, tag: _logName);
      return null;
    }
  }
  
  // Private helper methods
  
  String _generateVerificationId() {
    return 'verification_${_uuid.v4()}';
  }
  
  Future<void> _saveVerification(BusinessVerification verification) async {
    // In production, save to database
    _verifications[verification.id] = verification;
  }
  
  Future<List<BusinessVerification>> _getAllVerifications() async {
    // In production, query database
    return _verifications.values.toList();
  }
  
  Future<List<BusinessAccount>> _getAllBusinesses() async {
    // In production, query database
    // For now, delegate to account service
    return await _accountService.getBusinessAccountsByUser('system'); // Placeholder
  }
}

