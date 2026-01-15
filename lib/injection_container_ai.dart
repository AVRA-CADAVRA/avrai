import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai/core/services/storage_service.dart'
    show StorageService, SharedPreferencesCompat;
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/post_event_feedback_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/ai2ai_learning_service.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/services/quantum_satisfaction_enhancer.dart';
import 'package:avrai/core/ai/feedback_learning.dart' show UserFeedbackAnalyzer;
import 'package:avrai/core/ml/nlp_processor.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai/core/services/usage_pattern_tracker.dart';
import 'package:avrai/core/ai2ai/connection_log_queue.dart';
import 'package:avrai/core/ai2ai/cloud_intelligence_sync.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_ai/services/contextual_personality_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_coordinator_service.dart';
import 'dart:developer' as developer;
import 'package:avrai/core/services/enhanced_connectivity_service.dart';
import 'package:avrai/core/p2p/federated_learning.dart';
import 'package:avrai/core/ai/continuous_learning/data_collector.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning/orchestrator.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/unified_evolution_orchestrator.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/ai/event_queue.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/core/ai/structured_facts_extractor.dart';
import 'package:avrai/core/p2p/node_manager.dart';
import 'package:avrai/core/services/config_service.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';
import 'package:avrai/core/ml/inference_orchestrator.dart';
import 'package:avrai/core/ai/decision_coordinator.dart';
import 'package:avrai/core/ai2ai/embedding_delta_collector.dart';
import 'package:avrai/core/ai2ai/federated_learning_hooks.dart';
import 'package:avrai/core/services/user_name_resolution_service.dart';
import 'package:avrai/core/services/personality_agent_chat_service.dart';
import 'package:avrai/core/services/friend_chat_service.dart';
import 'package:avrai/core/services/community_chat_service.dart';
import 'package:avrai/core/services/dm_message_store.dart';
import 'package:avrai/core/services/community_message_store.dart';
import 'package:avrai/core/services/community_sender_key_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart' as ai2ai;
import 'package:avrai/core/services/business_expert_chat_service_ai2ai.dart';
import 'package:avrai/core/services/business_business_chat_service_ai2ai.dart';
import 'package:avrai/core/services/business_expert_outreach_service.dart';
import 'package:avrai/core/services/business_business_outreach_service.dart';
import 'package:avrai/core/services/business_member_service.dart';
import 'package:avrai/core/services/business_shared_agent_service.dart';
import 'package:avrai/core/services/business_account_service.dart';
import 'package:avrai/core/services/community_service.dart';
import 'package:avrai/core/services/geographic_expansion_service.dart';
import 'package:avrai/core/services/feature_flag_service.dart';
import 'package:avrai/data/repositories/hybrid_community_repository.dart';
import 'package:avrai/data/repositories/local_community_repository.dart';
import 'package:avrai/data/repositories/supabase_community_repository.dart';
import 'package:avrai/domain/repositories/community_repository.dart';
import 'package:avrai/core/services/user_anonymization_service.dart';
import 'package:avrai/core/services/event_recommendation_service.dart'
    as event_rec_service;
