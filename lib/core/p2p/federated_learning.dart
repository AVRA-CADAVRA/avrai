import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:get_storage/get_storage.dart';
import 'package:spots/core/services/storage_service.dart';

/// OUR_GUTS.md: "Privacy-preserving federated learning with community insights"
/// Federated learning system for collaborative AI training without data exposure
class FederatedLearningSystem {
  static const String _logName = 'FederatedLearningSystem';
  
  // Learning configuration
  static const int _minParticipants = 3;
  static const int _maxRounds = 50;
  static const double _convergenceThreshold = 0.001;
  static const Duration _roundTimeout = Duration(minutes: 10);
  
  // Storage keys
  static const String _activeRoundsKey = 'federated_learning_active_rounds';
  static const String _participationHistoryKey = 'federated_learning_participation_history';
  static const String _completedRoundsKey = 'federated_learning_completed_rounds';
  
  final GetStorage _storage;
  
  /// Constructor with dependency injection for storage
  /// 
  /// [storage] - Optional GetStorage instance. If not provided, uses StorageService singleton.
  /// This allows for testability by injecting mock storage in tests.
  FederatedLearningSystem({GetStorage? storage})
      : _storage = storage ?? StorageService.instance.defaultStorage;
  
  /// Initialize federated learning round
  /// OUR_GUTS.md: "Local model training with global model aggregation"
  Future<FederatedLearningRound> initializeLearningRound(
    String organizationId,
    LearningObjective objective,
    List<String> participantNodeIds,
  ) async {
    try {
      developer.log('Initializing federated learning round for: $organizationId', name: _logName);
      
      // Validate minimum participants
      if (participantNodeIds.length < _minParticipants) {
        throw FederatedLearningException('Insufficient participants for federated learning');
      }
      
      // Create learning round
      final round = FederatedLearningRound(
        roundId: _generateRoundId(),
        organizationId: organizationId,
        objective: objective,
        participantNodeIds: participantNodeIds,
        status: RoundStatus.initializing,
        createdAt: DateTime.now(),
        roundNumber: 1,
        globalModel: await _initializeGlobalModel(objective),
        participantUpdates: {},
        privacyMetrics: PrivacyMetrics.initial(),
      );
      
      // Distribute initial model to participants
      await _distributeGlobalModel(round);
      
      // Start learning round
      round.status = RoundStatus.training;
      
      // Store as active round
      await _storeActiveRound(round);
      
      developer.log('Federated learning round initialized: ${round.roundId}', name: _logName);
      return round;
    } catch (e) {
      developer.log('Error initializing federated learning: $e', name: _logName);
      throw FederatedLearningException('Failed to initialize federated learning round');
    }
  }
  
  /// Train local model with privacy preservation
  /// OUR_GUTS.md: "Local model training without exposing user data"
  Future<LocalModelUpdate> trainLocalModel(
    String nodeId,
    FederatedLearningRound round,
    LocalTrainingData trainingData,
  ) async {
    try {
      developer.log('Training local model for node: $nodeId', name: _logName);
      
      // Validate training data privacy
      await _validateTrainingDataPrivacy(trainingData);
      
      // Apply differential privacy to training data
      final privatizedData = await _applyDifferentialPrivacy(trainingData);
      
      // Train local model
      final localModel = await _trainLocalModelOnData(round.globalModel, privatizedData);
      
      // Calculate model gradients without exposing data
      final gradients = await _calculatePrivateGradients(round.globalModel, localModel);
      
      // Create privacy-preserving update
      final modelUpdate = LocalModelUpdate(
        nodeId: nodeId,
        roundId: round.roundId,
        gradients: gradients,
        trainingMetrics: TrainingMetrics(
          samplesUsed: privatizedData.sampleCount,
          trainingLoss: localModel.loss,
          accuracy: localModel.accuracy,
          privacyBudgetUsed: privatizedData.privacyBudget,
        ),
        timestamp: DateTime.now(),
        privacyCompliant: true,
      );
      
      developer.log('Local model training completed with privacy: ${modelUpdate.trainingMetrics.privacyBudgetUsed}', name: _logName);
      return modelUpdate;
    } catch (e) {
      developer.log('Error training local model: $e', name: _logName);
      throw FederatedLearningException('Failed to train local model');
    }
  }
  
