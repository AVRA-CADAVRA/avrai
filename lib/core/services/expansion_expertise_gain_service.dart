import 'package:spots/core/models/geographic_expansion.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/geographic_expansion_service.dart';

/// Expansion Expertise Gain Service
/// 
/// Grants expertise when expansion thresholds are met (75% coverage rule).
/// 
/// **Philosophy Alignment:**
/// - Clubs/communities can expand naturally (doors open through growth)
/// - 75% coverage rule enables expertise gain at each geographic level
/// - Geographic expansion enabled (locality → universe)
/// - Club leaders recognized as experts (doors for leaders)
/// 
/// **Key Features:**
/// - Check expansion thresholds and grant expertise
/// - Grant expertise for neighboring locality expansion (local expertise)
/// - Grant expertise when 75% city/state/nation/global coverage reached
/// - Update user expertise map
/// - Integration with ExpertiseCalculationService
class ExpansionExpertiseGainService {
  static const String _logName = 'ExpansionExpertiseGainService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final GeographicExpansionService _expansionService;

  ExpansionExpertiseGainService({
    GeographicExpansionService? expansionService,
  }) : _expansionService =
            expansionService ?? GeographicExpansionService();

  /// Main method to check and grant expertise from expansion
  /// 
  /// Checks all geographic levels and grants expertise when thresholds are met.
  /// 
  /// **Parameters:**
  /// - `user`: User to grant expertise to
  /// - `expansion`: Geographic expansion to check
  /// - `category`: Category for expertise
  /// 
  /// **Returns:**
  /// Updated user with new expertise (if any granted)
  Future<UnifiedUser> grantExpertiseFromExpansion({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      _logger.info(
        'Checking expertise gain from expansion: user=${user.id}, category=$category, club=${expansion.clubId}',
        tag: _logName,
      );

      Map<String, String> updatedExpertiseMap = Map.from(user.expertiseMap);
      bool expertiseGranted = false;

      // Check and grant expertise at each geographic level
      // Check in order: locality → city → state → nation → global → universal

      // 1. Check locality expertise (neighboring locality expansion)
      final localityExpertise = await checkAndGrantLocalityExpertise(
        user: user,
        expansion: expansion,
        category: category,
      );
      if (localityExpertise != null) {
        updatedExpertiseMap[category] = localityExpertise.name;
        expertiseGranted = true;
        _logger.info(
          'Granted locality expertise: user=${user.id}, category=$category',
          tag: _logName,
        );
      }

      // 2. Check city expertise (75% city coverage)
      final cityExpertise = await checkAndGrantCityExpertise(
        user: user,
        expansion: expansion,
        category: category,
      );
      if (cityExpertise != null) {
        // Only grant if higher than current level
        final currentLevel = user.getExpertiseLevel(category);
        if (currentLevel == null || cityExpertise.index > currentLevel.index) {
          updatedExpertiseMap[category] = cityExpertise.name;
          expertiseGranted = true;
          _logger.info(
            'Granted city expertise: user=${user.id}, category=$category',
            tag: _logName,
          );
        }
      }

      // 3. Check state expertise (75% state coverage)
      final stateExpertise = await checkAndGrantStateExpertise(
        user: user,
        expansion: expansion,
        category: category,
      );
      if (stateExpertise != null) {
        final currentLevel = user.getExpertiseLevel(category);
        if (currentLevel == null || stateExpertise.index > currentLevel.index) {
          updatedExpertiseMap[category] = stateExpertise.name;
          expertiseGranted = true;
          _logger.info(
            'Granted state expertise: user=${user.id}, category=$category',
            tag: _logName,
          );
        }
      }

      // 4. Check nation expertise (75% nation coverage)
      final nationExpertise = await checkAndGrantNationExpertise(
        user: user,
        expansion: expansion,
        category: category,
      );
      if (nationExpertise != null) {
        final currentLevel = user.getExpertiseLevel(category);
        if (currentLevel == null || nationExpertise.index > currentLevel.index) {
          updatedExpertiseMap[category] = nationExpertise.name;
          expertiseGranted = true;
          _logger.info(
            'Granted nation expertise: user=${user.id}, category=$category',
            tag: _logName,
          );
        }
      }

      // 5. Check global expertise (75% global coverage)
      final globalExpertise = await checkAndGrantGlobalExpertise(
        user: user,
        expansion: expansion,
        category: category,
      );
      if (globalExpertise != null) {
        final currentLevel = user.getExpertiseLevel(category);
        if (currentLevel == null || globalExpertise.index > currentLevel.index) {
          updatedExpertiseMap[category] = globalExpertise.name;
          expertiseGranted = true;
          _logger.info(
            'Granted global expertise: user=${user.id}, category=$category',
            tag: _logName,
          );
        }
      }

      // 6. Check universal expertise (75% universe coverage)
      final universalExpertise = await checkAndGrantUniversalExpertise(
        user: user,
        expansion: expansion,
        category: category,
      );
      if (universalExpertise != null) {
        final currentLevel = user.getExpertiseLevel(category);
        if (currentLevel == null || universalExpertise.index > currentLevel.index) {
          updatedExpertiseMap[category] = universalExpertise.name;
          expertiseGranted = true;
          _logger.info(
            'Granted universal expertise: user=${user.id}, category=$category',
            tag: _logName,
          );
        }
      }

      if (!expertiseGranted) {
        _logger.info(
          'No expertise granted: user=${user.id}, category=$category',
          tag: _logName,
        );
        return user;
      }

      // Update user with new expertise
      final updatedUser = user.copyWith(
        expertiseMap: updatedExpertiseMap,
        updatedAt: DateTime.now(),
      );

      // Notify user of expertise gain
      await notifyExpertiseGain(
        user: updatedUser,
        category: category,
        newLevel: ExpertiseLevel.fromString(updatedExpertiseMap[category]!)!,
      );

      return updatedUser;
    } catch (e) {
      _logger.error('Error granting expertise from expansion', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check and grant locality expertise
  /// 
  /// Grants local expertise for neighboring locality expansion.
  /// 
  /// **Returns:**
  /// ExpertiseLevel.local if granted, null otherwise
  Future<ExpertiseLevel?> checkAndGrantLocalityExpertise({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      // Check if expansion has reached locality threshold
      if (!_expansionService.hasReachedLocalityThreshold(expansion)) {
        return null;
      }

      // Check if user already has local or higher expertise
      final currentLevel = user.getExpertiseLevel(category);
      if (currentLevel != null && currentLevel.index >= ExpertiseLevel.local.index) {
        return null; // Already has local or higher
      }

      // Grant local expertise
      return ExpertiseLevel.local;
    } catch (e) {
      _logger.error('Error checking locality expertise', error: e, tag: _logName);
      return null;
    }
  }

  /// Check and grant city expertise
  /// 
  /// Grants city expertise when 75% city coverage reached.
  /// 
  /// **Returns:**
  /// ExpertiseLevel.city if granted, null otherwise
  Future<ExpertiseLevel?> checkAndGrantCityExpertise({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      // Check each city for 75% coverage
      for (final city in expansion.expandedCities) {
        if (_expansionService.hasReachedCityThreshold(expansion, city)) {
          // Check if user already has city or higher expertise
          final currentLevel = user.getExpertiseLevel(category);
          if (currentLevel != null && currentLevel.index >= ExpertiseLevel.city.index) {
            continue; // Already has city or higher
          }

          // Grant city expertise
          return ExpertiseLevel.city;
        }
      }

      return null;
    } catch (e) {
      _logger.error('Error checking city expertise', error: e, tag: _logName);
      return null;
    }
  }

  /// Check and grant state expertise
  /// 
  /// Grants state expertise when 75% state coverage reached.
  /// 
  /// **Returns:**
  /// ExpertiseLevel.regional if granted (regional = state level), null otherwise
  Future<ExpertiseLevel?> checkAndGrantStateExpertise({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      // Check each state for 75% coverage
      for (final state in expansion.expandedStates) {
        if (_expansionService.hasReachedStateThreshold(expansion, state)) {
          // Check if user already has regional or higher expertise
          final currentLevel = user.getExpertiseLevel(category);
          if (currentLevel != null && currentLevel.index >= ExpertiseLevel.regional.index) {
            continue; // Already has regional or higher
          }

          // Grant regional expertise (regional = state level)
          return ExpertiseLevel.regional;
        }
      }

      return null;
    } catch (e) {
      _logger.error('Error checking state expertise', error: e, tag: _logName);
      return null;
    }
  }

  /// Check and grant nation expertise
  /// 
  /// Grants nation expertise when 75% nation coverage reached.
  /// 
  /// **Returns:**
  /// ExpertiseLevel.national if granted, null otherwise
  Future<ExpertiseLevel?> checkAndGrantNationExpertise({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      // Check each nation for 75% coverage
      for (final nation in expansion.expandedNations) {
        if (_expansionService.hasReachedNationThreshold(expansion, nation)) {
          // Check if user already has national or higher expertise
          final currentLevel = user.getExpertiseLevel(category);
          if (currentLevel != null && currentLevel.index >= ExpertiseLevel.national.index) {
            continue; // Already has national or higher
          }

          // Grant national expertise
          return ExpertiseLevel.national;
        }
      }

      return null;
    } catch (e) {
      _logger.error('Error checking nation expertise', error: e, tag: _logName);
      return null;
    }
  }

  /// Check and grant global expertise
  /// 
  /// Grants global expertise when 75% global coverage reached.
  /// 
  /// **Returns:**
  /// ExpertiseLevel.global if granted, null otherwise
  Future<ExpertiseLevel?> checkAndGrantGlobalExpertise({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      // Check if global threshold reached
      if (_expansionService.hasReachedGlobalThreshold(expansion)) {
        // Check if user already has global or higher expertise
        final currentLevel = user.getExpertiseLevel(category);
        if (currentLevel != null && currentLevel.index >= ExpertiseLevel.global.index) {
          return null; // Already has global or higher
        }

        // Grant global expertise
        return ExpertiseLevel.global;
      }

      return null;
    } catch (e) {
      _logger.error('Error checking global expertise', error: e, tag: _logName);
      return null;
    }
  }

  /// Check and grant universal expertise
  /// 
  /// Grants universal expertise when 75% universe coverage reached.
  /// 
  /// **Returns:**
  /// ExpertiseLevel.universal if granted, null otherwise
  Future<ExpertiseLevel?> checkAndGrantUniversalExpertise({
    required UnifiedUser user,
    required GeographicExpansion expansion,
    required String category,
  }) async {
    try {
      // Universal expertise requires 75% coverage across all nations
      // This is a simplified check - in production, would check universe coverage
      if (_expansionService.hasReachedGlobalThreshold(expansion)) {
        // Check if expansion has coverage in multiple nations (simplified universe check)
        if (expansion.expandedNations.length >= 3) {
          // Check if user already has universal expertise
          final currentLevel = user.getExpertiseLevel(category);
          if (currentLevel != null && currentLevel.index >= ExpertiseLevel.universal.index) {
            return null; // Already has universal
          }

          // Grant universal expertise
          return ExpertiseLevel.universal;
        }
      }

      return null;
    } catch (e) {
      _logger.error('Error checking universal expertise', error: e, tag: _logName);
      return null;
    }
  }

  /// Update user expertise
  /// 
  /// Updates user's expertise map with new expertise level.
  /// 
  /// **Parameters:**
  /// - `user`: User to update
  /// - `category`: Category for expertise
  /// - `level`: New expertise level
  /// 
  /// **Returns:**
  /// Updated user
  UnifiedUser updateUserExpertise({
    required UnifiedUser user,
    required String category,
    required ExpertiseLevel level,
  }) {
    final updatedExpertiseMap = Map<String, String>.from(user.expertiseMap);
    updatedExpertiseMap[category] = level.name;

    return user.copyWith(
      expertiseMap: updatedExpertiseMap,
      updatedAt: DateTime.now(),
    );
  }

  /// Notify user of expertise gain
  /// 
  /// Sends notification to user about expertise gain.
  /// 
  /// **Parameters:**
  /// - `user`: User who gained expertise
  /// - `category`: Category for expertise
  /// - `newLevel`: New expertise level
  Future<void> notifyExpertiseGain({
    required UnifiedUser user,
    required String category,
    required ExpertiseLevel newLevel,
  }) async {
    try {
      _logger.info(
        'Expertise gain notification: user=${user.id}, category=$category, level=${newLevel.name}',
        tag: _logName,
      );

      // In production, would send push notification or in-app notification
      // For now, just log the notification
    } catch (e) {
      _logger.error('Error notifying expertise gain', error: e, tag: _logName);
      // Don't rethrow - notification failure shouldn't block expertise gain
    }
  }
}

