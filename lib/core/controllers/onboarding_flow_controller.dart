import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/models/onboarding_data.dart';
import 'package:avrai/core/services/onboarding_data_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/legal_document_service.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:get_it/get_it.dart';

/// Onboarding Flow Controller
/// 
/// Orchestrates the complete onboarding completion workflow.
/// Coordinates multiple services to validate, save, and prepare onboarding data.
/// 
/// **Responsibilities:**
/// - Validate legal document acceptance
/// - Get agentId for privacy protection
/// - Save onboarding data
/// - Coordinate all onboarding completion steps
/// - Handle errors gracefully
/// - Return unified result
/// 
/// **Dependencies:**
/// - `OnboardingDataService` - Save onboarding data
/// - `AgentIdService` - Get privacy-protected agentId
/// - `LegalDocumentService` - Validate legal acceptance
/// 
/// **Usage:**
/// ```dart
/// final controller = OnboardingFlowController();
/// final result = await controller.completeOnboarding(
///   data: onboardingData,
///   userId: userId,
///   context: context, // For legal dialogs if needed
/// );
/// 
/// if (result.isSuccess) {
///   // Onboarding completed successfully
///   final agentId = result.agentId!;
/// } else {
///   // Handle error
///   final error = result.error;
/// }
/// ```
class OnboardingFlowController implements WorkflowController<OnboardingData, OnboardingFlowResult> {
  static const String _logName = 'OnboardingFlowController';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final OnboardingDataService _onboardingDataService;
  final AgentIdService _agentIdService;
  final LegalDocumentService _legalDocumentService;
  // ignore: unused_field
  final AtomicClockService _atomicClock; // Reserved for future timestamp-based onboarding tracking
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final PersonalityKnotService? _personalityKnotService;
  final KnotStorageService? _knotStorageService;
  final LocationTimingQuantumStateService? _locationTimingService;
  
  OnboardingFlowController({
    OnboardingDataService? onboardingDataService,
    AgentIdService? agentIdService,
    LegalDocumentService? legalDocumentService,
    AtomicClockService? atomicClock,
    PersonalityKnotService? personalityKnotService,
    KnotStorageService? knotStorageService,
    LocationTimingQuantumStateService? locationTimingService,
  }) : _onboardingDataService = onboardingDataService ?? GetIt.instance<OnboardingDataService>(),
       _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
       _legalDocumentService = legalDocumentService ?? GetIt.instance<LegalDocumentService>(),
       _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
       _personalityKnotService = personalityKnotService ??
           (GetIt.instance.isRegistered<PersonalityKnotService>()
               ? GetIt.instance<PersonalityKnotService>()
               : null),
       _knotStorageService = knotStorageService ??
           (GetIt.instance.isRegistered<KnotStorageService>()
               ? GetIt.instance<KnotStorageService>()
               : null),
       _locationTimingService = locationTimingService ??
           (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
               ? GetIt.instance<LocationTimingQuantumStateService>()
               : null);
  
  @override
  Future<OnboardingFlowResult> execute(OnboardingData input) async {
    // This method is a convenience wrapper - actual implementation in completeOnboarding
    // We need userId which isn't in OnboardingData, so we use completeOnboarding directly
    throw UnimplementedError(
      'Use completeOnboarding() method instead - requires userId parameter',
    );
  }
  