import 'package:avrai/core/services/event_matching_service.dart';
import 'package:avrai/core/services/spot_vibe_matching_service.dart';
import 'package:avrai/core/services/vibe_compatibility_service.dart';
import 'package:avrai/core/services/oauth_deep_link_handler.dart';
import 'package:avrai/core/services/social_media_connection_service.dart';
import 'package:avrai/core/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai/core/services/social_media/social_media_service_factory.dart';
import 'package:avrai/core/services/social_media/platforms/google_platform_service.dart';
import 'package:avrai/core/services/social_media/platforms/instagram_platform_service.dart';
import 'package:avrai/core/services/social_media/platforms/facebook_platform_service.dart';
import 'package:avrai/core/services/social_media/platforms/twitter_platform_service.dart';
import 'package:avrai/core/services/social_media/platforms/linkedin_platform_service.dart';
import 'package:avrai/core/services/partnership_service.dart';
import 'package:avrai/core/services/social_media_insight_service.dart';
import 'package:avrai/core/services/social_media_sharing_service.dart';
import 'package:avrai/core/services/social_media_discovery_service.dart';
import 'package:avrai/core/services/public_profile_analysis_service.dart';
import 'package:avrai/core/services/social_media_vibe_analyzer.dart';
import 'package:avrai/core/services/preferences_profile_service.dart';
import 'package:avrai/core/services/onboarding_data_service.dart';
import 'package:avrai/core/services/onboarding_suggestion_event_store.dart';
import 'package:avrai/core/services/onboarding_place_list_generator.dart';
import 'package:avrai/core/services/onboarding_recommendation_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai/core/services/llm_service.dart';
import 'package:avrai/core/services/legal_document_service.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai/core/services/ai_improvement_tracking_service.dart';
import 'package:avrai/core/services/action_history_service.dart';
import 'package:avrai/core/services/location_obfuscation_service.dart';
import 'package:avrai/core/services/field_encryption_service.dart';
import 'package:avrai/core/services/audit_log_service.dart';
import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:avrai/supabase_config.dart';
import 'package:avrai/google_places_config.dart';
import 'package:avrai/core/services/group_formation_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';

