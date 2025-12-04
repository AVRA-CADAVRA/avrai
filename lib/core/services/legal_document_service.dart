import 'package:spots/core/models/user_agreement.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/legal/terms_of_service.dart';
import 'package:spots/core/legal/privacy_policy.dart';
import 'package:spots/core/legal/event_waiver.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Legal Document Service
/// 
/// Handles legal document tracking, agreement acceptance, and version management.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables transparent agreement tracking
/// - Supports version management
/// - Creates pathways for legal protection
/// 
/// **Responsibilities:**
/// - Track user agreements (Terms of Service, Privacy Policy)
/// - Generate event waivers
/// - Require agreement acceptance
/// - Manage agreement versions
/// - Check if user has accepted required agreements
/// 
/// **Usage:**
/// ```dart
/// final legalService = LegalDocumentService(eventService);
/// 
/// // Check if user has accepted Terms of Service
/// final hasAccepted = await legalService.hasAcceptedTerms('user-123');
/// 
/// // Accept Terms of Service
/// final agreement = await legalService.acceptTermsOfService(
///   userId: 'user-123',
///   ipAddress: '192.168.1.1',
/// );
/// ```
class LegalDocumentService {
  static const String _logName = 'LegalDocumentService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService? _eventService;
  
  // In-memory storage (in production, use database)
  final Map<String, List<UserAgreement>> _userAgreements = {};
  
  LegalDocumentService({
    ExpertiseEventService? eventService,
  }) : _eventService = eventService;
  
