import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:avrai/injection_container_core.dart';
import 'package:avrai/injection_container_payment.dart';
import 'package:avrai/injection_container_admin.dart';
import 'package:avrai/injection_container_knot.dart';
import 'package:avrai/injection_container_quantum.dart';
import 'package:avrai/injection_container_ai.dart';
import 'package:avrai/injection_container_predictive_outreach.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sembast/sembast.dart';
import 'package:avrai/core/services/geo_hierarchy_service.dart';

// Database
// Note: SembastDatabase is now initialized in registerCoreServices() (injection_container_core.dart)

// Auth
import 'package:avrai/data/datasources/remote/auth_remote_datasource.dart';
import 'package:avrai/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:avrai/data/datasources/local/auth_local_datasource.dart';
import 'package:avrai/data/datasources/local/auth_sembast_datasource.dart';
import 'package:avrai/data/repositories/auth_repository_impl.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai/domain/usecases/auth/update_password_usecase.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';

// Spots
import 'package:avrai/data/datasources/remote/spots_remote_datasource.dart';
import 'package:avrai/data/datasources/remote/spots_remote_datasource_impl.dart';
import 'package:avrai/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai/data/datasources/local/spots_sembast_datasource.dart';
import 'package:avrai/data/repositories/spots_repository_impl.dart';
import 'package:avrai/domain/repositories/spots_repository.dart';
import 'package:avrai/domain/usecases/spots/get_spots_usecase.dart';
import 'package:avrai/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:avrai/domain/usecases/spots/create_spot_usecase.dart';
import 'package:avrai/domain/usecases/spots/update_spot_usecase.dart';
import 'package:avrai/domain/usecases/spots/delete_spot_usecase.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';

// Lists
import 'package:avrai/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai/data/datasources/remote/lists_remote_datasource_impl.dart';
import 'package:avrai/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai/data/datasources/local/lists_sembast_datasource.dart';
import 'package:avrai/data/repositories/lists_repository_impl.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';
import 'package:avrai/domain/usecases/lists/get_lists_usecase.dart';
import 'package:avrai/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai/domain/usecases/lists/delete_list_usecase.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';

// Hybrid Search (Phase 2: External Data Integration)
import 'package:avrai/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai/data/datasources/remote/openstreetmap_datasource.dart';
import 'package:avrai/data/datasources/remote/openstreetmap_datasource_impl.dart';
import 'package:avrai/data/repositories/hybrid_search_repository.dart';
import 'package:avrai/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/presentation/blocs/group_matching_bloc.dart';
import 'package:avrai/core/controllers/group_matching_controller.dart';
import 'package:avrai/core/controllers/reservation_creation_controller.dart';
import 'package:avrai/core/services/group_formation_service.dart';

// Phase 2: Missing Services
import 'package:avrai/core/services/role_management_service.dart';
import 'package:avrai/core/models/user_role.dart';
// Note: SearchCacheService, AISearchSuggestionsService, CommunityValidationService,
// PerformanceMonitor, SecurityValidator, and DeploymentValidator are now registered
// in registerCoreServices() (injection_container_core.dart)
import 'package:avrai/core/services/ai_search_suggestions_service.dart';

// Patent #30: Quantum Atomic Clock System
import 'package:avrai_core/services/atomic_clock_service.dart';

// Patent #31: Topological Knot Theory for Personality Representation
// Note: Most knot services are registered in registerKnotServices() (injection_container_knot.dart)
// Import only services needed in main container (for CommunityService dependencies)
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
// Quantum Enhancement Implementation Plan - Phase 2.1: Decoherence Tracking
// Quantum Enhancement Implementation Plan - Phase 3.1: Quantum Prediction Features
// Quantum Enhancement Implementation Plan - Phase 4.1: Quantum Satisfaction Enhancement
// Feature Flag System
// Supabase Backend Integration
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/enhanced_connectivity_service.dart';
// Note: LargeCityDetectionService, NeighborhoodBoundaryService, and GeographicScopeService
// are now registered in registerCoreServices() (injection_container_core.dart)
import 'package:avrai/core/services/geographic_scope_service.dart';
// Business Chat Services (AI2AI routing)
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai/core/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai/core/services/business_shared_agent_service.dart';
// Onboarding & Agent Creation Services (Phase 1: Foundation)
import 'package:avrai/core/services/onboarding_data_service.dart';
import 'package:avrai/core/services/edge_function_service.dart';
import 'package:avrai/core/services/onboarding_aggregation_service.dart';
import 'package:avrai/core/services/social_enrichment_service.dart';
import 'package:avrai/core/services/social_media_connection_service.dart';
import 'package:avrai/core/services/onboarding_place_list_generator.dart';
import 'package:avrai/core/services/onboarding_recommendation_service.dart';
import 'package:avrai/core/services/preferences_profile_service.dart';
import 'package:avrai/core/services/event_recommendation_service.dart'
    as event_rec_service;
// Controllers (Phase 8.11)
import 'package:avrai/core/controllers/onboarding_flow_controller.dart';
import 'package:avrai/core/controllers/agent_initialization_controller.dart';
import 'package:avrai/core/controllers/event_creation_controller.dart';
import 'package:avrai/core/controllers/social_media_data_collection_controller.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/controllers/ai_recommendation_controller.dart';
import 'package:avrai/core/controllers/business_onboarding_controller.dart';
import 'package:avrai/core/controllers/event_attendance_controller.dart';
import 'package:avrai/core/controllers/list_creation_controller.dart';
import 'package:avrai/core/controllers/checkout_controller.dart';
import 'package:avrai/core/controllers/event_cancellation_controller.dart';
import 'package:avrai/core/controllers/partnership_checkout_controller.dart';
import 'package:avrai/core/controllers/partnership_proposal_controller.dart';
import 'package:avrai/core/controllers/profile_update_controller.dart';
import 'package:avrai/core/controllers/sponsorship_checkout_controller.dart';
import 'package:avrai/core/services/cancellation_service.dart';
import 'package:avrai/core/services/tax_document_storage_service.dart';
import 'package:avrai/core/services/dispute_resolution_service.dart';
import 'package:avrai/core/services/disputes/dispute_evidence_storage_service.dart';
import 'package:avrai/core/controllers/sync_controller.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';

// Phase 19: Multi-Entity Quantum Entanglement Matching System
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';