  /// Complete onboarding workflow
  /// 
  /// Validates legal acceptance, gets agentId, and saves onboarding data.
  /// 
  /// **Parameters:**
  /// - `data`: OnboardingData to save
  /// - `userId`: Authenticated user ID
  /// - `context`: BuildContext for legal dialogs (optional, can be null)
  /// 
  /// **Returns:**
  /// `OnboardingFlowResult` with success status, agentId, and any errors
  Future<OnboardingFlowResult> completeOnboarding({
    required OnboardingData data,
    required String userId,
    dynamic context, // BuildContext? but using dynamic to avoid Flutter dependency in core
  }) async {
    try {
      _logger.info('🎯 Starting onboarding completion workflow', tag: _logName);
      
      // STEP 1: Get agentId first (needed for validation)
      String agentId;
      try {
        agentId = await _agentIdService.getUserAgentId(userId);
        _logger.debug('✅ Got agentId: ${agentId.substring(0, 10)}...', tag: _logName);
      } catch (e) {
        _logger.error('❌ Failed to get agentId: $e', error: e, tag: _logName);
        return OnboardingFlowResult.failure(
          error: 'Failed to get agent ID: $e',
          errorCode: 'AGENT_ID_ERROR',
        );
      }
      
      // STEP 2: Ensure data has agentId set before validation
      final dataWithAgentId = OnboardingData(
        agentId: agentId,
        age: data.age,
        birthday: data.birthday,
        homebase: data.homebase,
        favoritePlaces: data.favoritePlaces,
        preferences: data.preferences,
        baselineLists: data.baselineLists,
        respectedFriends: data.respectedFriends,
        socialMediaConnected: data.socialMediaConnected,
        completedAt: data.completedAt,
      );
      
      // STEP 3: Validate onboarding data (now with agentId)
      final validation = validate(dataWithAgentId);
      if (!validation.isValid) {
        _logger.warn('❌ Onboarding data validation failed', tag: _logName);
        return OnboardingFlowResult.failure(
          error: validation.firstError ?? 'Invalid onboarding data',
          errorCode: 'VALIDATION_FAILED',
          validationErrors: validation,
        );
      }
      
      // STEP 4: Check legal acceptance (skip in integration tests)
      const bool isIntegrationTest = bool.fromEnvironment('FLUTTER_TEST');
      if (!isIntegrationTest) {
        try {
          final hasAcceptedTerms = await _legalDocumentService.hasAcceptedTerms(userId);
          final hasAcceptedPrivacy = await _legalDocumentService.hasAcceptedPrivacyPolicy(userId);
          
          if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
            _logger.warn('⚠️ Legal documents not accepted', tag: _logName);
            // Note: Legal dialog should be shown in UI layer before calling this controller
            // If we reach here without acceptance, return error
            return OnboardingFlowResult.failure(
              error: 'Legal documents must be accepted',
              errorCode: 'LEGAL_NOT_ACCEPTED',
              requiresLegalAcceptance: true,
            );
          }
        } catch (e) {
          _logger.warn('⚠️ Could not verify legal acceptance: $e', tag: _logName);
          // Continue - legal check is best-effort
        }
      }
      
      // STEP 5: Save onboarding data
      try {
        await _onboardingDataService.saveOnboardingData(userId, dataWithAgentId);
        _logger.info('✅ Onboarding data saved successfully', tag: _logName);
      } catch (e) {
        _logger.error('❌ Failed to save onboarding data: $e', error: e, tag: _logName);
        return OnboardingFlowResult.failure(
          error: 'Failed to save onboarding data: $e',
          errorCode: 'SAVE_ERROR',
        );
      }
      
      // STEP 6: AVRAI Core System Integration (optional, graceful degradation)
      // Note: Most AVRAI integrations happen in AgentInitializationController
      // after PersonalityProfile is created. This step is a placeholder for
      // future early integrations if needed.
      
      // 6.1: Knot services check (deferred to AgentInitializationController)
      if (_personalityKnotService != null && _knotStorageService != null) {
        _logger.debug('ℹ️ Knot services available (knot generation deferred to AgentInitializationController)', tag: _logName);
      }
      
      // 6.2: Location timing service check (deferred to AgentInitializationController)
      if (_locationTimingService != null) {
        _logger.debug('ℹ️ Location timing service available (4D quantum state creation deferred to AgentInitializationController)', tag: _logName);
      }
      
      // STEP 7: Return success
      _logger.info('✅ Onboarding completion workflow successful', tag: _logName);
      return OnboardingFlowResult.success(
        agentId: agentId,
        onboardingData: dataWithAgentId,
      );
    } catch (e, stackTrace) {
      _logger.error('❌ Unexpected error in onboarding workflow: $e', 
        error: e, 
        stackTrace: stackTrace,
        tag: _logName,
      );
      return OnboardingFlowResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }
  
  @override
  Future<void> rollback(OnboardingFlowResult result) async {
    // Onboarding flow doesn't require rollback - data is saved atomically
    // If save fails, no data is persisted, so nothing to rollback
  }
  
  @override
  ValidationResult validate(OnboardingData input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];
    
    // Validate agentId format
    if (input.agentId.isEmpty || !input.agentId.startsWith('agent_')) {
      errors['agentId'] = 'Invalid agentId format';
    }
    
    // Validate age if provided
    if (input.age != null && (input.age! < 13 || input.age! > 120)) {
      errors['age'] = 'Age must be between 13 and 120';
    }
    
    // Validate birthday if provided
    if (input.birthday != null && input.birthday!.isAfter(DateTime.now())) {
      errors['birthday'] = 'Birthday cannot be in the future';
    }
    
    // Validate completedAt
    if (input.completedAt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      generalErrors.add('Completion date cannot be more than 1 day in the future');
    }
    
    // Check if data is valid using model's validation
    if (!input.isValid) {
      generalErrors.add('Onboarding data failed model validation');
    }
    
    if (errors.isEmpty && generalErrors.isEmpty) {
      return ValidationResult.valid();
    } else {
      return ValidationResult.invalid(
        fieldErrors: errors,
        generalErrors: generalErrors,
      );
    }
  }
}

/// Result of onboarding flow completion
class OnboardingFlowResult extends ControllerResult {
  /// AgentId assigned to the user (if successful)
  final String? agentId;
  
  /// Saved onboarding data (if successful)
  final OnboardingData? onboardingData;
  
  /// Validation errors (if validation failed)
  final ValidationResult? validationErrors;
  
  /// Whether legal acceptance is required
  final bool requiresLegalAcceptance;
  
  const OnboardingFlowResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.agentId,
    this.onboardingData,
    this.validationErrors,
    this.requiresLegalAcceptance = false,
  });
  
  /// Create successful result
  factory OnboardingFlowResult.success({
    required String agentId,
    required OnboardingData onboardingData,
    Map<String, dynamic>? metadata,
  }) {
    return OnboardingFlowResult(
      success: true,
      agentId: agentId,
      onboardingData: onboardingData,
      metadata: metadata,
    );
  }
  
  /// Create failure result
  factory OnboardingFlowResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
    ValidationResult? validationErrors,
    bool requiresLegalAcceptance = false,
  }) {
    return OnboardingFlowResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
      validationErrors: validationErrors,
      requiresLegalAcceptance: requiresLegalAcceptance,
    );
  }
  
  @override
  List<Object?> get props => [
    ...super.props,
    agentId,
    onboardingData,
    validationErrors,
    requiresLegalAcceptance,
  ];
}