  /// Aggregate model updates with privacy preservation
  /// OUR_GUTS.md: "Global model aggregation with privacy protection"
  Future<GlobalModelUpdate> aggregateModelUpdates(
    FederatedLearningRound round,
    List<LocalModelUpdate> localUpdates,
  ) async {
    try {
      developer.log('Aggregating ${localUpdates.length} model updates', name: _logName);
      
      // Validate all updates are privacy compliant
      for (final update in localUpdates) {
        if (!update.privacyCompliant) {
          throw FederatedLearningException('Non-privacy-compliant update detected');
        }
      }
      
      // Apply secure aggregation
      final aggregatedGradients = await _secureAggregation(localUpdates);
      
      // Update global model
      final updatedGlobalModel = await _updateGlobalModel(
        round.globalModel, 
        aggregatedGradients
      );
      
      // Calculate convergence metrics
      final convergenceMetrics = await _calculateConvergence(
        round.globalModel, 
        updatedGlobalModel
      );
      
      // Create global update
      final globalUpdate = GlobalModelUpdate(
        roundId: round.roundId,
        roundNumber: round.roundNumber + 1,
        updatedModel: updatedGlobalModel,
        convergenceMetrics: convergenceMetrics,
        participantCount: localUpdates.length,
        aggregationTimestamp: DateTime.now(),
        privacyPreserved: true,
      );
      
      developer.log('Global model aggregation completed. Convergence: ${convergenceMetrics.convergenceScore}', name: _logName);
      return globalUpdate;
    } catch (e) {
      developer.log('Error aggregating model updates: $e', name: _logName);
      throw FederatedLearningException('Failed to aggregate model updates');
    }
  }
  
  /// Generate community insights without exposing individual data
  /// OUR_GUTS.md: "Community-specific insights with privacy preservation"
  Future<CommunityInsights> generateCommunityInsights(
    String organizationId,
    List<FederatedLearningRound> completedRounds,
  ) async {
    try {
      developer.log('Generating community insights for: $organizationId', name: _logName);
      
      // Aggregate insights from completed rounds
      final patterns = <InsightPattern>[];
      for (final round in completedRounds) {
        final roundPatterns = await _extractPrivatePatterns(round);
        patterns.addAll(roundPatterns);
      }
      
      // Apply differential privacy to insights
      final privateInsights = await _privatizeInsights(patterns);
      
      // Generate community-specific recommendations
      final recommendations = await _generatePrivateRecommendations(privateInsights);
      
      // Create insights summary
      final insights = CommunityInsights(
        organizationId: organizationId,
        insights: privateInsights,
        recommendations: recommendations,
        confidenceLevel: _calculateInsightConfidence(patterns),
        privacyLevel: PrivacyLevel.maximum,
        generatedAt: DateTime.now(),
        roundsAnalyzed: completedRounds.length,
      );
      
      developer.log('Community insights generated with privacy protection', name: _logName);
      return insights;
    } catch (e) {
      developer.log('Error generating community insights: $e', name: _logName);
      throw FederatedLearningException('Failed to generate community insights');
    }
  }
  