// Phase 15: Reservation System with Quantum Integration
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_recommendation_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/core/services/reservation_ticket_queue_service.dart';
// Phase 6.2 Enhancement: Knot Theory Integration
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_orchestrator_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_knot/avra_knot.dart' show CrossEntityCompatibilityService;
import 'package:avrai/core/services/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/reservation_cancellation_policy_service.dart';
import 'package:avrai/core/services/reservation_dispute_service.dart';
import 'package:avrai/core/services/reservation_notification_service.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/services/reservation_analytics_service.dart';
import 'package:avrai/core/services/business_reservation_analytics_service.dart';
// Phase 10.1: Multi-layered Check-In System
import 'package:avrai/core/services/reservation_proximity_service.dart';
import 'package:avrai/core/services/wifi_fingerprint_service.dart';
import 'package:avrai/core/services/reservation_check_in_service.dart';
import 'package:avrai/core/services/reservation_calendar_service.dart';
import 'package:avrai/core/services/reservation_recurrence_service.dart';
import 'package:avrai/core/services/reservation_sharing_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
// Phase 10.1: AI2AI Mesh Integration
import 'package:avrai/core/ai2ai/connection_orchestrator.dart'
    show VibeConnectionOrchestrator;
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart';
import 'package:avrai/core/services/rate_limiting_service.dart';
import 'package:avrai/core/services/event_success_analysis_service.dart';
import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai/core/services/post_event_feedback_service.dart';
import 'package:http/http.dart' as http;
import 'package:avrai/core/services/logger.dart';
// Device Discovery & Advertising
// Single integration boundary
import 'package:avrai_network/avra_network.dart';
import 'package:avrai/supabase_config.dart';
// ML (cloud-only, simplified)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/ml/embedding_cloud_client.dart';
import 'package:avrai/core/services/llm_service.dart';
// Google Places integration
import 'package:avrai/core/services/google_places_cache_service.dart';
import 'package:avrai/core/services/google_place_id_finder_service_new.dart';
import 'package:avrai/core/services/google_places_sync_service.dart';
import 'package:avrai/data/datasources/remote/google_places_datasource_new_impl.dart';
import 'package:avrai/google_places_config.dart';

