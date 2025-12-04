import 'dart:developer' as developer;
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';

/// User Anonymization Service
/// 
/// Converts UnifiedUser to AnonymousUser by filtering out ALL personal information.
/// 
/// **CRITICAL:** This service ensures zero personal data leaks into AI2AI network.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to secure AI2AI connections without privacy risk
/// - Protects user identity while enabling network participation
/// - Enables trust network without exposing personal information
/// 
/// **Usage:**
/// ```dart
/// final service = UserAnonymizationService();
/// final anonymousUser = await service.anonymizeUser(unifiedUser, agentId, personalityProfile);
/// ```
class UserAnonymizationService {
  static const String _logName = 'UserAnonymizationService';
  
  final LocationObfuscationService _locationObfuscationService;
  
  UserAnonymizationService({
    LocationObfuscationService? locationObfuscationService,
  }) : _locationObfuscationService = locationObfuscationService ?? LocationObfuscationService();
  
  /// Convert UnifiedUser to AnonymousUser
  /// 
  /// **Parameters:**
  /// - `user`: UnifiedUser to anonymize
  /// - `agentId`: Anonymous agent ID (required, must start with "agent_")
  /// - `personalityProfile`: Optional personality profile to include
  /// - `isAdmin`: If true, allows exact location (godmode/admin access)
  /// 
  /// **Returns:**
  /// AnonymousUser with all personal information filtered out
  /// 
  /// **Throws:**
  /// - Exception if agentId is invalid
  /// - Exception if personal data cannot be filtered
  Future<AnonymousUser> anonymizeUser(
    UnifiedUser user,
    String agentId,
    PersonalityProfile? personalityProfile, {
    bool isAdmin = false,
  }) async {
    try {
      // Validate agentId format
      if (!agentId.startsWith('agent_')) {
        throw Exception('Invalid agentId format: must start with "agent_"');
      }
      
      developer.log('Anonymizing user: ${user.id} -> agent: $agentId', name: _logName);
      
      // Filter preferences (remove any personal data)
      final filteredPreferences = _filterPreferences(user);
      
      // Obfuscate location if present
      ObfuscatedLocation? obfuscatedLocation;
      if (user.location != null) {
        try {
          obfuscatedLocation = await _locationObfuscationService.obfuscateLocation(
            user.location!,
            user.id, // Pass userId to check against home location
            isAdmin: isAdmin, // Respect admin/godmode permissions
          );
        } catch (e) {
          developer.log('Failed to obfuscate location: $e', name: _logName);
          // Continue without location if obfuscation fails
        }
      }
      
      // Create AnonymousUser (NO personal data fields)
      final anonymousUser = AnonymousUser(
        agentId: agentId,
        personalityDimensions: personalityProfile,
        preferences: filteredPreferences,
        expertise: user.expertise, // Safe to share (not personal)
        location: obfuscatedLocation,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Validate no personal data leaked
      anonymousUser.validateNoPersonalData();
      
      developer.log('User anonymized successfully', name: _logName);
      return anonymousUser;
    } catch (e) {
      developer.log('Error anonymizing user: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Filter preferences to remove personal data
  /// 
  /// Only keeps preferences that are safe to share in AI2AI network.
  /// Removes any preferences that could identify the user.
  Map<String, dynamic>? _filterPreferences(UnifiedUser user) {
    // For now, return null (no preferences shared)
    // In future, could filter specific safe preferences
    // but must ensure no personal data
    
    // Example of safe preferences (if we add them later):
    // - Food preferences (vegetarian, vegan, etc.) - safe
    // - Activity preferences (outdoor, indoor) - safe
    // - Price range preferences - safe
    // 
    // NOT safe:
    // - Home address
    // - Work address
    // - Personal identifiers
    // - Exact location preferences
    
    return null;
  }
  
  /// Validate that UnifiedUser can be safely anonymized
  /// 
  /// Checks for any issues that would prevent anonymization.
  /// 
  /// **Returns:**
  /// List of validation errors (empty if valid)
  List<String> validateUserForAnonymization(UnifiedUser user) {
    final errors = <String>[];
    
    // Check that user has required fields
    if (user.id.isEmpty) {
      errors.add('User ID is empty');
    }
    
    // Note: We don't check for email/name/etc. because we're filtering them out
    // This validation is just to ensure we can process the user
    
    return errors;
  }
}

