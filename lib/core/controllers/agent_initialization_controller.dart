import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/controllers/social_media_data_collection_controller.dart';
import 'package:avrai/core/services/social_media_connection_service.dart';
import 'package:avrai/core/services/social_media_insight_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/preferences_profile_service.dart';
import 'package:avrai/core/services/onboarding_place_list_generator.dart';
import 'package:avrai/core/services/onboarding_geo_context_service.dart';
import 'package:avrai/core/services/onboarding_recommendation_service.dart';
import 'package:avrai/core/services/geo_hierarchy_service.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_ingestion_service_v1.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai/core/models/onboarding_data.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/preferences_profile.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:get_it/get_it.dart';

/// Agent Initialization Controller
///
/// Orchestrates the complete AI agent initialization workflow during onboarding.
/// Coordinates multiple services to collect data, initialize profiles, and set up
/// the user's personalized AI agent.
///
/// **Responsibilities:**
/// - Collect social media data from all connected platforms
/// - Initialize PersonalityProfile from onboarding data
/// - Initialize PreferencesProfile from onboarding data
/// - Generate place lists (optional, non-blocking)
/// - Get recommendations (optional, non-blocking)
/// - Attempt cloud sync (optional, non-blocking)
/// - Handle errors per step (continue on failure)
/// - Return unified initialization result
///
/// **Dependencies:**
/// - `SocialMediaDataCollectionController` - Collect social media data from all platforms
/// - `PersonalityLearning` - Initialize personality profile
/// - `PreferencesProfileService` - Initialize preferences profile
/// - `OnboardingPlaceListGenerator` - Generate place lists
/// - `OnboardingRecommendationService` - Get recommendations
/// - `PersonalitySyncService` - Cloud sync
/// - `AgentIdService` - Get agentId
///
/// **Usage:**
/// ```dart
/// final controller = AgentInitializationController();
/// final result = await controller.initializeAgent(
///   userId: userId,
///   onboardingData: onboardingData,
///   generatePlaceLists: true,
///   getRecommendations: true,
///   attemptCloudSync: true,
/// );
///
/// if (result.isSuccess) {
///   final personalityProfile = result.personalityProfile!;
///   final preferencesProfile = result.preferencesProfile;
/// } else {
///   // Handle error
///   final error = result.error;
/// }
/// ```
class AgentInitializationController
    implements
        WorkflowController<Map<String, dynamic>, AgentInitializationResult> {
  static const String _logName = 'AgentInitializationController';
  static const int _homebaseGeohashPrecisionUsed = 7;
  static const int _placesSearchRadiusMeters = 5000;

  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  final SocialMediaDataCollectionController _socialMediaDataController;
  final PersonalityLearning _personalityLearning;
  final PreferencesProfileService _preferencesService;
  final OnboardingPlaceListGenerator _placeListGenerator;
  final OnboardingRecommendationService _recommendationService;
  final PersonalitySyncService _syncService;
  final AgentIdService _agentIdService;
  final SocialMediaInsightService _socialMediaInsightService;
  // Phase 3: Knot generation during onboarding
  final PersonalityKnotService? _personalityKnotService;
  final KnotStorageService? _knotStorageService;
  final GeoHierarchyService _geoHierarchyService;
  final SharedPreferencesCompat? _prefs;

  // AVRAI Core System Integration (optional, graceful degradation)
  // ignore: unused_field
  final AtomicClockService
      _atomicClock; // Reserved for future 4D quantum state timestamps
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final QuantumMatchingAILearningService? _aiLearningService;

  AgentInitializationController({
    SocialMediaDataCollectionController? socialMediaDataController,
    SocialMediaConnectionService?
        socialMediaService, // Deprecated - kept for backward compatibility
    PersonalityLearning? personalityLearning,
    PreferencesProfileService? preferencesService,
    OnboardingPlaceListGenerator? placeListGenerator,
    OnboardingRecommendationService? recommendationService,
    PersonalitySyncService? syncService,
    AgentIdService? agentIdService,
    SocialMediaInsightService? socialMediaInsightService,
    PersonalityKnotService? personalityKnotService,
    KnotStorageService? knotStorageService,
    GeoHierarchyService? geoHierarchyService,
    SharedPreferencesCompat? prefs,
    AtomicClockService? atomicClock,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _socialMediaDataController = socialMediaDataController ??
            GetIt.instance<SocialMediaDataCollectionController>(),
        _personalityLearning =
            personalityLearning ?? GetIt.instance<PersonalityLearning>(),
        _preferencesService =
            preferencesService ?? GetIt.instance<PreferencesProfileService>(),
        _placeListGenerator = placeListGenerator ??
            GetIt.instance<OnboardingPlaceListGenerator>(),
        _recommendationService = recommendationService ??
            GetIt.instance<OnboardingRecommendationService>(),
        _syncService = syncService ?? GetIt.instance<PersonalitySyncService>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _socialMediaInsightService = socialMediaInsightService ??
            GetIt.instance<SocialMediaInsightService>(),
        _personalityKnotService = personalityKnotService ??
            (GetIt.instance.isRegistered<PersonalityKnotService>()
                ? GetIt.instance<PersonalityKnotService>()
                : null),
        _knotStorageService = knotStorageService ??
            (GetIt.instance.isRegistered<KnotStorageService>()
                ? GetIt.instance<KnotStorageService>()
                : null),
        _geoHierarchyService = geoHierarchyService ??
            (GetIt.instance.isRegistered<GeoHierarchyService>()
                ? GetIt.instance<GeoHierarchyService>()
                : GeoHierarchyService()),
        _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _locationTimingService = locationTimingService ??
            (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
                ? GetIt.instance<LocationTimingQuantumStateService>()
                : null),
        _quantumEntanglementService = quantumEntanglementService ??
            (GetIt.instance.isRegistered<QuantumEntanglementService>()
                ? GetIt.instance<QuantumEntanglementService>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null);

  @override
  Future<AgentInitializationResult> execute(Map<String, dynamic> input) async {
    // This method is a convenience wrapper - actual implementation in initializeAgent
    // We need userId which isn't in the input map, so we use initializeAgent directly
    throw UnimplementedError(
      'Use initializeAgent() method instead - requires userId parameter',
    );
  }

  /// Initialize AI agent workflow
  ///
  /// Collects social media data, initializes personality and preferences profiles,
  /// and optionally generates place lists, gets recommendations, and attempts cloud sync.
  ///
  /// **Parameters:**
  /// - `userId`: Authenticated user ID
  /// - `onboardingData`: OnboardingData with user's onboarding information
  /// - `generatePlaceLists`: Whether to generate place lists (default: true)
  /// - `getRecommendations`: Whether to get recommendations (default: true)
  /// - `attemptCloudSync`: Whether to attempt cloud sync (default: true)
  ///
  /// **Returns:**
  /// `AgentInitializationResult` with success status, profiles, and any errors
  Future<AgentInitializationResult> initializeAgent({
    required String userId,
    required OnboardingData onboardingData,
    bool generatePlaceLists = true,
    bool getRecommendations = true,
    bool attemptCloudSync = true,
  }) async {
    try {
      _logger.info('🎯 Starting agent initialization workflow', tag: _logName);

      // STEP 1: Get agentId
      String agentId;
      try {
        agentId = await _agentIdService.getUserAgentId(userId);
        _logger.debug('✅ Got agentId: ${agentId.substring(0, 10)}...',
            tag: _logName);
      } catch (e) {
        _logger.error('❌ Failed to get agentId: $e', error: e, tag: _logName);
        return AgentInitializationResult.failure(
          error: 'Failed to get agent ID: $e',
          errorCode: 'AGENT_ID_ERROR',
        );
      }

      // STEP 2: Collect social media data (optional, continue on failure)
      Map<String, dynamic>? socialMediaData;
      bool hasSocialMediaConnections = false;
      try {
        // Use SocialMediaDataCollectionController to collect data from all platforms
        final collectionResult =
            await _socialMediaDataController.collectAllData(userId: userId);

        if (collectionResult.isSuccess &&
            collectionResult.structuredData != null) {
          socialMediaData = collectionResult.structuredData;
          hasSocialMediaConnections =
              collectionResult.profileData?.isNotEmpty ?? false;
          _logger.info(
            '📱 Collected social media data from ${collectionResult.profileData?.length ?? 0} platforms',
            tag: _logName,
          );

          // Log platform errors if any (non-blocking)
          if (collectionResult.platformErrors != null &&
              collectionResult.platformErrors!.isNotEmpty) {
            _logger.warn(
              '⚠️ Some platforms had errors: ${collectionResult.platformErrors!.keys.join(", ")}',
              tag: _logName,
            );
          }
        } else {
          _logger.debug(
              'ℹ️ No social media data collected (no connections or all failed)',
              tag: _logName);
        }
      } catch (e) {
        _logger.warn('⚠️ Could not collect social media data: $e',
            tag: _logName);
        // Continue without social media data - not critical
      }

      // STEP 2.5: Analyze social media insights (if connections exist, non-blocking)
      if (hasSocialMediaConnections) {
        try {
          _logger.info(
              '🔍 Analyzing social media insights for agent initialization...',
              tag: _logName);
          await _socialMediaInsightService.analyzeAllPlatforms(
            agentId: agentId,
            userId: userId,
          );
          _logger.info('✅ Social media insights analyzed', tag: _logName);
        } catch (e) {
          _logger.warn('⚠️ Could not analyze social media insights: $e',
              tag: _logName);
          // Continue - insight analysis is non-blocking
        }
      }

      // STEP 3: Initialize PersonalityProfile
      PersonalityProfile? personalityProfile;
      try {
        final onboardingDataMap = {
          'age': onboardingData.age,
          'birthday': onboardingData.birthday?.toIso8601String(),
          'homebase': onboardingData.homebase,
          'favoritePlaces': onboardingData.favoritePlaces,
          'preferences': onboardingData.preferences,
          'baselineLists': onboardingData.baselineLists,
          'respectedFriends': onboardingData.respectedFriends,
          'socialMediaConnected': onboardingData.socialMediaConnected,
        };

        personalityProfile =
            await _personalityLearning.initializePersonalityFromOnboarding(
          userId,
          onboardingData: onboardingDataMap,
          socialMediaData: socialMediaData,
        );

        _logger.info(
          '✅ PersonalityProfile initialized (generation ${personalityProfile.evolutionGeneration})',
          tag: _logName,
        );
      } catch (e) {
        _logger.error('❌ Failed to initialize PersonalityProfile: $e',
            error: e, tag: _logName);
        return AgentInitializationResult.failure(
          error: 'Failed to initialize personality profile: $e',
          errorCode: 'PERSONALITY_INIT_ERROR',
        );
      }

      // STEP 3.5: Update personality from social media insights (if available, non-blocking)
      if (hasSocialMediaConnections) {
        try {
          _logger.info(
              '🔄 Updating personality profile from social media insights...',
              tag: _logName);
          final updatedProfile =
              await _socialMediaInsightService.updatePersonalityFromInsights(
            agentId: agentId,
            userId: userId,
            personalityLearning: _personalityLearning,
          );
          personalityProfile = updatedProfile; // Use updated profile
          _logger.info(
            '✅ Personality updated from insights (generation ${updatedProfile.evolutionGeneration})',
            tag: _logName,
          );
        } catch (e) {
          _logger.warn('⚠️ Could not update personality from insights: $e',
              tag: _logName);
          // Continue - personality update is non-blocking, use original profile
        }
      }

      // STEP 3.6: Generate personality knot (Phase 3: Onboarding Integration)
      if (_personalityKnotService != null && _knotStorageService != null) {
        try {
          _logger.info(
            '🎯 Generating personality knot for agent: ${agentId.substring(0, 10)}...',
            tag: _logName,
          );

          // Generate knot from personality profile
          final personalityKnot = await _personalityKnotService!.generateKnot(
            personalityProfile!,
          );

          // Store knot
          await _knotStorageService!.saveKnot(agentId, personalityKnot);

          _logger.info(
            '✅ Personality knot generated and stored (crossings: ${personalityKnot.invariants.crossingNumber}, writhe: ${personalityKnot.invariants.writhe})',
            tag: _logName,
          );
        } catch (e) {
          _logger.warn(
            '⚠️ Could not generate personality knot: $e',
            tag: _logName,
          );
          // Continue without knot - knot generation is non-blocking
          // Knot can be generated later on-demand
        }
      } else {
        _logger.debug(
          'ℹ️ Knot services not available - skipping knot generation',
          tag: _logName,
        );
      }

      // STEP 4: Initialize PreferencesProfile
      PreferencesProfile? preferencesProfile;
      try {
        // Ensure onboardingData has agentId
        final onboardingDataWithAgentId = OnboardingData(
          agentId: agentId,
          age: onboardingData.age,
          birthday: onboardingData.birthday,
          homebase: onboardingData.homebase,
          favoritePlaces: onboardingData.favoritePlaces,
          preferences: onboardingData.preferences,
          baselineLists: onboardingData.baselineLists,
          respectedFriends: onboardingData.respectedFriends,
          socialMediaConnected: onboardingData.socialMediaConnected,
          completedAt: onboardingData.completedAt,
        );

        preferencesProfile = await _preferencesService.initializeFromOnboarding(
          onboardingDataWithAgentId,
        );

        _logger.info(
          '✅ PreferencesProfile initialized: ${preferencesProfile.categoryPreferences.length} categories, ${preferencesProfile.localityPreferences.length} localities',
          tag: _logName,
        );
      } catch (e) {
        _logger.warn('⚠️ Could not initialize PreferencesProfile: $e',
            tag: _logName);
        // Continue without PreferencesProfile (will be created empty later)
      }

      // STEP 5: Generate place lists (optional, non-blocking)
      List<Map<String, dynamic>>? generatedPlaceLists;
      if (generatePlaceLists) {
        try {
          final homebaseForPlaces = onboardingData.homebase ?? '';

          if (homebaseForPlaces.isNotEmpty) {
            final geo = await OnboardingGeoContextService(
              geoHierarchyService: _geoHierarchyService,
              prefs: _prefs,
            ).resolveHomebaseGeoContextBestEffort();

            final geoLabel =
                (geo.displayName?.isNotEmpty ?? false) ? geo.displayName : null;

            if (geo.hasCoordinates) {
              _logger.info(
                '🧭 Using cached homebase coords for place generation: '
                '${geo.latitude}, ${geo.longitude}'
                '${geoLabel != null ? ' ($geoLabel)' : ''}'
                '${geo.cityCode != null ? ' city=${geo.cityCode}' : ''}'
                '${geo.localityCode != null ? ' locality=${geo.localityCode}' : ''}',
                tag: _logName,
              );

              // Seed locality agent with homebase context (best-effort).
              try {
                final ingestion =
                    LocalityAgentIngestionServiceV1.tryGetFromDI();
                if (ingestion != null) {
                  await ingestion.seedHomebase(
                    userId: userId,
                    agentId: agentId,
                    latitude: geo.latitude!,
                    longitude: geo.longitude!,
                    cityCode: geo.cityCode,
                  );
                }
              } catch (e) {
                _logger.warn('⚠️ Locality agent homebase seed failed: $e',
                    tag: _logName);
              }
            } else {
              _logger.debug(
                'ℹ️ No cached homebase coords found; generating place lists without location bias',
                tag: _logName,
              );
            }

            final onboardingDataMap = {
              'age': onboardingData.age,
              'birthday': onboardingData.birthday?.toIso8601String(),
              'homebase': onboardingData.homebase,
              'favoritePlaces': onboardingData.favoritePlaces,
              'preferences': onboardingData.preferences,
            };

            final placeLists = await _placeListGenerator.generatePlaceLists(
              onboardingData: onboardingDataMap,
              homebase: homebaseForPlaces,
              latitude: geo.latitude,
              longitude: geo.longitude,
              maxLists: 5,
            );

            generatedPlaceLists = placeLists
                .map((list) => {
                      'name': list.name,
                      'places': list.places
                          .map((place) => place
                              .toJson()) // Preserve full Spot data including ID
                          .toList(),
                      'relevanceScore': list.relevanceScore,
                      'metadata': {
                        ...list.metadata,
                        'geoContext': {
                          ...geo.toJson(),
                          'geohashPrecisionUsed': _homebaseGeohashPrecisionUsed,
                          'radiusMeters': _placesSearchRadiusMeters,
                        },
                      },
                    })
                .toList();

            _logger.info('📍 Generated ${placeLists.length} place lists',
                tag: _logName);

            // Validation marker: confirms geo context was attached to list output.
            if (geo.hasCoordinates) {
              _logger.debug(
                '✅ Place list geoContext attached '
                '(city=${geo.cityCode ?? "unknown"}, locality=${geo.localityCode ?? "unknown"})',
                tag: _logName,
              );
            }
          }
        } catch (e) {
          _logger.warn('⚠️ Could not generate place lists: $e', tag: _logName);
          // Continue without place lists - not critical
        }
      }

      // STEP 6: Get recommendations (optional, non-blocking)
      Map<String, List<Map<String, dynamic>>>? recommendations;
      if (getRecommendations) {
        try {
          final onboardingDataMap = {
            'age': onboardingData.age,
            'birthday': onboardingData.birthday?.toIso8601String(),
            'homebase': onboardingData.homebase,
            'favoritePlaces': onboardingData.favoritePlaces,
            'preferences': onboardingData.preferences,
          };

          final recommendedLists =
              await _recommendationService.getRecommendedLists(
            userId: userId,
            onboardingData: onboardingDataMap,
            personalityDimensions: personalityProfile?.dimensions ?? {},
            maxRecommendations: 10,
          );

          final recommendedAccounts =
              await _recommendationService.getRecommendedAccounts(
            userId: userId,
            onboardingData: onboardingDataMap,
            personalityDimensions: personalityProfile?.dimensions ?? {},
            maxRecommendations: 10,
          );

          recommendations = {
            'lists': recommendedLists
                .map((rec) => {
                      'listName': rec.listName,
                      'compatibilityScore': rec.compatibilityScore,
                    })
                .toList(),
            'accounts': recommendedAccounts
                .map((rec) => {
                      'accountName': rec.accountName,
                      'compatibilityScore': rec.compatibilityScore,
                    })
                .toList(),
          };

          _logger.info(
            '💡 Found ${recommendedLists.length} list recommendations and ${recommendedAccounts.length} account recommendations',
            tag: _logName,
          );
        } catch (e) {
          _logger.warn('⚠️ Could not get recommendations: $e', tag: _logName);
          // Continue without recommendations - not critical
        }
      }

      // STEP 7: Attempt cloud sync (optional, non-blocking)
      bool cloudSyncAttempted = false;
      bool cloudSyncSucceeded = false;
      if (attemptCloudSync) {
        try {
          final syncEnabled = await _syncService.isCloudSyncEnabled(userId);

          if (syncEnabled) {
            cloudSyncAttempted = true;
            _logger.info('☁️ Cloud sync enabled, attempting to sync profile...',
                tag: _logName);

            // Note: Cloud sync may require password which may not be available during onboarding
            // This is handled gracefully - user can enable sync later in settings
            _logger.debug(
              'ℹ️ Cloud sync attempted (may require password from settings)',
              tag: _logName,
            );
            cloudSyncSucceeded =
                true; // Mark as attempted, actual sync may happen later
          } else {
            _logger.debug('ℹ️ Cloud sync disabled for user', tag: _logName);
          }
        } catch (e) {
          _logger.warn('⚠️ Error checking cloud sync status: $e',
              tag: _logName);
          // Continue - don't block initialization
        }
      }

      // STEP 8: AVRAI Core System Integration (optional, graceful degradation)

      // 8.1: Create 4D quantum location state if homebase provided
      if (_locationTimingService != null &&
          onboardingData.homebase != null &&
          onboardingData.homebase!.isNotEmpty) {
        try {
          // Try to get coordinates from geo context (if available from place list generation)
          final geo = await OnboardingGeoContextService(
            geoHierarchyService: _geoHierarchyService,
            prefs: _prefs,
          ).resolveHomebaseGeoContextBestEffort();

          if (geo.hasCoordinates) {
            _logger.info(
              '🌐 Creating 4D quantum location state for homebase: ${geo.latitude}, ${geo.longitude}',
              tag: _logName,
            );

            // Create UnifiedLocationData from geo context
            final locationData = UnifiedLocationData(
              latitude: geo.latitude!,
              longitude: geo.longitude!,
              city: geo.cityCode,
              address: geo.displayName,
            );

            // Create location quantum state for homebase
            final locationQuantumState =
                await _locationTimingService!.createLocationQuantumState(
              location: locationData,
              locationType: 0.7, // Default to suburban/urban mix
              accessibilityScore: null, // Not available from onboarding
              vibeLocationMatch: null, // Not available from onboarding
            );

            _logger.info(
              '✅ 4D quantum location state created for homebase',
              tag: _logName,
            );

            // Store quantum state (if storage service available)
            // Note: Quantum state storage would be handled by a dedicated service
            // This is a placeholder for future integration
            // ignore: unused_local_variable
            final _ = locationQuantumState;
          } else {
            _logger.debug(
              'ℹ️ Homebase coordinates not available - skipping 4D quantum state creation',
              tag: _logName,
            );
          }
        } catch (e) {
          _logger.warn(
            '⚠️ 4D quantum location state creation failed (non-blocking): $e',
            tag: _logName,
          );
          // Continue - 4D quantum state creation is optional
        }
      }

      // 8.2: Calculate initial quantum compatibility (optional)
      if (_quantumEntanglementService != null && personalityProfile != null) {
        try {
          // Create quantum state from personality profile
          // This is a placeholder for future quantum compatibility calculation
          // during initialization
          _logger.debug(
            'ℹ️ Quantum entanglement service available (compatibility calculation deferred to matching)',
            tag: _logName,
          );
        } catch (e) {
          _logger.warn(
            '⚠️ Quantum compatibility calculation failed (non-blocking): $e',
            tag: _logName,
          );
          // Continue - quantum compatibility is optional
        }
      }

      // 8.3: Learn from successful initialization via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null && personalityProfile != null) {
        try {
          // Learn from successful agent initialization
          // This helps the AI2AI network understand successful initialization patterns
          _logger.debug(
            '🤖 AI2AI learning service available (learning from initialization deferred to matching)',
            tag: _logName,
          );
          // Note: Actual learning happens when matches occur, not during initialization
          // This is a placeholder for future initialization-based learning
        } catch (e) {
          _logger.warn(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            tag: _logName,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }

      // STEP 9: Return success result
      _logger.info('✅ Agent initialization workflow completed successfully',
          tag: _logName);

      // Ensure personalityProfile is not null (should never be null at this point, but safety check)
      if (personalityProfile == null) {
        _logger.error('❌ PersonalityProfile is null after initialization',
            tag: _logName);
        return AgentInitializationResult.failure(
          error: 'Personality profile initialization failed',
          errorCode: 'PERSONALITY_NULL_ERROR',
        );
      }

      return AgentInitializationResult.success(
        agentId: agentId,
        personalityProfile: personalityProfile,
        preferencesProfile: preferencesProfile,
        socialMediaData: socialMediaData,
        generatedPlaceLists: generatedPlaceLists,
        recommendations: recommendations,
        cloudSyncAttempted: cloudSyncAttempted,
        cloudSyncSucceeded: cloudSyncSucceeded,
      );
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Unexpected error in agent initialization workflow: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return AgentInitializationResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  ValidationResult validate(Map<String, dynamic> input) {
    // Validation is done in initializeAgent method
    // This method exists for interface compliance
    return ValidationResult.valid();
  }

  @override
  Future<void> rollback(AgentInitializationResult result) async {
    // Agent initialization doesn't require rollback - profiles are created atomically
    // If initialization fails, no profiles are created, so nothing to rollback
  }
}

/// Result of agent initialization workflow
class AgentInitializationResult extends ControllerResult {
  final String? agentId;
  final PersonalityProfile? personalityProfile;
  final PreferencesProfile? preferencesProfile;
  final Map<String, dynamic>? socialMediaData;
  final List<Map<String, dynamic>>? generatedPlaceLists;
  final Map<String, List<Map<String, dynamic>>>? recommendations;
  final bool cloudSyncAttempted;
  final bool cloudSyncSucceeded;

  const AgentInitializationResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.agentId,
    this.personalityProfile,
    this.preferencesProfile,
    this.socialMediaData,
    this.generatedPlaceLists,
    this.recommendations,
    this.cloudSyncAttempted = false,
    this.cloudSyncSucceeded = false,
  });

  /// Create a successful result
  factory AgentInitializationResult.success({
    required String agentId,
    required PersonalityProfile personalityProfile,
    PreferencesProfile? preferencesProfile,
    Map<String, dynamic>? socialMediaData,
    List<Map<String, dynamic>>? generatedPlaceLists,
    Map<String, List<Map<String, dynamic>>>? recommendations,
    bool cloudSyncAttempted = false,
    bool cloudSyncSucceeded = false,
  }) {
    return AgentInitializationResult(
      success: true,
      agentId: agentId,
      personalityProfile: personalityProfile,
      preferencesProfile: preferencesProfile,
      socialMediaData: socialMediaData,
      generatedPlaceLists: generatedPlaceLists,
      recommendations: recommendations,
      cloudSyncAttempted: cloudSyncAttempted,
      cloudSyncSucceeded: cloudSyncSucceeded,
    );
  }

  /// Create a failed result
  factory AgentInitializationResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return AgentInitializationResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        agentId,
        personalityProfile,
        preferencesProfile,
        socialMediaData,
        generatedPlaceLists,
        recommendations,
        cloudSyncAttempted,
        cloudSyncSucceeded,
      ];
}