// Admin Services (God-Mode Admin System)
import 'package:avrai/core/services/business_account_service.dart';
import 'package:avrai/core/services/business_service.dart';
// Payment Processing - Agent 1: Payment Processing & Revenue
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai/core/services/payment_event_service.dart';
import 'package:avrai/core/services/revenue_split_service.dart';
import 'package:avrai/core/services/refund_service.dart';
import 'package:avrai/core/services/partnership_service.dart';
import 'package:avrai/core/services/sponsorship_service.dart';
import 'package:avrai/core/services/product_tracking_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/legal_document_service.dart';
import 'package:avrai/core/services/sales_tax_service.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai/core/services/community_service.dart';
import 'package:avrai/core/services/geographic_expansion_service.dart';
import 'package:avrai/core/services/feature_flag_service.dart';
import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/data/repositories/hybrid_community_repository.dart';
import 'package:avrai/data/repositories/local_community_repository.dart';
import 'package:avrai/data/repositories/supabase_community_repository.dart';
import 'package:avrai/domain/repositories/community_repository.dart';
// Phase 12: Neural Network Implementation
import 'package:avrai/core/services/calling_score_data_collector.dart';
import 'package:avrai/core/services/calling_score_calculator.dart';
import 'package:avrai/core/services/calling_score_baseline_metrics.dart';
import 'package:avrai/core/services/calling_score_training_data_preparer.dart';
import 'package:avrai/core/services/calling_score_ab_testing_service.dart';
import 'package:avrai/core/ml/calling_score_neural_model.dart';
import 'package:avrai/core/services/behavior_assessment_service.dart';
import 'package:avrai/core/ml/outcome_prediction_model.dart';
import 'package:avrai/core/services/outcome_prediction_service.dart';
import 'package:avrai/core/services/model_version_manager.dart';
import 'package:avrai/core/services/online_learning_service.dart';
import 'package:avrai/core/services/model_retraining_service.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/services/signal_protocol_initialization_service.dart';
import 'package:avrai/core/services/hybrid_encryption_service.dart';
import 'package:avrai/core/services/signal_protocol_encryption_service.dart';
import 'package:avrai/core/services/secure_mapping_encryption_service.dart';
import 'package:avrai/core/services/agent_id_migration_service.dart';
import 'package:avrai/core/services/mapping_key_rotation_service.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_engine.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_global_repository.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_ingestion_service_v1.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_local_store.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_mesh_cache.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_update_emitter_v1.dart';
import 'package:avrai/core/services/locality_agents/locality_geofence_planner.dart';
import 'package:avrai/core/services/locality_agents/os_geofence_registrar.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> init() async {
  const logger = AppLogger(defaultTag: 'DI', minimumLevel: LogLevel.debug);
  logger.info('🔧 [DI] Starting dependency injection initialization...');

  // Register core services first (foundational services that other modules depend on)
  // This includes: Connectivity, PermissionsPersistenceService, Sembast Database,
  // StorageService, FeatureFlagService, Geographic services, CommunityValidationService,
  // AtomicClockService, PerformanceMonitor, SecurityValidator, DeploymentValidator,
  // SearchCacheService, AISearchSuggestionsService, UserVibeAnalyzer, and SharedPreferencesCompat
  await registerCoreServices(sl);
  logger.debug('✅ [DI] Core services registered');

  // Data Sources - Local (Offline-First)
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthSembastDataSource());
  sl.registerLazySingleton<SpotsLocalDataSource>(
      () => SpotsSembastDataSource());
  sl.registerLazySingleton<ListsLocalDataSource>(
      () => ListsSembastDataSource());

  // Data Sources - Remote (Optional, for online features)
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<SpotsRemoteDataSource>(
      () => SpotsRemoteDataSourceImpl());
  sl.registerLazySingleton<ListsRemoteDataSource>(
      () => ListsRemoteDataSourceImpl());

  // Tax document storage (middle-ground):
  // - Prefer Supabase Storage (private, per-user bucket) for new uploads.
  // - Keep Firebase Analytics intact; Firebase Storage remains supported for legacy URLs.
  if (!sl.isRegistered<TaxDocumentStorageService>()) {
    sl.registerLazySingleton<TaxDocumentStorageService>(
      () => TaxDocumentStorageService(
        supabaseService: sl.isRegistered<SupabaseService>()
            ? sl<SupabaseService>()
            : SupabaseService(),
        useSupabase: true,
        // We don't inject FirebaseStorage here to keep DI safe in runtimes where Firebase isn't initialized.
        // Legacy Firebase URLs can still be opened by URL launcher, and Firebase Storage can be wired later if needed.
        useFirebase: true,
      ),
    );
  }

  // Paperwork documents (retention-locked):
  // - Dispute evidence uploads go into `paperwork-documents` bucket (private)
  if (!sl.isRegistered<DisputeEvidenceStorageService>()) {
    sl.registerLazySingleton<DisputeEvidenceStorageService>(
      () => DisputeEvidenceStorageService(
        supabaseService: sl<SupabaseService>(),
        ledger: sl<LedgerRecorderServiceV0>(),
      ),
    );
  }

  // Disputes (in-memory v0). Must be a singleton so submission + status pages
  // can read the same dispute state in this temporary implementation.
  if (!sl.isRegistered<DisputeResolutionService>()) {
    sl.registerLazySingleton<DisputeResolutionService>(
      () => DisputeResolutionService(
        eventService: sl<ExpertiseEventService>(),
      ),
    );
  }

  // Google Places Cache Service (for offline caching)
  sl.registerLazySingleton<GooglePlacesCacheService>(
      () => GooglePlacesCacheService());

  // Get Google Places API key from config
  final googlePlacesApiKey = GooglePlacesConfig.getApiKey();
  if (googlePlacesApiKey.isEmpty) {
    logger.warn(
      '⚠️ [DI] GOOGLE_PLACES_API_KEY is not set; Google Places calls will return empty results until provided via --dart-define',
    );
  }

  // Google Place ID Finder Service (New API)
  sl.registerLazySingleton<GooglePlaceIdFinderServiceNew>(
      () => GooglePlaceIdFinderServiceNew(
            apiKey: googlePlacesApiKey.isNotEmpty
                ? googlePlacesApiKey
                : 'demo_key', // Fallback for development
          ));

  // External Data Sources - Using New Places API (New)
  sl.registerLazySingleton<GooglePlacesDataSource>(
      () => GooglePlacesDataSourceNewImpl(
            apiKey: googlePlacesApiKey.isNotEmpty
                ? googlePlacesApiKey
                : 'demo_key', // Fallback for development
            httpClient: sl<http.Client>(),
            cacheService: sl<GooglePlacesCacheService>(),
          ));
  sl.registerLazySingleton<OpenStreetMapDataSource>(
      () => OpenStreetMapDataSourceImpl(
            httpClient: sl<http.Client>(),
          ));

  // Google Places Sync Service (using New API)
  sl.registerLazySingleton<GooglePlacesSyncService>(
      () => GooglePlacesSyncService(
            placeIdFinderNew: sl<GooglePlaceIdFinderServiceNew>(),
            cacheService: sl<GooglePlacesCacheService>(),
            googlePlacesDataSource: sl<GooglePlacesDataSource>(),
            spotsLocalDataSource: sl<SpotsLocalDataSource>(),
            connectivity: sl<Connectivity>(),
          ));

  // Repositories (Register first)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton<SpotsRepository>(
    () => SpotsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton<ListsRepository>(
    () => ListsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  // Hybrid Search Repository (Phase 2) - Always available for offline search
  sl.registerLazySingleton(() => HybridSearchRepository(
        localDataSource: sl<SpotsLocalDataSource>(),
        remoteDataSource: sl<SpotsRemoteDataSource>(),
        googlePlacesDataSource: sl<GooglePlacesDataSource>(),
        osmDataSource: sl<OpenStreetMapDataSource>(),
        googlePlacesCache: sl<GooglePlacesCacheService>(),
        connectivity: sl<Connectivity>(),
      ));

  // Auth Use cases (Register after repositories)
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePasswordUseCase(sl()));

  // Spots Use cases (Register after repositories)
  sl.registerLazySingleton(() => GetSpotsUseCase(sl()));
  sl.registerLazySingleton(() => GetSpotsFromRespectedListsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSpotUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSpotUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSpotUseCase(sl()));

  // Lists Use cases (Register after repositories)
  sl.registerLazySingleton(() => GetListsUseCase(sl()));
  sl.registerLazySingleton(() => CreateListUseCase(sl()));
  sl.registerLazySingleton(() => UpdateListUseCase(sl()));
  sl.registerLazySingleton(() => DeleteListUseCase(sl()));

  // Hybrid Search Use case (Phase 2)
  sl.registerLazySingleton(() => HybridSearchUseCase(sl()));

  // Services (Search services, StorageService, FeatureFlagService, Geographic services,
  // CommunityValidationService, AtomicClockService, UserVibeAnalyzer, and SharedPreferencesCompat
  // are now registered in registerCoreServices())

  // Phase 2: Missing Services
  // Register Phase 2 services (dependencies first)
  // Note: CommunityValidationService is registered in registerCoreServices()
  sl.registerLazySingleton<RoleManagementService>(
      () => RoleManagementServiceImpl(
            storageService: sl<StorageService>(),
            prefs: sl<SharedPreferencesCompat>(),
          ));

  // ============================================================================
  // SHARED FOUNDATIONAL SERVICES
  // ============================================================================
  // Register shared services that are used by multiple domain modules
  // These must be registered before domain modules are called
  // See PHASE_1_7_SHARED_SERVICES_ANALYSIS.md for details
  logger.debug('🔗 [DI] Registering shared foundational services...');

  // 1. BusinessAccountService (foundational - used by Payment, Admin, AI)
  sl.registerLazySingleton(() => BusinessAccountService());
  logger.debug('✅ [DI] BusinessAccountService registered (shared)');

  // ============================================================================
  // LEDGER PREREQS (must be registered before Event/Payment modules)
  // ============================================================================
  // These are needed early because v0 ledger writers are now called by foundational services
  // (events, partnerships, communities) and must not depend on late registration ordering.
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    );
  }
  if (!sl.isRegistered<SecureMappingEncryptionService>()) {
    sl.registerLazySingleton<SecureMappingEncryptionService>(
      () => SecureMappingEncryptionService(
        secureStorage: sl<FlutterSecureStorage>(),
      ),
    );
  }
  if (!sl.isRegistered<AgentIdService>()) {
    sl.registerLazySingleton(() => AgentIdService(
          encryptionService: sl<SecureMappingEncryptionService>(),
          businessService: sl<BusinessAccountService>(),
        ));
  }
  if (!sl.isRegistered<LedgerRecorderServiceV0>()) {
    sl.registerLazySingleton<LedgerRecorderServiceV0>(
      () => LedgerRecorderServiceV0(
        supabaseService: sl<SupabaseService>(),
        agentIdService: sl<AgentIdService>(),
        storage: sl<StorageService>(),
      ),
    );
  }
  if (!sl.isRegistered<LedgerReceiptsServiceV0>()) {
    sl.registerLazySingleton<LedgerReceiptsServiceV0>(
      () => LedgerReceiptsServiceV0(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (!sl.isRegistered<ProofRunServiceV0>()) {
    // Debug-only: skeptic-proof bundle receipts + export.
    sl.registerLazySingleton<ProofRunServiceV0>(
      () => ProofRunServiceV0(
        ledger: sl<LedgerRecorderServiceV0>(),
        supabase: sl<SupabaseService>(),
        prefs: sl<SharedPreferencesCompat>(),
      ),
    );
  }

  // 2. BusinessService (depends on BusinessAccountService)
  sl.registerLazySingleton<BusinessService>(() => BusinessService(
        accountService: sl<BusinessAccountService>(),
      ));
  logger.debug('✅ [DI] BusinessService registered (shared)');

  // 3. ExpertiseEventService (foundational event service - used by Payment, AI)
  sl.registerLazySingleton<ExpertiseEventService>(() => ExpertiseEventService(
        ledgerRecorder: sl<LedgerRecorderServiceV0>(),
      ));
  logger.debug('✅ [DI] ExpertiseEventService registered (shared)');

  logger.debug(
      '✅ [DI] Shared foundational services registered (BusinessAccountService, BusinessService, ExpertiseEventService)');

  // Note: CommunityService will be registered after Knot module (it has optional Knot dependencies)
  // Note: EventSuccessAnalysisService will be registered after Payment module (it needs PaymentService)

  // ============================================================================
  // DOMAIN MODULES
  // ============================================================================
  // Register domain-specific services in dependency order
  // See PHASE_1_7_REFACTORING_PLAN.md for details

  // 1. Knot Services (no domain dependencies)
  await registerKnotServices(sl);
  logger.debug('✅ [DI] Knot services registered');

  // Community repository (local-first, optional Supabase sync behind feature flag).
  if (!sl.isRegistered<CommunityRepository>()) {
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
    logger.debug('✅ [DI] CommunityRepository registered (hybrid)');
  }

  // Register CommunityService after Knot module (it has optional Knot dependencies)
  sl.registerLazySingleton(() => CommunityService(
        expansionService: GeographicExpansionService(),
        knotFabricService: sl<KnotFabricService>(),
        knotStorageService: sl<KnotStorageService>(),
        storageService: sl<StorageService>(),
        atomicClockService: sl<AtomicClockService>(),
        repository: sl<CommunityRepository>(),
        ledgerRecorder: sl<LedgerRecorderServiceV0>(),
      ));
  logger
      .debug('✅ [DI] CommunityService registered (shared, after Knot module)');

  // 2. Payment Services (depends on BusinessService, ExpertiseEventService)
  await registerPaymentServices(sl);
  logger.debug('✅ [DI] Payment services registered');

  // Register PostEventFeedbackService (needed by EventSuccessAnalysisService)
  // Note: PartnershipService is optional, so we check if it's registered
  sl.registerLazySingleton(() => PostEventFeedbackService(
        eventService: sl<ExpertiseEventService>(),
        partnershipService: sl.isRegistered<PartnershipService>()
            ? sl<PartnershipService>()
            : null,
      ));
  logger.debug(
      '✅ [DI] PostEventFeedbackService registered (shared, after Payment module)');

  // Register EventSuccessAnalysisService (depends on ExpertiseEventService, PostEventFeedbackService, optional PaymentService)
  sl.registerLazySingleton(() => EventSuccessAnalysisService(
        eventService: sl<ExpertiseEventService>(),
        feedbackService: sl<PostEventFeedbackService>(),
        paymentService: sl<PaymentService>(), // Optional, from Payment module
      ));
  logger.debug(
      '✅ [DI] EventSuccessAnalysisService registered (shared, after Payment module)');

  // 3. Quantum Services (depends on Knot services, EventSuccessAnalysisService)
  await registerQuantumServices(sl);
  logger.debug('✅ [DI] Quantum services registered');

  // Message Encryption Service (Phase 14.4: Signal Protocol Integration)
  // MUST be registered BEFORE AI services (AI2AIProtocol depends on it)
  // Uses HybridEncryptionService which tries Signal Protocol first, falls back to AES-256-GCM
  sl.registerLazySingleton<MessageEncryptionService>(
    () {
      final supabaseService = sl<SupabaseService>();
      final atomicClock = sl<AtomicClockService>();

      // Create Signal Protocol Encryption Service (will be used if Signal Protocol is available)
      // Note: SignalProtocolService is registered later in backend initialization, so check if registered
      SignalProtocolEncryptionService? signalProtocolEncryptionService;
      if (sl.isRegistered<SignalProtocolService>()) {
        try {
          final signalProtocolService = sl<SignalProtocolService>();
          signalProtocolEncryptionService = SignalProtocolEncryptionService(
            signalProtocol: signalProtocolService,
            supabaseService: supabaseService,
            atomicClock: atomicClock,
          );
        } catch (e) {
          logger.warn(
              '⚠️ [DI] Signal Protocol Encryption Service creation failed: $e');
          signalProtocolEncryptionService = null;
        }
      } else {
        logger.debug(
            'ℹ️ [DI] SignalProtocolService not registered yet, MessageEncryptionService will use AES-256-GCM fallback');
      }

      // Create hybrid service that tries Signal Protocol first, falls back to AES-256-GCM
      return HybridEncryptionService(
        signalProtocolService: signalProtocolEncryptionService,
      );
    },
  );
  logger.debug('✅ [DI] MessageEncryptionService registered');

  // 4. AI Services (depends on Knot, Quantum, and Payment services via PartnershipService)
  await registerAIServices(sl);
  logger.debug('✅ [DI] AI services registered');

  // 5. Admin Services (depends on BusinessAccountService, may depend on AI services)
  await registerAdminServices(sl);
  logger.debug('✅ [DI] Admin services registered');

  // 6. Predictive Outreach Services (depends on AI, Knot, Quantum services)
  await registerPredictiveOutreachServices(sl);
  logger.debug('✅ [DI] Predictive outreach services registered');

  // ============================================================================
  // INFRASTRUCTURE SERVICES (NOT in domain modules)
  // ============================================================================
  // Note: These services are foundational infrastructure and remain in main container

  // Agent ID Migration Service (for migrating plaintext mappings to encrypted)
  sl.registerLazySingleton<AgentIdMigrationService>(
    () => AgentIdMigrationService(
      supabaseService: sl<SupabaseService>(),
      encryptionService: sl<SecureMappingEncryptionService>(),
    ),
  );

  // Mapping Key Rotation Service (for rotating encryption keys)
  sl.registerLazySingleton<MappingKeyRotationService>(
    () => MappingKeyRotationService(
      supabaseService: sl<SupabaseService>(),
      encryptionService: sl<SecureMappingEncryptionService>(),
      agentIdService: sl<AgentIdService>(),
    ),
  );

  // Note: OnboardingDataService, SocialMediaVibeAnalyzer, and OnboardingPlaceListGenerator
  // are registered in AI module

  // Controllers (Phase 8.11)
  sl.registerLazySingleton(() => OnboardingFlowController(
        onboardingDataService: sl<OnboardingDataService>(),
        agentIdService: sl<AgentIdService>(),
        legalDocumentService: sl<LegalDocumentService>(),
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
      ));

  // Agent Initialization Controller (Phase 8.11)
  sl.registerLazySingleton(() => AgentInitializationController(
        socialMediaDataController: sl<SocialMediaDataCollectionController>(),
        personalityLearning: sl<PersonalityLearning>(),
        preferencesService: sl<PreferencesProfileService>(),
        placeListGenerator: sl<OnboardingPlaceListGenerator>(),
        recommendationService: sl<OnboardingRecommendationService>(),
        syncService: sl<PersonalitySyncService>(),
        agentIdService: sl<AgentIdService>(),
        atomicClock: sl<AtomicClockService>(),
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
      ));

  // ============================================================================
  // Locality Agents (v1) - geohash-keyed locality learning layer
  // ============================================================================
  if (!sl.isRegistered<LocalityAgentGlobalRepositoryV1>()) {
    sl.registerLazySingleton<LocalityAgentGlobalRepositoryV1>(
      () => LocalityAgentGlobalRepositoryV1(
        supabaseService: sl<SupabaseService>(),
        storage: sl<StorageService>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityAgentLocalStoreV1>()) {
    sl.registerLazySingleton<LocalityAgentLocalStoreV1>(
      () => LocalityAgentLocalStoreV1(storage: sl<StorageService>()),
    );
  }
  // NEW: Register LocalityAgentMeshCache for mesh-smoothed neighbor learning
  if (!sl.isRegistered<LocalityAgentMeshCache>()) {
    sl.registerLazySingleton<LocalityAgentMeshCache>(
      () => LocalityAgentMeshCache(storage: sl<StorageService>()),
    );
  }
  if (!sl.isRegistered<LocalityAgentEngineV1>()) {
    sl.registerLazySingleton<LocalityAgentEngineV1>(
      () => LocalityAgentEngineV1(
        globalRepo: sl<LocalityAgentGlobalRepositoryV1>(),
        localStore: sl<LocalityAgentLocalStoreV1>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityAgentUpdateEmitterV1>()) {
    sl.registerLazySingleton<LocalityAgentUpdateEmitterV1>(
      () => LocalityAgentUpdateEmitterV1(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityAgentIngestionServiceV1>()) {
    sl.registerLazySingleton<LocalityAgentIngestionServiceV1>(
      () => LocalityAgentIngestionServiceV1(
        agentIdService: sl<AgentIdService>(),
        geoHierarchyService: sl<GeoHierarchyService>(),
        prefs: sl.isRegistered<SharedPreferencesCompat>()
            ? sl<SharedPreferencesCompat>()
            : null,
        spotsLocalDataSource: sl<SpotsLocalDataSource>(),
        engine: sl<LocalityAgentEngineV1>(),
        emitter: sl<LocalityAgentUpdateEmitterV1>(),
      ),
    );
  }
  if (!sl.isRegistered<OsGeofenceRegistrarV1>()) {
    sl.registerLazySingleton<OsGeofenceRegistrarV1>(
      () => NoopOsGeofenceRegistrarV1(),
    );
  }
  if (!sl.isRegistered<LocalityGeofencePlannerV1>()) {
    sl.registerLazySingleton<LocalityGeofencePlannerV1>(
      () => LocalityGeofencePlannerV1(
        storage: sl<StorageService>(),
        registrar: sl<OsGeofenceRegistrarV1>(),
      ),
    );
  }

  // Event Creation Controller (Phase 8.11)
  sl.registerLazySingleton(() => EventCreationController(
        eventService: sl<ExpertiseEventService>(),
        geographicScopeService: sl<GeographicScopeService>(),
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        knotStringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
      ));

  // Social Media Data Collection Controller (Phase 8.11)
  sl.registerLazySingleton(() => SocialMediaDataCollectionController(
        socialMediaService: sl<SocialMediaConnectionService>(),
      ));

  // Payment Processing Controller (Phase 8.11)
  if (!sl.isRegistered<PaymentProcessingController>()) {
    sl.registerLazySingleton<PaymentProcessingController>(
        () => PaymentProcessingController(
              salesTaxService: sl<SalesTaxService>(),
              paymentEventService: sl<PaymentEventService>(),
            ));
  }

  // AI Recommendation Controller (Phase 8.11)
  sl.registerLazySingleton(() => AIRecommendationController(
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
            ? sl<IntegratedKnotRecommendationEngine>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        personalityLearning: sl<PersonalityLearning>(),
        preferencesProfileService: sl<PreferencesProfileService>(),
        eventRecommendationService:
            sl<event_rec_service.EventRecommendationService>(),
        agentIdService: sl<AgentIdService>(),
      ));

  // Sync Controller (Phase 8.11)
  // Register BusinessOnboardingController (Phase 8.11)
  sl.registerLazySingleton(() => BusinessOnboardingController(
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        businessAccountService: sl<BusinessAccountService>(),
        sharedAgentService: sl<BusinessSharedAgentService>(),
      ));

  // Register EventAttendanceController (Phase 8.11)
  sl.registerLazySingleton(() => EventAttendanceController(
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        knotStringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        eventService: sl<ExpertiseEventService>(),
        paymentController: sl<PaymentProcessingController>(),
        preferencesService: sl<PreferencesProfileService>(),
        agentIdService: sl<AgentIdService>(),
      ));

  // Register ListCreationController (Phase 8.11)
  sl.registerLazySingleton(() => ListCreationController(
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
            ? sl<IntegratedKnotRecommendationEngine>()
            : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        listsRepository: sl<ListsRepository>(),
        atomicClock: sl<AtomicClockService>(),
      ));

  // Register ProfileUpdateController (Phase 8.11)
  sl.registerLazySingleton(() => ProfileUpdateController(
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotStringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        authRepository: sl<AuthRepository>(),
        atomicClock: sl<AtomicClockService>(),
      ));

  // Register EventCancellationController (Phase 8.11)
  sl.registerLazySingleton(() => EventCancellationController(
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        cancellationService: sl<CancellationService>(),
        eventService: sl<ExpertiseEventService>(),
        paymentService: sl<PaymentService>(),
      ));

  // Register PartnershipProposalController (Phase 8.11)
  sl.registerLazySingleton(() => PartnershipProposalController(
        atomicClock: sl<AtomicClockService>(),
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        partnershipService: sl<PartnershipService>(),
        businessService: sl<BusinessService>(),
      ));

  // Register CheckoutController (Phase 8.11)
  sl.registerLazySingleton(() => CheckoutController(
        atomicClock: sl<AtomicClockService>(),
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        paymentController: sl<PaymentProcessingController>(),
        salesTaxService: sl<SalesTaxService>(),
        legalService: sl<LegalDocumentService>(),
        eventService: sl<ExpertiseEventService>(),
      ));

  // Register PartnershipCheckoutController (Phase 8.11)
  sl.registerLazySingleton(() => PartnershipCheckoutController(
        atomicClock: sl<AtomicClockService>(),
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        paymentController: sl<PaymentProcessingController>(),
        revenueSplitService: sl<RevenueSplitService>(),
        partnershipService: sl<PartnershipService>(),
        eventService: sl<ExpertiseEventService>(),
        salesTaxService: sl<SalesTaxService>(),
      ));

  // Register SponsorshipCheckoutController (Phase 8.11)
  sl.registerLazySingleton(() => SponsorshipCheckoutController(
        atomicClock: sl<AtomicClockService>(),
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        sponsorshipService: sl<SponsorshipService>(),
        eventService: sl<ExpertiseEventService>(),
        productTrackingService: sl<ProductTrackingService>(),
      ));

  sl.registerLazySingleton(() => SyncController(
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        ai2aiProtocol: sl.isRegistered<AnonymousCommunicationProtocol>()
            ? sl<AnonymousCommunicationProtocol>()
            : null,
        connectivityService: sl<EnhancedConnectivityService>(),
        personalitySyncService: sl<PersonalitySyncService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));

  // Note: OnboardingRecommendationService, PreferencesProfileService, EventRecommendationService,
  // EventMatchingService, SpotVibeMatchingService, OAuthDeepLinkHandler, SocialMediaConnectionService,
  // and related social media services are registered in AI module

  // Note: Quantum services are registered in Quantum module

  // Note: MessageEncryptionService is now registered BEFORE AI services (moved up to fix dependency order)
  // Note: AI/network services (chat services, business services, admin services, payment services,
  // AI learning services, etc.) are registered in their respective domain modules

  // ============================================================================
  // BACKEND INITIALIZATION
  // ============================================================================
  // Backend (Single Integration Boundary): initialize and expose avra_network
  try {
    logger.info('🔌 [DI] Initializing Supabase backend...');

    if (!SupabaseConfig.isValid) {
      logger
          .warn('⚠️ [DI] SupabaseConfig is invalid. URL or anonKey is empty.');
      logger.warn(
          '⚠️ [DI] Make sure to run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
      throw Exception('Supabase configuration is invalid');
    }

    final backend = await BackendFactory.create(
      BackendConfig.supabase(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        serviceRoleKey: SupabaseConfig.serviceRoleKey.isNotEmpty
            ? SupabaseConfig.serviceRoleKey
            : null,
        name: 'Supabase',
        isDefault: true,
      ),
    );
    logger.info('✅ [DI] Supabase backend created successfully');

    // Expose the unified backend and its components
    logger.debug('📝 [DI] Registering backend components...');
    sl.registerSingleton<BackendInterface>(backend);
    sl.registerLazySingleton<AuthBackend>(() => backend.auth);
    sl.registerLazySingleton<DataBackend>(() => backend.data);
    sl.registerLazySingleton<RealtimeBackend>(() => backend.realtime);
    logger.debug('✅ [DI] Backend components registered');

    // Register Supabase Client for LLM service
    try {
      logger.debug('🤖 [DI] Registering LLM service...');
      // Only register if Supabase is initialized
      try {
        final supabaseClient = Supabase.instance.client;
        sl.registerLazySingleton<SupabaseClient>(() => supabaseClient);

        // Register Edge Function Service (Phase 11 Section 4: Edge Mesh Functions)
        sl.registerLazySingleton(() => EdgeFunctionService(
              client: supabaseClient,
            ));
        logger.debug('✅ [DI] EdgeFunctionService registered');

        // Register Onboarding Aggregation Service (Phase 11 Section 4: Edge Mesh Functions)
        sl.registerLazySingleton(() => OnboardingAggregationService(
              edgeFunctionService: sl<EdgeFunctionService>(),
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] OnboardingAggregationService registered');

        // Register Social Enrichment Service (Phase 11 Section 4: Edge Mesh Functions)
        sl.registerLazySingleton(() => SocialEnrichmentService(
              edgeFunctionService: sl<EdgeFunctionService>(),
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] SocialEnrichmentService registered');

        // Register FactsIndex (Phase 11 Section 5: Retrieval + LLM Fusion)
        // Requires SupabaseClient to be available
        sl.registerLazySingleton(() => FactsIndex(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] FactsIndex registered');

        // Register Calling Score Data Collector (Phase 12 Section 1: Foundation & Data Collection)
        // Note: Register BehaviorAssessmentService first (if not already registered)
        if (!sl.isRegistered<BehaviorAssessmentService>()) {
          sl.registerLazySingleton<BehaviorAssessmentService>(
              () => BehaviorAssessmentService());
          logger.debug('✅ [DI] BehaviorAssessmentService registered');
        }

        // Register Calling Score Data Collector
        sl.registerLazySingleton(() => CallingScoreDataCollector(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
              enabled:
                  true, // Enable data collection for neural network training
            ));
        logger.debug('✅ [DI] CallingScoreDataCollector registered');

        // Register Calling Score Baseline Metrics (Phase 12 Section 1.2: Baseline Metrics)
        sl.registerLazySingleton(() => CallingScoreBaselineMetrics(
              supabase: supabaseClient,
            ));
        logger.debug('✅ [DI] CallingScoreBaselineMetrics registered');

        // Register Calling Score Neural Model (Phase 12 Section 2.1: Calling Score Prediction Model)
        // Register ModelVersionManager (Phase 12 Section 3.2.2: Model Versioning)
        sl.registerLazySingleton(() => ModelVersionManager());
        logger.debug('✅ [DI] ModelVersionManager registered');

        // Register ModelRetrainingService (Phase 12 Section 3.2.1: Backend Integration)
        sl.registerLazySingleton(() => ModelRetrainingService(
              versionManager: sl<ModelVersionManager>(),
            ));
        logger.debug('✅ [DI] ModelRetrainingService registered');

        // Register OnlineLearningService (Phase 12 Section 3.2.1: Continuous Learning)
        sl.registerLazySingleton(() => OnlineLearningService(
              supabase: supabaseClient,
              dataCollector: sl<CallingScoreDataCollector>(),
              versionManager: sl<ModelVersionManager>(),
              retrainingService: sl<ModelRetrainingService>(),
            ));
        logger.debug('✅ [DI] OnlineLearningService registered');

        sl.registerLazySingleton(() => CallingScoreNeuralModel());
        logger.debug('✅ [DI] CallingScoreNeuralModel registered');

        // Register Calling Score Training Data Preparer (Phase 12 Section 2.1)
        sl.registerLazySingleton(() => CallingScoreTrainingDataPreparer(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
              neuralModel: sl<CallingScoreNeuralModel>(),
            ));
        logger.debug('✅ [DI] CallingScoreTrainingDataPreparer registered');

        // Register Calling Score A/B Testing Service (Phase 12 Section 2.3: A/B Testing Framework)
        sl.registerLazySingleton(() => CallingScoreABTestingService(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] CallingScoreABTestingService registered');

        // Register Outcome Prediction Model (Phase 12 Section 3.1: Outcome Prediction Model)
        sl.registerLazySingleton(() => OutcomePredictionModel());
        logger.debug('✅ [DI] OutcomePredictionModel registered');

        // Register Outcome Prediction Service (Phase 12 Section 3.1: Outcome Prediction Model)
        sl.registerLazySingleton(() => OutcomePredictionService(
              model: sl<OutcomePredictionModel>(),
              supabase: supabaseClient,
              dataCollector: sl<CallingScoreDataCollector>(),
            ));
        logger.debug('✅ [DI] OutcomePredictionService registered');

        // Register Calling Score Calculator (Phase 12: Neural Network Implementation)
        // Phase 12 Section 2.2: Hybrid calling score calculation
        // Phase 12 Section 2.3: A/B testing integration
        // Phase 12 Section 3.1: Outcome prediction integration
        sl.registerLazySingleton(() => CallingScoreCalculator(
              behaviorAssessment: sl<BehaviorAssessmentService>(),
              dataCollector: sl<CallingScoreDataCollector>(),
              neuralModel:
                  sl<CallingScoreNeuralModel>(), // Optional: Hybrid calculation
              abTestingService:
                  sl<CallingScoreABTestingService>(), // Optional: A/B testing
              outcomePredictionService: sl<
                  OutcomePredictionService>(), // Optional: Outcome prediction
            ));
        logger.debug(
            '✅ [DI] CallingScoreCalculator registered (with neural model, A/B testing, and outcome prediction support)');

        // Register Signal Protocol Services (Phase 14: Signal Protocol Implementation - Option 1)
        sl.registerLazySingleton(() => SignalFFIBindings());
        logger.debug('✅ [DI] SignalFFIBindings registered');

        // Register Platform Bridge Bindings (Phase 14: Platform Bridge)
        // Must be registered before Rust Wrapper and Store Callbacks
        sl.registerLazySingleton(() => SignalPlatformBridgeBindings());
        logger.debug('✅ [DI] SignalPlatformBridgeBindings registered');

        // Register Rust Wrapper Bindings (Phase 14: Rust Wrapper)
        // Must be registered before Store Callbacks
        sl.registerLazySingleton(() => SignalRustWrapperBindings());
        logger.debug('✅ [DI] SignalRustWrapperBindings registered');

        sl.registerLazySingleton(() => SignalKeyManager(
              secureStorage: sl<FlutterSecureStorage>(),
              ffiBindings: sl<SignalFFIBindings>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] SignalKeyManager registered');

        sl.registerLazySingleton(() => SignalSessionManager(
              database: sl<Database>(),
              ffiBindings: sl<SignalFFIBindings>(),
              keyManager: sl<SignalKeyManager>(),
            ));
        logger.debug('✅ [DI] SignalSessionManager registered');

        // Register Store Callbacks (Phase 14: Store Callbacks)
        // Requires Platform Bridge and Rust Wrapper
        sl.registerLazySingleton(() => SignalFFIStoreCallbacks(
              keyManager: sl<SignalKeyManager>(),
              sessionManager: sl<SignalSessionManager>(),
              ffiBindings: sl<SignalFFIBindings>(),
              rustWrapper: sl<SignalRustWrapperBindings>(),
              platformBridge: sl<SignalPlatformBridgeBindings>(),
            ));
        logger.debug('✅ [DI] SignalFFIStoreCallbacks registered');

        sl.registerLazySingleton(() => SignalProtocolService(
              ffiBindings: sl<SignalFFIBindings>(),
              storeCallbacks: sl<SignalFFIStoreCallbacks>(),
              keyManager: sl<SignalKeyManager>(),
              sessionManager: sl<SignalSessionManager>(),
              atomicClock: sl<AtomicClockService>(),
            ));
        logger.debug('✅ [DI] SignalProtocolService registered');

        // Register Signal Protocol Initialization Service (Phase 14)
        // Pass dependencies for proper initialization sequence
        sl.registerLazySingleton(() => SignalProtocolInitializationService(
              signalProtocol: sl<SignalProtocolService>(),
              platformBridge: sl<SignalPlatformBridgeBindings>(),
              rustWrapper: sl<SignalRustWrapperBindings>(),
              storeCallbacks: sl<SignalFFIStoreCallbacks>(),
            ));
        logger.debug('✅ [DI] SignalProtocolInitializationService registered');

        // Register Reservation Services (Phase 15: Reservation System with Quantum Integration)
        // Phase 15 Section 15.1: Foundation - Quantum Integration
        sl.registerLazySingleton(() => ReservationQuantumService(
              atomicClock: sl<AtomicClockService>(),
              quantumVibeEngine: sl<QuantumVibeEngine>(),
              vibeAnalyzer: sl<UserVibeAnalyzer>(),
              personalityLearning: sl<PersonalityLearning>(),
              locationTimingService: sl<LocationTimingQuantumStateService>(),
              entanglementService: sl<
                  QuantumEntanglementService>(), // Optional, graceful degradation
            ));
        logger.debug('✅ [DI] ReservationQuantumService registered');

        sl.registerLazySingleton(() => ReservationService(
              atomicClock: sl<AtomicClockService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              refundService:
                  sl.isRegistered<RefundService>() ? sl<RefundService>() : null,
              cancellationPolicyService:
                  sl.isRegistered<ReservationCancellationPolicyService>()
                      ? sl<ReservationCancellationPolicyService>()
                      : null,
              // Phase 7.1: Analytics Integration
              analyticsService: sl.isRegistered<ReservationAnalyticsService>()
                  ? sl<ReservationAnalyticsService>()
                  : null,
              eventLogger:
                  sl.isRegistered<EventLogger>() ? sl<EventLogger>() : null,
            ));
        logger.debug('✅ [DI] ReservationService registered');

        sl.registerLazySingleton(() => ReservationRecommendationService(
              quantumService: sl<ReservationQuantumService>(),
              atomicClock: sl<AtomicClockService>(),
              entanglementService: sl.isRegistered<QuantumEntanglementService>()
                  ? sl<QuantumEntanglementService>()
                  : null, // Optional, graceful degradation
              eventService: sl.isRegistered<ExpertiseEventService>()
                  ? sl<ExpertiseEventService>()
                  : null,
              agentIdService: sl.isRegistered<AgentIdService>()
                  ? sl<AgentIdService>()
                  : null,
              llmService: sl.isRegistered<LLMService>()
                  ? sl<LLMService>()
                  : null, // Phase 6.2: AI-powered suggestions
              personalityLearning: sl.isRegistered<PersonalityLearning>()
                  ? sl<PersonalityLearning>()
                  : null, // Phase 6.2: User preferences
              aiSearchService: sl.isRegistered<AISearchSuggestionsService>()
                  ? sl<AISearchSuggestionsService>()
                  : null, // Phase 6.2: Suggestion patterns
              reservationService: sl.isRegistered<ReservationService>()
                  ? sl<ReservationService>()
                  : null, // Phase 6.2: Past reservations
              // Phase 6.2 Enhancement: Knot Theory Integration
              knotService: sl.isRegistered<PersonalityKnotService>()
                  ? sl<PersonalityKnotService>()
                  : null,
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
                  ? sl<IntegratedKnotRecommendationEngine>()
                  : null,
            ));
        logger.debug('✅ [DI] ReservationRecommendationService registered');

        // Register Reservation Analytics Service (Phase 7.1)
        sl.registerLazySingleton(() => ReservationAnalyticsService(
              reservationService: sl<ReservationService>(),
              agentIdService: sl<AgentIdService>(),
              eventLogger:
                  sl.isRegistered<EventLogger>() ? sl<EventLogger>() : null,
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              // Phase 7.1 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              atomicClock: sl.isRegistered<AtomicClockService>()
                  ? sl<AtomicClockService>()
                  : null,
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              quantumService: sl.isRegistered<ReservationQuantumService>()
                  ? sl<ReservationQuantumService>()
                  : null,
              personalityLearning: sl.isRegistered<PersonalityLearning>()
                  ? sl<PersonalityLearning>()
                  : null,
            ));
        logger.debug('✅ [DI] ReservationAnalyticsService registered');

        // Register Business Reservation Analytics Service (Phase 7.2)
        sl.registerLazySingleton(() => BusinessReservationAnalyticsService(
              reservationService: sl<ReservationService>(),
              agentIdService: sl<AgentIdService>(),
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              rateLimitService: sl.isRegistered<ReservationRateLimitService>()
                  ? sl<ReservationRateLimitService>()
                  : null,
              waitlistService: sl.isRegistered<ReservationWaitlistService>()
                  ? sl<ReservationWaitlistService>()
                  : null,
              availabilityService:
                  sl.isRegistered<ReservationAvailabilityService>()
                      ? sl<ReservationAvailabilityService>()
                      : null,
              eventLogger:
                  sl.isRegistered<EventLogger>() ? sl<EventLogger>() : null,
              // Phase 7.2 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              atomicClock: sl.isRegistered<AtomicClockService>()
                  ? sl<AtomicClockService>()
                  : null,
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              quantumService: sl.isRegistered<ReservationQuantumService>()
                  ? sl<ReservationQuantumService>()
                  : null,
              personalityLearning: sl.isRegistered<PersonalityLearning>()
                  ? sl<PersonalityLearning>()
                  : null,
            ));
        logger.debug('✅ [DI] BusinessReservationAnalyticsService registered');

        // Register Reservation Creation Controller (Phase 15.1.2.5)
        sl.registerLazySingleton(() => ReservationCreationController(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              quantumController: sl<QuantumMatchingController>(),
              agentIdService: sl<AgentIdService>(),
              atomicClock: sl<AtomicClockService>(),
              availabilityService:
                  sl.isRegistered<ReservationAvailabilityService>()
                      ? sl<ReservationAvailabilityService>()
                      : null,
              rateLimitService: sl.isRegistered<ReservationRateLimitService>()
                  ? sl<ReservationRateLimitService>()
                  : null,
              ticketQueueService:
                  sl.isRegistered<ReservationTicketQueueService>()
                      ? sl<ReservationTicketQueueService>()
                      : null,
            ));
        logger.debug('✅ [DI] ReservationCreationController registered');

        // Register Reservation Availability Service (Phase 15.1.4)
        sl.registerLazySingleton(() => ReservationAvailabilityService(
              reservationService: sl<ReservationService>(),
              eventService: sl<ExpertiseEventService>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] ReservationAvailabilityService registered');

        // Register Reservation Ticket Queue Service (Phase 15.1.3)
        sl.registerLazySingleton(() => ReservationTicketQueueService(
              atomicClock: sl<AtomicClockService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] ReservationTicketQueueService registered');

        // Register Rate Limiting Service (if not already registered)
        if (!sl.isRegistered<RateLimitingService>()) {
          sl.registerLazySingleton(() => RateLimitingService());
          logger.debug('✅ [DI] RateLimitingService registered');
        }

        // Register Reservation Rate Limit Service (Phase 15.1.8) - CRITICAL GAP FIX
        sl.registerLazySingleton(() => ReservationRateLimitService(
              rateLimitingService: sl<RateLimitingService>(),
              agentIdService: sl<AgentIdService>(),
              reservationService: sl<ReservationService>(),
            ));
        logger.debug('✅ [DI] ReservationRateLimitService registered');

        // Register Reservation Cancellation Policy Service (Phase 15.1.5)
        sl.registerLazySingleton(() => ReservationCancellationPolicyService(
              reservationService: sl<ReservationService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] ReservationCancellationPolicyService registered');

        // Register Reservation Dispute Service (Phase 15.1.6)
        sl.registerLazySingleton(() => ReservationDisputeService(
              reservationService: sl<ReservationService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              refundService:
                  sl.isRegistered<RefundService>() ? sl<RefundService>() : null,
            ));
        logger.debug('✅ [DI] ReservationDisputeService registered');

        // Register Reservation Notification Service (Phase 15.1.7)
        sl.registerLazySingleton(() => ReservationNotificationService(
              supabaseService: sl<SupabaseService>(),
              storageService: sl<StorageService>(),
            ));
        logger.debug('✅ [DI] ReservationNotificationService registered');

        // Register Reservation Waitlist Service (Phase 15.1.9) - CRITICAL GAP FIX
        sl.registerLazySingleton(() => ReservationWaitlistService(
              atomicClock: sl<AtomicClockService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
              notificationService:
                  sl.isRegistered<ReservationNotificationService>()
                      ? sl<ReservationNotificationService>()
                      : null,
            ));
        logger.debug('✅ [DI] ReservationWaitlistService registered');

        // Phase 10.1: Multi-layered Check-In System Services
        // Register Reservation Proximity Service (no dependencies)
        sl.registerLazySingleton(() => ReservationProximityService());
        logger.debug('✅ [DI] ReservationProximityService registered');

        // Register WiFi Fingerprint Service (no dependencies)
        sl.registerLazySingleton(() => WiFiFingerprintService());
        logger.debug('✅ [DI] WiFiFingerprintService registered');

        // Register Reservation Check-In Service (Phase 10.1: Full knot/quantum/AI2AI integration)
        sl.registerLazySingleton(() => ReservationCheckInService(
              reservationService: sl<ReservationService>(),
              proximityService: sl<ReservationProximityService>(),
              wifiService: sl<WiFiFingerprintService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
                  : null,
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              // Optional AI2AI mesh learning (graceful degradation if not available)
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              // Optional Signal Protocol services (graceful degradation if not available)
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
              ai2aiProtocol: sl.isRegistered<AnonymousCommunicationProtocol>()
                  ? sl<AnonymousCommunicationProtocol>()
                  : null,
              orchestrator: sl.isRegistered<VibeConnectionOrchestrator>()
                  ? sl<VibeConnectionOrchestrator>()
                  : null,
              meshService: sl.isRegistered<AdaptiveMeshNetworkingService>()
                  ? sl<AdaptiveMeshNetworkingService>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationCheckInService registered (Phase 10.1: Full integration)');

        // Register Reservation Calendar Service (Phase 10.2: Calendar integration with full AVRAI integration)
        sl.registerLazySingleton(() => ReservationCalendarService(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
                  : null,
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              // Optional AI2AI mesh learning (graceful degradation if not available)
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              // Optional Signal Protocol services (graceful degradation if not available)
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
              ai2aiProtocol: sl.isRegistered<AnonymousCommunicationProtocol>()
                  ? sl<AnonymousCommunicationProtocol>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationCalendarService registered (Phase 10.2: Full AVRAI integration)');

        // Phase 10.3: Recurring Reservations Service
        sl.registerLazySingleton(() => ReservationRecurrenceService(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
                  : null,
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              // Optional AI2AI services
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
              ai2aiProtocol: sl.isRegistered<AnonymousCommunicationProtocol>()
                  ? sl<AnonymousCommunicationProtocol>()
                  : null,
              // Optional analytics
              analyticsService: sl.isRegistered<ReservationAnalyticsService>()
                  ? sl<ReservationAnalyticsService>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationRecurrenceService registered (Phase 10.3: Full AVRAI integration)');

        // Phase 10.4: Reservation Sharing & Transfer Service
        sl.registerLazySingleton(() => ReservationSharingService(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
                  : null,
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              // Optional AI2AI services
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
              ai2aiProtocol: sl.isRegistered<AnonymousCommunicationProtocol>()
                  ? sl<AnonymousCommunicationProtocol>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationSharingService registered (Phase 10.4: Full AVRAI integration)');

        // Register LLM Service (Google Gemini) with connectivity check
        sl.registerLazySingleton<LLMService>(() => LLMService(
              supabaseClient,
              connectivity: sl<Connectivity>(),
            ));
        logger.debug('✅ [DI] LLM service registered');
      } catch (e) {
        logger.warn(
            '⚠️ [DI] Supabase not initialized, skipping LLM service registration');
      }
    } catch (e, stackTrace) {
      logger.warn('⚠️ [DI] LLM service registration failed (optional): $e');
      logger.debug('Stack trace: $stackTrace');
      // LLM service optional - app can work without it
    }
  } catch (e, stackTrace) {
    logger.error('❌ [DI] Backend initialization failed', error: e);
    logger.debug('Stack trace: $stackTrace');
    // Continue without backend on web if initialization fails
  }

  logger.info('✅ [DI] Dependency injection initialization complete');

  // ===========================
  // Cloud Embeddings (Simplified - No ONNX)
  // ===========================
  // Note: Embeddings are now cloud-only via Supabase Edge Function
  // ONNX infrastructure removed - use Gemini/cloud embeddings instead
  try {
    // Only register if Supabase is initialized
    try {
      final supabaseClient = Supabase.instance.client;
      sl.registerLazySingleton<EmbeddingCloudClient>(
          () => EmbeddingCloudClient(client: supabaseClient));
    } catch (_) {
      logger.warn(
          '⚠️ [DI] Supabase not initialized, skipping EmbeddingCloudClient registration');
    }
  } catch (_) {
    // Embeddings optional - app works without them
  }

  // Blocs (Register last, after all dependencies)
  sl.registerFactory(() => AuthBloc(
        signInUseCase: sl(),
        signUpUseCase: sl(),
        signOutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        updatePasswordUseCase: sl(),
      ));

  sl.registerFactory(() => SpotsBloc(
        getSpotsUseCase: sl(),
        getSpotsFromRespectedListsUseCase: sl(),
        createSpotUseCase: sl(),
        updateSpotUseCase: sl(),
        deleteSpotUseCase: sl(),
      ));

  sl.registerFactory(() => ListsBloc(
        getListsUseCase: sl(),
        createListUseCase: sl(),
        updateListUseCase: sl(),
        deleteListUseCase: sl(),
      ));

  // Phase 19.18: Quantum Group Matching System
  // Section GM.4: Group Matching BLoC
  sl.registerFactory(() => GroupMatchingBloc(
        controller: sl<GroupMatchingController>(),
        formationService: sl<GroupFormationService>(),
        searchRepository: sl.isRegistered<HybridSearchRepository>()
            ? sl<HybridSearchRepository>()
            : null,
      ));

  // Hybrid Search Bloc (Phase 2)
  sl.registerFactory(() => HybridSearchBloc(
        hybridSearchUseCase: sl(),
        cacheService: sl(),
        suggestionsService: sl(),
      ));
}
