import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:avrai/core/services/llm_service.dart';
import 'package:avrai/core/services/bert_squad/avrai_context_builder.dart';
import 'package:avrai/core/services/bert_squad/query_classifier.dart';
import 'package:avrai/core/models/spot.dart';

/// BERT-SQuAD backend for question answering about AVRAI dataset.
/// 
/// Uses BERT-SQuAD CoreML model to answer questions about:
/// - Spots (addresses, categories, descriptions)
/// - User profiles (personality dimensions, expertise)
/// - Lists (spot memberships, curation)
/// - Community metrics (respect counts, views)
class BertSquadBackend implements LlmBackend {
  static const String _logName = 'BertSquadBackend';
  static const MethodChannel _channel = MethodChannel('avra/bert_squad');
  
  final AvraiContextBuilder _contextBuilder = AvraiContextBuilder();
  final QueryClassifier _queryClassifier = QueryClassifier();
  
  String? _loadedModelPath;
  bool _isModelLoaded = false;
  
  /// Path to BERT-SQuAD model.
  /// 
  /// Checks:
  /// 1. App bundle Resources/models/
  /// 2. User's AVRAI/models/macos/ directory (development)
  static String get defaultModelPath {
    if (Platform.isMacOS) {
      // Option 1: App bundle (if bundled in release)
      final executablePath = Platform.resolvedExecutable;
      if (executablePath.contains('/Contents/')) {
        final appPath = executablePath.substring(0, executablePath.lastIndexOf('/Contents/'));
        final bundlePath = '$appPath/Contents/Resources/models/BERTSQUADFP16.mlmodel';
        
        if (File(bundlePath).existsSync()) {
          return bundlePath;
        }
      }
      
      // Option 2: Development models directory
      final homeDir = Platform.environment['HOME'] ?? '';
      final modelsPath = '$homeDir/AVRAI/models/macos/BERTSQUADFP16.mlmodel';
      
      if (File(modelsPath).existsSync()) {
        return modelsPath;
      }
      
      // Return default path (will fail if doesn't exist, but that's handled)
      return modelsPath;
    }
    return '';
  }
  
  /// Load BERT-SQuAD model.
  Future<void> _ensureModelLoaded() async {
    if (_isModelLoaded && _loadedModelPath != null) {
      return;
    }
    
    try {
      final modelPath = defaultModelPath;
      
      if (!File(modelPath).existsSync()) {
        developer.log(
          'BERT-SQuAD model not found at $modelPath',
          name: _logName,
        );
        _isModelLoaded = false;
        return;
      }
      
      final result = await _channel.invokeMethod<bool>(
        'loadModel',
        <String, dynamic>{'model_path': modelPath},
      );
      
      if (result == true) {
        _loadedModelPath = modelPath;
        _isModelLoaded = true;
        developer.log('BERT-SQuAD model loaded', name: _logName);
      } else {
        developer.log('Failed to load BERT-SQuAD model', name: _logName);
        _isModelLoaded = false;
      }
    } on PlatformException catch (e) {
      developer.log(
        'Platform error loading BERT-SQuAD: ${e.code} ${e.message}',
        name: _logName,
      );
      _isModelLoaded = false;
    } catch (e, stackTrace) {
      developer.log(
        'Error loading BERT-SQuAD model: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      _isModelLoaded = false;
    }
  }
  
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    // BERT-SQuAD only supports single question-answer, not conversation
    if (messages.isEmpty) {
      throw Exception('BERT-SQuAD requires at least one message');
    }
    
    // Get the last user message as the question
    final lastMessage = messages.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => messages.last,
    );
    
    final question = lastMessage.content;
    
    // Check if this is a dataset question
    final isDatasetQuestion = await _queryClassifier.isDatasetQuestion(question);
    if (!isDatasetQuestion) {
      throw Exception('Query is not suitable for BERT-SQuAD');
    }
    
    // Ensure model is loaded
    await _ensureModelLoaded();
    if (!_isModelLoaded) {
      throw Exception('BERT-SQuAD model not available');
    }
    
    // Build context from AVRAI data
    final avraiContext = await _contextBuilder.buildContext(
      query: question,
      userId: context?.userId,
      spots: await _fetchRelevantSpots(question, context),
      personalityProfile: context?.personality,
      additionalData: context?.preferences,
    );
    
    if (avraiContext.isEmpty) {
      throw Exception('No context available for question');
    }
    
    // Run BERT-SQuAD inference
    try {
      final answer = await _channel.invokeMethod<String>(
        'answer',
        <String, dynamic>{
          'question': question,
          'context': avraiContext,
        },
      ).timeout(timeout);
      
      if (answer == null || answer.isEmpty) {
        throw Exception('BERT-SQuAD returned empty answer');
      }
      
      return answer;
    } on PlatformException catch (e) {
      throw Exception('BERT-SQuAD platform error: ${e.code} ${e.message}');
    } on TimeoutException {
      throw TimeoutException('BERT-SQuAD timed out');
    }
  }
  
  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    // BERT-SQuAD doesn't support streaming - return single answer
    final answer = await chat(
      service: service,
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
      timeout: const Duration(seconds: 10),
    );
    
    yield answer;
  }
  
  /// Fetch relevant spots based on query.
  Future<List<Spot>> _fetchRelevantSpots(String query, LLMContext? context) async {
    // Extract spot names from query
    // In production, use proper entity extraction
    final spotNames = _extractSpotNames(query);
    
    if (spotNames.isEmpty) {
      return [];
    }
    
    // Fetch spots (simplified - in production use proper data source)
    try {
      // This would use your actual spot repository
      // For now, return empty list
      return [];
    } catch (e) {
      developer.log('Error fetching spots: $e', name: _logName);
      return [];
    }
  }
  
  /// Extract spot names from query (simplified).
  List<String> _extractSpotNames(String query) {
    // Simplified extraction - in production use NLP entity extraction
    final words = query.toLowerCase().split(' ');
    final spotKeywords = ['spot', 'place', 'location', 'venue'];
    
    final spotNames = <String>[];
    for (int i = 0; i < words.length - 1; i++) {
      if (spotKeywords.contains(words[i])) {
        // Next word might be the spot name
        if (i + 1 < words.length) {
          spotNames.add(words[i + 1]);
        }
      }
    }
    
    return spotNames;
  }
  
}