  /// Check if user has accepted Terms of Service (current version)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user has accepted current version, `false` otherwise
  Future<bool> hasAcceptedTerms(String userId) async {
    try {
      final agreements = await getUserAgreements(userId);
      final termsAgreement = agreements.firstWhere(
        (a) => a.documentType == 'terms_of_service' && a.isActive,
        orElse: () => throw StateError('No terms agreement'),
      );
      
      return TermsOfService.isCurrentVersion(termsAgreement.version);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has accepted Privacy Policy (current version)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user has accepted current version, `false` otherwise
  Future<bool> hasAcceptedPrivacyPolicy(String userId) async {
    try {
      final agreements = await getUserAgreements(userId);
      final privacyAgreement = agreements.firstWhere(
        (a) => a.documentType == 'privacy_policy' && a.isActive,
        orElse: () => throw StateError('No privacy agreement'),
      );
      
      return PrivacyPolicy.isCurrentVersion(privacyAgreement.version);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has accepted event waiver
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// `true` if user has accepted waiver, `false` otherwise
  Future<bool> hasAcceptedEventWaiver(String userId, String eventId) async {
    try {
      final agreements = await getUserAgreements(userId);
      return agreements.any(
        (a) => a.documentType == 'event_waiver' &&
            a.eventId == eventId &&
            a.isActive,
      );
    } catch (e) {
      return false;
    }
  }
  
  /// Accept Terms of Service
  /// 
  /// **Flow:**
  /// 1. Create UserAgreement record
  /// 2. Save agreement
  /// 3. Return agreement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ipAddress`: IP address (for legal record)
  /// - `userAgent`: User agent (optional)
  /// 
  /// **Returns:**
  /// Created UserAgreement
  Future<UserAgreement> acceptTermsOfService({
    required String userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      _logger.info('User accepting Terms of Service: user=$userId', tag: _logName);
      
      // Revoke old agreements if any
      await _revokeOldAgreements(userId, 'terms_of_service');
      
      // Create new agreement
      final agreement = UserAgreement(
        id: 'agreement_${_uuid.v4()}',
        userId: userId,
        documentType: 'terms_of_service',
        version: TermsOfService.version,
        agreedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        isActive: true,
        updatedAt: DateTime.now(),
      );
      
      await _saveAgreement(agreement);
      
      _logger.info('Terms of Service accepted: ${agreement.id}', tag: _logName);
      
      return agreement;
    } catch (e) {
      _logger.error('Error accepting Terms of Service', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Accept Privacy Policy
  /// 
  /// **Flow:**
  /// 1. Create UserAgreement record
  /// 2. Save agreement
  /// 3. Return agreement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ipAddress`: IP address (for legal record)
  /// - `userAgent`: User agent (optional)
  /// 
  /// **Returns:**
  /// Created UserAgreement
  Future<UserAgreement> acceptPrivacyPolicy({
    required String userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      _logger.info('User accepting Privacy Policy: user=$userId', tag: _logName);
      
      // Revoke old agreements if any
      await _revokeOldAgreements(userId, 'privacy_policy');
      
      // Create new agreement
      final agreement = UserAgreement(
        id: 'agreement_${_uuid.v4()}',
        userId: userId,
        documentType: 'privacy_policy',
        version: PrivacyPolicy.version,
        agreedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        isActive: true,
        updatedAt: DateTime.now(),
      );
      
      await _saveAgreement(agreement);
      
      _logger.info('Privacy Policy accepted: ${agreement.id}', tag: _logName);
      
      return agreement;
    } catch (e) {
      _logger.error('Error accepting Privacy Policy', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Generate and accept event waiver
  /// 
  /// **Flow:**
  /// 1. Get event details
  /// 2. Generate waiver text
  /// 3. Create UserAgreement record
  /// 4. Save agreement
  /// 5. Return agreement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// - `ipAddress`: IP address (for legal record)
  /// - `userAgent`: User agent (optional)
  /// 
  /// **Returns:**
  /// Created UserAgreement with waiver
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  Future<UserAgreement> acceptEventWaiver({
    required String userId,
    required String eventId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      _logger.info('User accepting event waiver: user=$userId, event=$eventId', tag: _logName);
      
      if (_eventService == null) {
        throw Exception('EventService not available');
      }
      
      // Get event
      final event = await _eventService!.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Generate waiver (waiver text is generated by EventWaiver class)
      // The actual waiver text would be displayed to user before acceptance
      
      // Create agreement
      final agreement = UserAgreement(
        id: 'agreement_${_uuid.v4()}',
        userId: userId,
        documentType: 'event_waiver',
        version: '1.0.0', // Waiver version (could be event-specific)
        agreedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        eventId: eventId,
        isActive: true,
        updatedAt: DateTime.now(),
      );
      
      await _saveAgreement(agreement);
      
      _logger.info('Event waiver accepted: ${agreement.id}', tag: _logName);
      
      return agreement;
    } catch (e) {
      _logger.error('Error accepting event waiver', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Generate event waiver text
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// Waiver text for the event
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  Future<String> generateEventWaiver(String eventId) async {
    try {
      if (_eventService == null) {
        throw Exception('EventService not available');
      }
      
      final event = await _eventService!.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Use EventWaiver class to generate waiver
      if (EventWaiver.requiresFullWaiver(event)) {
        return EventWaiver.generateWaiver(event);
      } else {
        return EventWaiver.generateSimplifiedWaiver(event);
      }
    } catch (e) {
      _logger.error('Error generating event waiver', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Check if user needs to accept updated Terms of Service
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user needs to accept new version, `false` otherwise
  Future<bool> needsTermsUpdate(String userId) async {
    try {
      final hasAccepted = await hasAcceptedTerms(userId);
      if (!hasAccepted) {
        return true; // Never accepted
      }
      
      final agreements = await getUserAgreements(userId);
      final termsAgreement = agreements.firstWhere(
        (a) => a.documentType == 'terms_of_service' && a.isActive,
        orElse: () => throw StateError('No terms agreement'),
      );
      
      // Check if version is current
      return !TermsOfService.isCurrentVersion(termsAgreement.version);
    } catch (e) {
      return true; // If error, assume update needed
    }
  }
  
  /// Check if user needs to accept updated Privacy Policy
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// `true` if user needs to accept new version, `false` otherwise
  Future<bool> needsPrivacyUpdate(String userId) async {
    try {
      final hasAccepted = await hasAcceptedPrivacyPolicy(userId);
      if (!hasAccepted) {
        return true; // Never accepted
      }
      
      final agreements = await getUserAgreements(userId);
      final privacyAgreement = agreements.firstWhere(
        (a) => a.documentType == 'privacy_policy' && a.isActive,
        orElse: () => throw StateError('No privacy agreement'),
      );
      
      // Check if version is current
      return !PrivacyPolicy.isCurrentVersion(privacyAgreement.version);
    } catch (e) {
      return true; // If error, assume update needed
    }
  }
  
  /// Get all agreements for a user
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// List of UserAgreement records
  Future<List<UserAgreement>> getUserAgreements(String userId) async {
    try {
      return _userAgreements[userId] ?? [];
    } catch (e) {
      _logger.error('Error getting user agreements', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get agreement by ID
  /// 
  /// **Parameters:**
  /// - `agreementId`: Agreement ID
  /// 
  /// **Returns:**
  /// UserAgreement if found, null otherwise
  Future<UserAgreement?> getAgreement(String agreementId) async {
    try {
      for (final agreements in _userAgreements.values) {
        try {
          return agreements.firstWhere((a) => a.id == agreementId);
        } catch (e) {
          continue;
        }
      }
      return null;
    } catch (e) {
      _logger.error('Error getting agreement', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Revoke an agreement
  /// 
  /// **Parameters:**
  /// - `agreementId`: Agreement ID
  /// - `reason`: Reason for revocation
  /// 
  /// **Returns:**
  /// Updated UserAgreement
  Future<UserAgreement> revokeAgreement({
    required String agreementId,
    String? reason,
  }) async {
    try {
      final agreement = await getAgreement(agreementId);
      if (agreement == null) {
        throw Exception('Agreement not found: $agreementId');
      }
      
      final updated = agreement.copyWith(
        isActive: false,
        revokedAt: DateTime.now(),
        revocationReason: reason,
        updatedAt: DateTime.now(),
      );
      
      await _saveAgreement(updated);
      
      _logger.info('Agreement revoked: $agreementId', tag: _logName);
      
      return updated;
    } catch (e) {
      _logger.error('Error revoking agreement', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  Future<void> _saveAgreement(UserAgreement agreement) async {
    // In production, save to database
    if (!_userAgreements.containsKey(agreement.userId)) {
      _userAgreements[agreement.userId] = [];
    }
    
    // Remove old agreement with same type if exists
    _userAgreements[agreement.userId]!.removeWhere(
      (a) => a.id == agreement.id,
    );
    
    // Add new agreement
    _userAgreements[agreement.userId]!.add(agreement);
  }
  
  Future<void> _revokeOldAgreements(String userId, String documentType) async {
    try {
      final agreements = await getUserAgreements(userId);
      for (final agreement in agreements) {
        if (agreement.documentType == documentType && agreement.isActive) {
          await revokeAgreement(
            agreementId: agreement.id,
            reason: 'New version accepted',
          );
        }
      }
    } catch (e) {
      _logger.error('Error revoking old agreements', error: e, tag: _logName);
    }
  }
}