/// AI/Network Services Registration Module
///
/// Registers all AI and network-related services.
/// This includes:
/// - Personality learning and AI services
/// - AI2AI communication services
/// - Social media services
/// - Chat services
/// - Event/spot matching services
/// - Message encryption and anonymous communication
/// - Network services (connection, discovery, advertising)
/// - Learning systems (continuous, federated)
Future<void> registerAIServices(GetIt sl) async {
  const logger = AppLogger(defaultTag: 'DI-AI', minimumLevel: LogLevel.debug);
  logger.debug('🤖 [DI-AI] Registering AI/network services...');

  // Security & Anonymization Services (Phase 7.3.5-6)
  sl.registerLazySingleton<LocationObfuscationService>(
      () => LocationObfuscationService());
  sl.registerLazySingleton<UserAnonymizationService>(
      () => UserAnonymizationService(
            locationObfuscationService: sl<LocationObfuscationService>(),
          ));
  sl.registerLazySingleton<FieldEncryptionService>(
      () => FieldEncryptionService());
  sl.registerLazySingleton<AuditLogService>(() => AuditLogService());

  // Legal Document Service (for Terms of Service and Privacy Policy acceptance)
  sl.registerLazySingleton<LegalDocumentService>(() => LegalDocumentService(
        eventService: sl<ExpertiseEventService>(),
        supabaseService: sl<SupabaseService>(),
        storage: sl<StorageService>(),
        ledger: sl<LedgerRecorderServiceV0>(),
        receipts: sl<LedgerReceiptsServiceV0>(),
      ));

  sl.registerLazySingleton<DeviceDiscoveryService>(() {
    final platform = DeviceDiscoveryFactory.createPlatformDiscovery();
    return DeviceDiscoveryService(platform: platform);
  });

  // Personality Advertising Service
  sl.registerLazySingleton<PersonalityAdvertisingService>(() {
    return PersonalityAdvertisingService();
  });

  // PersonalityLearning (Philosophy: "Always Learning With You")
  // On-device AI learning that works offline
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    return PersonalityLearning.withPrefs(prefs);
  });

  // AI2AI Learning Service (Phase 7, Week 38)
  // Wrapper service for AI2AI learning methods UI
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    final personalityLearning = sl<PersonalityLearning>();
    return AI2AILearning.create(
      prefs: prefs,
      personalityLearning: personalityLearning,
    );
  });

  // UserFeedbackAnalyzer (Philosophy: "Dynamic dimension discovery through user feedback analysis")
  // Advanced feedback learning system that extracts implicit personality dimensions
  // Enhanced with Quantum Satisfaction Enhancement (Phase 4.1)
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    final personalityLearning = sl<PersonalityLearning>();
    final quantumSatisfactionEnhancer = sl<QuantumSatisfactionEnhancer>();
    final atomicClock = sl<AtomicClockService>();
    return UserFeedbackAnalyzer(
      prefs: prefs,
      personalityLearning: personalityLearning,
      quantumSatisfactionEnhancer: quantumSatisfactionEnhancer,
      atomicClock: atomicClock,
    );
  });

  // NLPProcessor (Natural Language Processing for text analysis)
  sl.registerLazySingleton(() => NLPProcessor());

  // PersonalitySyncService (Philosophy: "Cloud sync is optional and encrypted")
  sl.registerLazySingleton(() {
    final supabaseService = sl<SupabaseService>();
    final storageService = sl<StorageService>();
    return PersonalitySyncService(
      supabaseService: supabaseService,
      storageService: storageService,
    );
  });

  // UsagePatternTracker (Philosophy: "The key adapts to YOUR usage")
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    return UsagePatternTracker(prefs);
  });

  // AI2AI Protocol (Philosophy: "The Key Works Everywhere")
  // Phase 14: Updated to use MessageEncryptionService (Signal Protocol ready)
  sl.registerLazySingleton(() => AI2AIProtocol(
        encryptionService: sl<MessageEncryptionService>(),
      ));

  // Connection Log Queue (Philosophy: "Cloud is optional enhancement")
  sl.registerLazySingleton(
      () => ConnectionLogQueue(sl<SharedPreferencesCompat>()));

  // Cloud Intelligence Sync (Philosophy: "Cloud adds network wisdom")
  sl.registerLazySingleton(() => CloudIntelligenceSync(
        queue: sl<ConnectionLogQueue>(),
        connectivity: sl<Connectivity>(),
      ));

  // VibeConnectionOrchestrator + AI2AIRealtimeService wiring
  // Philosophy: "The Key Works Everywhere" - offline AI2AI via PersonalityLearning
  sl.registerLazySingleton<VibeConnectionOrchestrator>(() {
    final connectivity = sl<Connectivity>();
    final vibeAnalyzer = sl<UserVibeAnalyzer>();
    final deviceDiscovery = sl<DeviceDiscoveryService>();
    final advertisingService = sl<PersonalityAdvertisingService>();
    final personalityLearning = sl<PersonalityLearning>();
    final ai2aiProtocol = sl<AI2AIProtocol>();
    final signalKeyManager =
        sl.isRegistered<SignalKeyManager>() ? sl<SignalKeyManager>() : null;
    final prefs = sl<SharedPreferencesCompat>();

    final orchestrator = VibeConnectionOrchestrator(
      vibeAnalyzer: vibeAnalyzer,
      connectivity: connectivity,
      deviceDiscovery: deviceDiscovery,
      advertisingService: advertisingService,
      personalityLearning: personalityLearning,
      protocol: ai2aiProtocol,
      signalKeyManager: signalKeyManager,
      prefs: prefs,
    );

    // Wire personality evolution -> advertising refresh.
    // This makes "continuous learning" visible to nearby peers when discovery is enabled.
    // Also wire to knot evolution coordinator for automatic knot regeneration and tracking.
    personalityLearning.setEvolutionCallback((userId, evolvedProfile) {
      // Fire-and-forget: we don't want to block learning on BLE/advertising operations.
      Future<void>(() async {
        // Update advertising (existing functionality)
        await orchestrator.updatePersonalityAdvertising(userId, evolvedProfile);

        // NEW: Handle knot evolution (automatic regeneration and snapshot creation)
        // Knot services are registered before AI services, so coordinator should be available
        if (sl.isRegistered<KnotEvolutionCoordinatorService>()) {
          try {
            final knotCoordinator = sl<KnotEvolutionCoordinatorService>();
            await knotCoordinator.handleProfileEvolution(
                userId, evolvedProfile);
          } catch (e) {
            // Log but don't fail - knot evolution is non-blocking
            developer.log(
              '⚠️ Failed to handle knot evolution: $e',
              name: 'injection_container_ai',
            );
          }
        }
      });
    });
    // Build realtime with orchestrator and register it for app-wide access
    // Note: RealtimeBackend is registered during backend initialization (after AI services)
    // So we check if it's available and only set realtime service if it is
    if (sl.isRegistered<RealtimeBackend>()) {
      try {
        final realtimeBackend = sl<RealtimeBackend>();
        final realtime = AI2AIBroadcastService(realtimeBackend);
        orchestrator.setRealtimeService(realtime);
        // Expose realtime service via DI for UI pages/debug tools
        if (!sl.isRegistered<AI2AIBroadcastService>()) {
          sl.registerSingleton<AI2AIBroadcastService>(realtime);
        }
      } catch (e) {
        developer.log(
          '⚠️ RealtimeBackend not available yet, VibeConnectionOrchestrator will work without realtime',
          name: 'injection_container_ai',
        );
      }
    } else {
      developer.log(
        'ℹ️ RealtimeBackend not registered yet, VibeConnectionOrchestrator will work without realtime',
        name: 'injection_container_ai',
      );
    }
    return orchestrator;
  });

  // HTTP Client (shared across datasources)
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // AI Improvement Tracking Service
  sl.registerLazySingleton(() {
    final storageService = sl<StorageService>();
    return AIImprovementTrackingService(storage: storageService.defaultStorage);
  });

  // Action History Service
  sl.registerLazySingleton(() {
    final storageService = sl<StorageService>();
    return ActionHistoryService(storage: storageService.defaultStorage);
  });

  // Contextual Personality Service
  sl.registerLazySingleton(() => ContextualPersonalityService());

  // Enhanced Connectivity Service
  sl.registerLazySingleton(() {
    final httpClient = sl<http.Client>();
    return EnhancedConnectivityService(httpClient: httpClient);
  });

  // Federated Learning System
  sl.registerLazySingleton<FederatedLearningSystem>(() {
    final storageService = sl<StorageService>();
    return FederatedLearningSystem(storage: storageService.defaultStorage);
  });

  // Continuous Learning System
  sl.registerLazySingleton<ContinuousLearningSystem>(() {
    final agentIdService = sl<AgentIdService>();
    final dataCollector = LearningDataCollector(agentIdService: agentIdService);
    final dataProcessor = LearningDataProcessor();
    final orchestrator = ContinuousLearningOrchestrator(
      dataCollector: dataCollector,
      dataProcessor: dataProcessor,
      // Perf triage: slow down in debug/dev to reduce CPU churn.
      cycleInterval: SupabaseConfig.debug
          ? const Duration(seconds: 5)
          : const Duration(seconds: 1),
    );
    return ContinuousLearningSystem(
      agentIdService: agentIdService,
      orchestrator: orchestrator,
    );
  });

  // Event Queue (offline-capable event queuing)
  sl.registerLazySingleton(() => EventQueue());

  // Event Logger (context-enriched event logging)
  sl.registerLazySingleton(() {
    final agentIdService = sl<AgentIdService>();
    final supabaseService = sl<SupabaseService>();
    final eventQueue = sl<EventQueue>();
    final learningSystem = sl<ContinuousLearningSystem>();
    return EventLogger(
      agentIdService: agentIdService,
      supabaseService: supabaseService,
      eventQueue: eventQueue,
      learningSystem: learningSystem,
    );
  });

  // Structured Facts Extractor
  sl.registerLazySingleton(() => StructuredFactsExtractor());

  // P2P Node Manager
  sl.registerLazySingleton(() => P2PNodeManager());

  // Config (must be registered before InferenceOrchestrator)
  sl.registerLazySingleton<ConfigService>(() => ConfigService(
        environment: 'development',
        supabaseUrl: SupabaseConfig.url,
        supabaseAnonKey: SupabaseConfig.anonKey,
        googlePlacesApiKey: GooglePlacesConfig.getApiKey(),
        debug: SupabaseConfig.debug,
        inferenceBackend: 'onnx',
        orchestrationStrategy: 'device_first',
      ));

  // ONNX Dimension Scorer
  sl.registerLazySingleton<OnnxDimensionScorer>(() => OnnxDimensionScorer());

  // Inference Orchestrator
  sl.registerLazySingleton(() {
    final config = sl<ConfigService>();
    final llmService = sl<LLMService>();
    final onnxScorer = sl<OnnxDimensionScorer>();
    return InferenceOrchestrator(
      onnxScorer: onnxScorer,
      llmService: llmService,
      config: config,
    );
  });

  // Decision Coordinator
  sl.registerLazySingleton(() {
    final orchestrator = sl<InferenceOrchestrator>();
    final config = sl<ConfigService>();
    return DecisionCoordinator(
      orchestrator: orchestrator,
      config: config,
    );
  });

  // Embedding Delta Collector
  sl.registerLazySingleton(() => EmbeddingDeltaCollector());

  // Federated Learning Hooks
  sl.registerLazySingleton(() {
    final deltaCollector = sl<EmbeddingDeltaCollector>();
    return FederatedLearningHooks(
      deltaCollector: deltaCollector,
    );
  });

  // PreferencesProfile Service (for preference learning and quantum recommendations)
  sl.registerLazySingleton<PreferencesProfileService>(
      () => PreferencesProfileService(
            storage: sl<StorageService>(),
          ));

  // Event Recommendation Service (for AI recommendations)
  sl.registerLazySingleton<event_rec_service.EventRecommendationService>(
    () => event_rec_service.EventRecommendationService(
      eventService: sl<ExpertiseEventService>(),
      knotRecommendationEngine: sl<IntegratedKnotRecommendationEngine>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeCompatibilityService: sl<VibeCompatibilityService>(),
      agentIdService: sl<AgentIdService>(),
      knotFabricService: sl<KnotFabricService>(),
      knotStorageService: sl<KnotStorageService>(),
      quantumMatchingController: sl.isRegistered<QuantumMatchingController>()
          ? sl<QuantumMatchingController>()
          : null,
    ),
  );

  // Event Matching Service (for event matching signals)
  sl.registerLazySingleton<EventMatchingService>(
    () => EventMatchingService(
      knotRecommendationEngine: sl<IntegratedKnotRecommendationEngine>(),
      personalityLearning: sl<PersonalityLearning>(),
      feedbackService: sl.isRegistered<PostEventFeedbackService>()
          ? sl<PostEventFeedbackService>()
          : null,
      socialMediaConnectionService:
          sl.isRegistered<SocialMediaConnectionService>()
              ? sl<SocialMediaConnectionService>()
              : null,
    ),
  );

  // Spot Vibe Matching Service (for spot-user vibe matching)
  sl.registerLazySingleton<SpotVibeMatchingService>(
    () => SpotVibeMatchingService(
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      entityKnotService: sl<EntityKnotService>(),
      personalityKnotService: sl<PersonalityKnotService>(),
    ),
  );

  // OAuth Deep Link Handler (Phase 8.2: OAuth Implementation)
  sl.registerLazySingleton<OAuthDeepLinkHandler>(
    () => OAuthDeepLinkHandler(),
  );

  // Social Media Connection Service (Phase 8.2: Social Media Data Collection)
  // Phase 1.3: Refactored to use platform-specific services
  // Register common utilities first
  sl.registerLazySingleton<SocialMediaCommonUtils>(
    () => SocialMediaCommonUtils(sl<StorageService>()),
  );

  // Register platform services
  sl.registerLazySingleton<GooglePlatformService>(
    () => GooglePlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<InstagramPlatformService>(
    () => InstagramPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<FacebookPlatformService>(
    () => FacebookPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<TwitterPlatformService>(
    () => TwitterPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<LinkedInPlatformService>(
    () => LinkedInPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );

  // Register factory with platform services
  sl.registerLazySingleton<SocialMediaServiceFactory>(
    () => SocialMediaServiceFactory(
      services: {
        'google': sl<GooglePlatformService>(),
        'instagram': sl<InstagramPlatformService>(),
        'facebook': sl<FacebookPlatformService>(),
        'twitter': sl<TwitterPlatformService>(),
        'linkedin': sl<LinkedInPlatformService>(),
      },
    ),
  );

  // Register main service with factory
  sl.registerLazySingleton<SocialMediaConnectionService>(
    () => SocialMediaConnectionService(
      sl<StorageService>(),
      sl<AgentIdService>(),
      sl<OAuthDeepLinkHandler>(),
      serviceFactory: sl<SocialMediaServiceFactory>(),
    ),
  );

  // Social Media Insight Service (Phase 10: Personality Learning Integration)
  sl.registerLazySingleton<SocialMediaInsightService>(
    () => SocialMediaInsightService(
      storageService: sl<StorageService>(),
      connectionService: sl<SocialMediaConnectionService>(),
      vibeAnalyzer: sl<SocialMediaVibeAnalyzer>(),
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Social Media Sharing Service (Phase 10: Sharing System)
  sl.registerLazySingleton<SocialMediaSharingService>(
    () => SocialMediaSharingService(
      connectionService: sl<SocialMediaConnectionService>(),
    ),
  );

  // Social Media Discovery Service (Phase 10: Friend Discovery)
  sl.registerLazySingleton<SocialMediaDiscoveryService>(
    () => SocialMediaDiscoveryService(
      storageService: sl<StorageService>(),
      connectionService: sl<SocialMediaConnectionService>(),
      supabaseService: sl<SupabaseService>(),
    ),
  );

  // Public Profile Analysis Service (Phase 10: User-Provided Handles)
  sl.registerLazySingleton<PublicProfileAnalysisService>(
    () => PublicProfileAnalysisService(
      storageService: sl<StorageService>(),
      vibeAnalyzer: sl<SocialMediaVibeAnalyzer>(),
      insightService: sl<SocialMediaInsightService>(),
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Phase 3: Unified Chat Services
  sl.registerLazySingleton(() => UserNameResolutionService());
  sl.registerLazySingleton(() => PersonalityAgentChatService(
        llmService: sl<LLMService>(),
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService: sl<AgentIdService>(),
        personalityLearning: sl<PersonalityLearning>(),
        searchRepository: sl<HybridSearchRepository>(),
      ));
  // DM blob store (payloadless realtime)
  if (!sl.isRegistered<DmMessageStore>()) {
    sl.registerLazySingleton(
        () => DmMessageStore(supabase: sl<SupabaseService>()));
  }

  // Community sender keys + message store (payloadless notify + single ciphertext)
  sl.registerLazySingleton(
      () => CommunityMessageStore(supabase: sl<SupabaseService>()));
  sl.registerLazySingleton(() => CommunitySenderKeyService(
        secureStorage: sl<FlutterSecureStorage>(),
        supabase: sl<SupabaseService>(),
        agentIdService: sl<AgentIdService>(),
        encryptionService: sl<MessageEncryptionService>(),
      ));

  sl.registerLazySingleton(() => FriendChatService(
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService: sl<AgentIdService>(),
        realtimeBackend: sl.isRegistered<RealtimeBackend>() ? sl<RealtimeBackend>() : null,
        atomicClock: sl<AtomicClockService>(),
        dmStore: sl<DmMessageStore>(),
      ));
  sl.registerLazySingleton(() => CommunityChatService(
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService: sl<AgentIdService>(),
        realtimeBackend: sl.isRegistered<RealtimeBackend>() ? sl<RealtimeBackend>() : null,
        atomicClock: sl<AtomicClockService>(),
        dmStore: sl<DmMessageStore>(),
        senderKeyService: sl<CommunitySenderKeyService>(),
        communityMessageStore: sl<CommunityMessageStore>(),
      ));

  // Community Service (for community chat member lists)
  if (!sl.isRegistered<CommunityRepository>() &&
      sl.isRegistered<StorageService>() &&
      sl.isRegistered<FeatureFlagService>()) {
    sl.registerLazySingleton<CommunityRepository>(
        () => HybridCommunityRepository(
              local: LocalCommunityRepository(
                storageService: sl<StorageService>(),
              ),
              remote: SupabaseCommunityRepository(
                supabaseService: sl.isRegistered<SupabaseService>()
                    ? sl<SupabaseService>()
                    : SupabaseService(),
              ),
              featureFlags: sl<FeatureFlagService>(),
            ));
  }
  if (!sl.isRegistered<CommunityService>()) {
    sl.registerLazySingleton<CommunityService>(() => CommunityService(
          expansionService: GeographicExpansionService(),
          knotFabricService: sl<KnotFabricService>(),
          knotStorageService: sl<KnotStorageService>(),
          storageService:
              sl.isRegistered<StorageService>() ? sl<StorageService>() : null,
          atomicClockService: sl.isRegistered<AtomicClockService>()
              ? sl<AtomicClockService>()
              : AtomicClockService(),
          repository: sl.isRegistered<CommunityRepository>()
              ? sl<CommunityRepository>()
              : null,
        ));
  }

  // Anonymous Communication Protocol (Phase 14: Signal Protocol ready)
  sl.registerLazySingleton(() => ai2ai.AnonymousCommunicationProtocol(
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        supabase: sl<SupabaseClient>(),
        atomicClock: sl<AtomicClockService>(),
        anonymizationService: sl<UserAnonymizationService>(),
        supabaseService:
            sl.isRegistered<SupabaseService>() ? sl<SupabaseService>() : null,
      ));

  // Business-Expert Chat Service (AI2AI routing)
  sl.registerLazySingleton(() => BusinessExpertChatServiceAI2AI(
        ai2aiProtocol: sl<ai2ai.AnonymousCommunicationProtocol>(),
        encryptionService: sl<MessageEncryptionService>(),
        businessService: sl<BusinessAccountService>(),
        agentIdService: sl<AgentIdService>(),
      ));

  // Business-Business Chat Service (AI2AI routing)
  sl.registerLazySingleton(() => BusinessBusinessChatServiceAI2AI(
        ai2aiProtocol: sl<ai2ai.AnonymousCommunicationProtocol>(),
        encryptionService: sl<MessageEncryptionService>(),
        businessService: sl<BusinessAccountService>(),
        agentIdService: sl<AgentIdService>(),
      ));

  // Business-Expert Outreach Service (vibe-based matching)
  sl.registerLazySingleton(() => BusinessExpertOutreachService(
        partnershipService: sl<PartnershipService>(),
        chatService: sl<BusinessExpertChatServiceAI2AI>(),
      ));

  // Business-Business Outreach Service (partnership discovery)
  sl.registerLazySingleton(() => BusinessBusinessOutreachService(
        partnershipService: sl<PartnershipService>(),
        businessService: sl<BusinessAccountService>(),
        chatService: sl<BusinessBusinessChatServiceAI2AI>(),
      ));

  // Business Member Service (multi-user support)
  sl.registerLazySingleton(() => BusinessMemberService(
        businessAccountService: sl<BusinessAccountService>(),
      ));

  // Business Shared Agent Service (neural network of agents)
  sl.registerLazySingleton(() => BusinessSharedAgentService(
        businessAccountService: sl<BusinessAccountService>(),
        memberService: sl<BusinessMemberService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));

  // Social Media Vibe Analyzer
  sl.registerLazySingleton(() => SocialMediaVibeAnalyzer());

  // Onboarding & Agent Creation Services
  sl.registerLazySingleton(() => OnboardingDataService(
        agentIdService: sl<AgentIdService>(),
        onboardingAggregationService:
            null, // Will be resolved lazily if available
      ));

  // Onboarding suggestion event store (provenance + user actions during onboarding).
  sl.registerLazySingleton(() => OnboardingSuggestionEventStore(
        agentIdService: sl<AgentIdService>(),
      ));

  // Post-install bootstrap: builds local system prompt/memory from onboarding signals.
  sl.registerLazySingleton(() => LocalLlmPostInstallBootstrapService(
        agentIdService: sl<AgentIdService>(),
        onboardingDataService: sl<OnboardingDataService>(),
        suggestionEventStore: sl<OnboardingSuggestionEventStore>(),
      ));

  // Phase 8.5: Onboarding Place List Generator
  sl.registerLazySingleton<OnboardingPlaceListGenerator>(
    () => OnboardingPlaceListGenerator(
      placesDataSource: sl<GooglePlacesDataSource>(),
    ),
  );

  // Onboarding Recommendation Service
  sl.registerLazySingleton(() => OnboardingRecommendationService(
        agentIdService: sl<AgentIdService>(),
      ));

  // Phase 19.18: Quantum Group Matching System
  // Section GM.2: Group Formation Service
  sl.registerLazySingleton<GroupFormationService>(
    () => GroupFormationService(
      deviceDiscovery: sl<DeviceDiscoveryService>(),
      atomicClock: sl<AtomicClockService>(),
      agentIdService: sl<AgentIdService>(),
      knotStorage: sl<KnotStorageService>(),
      knotCompatibilityService:
          sl.isRegistered<CrossEntityCompatibilityService>()
              ? sl<CrossEntityCompatibilityService>()
              : null,
      personalityLearning: sl<PersonalityLearning>(),
      socialDiscovery: sl.isRegistered<SocialMediaDiscoveryService>()
          ? sl<SocialMediaDiscoveryService>()
          : null,
      orchestrator: sl.isRegistered<VibeConnectionOrchestrator>()
          ? sl<VibeConnectionOrchestrator>()
          : null,
      meshService: sl.isRegistered<AdaptiveMeshNetworkingService>()
          ? sl<AdaptiveMeshNetworkingService>()
          : null,
    ),
  );

  // Unified Evolution Orchestrator
  // Coordinates all evolution-related activities across the SPOTS ecosystem
  sl.registerLazySingleton<UnifiedEvolutionOrchestrator>(() {
    final personalityLearning = sl<PersonalityLearning>();
    final agentIdService = sl<AgentIdService>();
    final knotEvolutionCoordinator =
        sl.isRegistered<KnotEvolutionCoordinatorService>()
            ? sl<KnotEvolutionCoordinatorService>()
            : null;
    final quantumMatchingLearning =
        sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null;
    final continuousLearningOrchestrator =
        sl.isRegistered<ContinuousLearningOrchestrator>()
            ? sl<ContinuousLearningOrchestrator>()
            : null;
    final ai2aiLearning =
        sl.isRegistered<AI2AILearning>() ? sl<AI2AILearning>() : null;

    return UnifiedEvolutionOrchestrator(
      personalityLearning: personalityLearning,
      agentIdService: agentIdService,
      knotEvolutionCoordinator: knotEvolutionCoordinator,
      quantumMatchingLearning: quantumMatchingLearning,
      continuousLearningOrchestrator: continuousLearningOrchestrator,
      ai2aiLearning: ai2aiLearning,
    );
  });

  // Initialize Unified Evolution Orchestrator after registration
  // This sets up the evolution callback to coordinate all evolution systems
  Future.microtask(() async {
    if (sl.isRegistered<UnifiedEvolutionOrchestrator>()) {
      try {
        final orchestrator = sl<UnifiedEvolutionOrchestrator>();
        await orchestrator.initialize();
        logger.debug('✅ [DI-AI] UnifiedEvolutionOrchestrator initialized');
      } catch (e) {
        logger.warning(
            '⚠️ [DI-AI] Failed to initialize UnifiedEvolutionOrchestrator: $e');
      }
    }
  });

  logger.debug('✅ [DI-AI] AI/network services registered');
}
