import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/models/list.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

/// List Creation Controller
/// 
/// Orchestrates the complete list creation workflow. Coordinates validation,
/// permissions, list creation, spot addition, and optional AI suggestions.
/// 
/// **Responsibilities:**
/// - Validate list data
/// - Check user permissions (via repository)
/// - Create list
/// - Add initial spots (if provided)
/// - Generate AI suggestions (optional, when service available)
/// - Return unified result with errors
/// 
/// **Dependencies:**
/// - `ListsRepository` - Create lists and check permissions
/// - `AtomicClockService` - Mandatory for timestamps (Phase 8.3+)
/// 
/// **Usage:**
/// ```dart
/// final controller = ListCreationController();
/// final result = await controller.createList(
///   data: ListFormData(
///     title: 'My List',
///     description: 'A list of spots',
///     category: 'General',
///     isPublic: true,
///   ),
///   curator: user,
///   initialSpotIds: ['spot1', 'spot2'],
/// );
/// 
/// if (result.isSuccess) {
///   // List created successfully
/// } else {
///   // Handle errors
/// }
/// ```
class ListCreationController
    implements WorkflowController<ListFormData, ListCreationResult> {
  static const String _logName = 'ListCreationController';

  final ListsRepository _listsRepository;
  final AtomicClockService _atomicClock;
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final IntegratedKnotRecommendationEngine? _knotEngine;
  final QuantumMatchingAILearningService? _aiLearningService;

  ListCreationController({
    ListsRepository? listsRepository,
    AtomicClockService? atomicClock,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    CrossEntityCompatibilityService? knotCompatibilityService,
    IntegratedKnotRecommendationEngine? knotEngine,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _listsRepository =
            listsRepository ?? GetIt.instance<ListsRepository>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _locationTimingService = locationTimingService ??
            (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
                ? GetIt.instance<LocationTimingQuantumStateService>()
                : null),
        _quantumEntanglementService = quantumEntanglementService ??
            (GetIt.instance.isRegistered<QuantumEntanglementService>()
                ? GetIt.instance<QuantumEntanglementService>()
                : null),
        _knotCompatibilityService = knotCompatibilityService ??
            (GetIt.instance.isRegistered<CrossEntityCompatibilityService>()
                ? GetIt.instance<CrossEntityCompatibilityService>()
                : null),
        _knotEngine = knotEngine ??
            (GetIt.instance.isRegistered<IntegratedKnotRecommendationEngine>()
                ? GetIt.instance<IntegratedKnotRecommendationEngine>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null);

  /// Create a list
  /// 
  /// Orchestrates the complete list creation workflow:
  /// 1. Validate input
  /// 2. Check user permissions
  /// 3. Create list with atomic timestamps
  /// 4. Add initial spots (if provided)
  /// 5. Generate AI suggestions (optional, when service available)
  /// 6. Return unified result
  /// 
  /// **Parameters:**
  /// - `data`: List form data (title, description, category, etc.)
  /// - `curator`: User creating the list
  /// - `initialSpotIds`: Optional list of spot IDs to add initially
  /// - `generateAISuggestions`: Whether to generate AI suggestions (default: false)
  /// 
  /// **Returns:**
  /// `ListCreationResult` with success/failure and error details
  Future<ListCreationResult> createList({
    required ListFormData data,
    required UnifiedUser curator,
    List<String>? initialSpotIds,
    bool generateAISuggestions = false,
  }) async {
    try {
      developer.log(
        'Starting list creation: title=${data.title}, curator=${curator.id}',
        name: _logName,
      );

      // Step 1: Validate input
      final validationResult = validate(data);
      if (!validationResult.isValid) {
        return ListCreationResult.failure(
          error: validationResult.allErrors.join(', '),
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Step 2: Check user permissions
      final canCreate = await _listsRepository.canUserCreateList(curator.id);
      if (!canCreate) {
        return ListCreationResult.failure(
          error: 'User does not have permission to create lists',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      // Step 3: Create list with atomic timestamps
      final atomicTimestamp = await _atomicClock.getAtomicTimestamp();
      final now = atomicTimestamp.serverTime;
      final list = SpotList(
        id: '', // Will be set by repository
        title: data.title,
        description: data.description,
        category: data.category,
        isPublic: data.isPublic,
        spots: const [],
        spotIds: initialSpotIds ?? const [],
        curatorId: curator.id,
        tags: data.tags ?? const [],
        createdAt: now,
        updatedAt: now,
      );

      final createdList = await _listsRepository.createList(list);

      developer.log(
        'List created successfully: id=${createdList.id}, title=${createdList.title}',
        name: _logName,
      );

      // Step 4: Initial spots are included in list creation (spotIds field)
      // Note: Spots are referenced by ID, actual Spot objects are loaded separately
      // If additional spot validation or linking is needed, it can be done via
      // ListsRepository.updateList() after creation
      if (initialSpotIds != null && initialSpotIds.isNotEmpty) {
        developer.log(
          'List created with ${initialSpotIds.length} initial spot IDs',
          name: _logName,
        );
      }

      // Step 5: AVRAI Core System Integration (optional, graceful degradation)
      
      // 5.1: Create 4D quantum states for spots in list (if spots provided)
      if (_locationTimingService != null && initialSpotIds != null && initialSpotIds.isNotEmpty) {
        try {
          developer.log(
            '🌐 Creating 4D quantum states for ${initialSpotIds.length} spots in list',
            name: _logName,
          );
          
          // Note: Full implementation would load Spot objects and create quantum states
          // This is a placeholder for future 4D quantum state creation for list spots
          developer.log(
            'ℹ️ 4D quantum state creation for spots deferred (requires Spot objects)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ 4D quantum state creation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - quantum state creation is optional
        }
      }
      
      // 5.2: Calculate quantum compatibility (user ↔ spots)
      if (_quantumEntanglementService != null && initialSpotIds != null && initialSpotIds.isNotEmpty) {
        try {
          developer.log(
            '🔬 Quantum compatibility calculation deferred (requires Spot objects and user profile)',
            name: _logName,
          );
          // Note: Full implementation would use QuantumMatchingController
        } catch (e) {
          developer.log(
            '⚠️ Quantum compatibility calculation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - quantum compatibility is optional
        }
      }
      
      // 5.3: Calculate knot compatibility for recommendations
      if (_knotCompatibilityService != null) {
        try {
          developer.log(
            '🎯 Knot compatibility service available (compatibility calculation deferred)',
            name: _logName,
          );
          // Note: Full implementation would calculate knot compatibility for recommendations
        } catch (e) {
          developer.log(
            '⚠️ Knot compatibility calculation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot compatibility is optional
        }
      }
      
      // 5.4: Use knot-based recommendations (if available)
      if (_knotEngine != null && generateAISuggestions) {
        try {
          developer.log(
            '🧵 Using knot-based recommendation engine for AI suggestions',
            name: _logName,
          );
          // Note: Full implementation would use IntegratedKnotRecommendationEngine
          // This is a placeholder for future knot-based list recommendations
        } catch (e) {
          developer.log(
            '⚠️ Knot-based recommendations failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot recommendations are optional
        }
      }
      
      // 5.5: Learn from list creation via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during list creation
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }
      
      // Step 6: Generate AI suggestions (optional, when service available)
      // TODO(Phase 8.12): Implement AI list generation when AIListGeneratorService is available
      if (generateAISuggestions) {
        developer.log(
          'AI suggestions requested but not yet implemented',
          name: _logName,
        );
        // For now, AI suggestions are not implemented
        // This can be added when AIListGeneratorService is available
      }

      return ListCreationResult.success(
        list: createdList,
        spotsAdded: initialSpotIds?.length ?? 0,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error creating list: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return ListCreationResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<ListCreationResult> execute(ListFormData input) async {
    if (input.curator == null) {
      return ListCreationResult.failure(
        error: 'Curator is required for list creation',
        errorCode: 'MISSING_CURATOR',
      );
    }
    return createList(
      data: input,
      curator: input.curator!,
      initialSpotIds: input.initialSpotIds,
      generateAISuggestions: input.generateAISuggestions,
    );
  }

  @override
  ValidationResult validate(ListFormData input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    // Validate title
    if (input.title.trim().isEmpty) {
      errors['title'] = 'Title is required';
    } else if (input.title.trim().length < 3) {
      errors['title'] = 'Title must be at least 3 characters';
    }

    // Validate description
    if (input.description.trim().isEmpty) {
      errors['description'] = 'Description is required';
    }

    if (errors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: errors,
        generalErrors: generalErrors,
      );
    }

    return ValidationResult.valid();
  }

  @override
  Future<void> rollback(ListCreationResult result) async {
    // Rollback list creation (delete the list)
    if (result.success && result.list != null) {
      try {
        await _listsRepository.deleteList(result.list!.id);
        developer.log(
          'Rolled back list creation: id=${result.list!.id}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Error rolling back list creation: $e',
          name: _logName,
          error: e,
        );
        // Don't rethrow - rollback failures should be logged but not block
      }
    }
  }
}

/// List Form Data
/// 
/// Input data for list creation
class ListFormData {
  final String title;
  final String description;
  final String? category;
  final bool isPublic;
  final List<String>? tags;
  final UnifiedUser? curator;
  final List<String>? initialSpotIds;
  final bool generateAISuggestions;

  ListFormData({
    required this.title,
    required this.description,
    this.category,
    this.isPublic = true,
    this.tags,
    this.curator,
    this.initialSpotIds,
    this.generateAISuggestions = false,
  });
}

/// List Creation Result
/// 
/// Unified result for list creation operations
class ListCreationResult extends ControllerResult {
  final SpotList? list;
  final int? spotsAdded;
  final String? warning;

  const ListCreationResult._({
    required super.success,
    required super.error,
    required super.errorCode,
    this.list,
    this.spotsAdded,
    this.warning,
  });

  factory ListCreationResult.success({
    required SpotList list,
    int spotsAdded = 0,
    String? warning,
  }) {
    return ListCreationResult._(
      success: true,
      error: null,
      errorCode: null,
      list: list,
      spotsAdded: spotsAdded,
      warning: warning,
    );
  }

  factory ListCreationResult.failure({
    required String error,
    required String errorCode,
  }) {
    return ListCreationResult._(
      success: false,
      error: error,
      errorCode: errorCode,
      list: null,
      spotsAdded: null,
      warning: null,
    );
  }
}

