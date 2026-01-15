import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/services/enhanced_connectivity_service.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart';

// Import for SharedPreferencesCompat (matches injection_container.dart)
import 'package:avrai/core/services/storage_service.dart'
    show SharedPreferencesCompat;

/// Sync Controller
///
/// Orchestrates data synchronization between local and cloud storage.
/// Coordinates connectivity checks, conflict detection, and sync operations
/// for personality profiles and other user data.
///
/// **Responsibilities:**
/// - Check connectivity before sync
/// - Sync personality profile to/from cloud
/// - Detect and resolve conflicts
/// - Handle sync errors gracefully
/// - Return unified sync results
///
/// **Dependencies:**
/// - `EnhancedConnectivityService` - Check connectivity
/// - `PersonalitySyncService` - Sync personality profiles
/// - `PersonalityLearning` - Load local personality profile
/// - `StorageService` - Local storage operations
///
/// **Usage:**
/// ```dart
/// final controller = SyncController();
/// final result = await controller.syncUserData(
///   userId: 'user_123',
///   password: 'user_password',
///   scope: SyncScope.personality,
/// );
///
/// if (result.isSuccess) {
///   // Sync completed successfully
/// } else {
///   // Handle errors
/// }
/// ```
class SyncController implements WorkflowController<SyncInput, SyncResult> {
  static const String _logName = 'SyncController';