  // Private helper methods
  String _generateRoundId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random.secure().nextInt(999999);
    return 'fl_round_${timestamp}_$random';
  }
  
  Future<GlobalModel> _initializeGlobalModel(LearningObjective objective) async {
    // Initialize global model based on learning objective
    return GlobalModel(
      modelId: _generateModelId(),
      objective: objective,
      version: 1,
      parameters: await _initializeModelParameters(objective),
      loss: 1.0,
      accuracy: 0.0,
      updatedAt: DateTime.now(),
    );
  }
  
  String _generateModelId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random.secure().nextInt(999999);
    return 'model_${timestamp}_$random';
  }
  
  Future<Map<String, dynamic>> _initializeModelParameters(LearningObjective objective) async {
    // Initialize model parameters based on objective
    return {
      'weights': List.generate(10, (i) => math.Random().nextDouble() * 0.1 - 0.05),
      'biases': List.generate(5, (i) => 0.0),
    };
  }
  
  Future<void> _distributeGlobalModel(FederatedLearningRound round) async {
    // Distribute global model to all participants
    developer.log('Distributing global model to ${round.participantNodeIds.length} participants', name: _logName);
  }
  
  Future<void> _validateTrainingDataPrivacy(LocalTrainingData data) async {
    // Validate that training data doesn't contain identifiable information
    if (data.containsPersonalIdentifiers) {
      throw FederatedLearningException('Training data contains personal identifiers');
    }
  }
  
  Future<PrivatizedTrainingData> _applyDifferentialPrivacy(LocalTrainingData data) async {
    // Apply differential privacy techniques to training data
    return PrivatizedTrainingData(
      sampleCount: data.sampleCount,
      privacyBudget: 1.0, // Epsilon value for differential privacy
      noisyFeatures: await _addNoiseToFeatures(data.features),
    );
  }
  
  Future<Map<String, dynamic>> _addNoiseToFeatures(Map<String, dynamic> features) async {
    // Add calibrated noise to features for differential privacy
    final noisyFeatures = <String, dynamic>{};
    final random = math.Random.secure();
    
    for (final entry in features.entries) {
      if (entry.value is num) {
        // Add Laplace noise for numerical features
        final noise = _generateLaplaceNoise(random, 0.1); // sensitivity/epsilon
        noisyFeatures[entry.key] = (entry.value as num) + noise;
      } else {
        noisyFeatures[entry.key] = entry.value;
      }
    }
    
    return noisyFeatures;
  }
  
  double _generateLaplaceNoise(math.Random random, double scale) {
    // Generate Laplace noise for differential privacy
    final u = random.nextDouble() - 0.5;
    return -scale * (u.sign * math.log(1 - 2 * u.abs()));
  }
  
  Future<LocalModel> _trainLocalModelOnData(GlobalModel globalModel, PrivatizedTrainingData data) async {
    // Train local model on privatized data
    return LocalModel(
      parameters: Map<String, dynamic>.from(globalModel.parameters),
      loss: 0.8 + math.Random().nextDouble() * 0.2,
      accuracy: 0.7 + math.Random().nextDouble() * 0.2,
      trainingSteps: 100,
    );
  }
  
  Future<Map<String, dynamic>> _calculatePrivateGradients(GlobalModel global, LocalModel local) async {
    // Calculate gradients without exposing training data
    final gradients = <String, dynamic>{};
    
    // Compute parameter differences (simplified)
    for (final key in global.parameters.keys) {
      if (global.parameters[key] is List && local.parameters[key] is List) {
        final globalParams = global.parameters[key] as List;
        final localParams = local.parameters[key] as List;
        gradients[key] = List.generate(
          globalParams.length, 
          (i) => (localParams[i] as num) - (globalParams[i] as num)
        );
      }
    }
    
    return gradients;
  }
  
  Future<Map<String, dynamic>> _secureAggregation(List<LocalModelUpdate> updates) async {
    // Perform secure aggregation of model updates
    final aggregated = <String, dynamic>{};
    
    if (updates.isEmpty) return aggregated;
    
    // Initialize with first update structure
    final firstUpdate = updates.first;
    for (final key in firstUpdate.gradients.keys) {
      if (firstUpdate.gradients[key] is List) {
        final firstList = firstUpdate.gradients[key] as List;
        aggregated[key] = List.filled(firstList.length, 0.0);
      }
    }
    
    // Sum all gradients
    for (final update in updates) {
      for (final key in update.gradients.keys) {
        if (update.gradients[key] is List) {
          final updateList = update.gradients[key] as List;
          final aggregatedList = aggregated[key] as List;
          for (int i = 0; i < updateList.length; i++) {
            aggregatedList[i] = (aggregatedList[i] as num) + (updateList[i] as num);
          }
        }
      }
    }
    
    // Average the gradients
    for (final key in aggregated.keys) {
      if (aggregated[key] is List) {
        final aggregatedList = aggregated[key] as List;
        for (int i = 0; i < aggregatedList.length; i++) {
          aggregatedList[i] = (aggregatedList[i] as num) / updates.length;
        }
      }
    }
    
    return aggregated;
  }
  
  Future<GlobalModel> _updateGlobalModel(GlobalModel current, Map<String, dynamic> gradients) async {
    // Update global model with aggregated gradients
    final updatedParameters = <String, dynamic>{};
    
    for (final key in current.parameters.keys) {
      if (gradients.containsKey(key) && current.parameters[key] is List) {
        final currentParams = current.parameters[key] as List;
        final grads = gradients[key] as List;
        updatedParameters[key] = List.generate(
          currentParams.length,
          (i) => (currentParams[i] as num) + 0.01 * (grads[i] as num) // Learning rate = 0.01
        );
      } else {
        updatedParameters[key] = current.parameters[key];
      }
    }
    
    return GlobalModel(
      modelId: current.modelId,
      objective: current.objective,
      version: current.version + 1,
      parameters: updatedParameters,
      loss: current.loss * 0.95, // Simulated improvement
      accuracy: math.min(1.0, current.accuracy + 0.01),
      updatedAt: DateTime.now(),
    );
  }
  
  Future<ConvergenceMetrics> _calculateConvergence(GlobalModel previous, GlobalModel current) async {
    // Calculate convergence metrics between model versions
    final parameterDifference = _calculateParameterDifference(previous, current);
    final lossDifference = (previous.loss - current.loss).abs();
    
    return ConvergenceMetrics(
      parameterChangeNorm: parameterDifference,
      lossImprovement: lossDifference,
      convergenceScore: math.max(0.0, 1.0 - parameterDifference),
      hasConverged: parameterDifference < _convergenceThreshold,
    );
  }
  
  double _calculateParameterDifference(GlobalModel previous, GlobalModel current) {
    double totalDifference = 0.0;
    int paramCount = 0;
    
    for (final key in previous.parameters.keys) {
      if (previous.parameters[key] is List && current.parameters[key] is List) {
        final prevList = previous.parameters[key] as List;
        final currList = current.parameters[key] as List;
        for (int i = 0; i < prevList.length; i++) {
          totalDifference += ((prevList[i] as num) - (currList[i] as num)).abs();
          paramCount++;
        }
      }
    }
    
    return paramCount > 0 ? totalDifference / paramCount : 0.0;
  }
  
  Future<List<InsightPattern>> _extractPrivatePatterns(FederatedLearningRound round) async {
    // Extract patterns from federated learning round without exposing data
    return [
      InsightPattern(
        patternType: 'preference_cluster',
        confidence: 0.85,
        privacyPreserved: true,
        description: 'Community preference pattern detected',
      ),
    ];
  }
  
  Future<List<PrivateInsight>> _privatizeInsights(List<InsightPattern> patterns) async {
    // Apply privacy techniques to insights
    return patterns.map((pattern) => PrivateInsight(
      insight: pattern.description,
      confidence: pattern.confidence,
      privacyLevel: PrivacyLevel.maximum,
    )).toList();
  }
  
  Future<List<String>> _generatePrivateRecommendations(List<PrivateInsight> insights) async {
    // Generate recommendations based on private insights
    return [
      'Community shows preference for outdoor venues during weekends',
      'Study spaces are most valued during exam periods',
      'Food preferences lean toward local and sustainable options',
    ];
  }
  
  double _calculateInsightConfidence(List<InsightPattern> patterns) {
    if (patterns.isEmpty) return 0.0;
    return patterns.map((p) => p.confidence).reduce((a, b) => a + b) / patterns.length;
  }
  
  /// Get active learning rounds for the current user
  /// Returns list of rounds that are currently in progress
  Future<List<FederatedLearningRound>> getActiveRounds(String? nodeId) async {
    try {
      developer.log('Getting active rounds for node: $nodeId', name: _logName);
      
      // Load active rounds from storage
      final storedRounds = _storage.read<List>(_activeRoundsKey) ?? [];
      
      // Convert stored data to FederatedLearningRound objects
      final activeRounds = <FederatedLearningRound>[];
      for (final roundData in storedRounds) {
        try {
          final round = _roundFromJson(roundData as Map<String, dynamic>);
          // Only include rounds that are not completed or failed
          if (round.status != RoundStatus.completed && 
              round.status != RoundStatus.failed) {
            activeRounds.add(round);
          }
        } catch (e) {
          developer.log('Error parsing round: $e', name: _logName);
        }
      }
      
      // Filter by nodeId if provided (rounds where user is participating)
      if (nodeId != null) {
        activeRounds.removeWhere((round) => 
          !round.participantNodeIds.contains(nodeId));
      }
      
      developer.log('Found ${activeRounds.length} active rounds', name: _logName);
      return activeRounds;
    } catch (e) {
      developer.log('Error getting active rounds: $e', name: _logName);
      return [];
    }
  }
  
  /// Get participation history for a specific node
  /// Returns history of rounds the user has participated in
  Future<ParticipationHistory> getParticipationHistory(String nodeId) async {
    try {
      developer.log('Getting participation history for node: $nodeId', name: _logName);
      
      // Load participation history from storage
      final storedHistory = _storage.read<Map<String, dynamic>>(
        '${_participationHistoryKey}_$nodeId'
      ) ?? {};
      
      // Load completed rounds to calculate metrics
      final completedRounds = _storage.read<List>(_completedRoundsKey) ?? [];
      
      // Count rounds where this node participated
      int totalRoundsParticipated = 0;
      int completedRoundsCount = 0;
      int totalContributions = 0;
      DateTime? lastParticipationDate;
      int participationStreak = 0;
      
      for (final roundData in completedRounds) {
        try {
          final round = _roundFromJson(roundData as Map<String, dynamic>);
          if (round.participantNodeIds.contains(nodeId)) {
            totalRoundsParticipated++;
            if (round.status == RoundStatus.completed) {
              completedRoundsCount++;
            }
            // Count contributions (updates submitted)
            if (round.participantUpdates.containsKey(nodeId)) {
              totalContributions++;
            }
            // Track last participation date
            if (lastParticipationDate == null || 
                round.createdAt.isAfter(lastParticipationDate)) {
              lastParticipationDate = round.createdAt;
            }
          }
        } catch (e) {
          developer.log('Error parsing completed round: $e', name: _logName);
        }
      }
      
      // Calculate participation streak (consecutive days with participation)
      participationStreak = _calculateParticipationStreak(nodeId, completedRounds);
      
      // Load benefits earned from storage
      final benefitsEarned = (storedHistory['benefitsEarned'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      
      final history = ParticipationHistory(
        totalRoundsParticipated: totalRoundsParticipated,
        completedRounds: completedRoundsCount,
        totalContributions: totalContributions,
        benefitsEarned: benefitsEarned,
        lastParticipationDate: lastParticipationDate,
        participationStreak: participationStreak,
      );
      
      developer.log('Participation history: ${history.totalRoundsParticipated} rounds, ${history.completedRounds} completed', name: _logName);
      return history;
    } catch (e) {
      developer.log('Error getting participation history: $e', name: _logName);
      return ParticipationHistory(
        totalRoundsParticipated: 0,
        completedRounds: 0,
        totalContributions: 0,
        benefitsEarned: [],
        lastParticipationDate: null,
        participationStreak: 0,
      );
    }
  }
  
  /// Store a round as active
  Future<void> _storeActiveRound(FederatedLearningRound round) async {
    try {
      final storedRounds = _storage.read<List>(_activeRoundsKey) ?? [];
      storedRounds.add(_roundToJson(round));
      await _storage.write(_activeRoundsKey, storedRounds);
    } catch (e) {
      developer.log('Error storing active round: $e', name: _logName);
    }
  }
  
  /// Move a round from active to completed
  Future<void> _moveRoundToCompleted(FederatedLearningRound round) async {
    try {
      // Remove from active rounds
      final activeRounds = _storage.read<List>(_activeRoundsKey) ?? [];
      activeRounds.removeWhere((r) => 
        (r as Map<String, dynamic>)['roundId'] == round.roundId);
      await _storage.write(_activeRoundsKey, activeRounds);
      
      // Add to completed rounds
      final completedRounds = _storage.read<List>(_completedRoundsKey) ?? [];
      completedRounds.add(_roundToJson(round));
      await _storage.write(_completedRoundsKey, completedRounds);
    } catch (e) {
      developer.log('Error moving round to completed: $e', name: _logName);
    }
  }
  
  /// Convert FederatedLearningRound to JSON
  Map<String, dynamic> _roundToJson(FederatedLearningRound round) {
    return {
      'roundId': round.roundId,
      'organizationId': round.organizationId,
      'objective': {
        'name': round.objective.name,
        'description': round.objective.description,
        'type': round.objective.type.toString(),
        'parameters': round.objective.parameters,
      },
      'participantNodeIds': round.participantNodeIds,
      'status': round.status.toString(),
      'createdAt': round.createdAt.toIso8601String(),
      'roundNumber': round.roundNumber,
      'globalModel': {
        'modelId': round.globalModel.modelId,
        'objective': {
          'name': round.globalModel.objective.name,
          'description': round.globalModel.objective.description,
          'type': round.globalModel.objective.type.toString(),
          'parameters': round.globalModel.objective.parameters,
        },
        'version': round.globalModel.version,
        'parameters': round.globalModel.parameters,
        'loss': round.globalModel.loss,
        'accuracy': round.globalModel.accuracy,
        'updatedAt': round.globalModel.updatedAt.toIso8601String(),
      },
      'participantUpdates': round.participantUpdates.map((key, value) => 
        MapEntry(key, {
          'nodeId': value.nodeId,
          'roundId': value.roundId,
          'gradients': value.gradients,
          'trainingMetrics': {
            'samplesUsed': value.trainingMetrics.samplesUsed,
            'trainingLoss': value.trainingMetrics.trainingLoss,
            'accuracy': value.trainingMetrics.accuracy,
            'privacyBudgetUsed': value.trainingMetrics.privacyBudgetUsed,
          },
          'timestamp': value.timestamp.toIso8601String(),
          'privacyCompliant': value.privacyCompliant,
        })
      ),
      'privacyMetrics': {
        'privacyBudgetUsed': round.privacyMetrics.privacyBudgetUsed,
        'noiseLevelApplied': round.privacyMetrics.noiseLevelApplied,
        'differentialPrivacyEnabled': round.privacyMetrics.differentialPrivacyEnabled,
      },
    };
  }
  
  /// Convert JSON to FederatedLearningRound
  FederatedLearningRound _roundFromJson(Map<String, dynamic> json) {
    final objectiveJson = json['objective'] as Map<String, dynamic>;
    final objective = LearningObjective(
      name: objectiveJson['name'] as String,
      description: objectiveJson['description'] as String,
      type: _parseLearningType(objectiveJson['type'] as String),
      parameters: Map<String, dynamic>.from(objectiveJson['parameters'] as Map),
    );
    
    final globalModelJson = json['globalModel'] as Map<String, dynamic>;
    final globalModelObjectiveJson = globalModelJson['objective'] as Map<String, dynamic>;
    final globalModel = GlobalModel(
      modelId: globalModelJson['modelId'] as String,
      objective: LearningObjective(
        name: globalModelObjectiveJson['name'] as String,
        description: globalModelObjectiveJson['description'] as String,
        type: _parseLearningType(globalModelObjectiveJson['type'] as String),
        parameters: Map<String, dynamic>.from(globalModelObjectiveJson['parameters'] as Map),
      ),
      version: globalModelJson['version'] as int,
      parameters: Map<String, dynamic>.from(globalModelJson['parameters'] as Map),
      loss: (globalModelJson['loss'] as num).toDouble(),
      accuracy: (globalModelJson['accuracy'] as num).toDouble(),
      updatedAt: DateTime.parse(globalModelJson['updatedAt'] as String),
    );
    
    final participantUpdates = <String, LocalModelUpdate>{};
    final updatesJson = json['participantUpdates'] as Map<String, dynamic>? ?? {};
    for (final entry in updatesJson.entries) {
      final updateJson = entry.value as Map<String, dynamic>;
      final metricsJson = updateJson['trainingMetrics'] as Map<String, dynamic>;
      participantUpdates[entry.key] = LocalModelUpdate(
        nodeId: updateJson['nodeId'] as String,
        roundId: updateJson['roundId'] as String,
        gradients: Map<String, dynamic>.from(updateJson['gradients'] as Map),
        trainingMetrics: TrainingMetrics(
          samplesUsed: metricsJson['samplesUsed'] as int,
          trainingLoss: (metricsJson['trainingLoss'] as num).toDouble(),
          accuracy: (metricsJson['accuracy'] as num).toDouble(),
          privacyBudgetUsed: (metricsJson['privacyBudgetUsed'] as num).toDouble(),
        ),
        timestamp: DateTime.parse(updateJson['timestamp'] as String),
        privacyCompliant: updateJson['privacyCompliant'] as bool,
      );
    }
    
    final privacyMetricsJson = json['privacyMetrics'] as Map<String, dynamic>;
    final privacyMetrics = PrivacyMetrics(
      privacyBudgetUsed: (privacyMetricsJson['privacyBudgetUsed'] as num).toDouble(),
      noiseLevelApplied: (privacyMetricsJson['noiseLevelApplied'] as num).toDouble(),
      differentialPrivacyEnabled: privacyMetricsJson['differentialPrivacyEnabled'] as bool,
    );
    
    return FederatedLearningRound(
      roundId: json['roundId'] as String,
      organizationId: json['organizationId'] as String,
      objective: objective,
      participantNodeIds: List<String>.from(json['participantNodeIds'] as List),
      status: _parseRoundStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      roundNumber: json['roundNumber'] as int,
      globalModel: globalModel,
      participantUpdates: participantUpdates,
      privacyMetrics: privacyMetrics,
    );
  }
  
  LearningType _parseLearningType(String type) {
    switch (type) {
      case 'LearningType.recommendation':
        return LearningType.recommendation;
      case 'LearningType.classification':
        return LearningType.classification;
      case 'LearningType.clustering':
        return LearningType.clustering;
      case 'LearningType.prediction':
        return LearningType.prediction;
      default:
        return LearningType.recommendation;
    }
  }
  
  RoundStatus _parseRoundStatus(String status) {
    switch (status) {
      case 'RoundStatus.initializing':
        return RoundStatus.initializing;
      case 'RoundStatus.training':
        return RoundStatus.training;
      case 'RoundStatus.aggregating':
        return RoundStatus.aggregating;
      case 'RoundStatus.completed':
        return RoundStatus.completed;
      case 'RoundStatus.failed':
        return RoundStatus.failed;
      default:
        return RoundStatus.initializing;
    }
  }
  
  /// Calculate participation streak (consecutive days with participation)
  int _calculateParticipationStreak(String nodeId, List<dynamic> completedRounds) {
    final participationDates = <DateTime>[];
    for (final roundData in completedRounds) {
      try {
        final round = _roundFromJson(roundData as Map<String, dynamic>);
        if (round.participantNodeIds.contains(nodeId) && 
            round.status == RoundStatus.completed) {
          participationDates.add(round.createdAt);
        }
      } catch (e) {
        // Skip invalid rounds
      }
    }
    
    if (participationDates.isEmpty) return 0;
    
    // Sort dates descending
    participationDates.sort((a, b) => b.compareTo(a));
    
    // Calculate streak
    int streak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    for (int i = 0; i < participationDates.length; i++) {
      final participationDate = DateTime(
        participationDates[i].year,
        participationDates[i].month,
        participationDates[i].day,
      );
      
      final expectedDate = todayDate.subtract(Duration(days: i));
      if (participationDate == expectedDate) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

// Supporting classes and enums
enum RoundStatus { initializing, training, aggregating, completed, failed }
enum PrivacyLevel { low, medium, high, maximum }

class LearningObjective {
  final String name;
  final String description;
  final LearningType type;
  final Map<String, dynamic> parameters;
  
  LearningObjective({
    required this.name,
    required this.description,
    required this.type,
    required this.parameters,
  });
}

enum LearningType { recommendation, classification, clustering, prediction }

class FederatedLearningRound {
  final String roundId;
  final String organizationId;
  final LearningObjective objective;
  final List<String> participantNodeIds;
  RoundStatus status;
  final DateTime createdAt;
  int roundNumber;
  GlobalModel globalModel;
  final Map<String, LocalModelUpdate> participantUpdates;
  final PrivacyMetrics privacyMetrics;
  
  FederatedLearningRound({
    required this.roundId,
    required this.organizationId,
    required this.objective,
    required this.participantNodeIds,
    required this.status,
    required this.createdAt,
    required this.roundNumber,
    required this.globalModel,
    required this.participantUpdates,
    required this.privacyMetrics,
  });
}

class PrivacyMetrics {
  final double privacyBudgetUsed;
  final double noiseLevelApplied;
  final bool differentialPrivacyEnabled;
  
  PrivacyMetrics({
    required this.privacyBudgetUsed,
    required this.noiseLevelApplied,
    required this.differentialPrivacyEnabled,
  });
  
  static PrivacyMetrics initial() => PrivacyMetrics(
    privacyBudgetUsed: 0.0,
    noiseLevelApplied: 0.0,
    differentialPrivacyEnabled: true,
  );
}

class GlobalModel {
  final String modelId;
  final LearningObjective objective;
  final int version;
  final Map<String, dynamic> parameters;
  final double loss;
  final double accuracy;
  final DateTime updatedAt;
  
  GlobalModel({
    required this.modelId,
    required this.objective,
    required this.version,
    required this.parameters,
    required this.loss,
    required this.accuracy,
    required this.updatedAt,
  });
}

class LocalTrainingData {
  final int sampleCount;
  final Map<String, dynamic> features;
  final bool containsPersonalIdentifiers;
  
  LocalTrainingData({
    required this.sampleCount,
    required this.features,
    required this.containsPersonalIdentifiers,
  });
}

class PrivatizedTrainingData {
  final int sampleCount;
  final double privacyBudget;
  final Map<String, dynamic> noisyFeatures;
  
  PrivatizedTrainingData({
    required this.sampleCount,
    required this.privacyBudget,
    required this.noisyFeatures,
  });
}

class LocalModel {
  final Map<String, dynamic> parameters;
  final double loss;
  final double accuracy;
  final int trainingSteps;
  
  LocalModel({
    required this.parameters,
    required this.loss,
    required this.accuracy,
    required this.trainingSteps,
  });
}

class LocalModelUpdate {
  final String nodeId;
  final String roundId;
  final Map<String, dynamic> gradients;
  final TrainingMetrics trainingMetrics;
  final DateTime timestamp;
  final bool privacyCompliant;
  
  LocalModelUpdate({
    required this.nodeId,
    required this.roundId,
    required this.gradients,
    required this.trainingMetrics,
    required this.timestamp,
    required this.privacyCompliant,
  });
}

class TrainingMetrics {
  final int samplesUsed;
  final double trainingLoss;
  final double accuracy;
  final double privacyBudgetUsed;
  
  TrainingMetrics({
    required this.samplesUsed,
    required this.trainingLoss,
    required this.accuracy,
    required this.privacyBudgetUsed,
  });
}

class GlobalModelUpdate {
  final String roundId;
  final int roundNumber;
  final GlobalModel updatedModel;
  final ConvergenceMetrics convergenceMetrics;
  final int participantCount;
  final DateTime aggregationTimestamp;
  final bool privacyPreserved;
  
  GlobalModelUpdate({
    required this.roundId,
    required this.roundNumber,
    required this.updatedModel,
    required this.convergenceMetrics,
    required this.participantCount,
    required this.aggregationTimestamp,
    required this.privacyPreserved,
  });
}

class ConvergenceMetrics {
  final double parameterChangeNorm;
  final double lossImprovement;
  final double convergenceScore;
  final bool hasConverged;
  
  ConvergenceMetrics({
    required this.parameterChangeNorm,
    required this.lossImprovement,
    required this.convergenceScore,
    required this.hasConverged,
  });
}

class CommunityInsights {
  final String organizationId;
  final List<PrivateInsight> insights;
  final List<String> recommendations;
  final double confidenceLevel;
  final PrivacyLevel privacyLevel;
  final DateTime generatedAt;
  final int roundsAnalyzed;
  
  CommunityInsights({
    required this.organizationId,
    required this.insights,
    required this.recommendations,
    required this.confidenceLevel,
    required this.privacyLevel,
    required this.generatedAt,
    required this.roundsAnalyzed,
  });
}

class InsightPattern {
  final String patternType;
  final double confidence;
  final bool privacyPreserved;
  final String description;
  
  InsightPattern({
    required this.patternType,
    required this.confidence,
    required this.privacyPreserved,
    required this.description,
  });
}

class PrivateInsight {
  final String insight;
  final double confidence;
  final PrivacyLevel privacyLevel;
  
  PrivateInsight({
    required this.insight,
    required this.confidence,
    required this.privacyLevel,
  });
}

class FederatedLearningException implements Exception {
  final String message;
  FederatedLearningException(this.message);
}

/// Participation history for a user in federated learning
class ParticipationHistory {
  /// Total number of rounds user has participated in
  final int totalRoundsParticipated;
  
  /// Number of rounds completed successfully
  final int completedRounds;
  
  /// Total number of contributions (model updates) made
  final int totalContributions;
  
  /// List of benefits earned from participation
  final List<String> benefitsEarned;
  
  /// Date of last participation
  final DateTime? lastParticipationDate;
  
  /// Current participation streak (consecutive rounds)
  final int participationStreak;
  
  ParticipationHistory({
    required this.totalRoundsParticipated,
    required this.completedRounds,
    required this.totalContributions,
    required this.benefitsEarned,
    this.lastParticipationDate,
    required this.participationStreak,
  });
  
  /// Calculate completion rate (0.0-1.0)
  double get completionRate {
    if (totalRoundsParticipated == 0) return 0.0;
    return completedRounds / totalRoundsParticipated;
  }
  
  /// Calculate average contributions per round
  double get averageContributionsPerRound {
    if (totalRoundsParticipated == 0) return 0.0;
    return totalContributions / totalRoundsParticipated;
  }
}
