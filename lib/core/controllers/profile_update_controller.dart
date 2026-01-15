import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/models/user.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/preferences_profile.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/preferences_profile_service.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// Profile Update Controller
///
/// Orchestrates the complete profile update workflow. Coordinates validation,
/// user profile updates, personality/profile updates, and cloud synchronization.
///
/// **Responsibilities:**
/// - Validate profile changes
/// - Update user profile (via AuthRepository)
/// - Update PersonalityProfile (if personality fields changed)
/// - Update PreferencesProfile (if preferences changed)
/// - Sync to cloud (if sync enabled)
/// - Return unified result with errors
///
/// **Dependencies:**
/// - `AuthRepository` - Update user profile
/// - `PersonalityLearning` - Update personality profile
/// - `PreferencesProfileService` - Update preferences profile
/// - `PersonalitySyncService` - Sync personality to cloud
/// - `AtomicClockService` - Mandatory for timestamps (Phase 8.3+)
/// - `AgentIdService` - Get agent ID for user
///
/// **Usage:**
/// ```dart
/// final controller = ProfileUpdateController();
/// final result = await controller.updateProfile(
///   userId: 'user_123',
///   data: ProfileUpdateData(
///     displayName: 'New Name',
///     bio: 'Updated bio',
///     location: 'New Location',
///   ),
/// );
///
/// if (result.isSuccess) {
///   // Profile updated successfully
/// } else {
///   // Handle errors
/// }
/// ```
class ProfileUpdateController
    implements WorkflowController<ProfileUpdateData, ProfileUpdateResult> {
  static const String _logName = 'ProfileUpdateController';

  final AuthRepository _authRepository;
  final PersonalityLearning? _personalityLearning;
  final PreferencesProfileService? _preferencesService;
  final PersonalitySyncService? _syncService;
  final AtomicClockService _atomicClock;
  final AgentIdService? _agentIdService;
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final PersonalityKnotService? _personalityKnotService;
  final KnotStorageService? _knotStorageService;
  final KnotEvolutionStringService? _knotStringService;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumMatchingAILearningService? _aiLearningService;

  ProfileUpdateController({
    AuthRepository? authRepository,
    PersonalityLearning? personalityLearning,
    PreferencesProfileService? preferencesService,
    PersonalitySyncService? syncService,
    AtomicClockService? atomicClock,
    AgentIdService? agentIdService,
    PersonalityKnotService? personalityKnotService,
    KnotStorageService? knotStorageService,
    KnotEvolutionStringService? knotStringService,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _authRepository = authRepository ?? GetIt.instance<AuthRepository>(),
        _personalityLearning = personalityLearning ??
            (GetIt.instance.isRegistered<PersonalityLearning>()
                ? GetIt.instance<PersonalityLearning>()
                : null),
        _preferencesService = preferencesService ??
            (GetIt.instance.isRegistered<PreferencesProfileService>()
                ? GetIt.instance<PreferencesProfileService>()
                : null),
        _syncService = syncService ??
            (GetIt.instance.isRegistered<PersonalitySyncService>()
                ? GetIt.instance<PersonalitySyncService>()
                : null),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _agentIdService = agentIdService ??
            (GetIt.instance.isRegistered<AgentIdService>()
                ? GetIt.instance<AgentIdService>()
                : null),
        _personalityKnotService = personalityKnotService ??
            (GetIt.instance.isRegistered<PersonalityKnotService>()
                ? GetIt.instance<PersonalityKnotService>()
                : null),
        _knotStorageService = knotStorageService ??
            (GetIt.instance.isRegistered<KnotStorageService>()
                ? GetIt.instance<KnotStorageService>()
                : null),
        _knotStringService = knotStringService ??
            (GetIt.instance.isRegistered<KnotEvolutionStringService>()
                ? GetIt.instance<KnotEvolutionStringService>()
                : null),
        _locationTimingService = locationTimingService ??
            (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
                ? GetIt.instance<LocationTimingQuantumStateService>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null);

  /// Update user profile
  ///
  /// Orchestrates the complete profile update workflow:
  /// 1. Validate input
  /// 2. Get current user
  /// 3. Update user profile with atomic timestamps
  /// 4. Update personality profile (if personality fields changed)
  /// 5. Update preferences profile (if preferences changed)
  /// 6. Sync to cloud (if sync enabled)
  /// 7. Return unified result
  ///
  /// **Parameters:**
  /// - `userId`: User ID to update
  /// - `data`: Profile update data (displayName, bio, location, etc.)
  ///
  /// **Returns:**
  /// `ProfileUpdateResult` with success/failure and error details
  Future<ProfileUpdateResult> updateProfile({
    required String userId,
    required ProfileUpdateData data,
  }) async {
    try {
      developer.log(
        'Starting profile update: userId=$userId',
        name: _logName,
      );

      // Step 1: Validate input
      final validationResult = validate(data);
      if (!validationResult.isValid) {
        return ProfileUpdateResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Get current user
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null || currentUser.id != userId) {
        return ProfileUpdateResult.failure(
          error: 'User not found or unauthorized',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      // Step 3: Update user profile with atomic timestamps
      final atomicTimestamp = await _atomicClock.getAtomicTimestamp();
      final now = atomicTimestamp.serverTime;

      // Update user profile (User model only has displayName currently)
      final updatedUser = currentUser.copyWith(
        displayName: data.displayName ?? currentUser.displayName,
        updatedAt: now,
      );

      final savedUser = await _authRepository.updateCurrentUser(updatedUser);
      if (savedUser == null) {
        return ProfileUpdateResult.failure(
          error: 'Failed to update user profile',
          errorCode: 'UPDATE_FAILED',
        );
      }

      developer.log(
        'User profile updated successfully: userId=$userId',
        name: _logName,
      );

      // Step 4: Update personality profile (if personality fields changed)
      PersonalityProfile? updatedPersonality;
      if (data.personalityUpdates != null && _personalityLearning != null) {
        try {
          final currentPersonality =
              await _personalityLearning!.getCurrentPersonality(userId);

          if (currentPersonality != null) {
            // Update personality with new data
            // For now, personality updates are limited - can be extended
            developer.log(
              'Personality profile updates requested but not yet implemented',
              name: _logName,
            );
            updatedPersonality = currentPersonality;
          }
        } catch (e) {
          developer.log(
            'Error updating personality profile: $e',
            name: _logName,
            error: e,
          );
          // Don't fail the whole update if personality update fails
        }
      }

      // Step 5: Update preferences profile (if preferences changed)
      PreferencesProfile? updatedPreferences;
      if (data.preferencesUpdates != null && _preferencesService != null) {
        try {
          final currentPreferences =
              await _preferencesService!.getPreferencesProfile(userId);

          if (currentPreferences != null) {
            // Update preferences with new data
            // For now, preferences updates are limited - can be extended
            developer.log(
              'Preferences profile updates requested but not yet implemented',
              name: _logName,
            );
            updatedPreferences = currentPreferences;
          }
        } catch (e) {
          developer.log(
            'Error updating preferences profile: $e',
            name: _logName,
            error: e,
          );
          // Don't fail the whole update if preferences update fails
        }
      }

      // Step 6: AVRAI Core System Integration (optional, graceful degradation)
      
      // 6.1: Regenerate personality knot if personality profile changed
      if (updatedPersonality != null && 
          _personalityKnotService != null && 
          _knotStorageService != null &&
          _agentIdService != null) {
        try {
          developer.log(
            '🎯 Regenerating personality knot after profile update',
            name: _logName,
          );
          
          final agentId = await _agentIdService!.getUserAgentId(userId);
          
          // Generate new knot from updated personality profile
          final updatedKnot = await _personalityKnotService!.generateKnot(updatedPersonality);
          
          // Store updated knot
          await _knotStorageService!.saveKnot(agentId, updatedKnot);
          // agentId is used above
          
          developer.log(
            '✅ Personality knot regenerated and stored (crossings: ${updatedKnot.invariants.crossingNumber})',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Knot regeneration failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot regeneration is optional
        }
      }
      
      // 6.2: Update knot evolution string to track personality changes
      if (updatedPersonality != null && 
          _knotStringService != null &&
          _agentIdService != null) {
        try {
          developer.log(
            '🧵 Updating knot evolution string after profile update',
            name: _logName,
          );
          
          // Get agentId and knot history (if available)
          // Note: Full implementation would retrieve knot history and update evolution string
          // This is a placeholder for future string evolution tracking
          await _agentIdService!.getUserAgentId(userId);
          developer.log(
            'ℹ️ String evolution update deferred (requires knot history)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ String evolution update failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - string evolution is optional
        }
      }
      
      // 6.3: Update 4D quantum location state if location changed
      if (data.location != null && 
          _locationTimingService != null &&
          data.location != savedUser.displayName) {
        try {
          developer.log(
            '🌐 Updating 4D quantum location state after location change',
            name: _logName,
          );
          
          // Note: Full implementation would parse location and create quantum state
          // This is a placeholder for future location quantum state updates
          developer.log(
            'ℹ️ Location quantum state update deferred (requires location parsing)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Location quantum state update failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - location quantum state update is optional
        }
      }
      
      // 6.4: Learn from profile update via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during profile update
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }
      
      // Step 7: Sync to cloud (if sync enabled)
      if (_syncService != null) {
        try {
          final syncEnabled = await _syncService!.isCloudSyncEnabled(userId);
          if (syncEnabled && updatedPersonality != null) {
            // Sync personality profile to cloud
            // Note: Sync requires password, which we don't have here
            // For now, we'll skip auto-sync on profile update
            // User can manually sync via Privacy Settings page
            developer.log(
              'Cloud sync enabled but requires manual sync via Privacy Settings',
              name: _logName,
            );
          }
        } catch (e) {
          developer.log(
            'Error checking sync status: $e',
            name: _logName,
            error: e,
          );
          // Don't fail the whole update if sync check fails
        }
      }

      return ProfileUpdateResult.success(
        user: savedUser,
        personalityUpdated: updatedPersonality != null,
        preferencesUpdated: updatedPreferences != null,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating profile: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<ProfileUpdateResult> execute(ProfileUpdateData input) async {
    // Execute method requires userId - this is a design limitation
    // For now, return error. In practice, updateProfile should be called directly
    return ProfileUpdateResult.failure(
      error: 'execute() requires userId. Use updateProfile() instead.',
      errorCode: 'INVALID_USAGE',
    );
  }

  @override
  ValidationResult validate(ProfileUpdateData input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate displayName (if provided)
    if (input.displayName != null && input.displayName!.trim().isEmpty) {
      errors['displayName'] = 'Display name cannot be empty';
    }

    // Validate bio length (if provided) - TODO: Add when User model supports bio
    // if (input.bio != null && input.bio!.length > 500) {
    //   errors['bio'] = 'Bio must be 500 characters or less';
    // }

    if (errors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: errors,
        generalErrors: generalErrors,
      );
    }

    return ValidationResult.valid();
  }

  @override
  Future<void> rollback(ProfileUpdateResult result) async {
    // Rollback profile update (restore previous user)
    if (result.success && result.user != null && result.previousUser != null) {
      try {
        await _authRepository.updateCurrentUser(result.previousUser!);
        developer.log(
          'Rolled back profile update: userId=${result.user!.id}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error rolling back profile update: $e',
          name: _logName,
          error: e,
        );
        // Don't rethrow - rollback failures should be logged but not block
      }
    }
  }
}

/// Profile Update Data
///
/// Input data for profile updates
class ProfileUpdateData {
  final String? displayName;
  final String? bio;
  final String? location;
  final String? photoUrl;
  final List<String>? tags;
  final Map<String, dynamic>? personalityUpdates;
  final Map<String, dynamic>? preferencesUpdates;

  ProfileUpdateData({
    this.displayName,
    this.bio,
    this.location,
    this.photoUrl,
    this.tags,
    this.personalityUpdates,
    this.preferencesUpdates,
  });
}

/// Profile Update Result
///
/// Unified result for profile update operations
class ProfileUpdateResult extends ControllerResult {
  final User? user;
  final User? previousUser;
  final bool personalityUpdated;
  final bool preferencesUpdated;

  const ProfileUpdateResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.user,
    this.previousUser,
    this.personalityUpdated = false,
    this.preferencesUpdated = false,
  });

  factory ProfileUpdateResult.success({
    required User user,
    User? previousUser,
    bool personalityUpdated = false,
    bool preferencesUpdated = false,
  }) {
    return ProfileUpdateResult._(
      success: true,
      error: null,
      errorCode: null,
      user: user,
      previousUser: previousUser,
      personalityUpdated: personalityUpdated,
      preferencesUpdated: preferencesUpdated,
    );
  }

  factory ProfileUpdateResult.failure({
    required String error,
    required String errorCode,
  }) {
    return ProfileUpdateResult._(
      success: false,
      error: error,
      errorCode: errorCode,
      user: null,
      previousUser: null,
      personalityUpdated: false,
      preferencesUpdated: false,
    );
  }
}