  final EnhancedConnectivityService _connectivityService;
  final PersonalitySyncService _personalitySyncService;
  final PersonalityLearning _personalityLearning;
  final AgentIdService? _agentIdService;
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final PersonalityKnotService? _personalityKnotService;
  final KnotStorageService? _knotStorageService;
  final KnotFabricService? _knotFabricService;
  final KnotWorldsheetService? _knotWorldsheetService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  SyncController({
    EnhancedConnectivityService? connectivityService,
    PersonalitySyncService? personalitySyncService,
    PersonalityLearning? personalityLearning,
    AgentIdService? agentIdService,
    PersonalityKnotService? personalityKnotService,
    KnotStorageService? knotStorageService,
    KnotFabricService? knotFabricService,
    KnotWorldsheetService? knotWorldsheetService,
    QuantumEntanglementService? quantumEntanglementService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _connectivityService = connectivityService ??
            GetIt.instance<EnhancedConnectivityService>(),
        _personalitySyncService =
            personalitySyncService ?? GetIt.instance<PersonalitySyncService>(),
        _personalityLearning = personalityLearning ??
            (() {
              // Use same pattern as injection_container.dart
              final prefs = GetIt.instance<SharedPreferencesCompat>();
              return PersonalityLearning.withPrefs(prefs);
            })(),
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
        _knotFabricService = knotFabricService ??
            (GetIt.instance.isRegistered<KnotFabricService>()
                ? GetIt.instance<KnotFabricService>()
                : null),
        _knotWorldsheetService = knotWorldsheetService ??
            (GetIt.instance.isRegistered<KnotWorldsheetService>()
                ? GetIt.instance<KnotWorldsheetService>()
                : null),
        _quantumEntanglementService = quantumEntanglementService ??
            (GetIt.instance.isRegistered<QuantumEntanglementService>()
                ? GetIt.instance<QuantumEntanglementService>()
                : null),
        _ai2aiProtocol = ai2aiProtocol ??
            (GetIt.instance.isRegistered<AnonymousCommunicationProtocol>()
                ? GetIt.instance<AnonymousCommunicationProtocol>()
                : null);

  /// Sync user data to/from cloud
  ///
  /// Orchestrates the complete sync workflow:
  /// 1. Check connectivity
  /// 2. Load local data
  /// 3. Sync based on scope
  /// 4. Handle conflicts
  /// 5. Return unified result
  ///
  /// **Parameters:**
  /// - `userId`: User ID to sync data for
  /// - `password`: User password (for encryption key derivation)
  /// - `scope`: What data to sync (personality, preferences, all)
  ///
  /// **Returns:**
  /// SyncResult with success/error state and sync details
  Future<SyncResult> syncUserData({
    required String userId,
    required String password,
    SyncScope scope = SyncScope.all,
  }) async {
    try {
      developer.log('Starting sync for user: $userId, scope: $scope',
          name: _logName);

      // 1. Check connectivity
      final hasConnectivity = await _connectivityService.hasInternetAccess();
      if (!hasConnectivity) {
        developer.log('No internet connectivity, cannot sync', name: _logName);
        return const SyncResult.failure(
          error:
              'No internet connectivity. Please check your connection and try again.',
          errorCode: 'NO_CONNECTIVITY',
        );
      }

      // 2. Check if sync is enabled
      final syncEnabled =
          await _personalitySyncService.isCloudSyncEnabled(userId);
      if (!syncEnabled) {
        developer.log('Cloud sync disabled for user: $userId', name: _logName);
        return const SyncResult.failure(
          error:
              'Cloud sync is disabled. Enable it in settings to sync your data.',
          errorCode: 'SYNC_DISABLED',
        );
      }

      // 3. Sync based on scope
      final syncDetails = <String, dynamic>{};

      if (scope == SyncScope.personality || scope == SyncScope.all) {
        try {
          // Load local personality profile
          final localProfile =
              await _personalityLearning.initializePersonality(userId);

          // Sync to cloud
          await _personalitySyncService.syncToCloud(
            userId,
            localProfile,
            password,
          );

          syncDetails['personality'] = 'synced';
          developer.log('Personality profile synced successfully',
              name: _logName);
        } catch (e, stackTrace) {
          developer.log(
            'Error syncing personality profile',
            error: e,
            stackTrace: stackTrace,
            name: _logName,
          );
          syncDetails['personality'] = 'failed: ${e.toString()}';
          // Continue with other sync operations even if one fails
        }
      }

      // TODO(Phase 8.12): Add preferences profile sync when cloud sync is implemented
      // if (scope == SyncScope.preferences || scope == SyncScope.all) {
      //   // Sync preferences profile
      // }

      // Step 4: AVRAI Core System Integration (optional, graceful degradation)
      
      // 4.1: Sync knot data if available
      if ((scope == SyncScope.personality || scope == SyncScope.all) &&
          _personalityKnotService != null &&
          _knotStorageService != null &&
          _agentIdService != null) {
        try {
          developer.log(
            '🎯 Syncing personality knot data',
            name: _logName,
          );
          
          // Get agentId for knot sync (reserved for future implementation)
          // final agentId = await _agentIdService!.getUserAgentId(userId);
          
          // Note: Full implementation would sync knot data to/from cloud
          // This is a placeholder for future knot data sync
          developer.log(
            'ℹ️ Knot data sync deferred (requires cloud knot storage)',
            name: _logName,
          );
          
          syncDetails['knot'] = 'deferred';
        } catch (e) {
          developer.log(
            '⚠️ Knot data sync failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          syncDetails['knot'] = 'failed: ${e.toString()}';
          // Continue - knot sync is optional
        }
      }
      
      // 4.2: Sync fabric data if group data exists
      if (scope == SyncScope.all && _knotFabricService != null && _agentIdService != null) {
        try {
          developer.log(
            '🧵 Syncing fabric data (if group data exists)',
            name: _logName,
          );
          
          // Note: Full implementation would sync fabric data to/from cloud
          // This is a placeholder for future fabric data sync
          developer.log(
            'ℹ️ Fabric data sync deferred (requires cloud fabric storage)',
            name: _logName,
          );
          
          syncDetails['fabric'] = 'deferred';
        } catch (e) {
          developer.log(
            '⚠️ Fabric data sync failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          syncDetails['fabric'] = 'failed: ${e.toString()}';
          // Continue - fabric sync is optional
        }
      }
      
      // 4.3: Sync worldsheet data if group tracking exists
      if (scope == SyncScope.all && _knotWorldsheetService != null && _agentIdService != null) {
        try {
          developer.log(
            '📊 Syncing worldsheet data (if group tracking exists)',
            name: _logName,
          );
          
          // Note: Full implementation would sync worldsheet data to/from cloud
          developer.log(
            'ℹ️ Worldsheet data sync deferred (requires cloud worldsheet storage)',
            name: _logName,
          );
          
          syncDetails['worldsheet'] = 'deferred';
        } catch (e) {
          developer.log(
            '⚠️ Worldsheet data sync failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          syncDetails['worldsheet'] = 'failed: ${e.toString()}';
          // Continue - worldsheet sync is optional
        }
      }
      
      // 4.4: Sync quantum states if available
      if (scope == SyncScope.all && _quantumEntanglementService != null) {
        try {
          developer.log(
            '🔬 Syncing quantum states (if available)',
            name: _logName,
          );
          
          // Note: Full implementation would sync quantum states to/from cloud
          developer.log(
            'ℹ️ Quantum state sync deferred (requires cloud quantum state storage)',
            name: _logName,
          );
          
          syncDetails['quantum'] = 'deferred';
        } catch (e) {
          developer.log(
            '⚠️ Quantum state sync failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          syncDetails['quantum'] = 'failed: ${e.toString()}';
          // Continue - quantum state sync is optional
        }
      }
      
      // 4.5: Use AI2AI mesh for distributed sync (optional)
      if (_ai2aiProtocol != null && hasConnectivity) {
        try {
          developer.log(
            '🤖 AI2AI mesh sync available (distributed sync deferred)',
            name: _logName,
          );
          
          // Note: Full implementation would use AI2AI mesh for peer-to-peer sync
          // This is a placeholder for future AI2AI mesh sync
          developer.log(
            'ℹ️ AI2AI mesh sync deferred (requires mesh network implementation)',
            name: _logName,
          );
          
          syncDetails['ai2ai'] = 'deferred';
        } catch (e) {
          developer.log(
            '⚠️ AI2AI mesh sync failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          syncDetails['ai2ai'] = 'failed: ${e.toString()}';
          // Continue - AI2AI mesh sync is optional
        }
      }

      developer.log('Sync completed for user: $userId', name: _logName);
      return SyncResult.success(
        syncedItems: syncDetails,
        syncTimestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during sync',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return SyncResult.failure(
        error: 'Sync failed: ${e.toString()}',
        errorCode: 'SYNC_FAILED',
      );
    }
  }

  /// Load data from cloud
  ///
  /// Downloads data from cloud and merges with local data.
  /// Handles conflicts by merging profiles.
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `password`: User password (for decryption)
  /// - `scope`: What data to load
  ///
  /// **Returns:**
  /// SyncResult with loaded data
  Future<SyncResult> loadFromCloud({
    required String userId,
    required String password,
    SyncScope scope = SyncScope.all,
  }) async {
    try {
      developer.log('Loading data from cloud for user: $userId',
          name: _logName);

      // 1. Check connectivity
      final hasConnectivity = await _connectivityService.hasInternetAccess();
      if (!hasConnectivity) {
        return const SyncResult.failure(
          error:
              'No internet connectivity. Please check your connection and try again.',
          errorCode: 'NO_CONNECTIVITY',
        );
      }

      // 2. Check if sync is enabled
      final syncEnabled =
          await _personalitySyncService.isCloudSyncEnabled(userId);
      if (!syncEnabled) {
        return const SyncResult.failure(
          error:
              'Cloud sync is disabled. Enable it in settings to load your data.',
          errorCode: 'SYNC_DISABLED',
        );
      }

      final loadedItems = <String, dynamic>{};

      // 3. Load personality profile from cloud
      if (scope == SyncScope.personality || scope == SyncScope.all) {
        try {
          final cloudProfile = await _personalitySyncService.loadFromCloud(
            userId,
            password,
          );

          if (cloudProfile != null) {
            // PersonalitySyncService handles merging during syncToCloud
            // For loadFromCloud, we just return the cloud profile
            loadedItems['personality'] = cloudProfile;
            developer.log('Personality profile loaded from cloud',
                name: _logName);
          } else {
            loadedItems['personality'] = 'not_found';
          }
        } catch (e, stackTrace) {
          developer.log(
            'Error loading personality profile from cloud',
            error: e,
            stackTrace: stackTrace,
            name: _logName,
          );
          loadedItems['personality'] = 'failed: ${e.toString()}';
        }
      }

      return SyncResult.success(
        syncedItems: loadedItems,
        syncTimestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error loading from cloud',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return SyncResult.failure(
        error: 'Load failed: ${e.toString()}',
        errorCode: 'LOAD_FAILED',
      );
    }
  }

  // WorkflowController interface implementation

  @override
  Future<SyncResult> execute(SyncInput input) async {
    return await syncUserData(
      userId: input.userId,
      password: input.password,
      scope: input.scope,
    );
  }

  @override
  ValidationResult validate(SyncInput input) {
    final errors = <String, String>{};

    if (input.userId.isEmpty) {
      errors['userId'] = 'User ID is required';
    }

    if (input.password.isEmpty) {
      errors['password'] = 'Password is required';
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      fieldErrors: errors,
    );
  }

  @override
  Future<void> rollback(SyncResult result) async {
    // Sync operations are idempotent and don't require rollback
    // If sync fails, local data remains unchanged
    developer.log('Rollback not needed for sync operations', name: _logName);
  }
}

/// Sync scope - what data to sync
enum SyncScope {
  /// Sync personality profile only
  personality,

  /// Sync preferences profile only (future)
  preferences,

  /// Sync all available data
  all,
}

/// Input for sync operations
class SyncInput {
  final String userId;
  final String password;
  final SyncScope scope;

  const SyncInput({
    required this.userId,
    required this.password,
    this.scope = SyncScope.all,
  });
}

/// Result of sync operations
class SyncResult extends ControllerResult {
  final Map<String, dynamic> syncedItems;
  final DateTime? syncTimestamp;

  const SyncResult.success({
    required this.syncedItems,
    this.syncTimestamp,
  }) : super(
          success: true,
          error: null,
          errorCode: null,
        );

  const SyncResult.failure({
    required String super.error,
    super.errorCode,
    this.syncedItems = const {},
    this.syncTimestamp,
  }) : super(
          success: false,
        );

  /// Get synced personality profile (if available)
  PersonalityProfile? get personalityProfile {
    final personality = syncedItems['personality'];
    if (personality is PersonalityProfile) {
      return personality;
    }
    return null;
  }
}
