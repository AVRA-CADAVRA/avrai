import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user_vibe.dart';
import 'package:avrai/core/models/connection_metrics.dart';
import 'package:avrai/core/ai/personality_learning.dart' as pl;
import 'package:avrai/core/services/config_service.dart';
import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/core/services/device_capability_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai/core/services/on_device_ai_capability_gate.dart';
import 'package:avrai/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'package:avrai/core/services/bert_squad/bert_squad_backend.dart';
import 'package:avrai/core/services/bert_squad/query_classifier.dart';
import 'package:http/http.dart' as http;
// NOTE: This is Android-only at runtime. We keep the dependency optional in
// practice by only using it when `TargetPlatform.android`. Some lint runners
// may not see newly added pub deps, so we suppress URI resolution warnings.
// ignore: uri_does_not_exist
import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

/// LLM Service for Google Gemini integration
/// Provides LLM-powered chat and text generation for SPOTS AI features
/// Handles offline scenarios gracefully with connectivity checks
/// Implements resilience patterns: timeouts, circuit breaker, error handling
/// 
/// TODO: Standardize error handling to use AppLogger (see week_42_error_handling_standard.md)
class LLMService {
  static const String _logName = 'LLMService';
  static const String _prefsKeyOfflineLlmEnabled = 'offline_llm_enabled_v1';
  static const String _prefsKeyLocalLlmActiveModelDir =
      'local_llm_active_model_dir_v1';
  static const String _prefsKeyLocalLlmActiveModelId =
      'local_llm_active_model_id_v1';
  
  // Resilience configuration
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _circuitBreakerOpenDuration = Duration(minutes: 5);
  static const int _circuitBreakerFailureThreshold = 5;
  
  final SupabaseClient client;
  final Connectivity connectivity;

  // Local LLM backend (Option B: iOS CoreML + Android llama.cpp).
  // This is intentionally optional: if the platform integration isn't present,
  // we fall back to cloud (when online).
  final LlmBackend _cloudBackend;
  final LlmBackend _localBackend;
  final LlmBackend? _bertSquadBackend; // Optional BERT-SQuAD for dataset Q&A
  final Future<bool> Function({required bool isOnline})? _shouldUseLocalOverride;
  final Future<bool> Function()? _isOnlineOverride;
  
  // Circuit breaker state
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerOpenedAt;
  bool _circuitBreakerOpen = false;
  
  LLMService(
    this.client, {
    Connectivity? connectivity,
    LlmBackend? cloudBackend,
    LlmBackend? localBackend,
    LlmBackend? bertSquadBackend,
    Future<bool> Function({required bool isOnline})? shouldUseLocalOverride,
    Future<bool> Function()? isOnlineOverride,
  })  : connectivity = connectivity ?? Connectivity(),
        _cloudBackend = cloudBackend ??
            CloudFailoverBackend(
              primary: CloudGeminiBackend(),
              fallback: CloudGeminiGenerationBackend(),
            ),
        _localBackend = localBackend ?? _createLocalBackend(),
        _bertSquadBackend = bertSquadBackend ?? _createBertSquadBackend(),
        _shouldUseLocalOverride = shouldUseLocalOverride,
        _isOnlineOverride = isOnlineOverride;

  static LlmBackend _createLocalBackend() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidLlamaFlutterAndroidBackend();
    }
    // iOS and macOS both use LocalPlatformLlmBackend (method channel)
    return LocalPlatformLlmBackend();
  }
  
  /// Create BERT-SQuAD backend if available (macOS only).
  static LlmBackend? _createBertSquadBackend() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        return BertSquadBackend();
      } catch (e) {
        developer.log('BERT-SQuAD backend not available: $e', name: _logName);
        return null;
      }
    }
    return null;
  }
  
  /// Check if device is online
  Future<bool> _isOnline() async {
    final override = _isOnlineOverride;
    if (override != null) {
      try {
        return await override();
      } catch (_) {
        // Fall through to connectivity-based check.
      }
    }
    try {
      final result = await connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      developer.log('Connectivity check failed, assuming offline: $e', name: _logName);
      return false;
    }
  }

  Future<SharedPreferencesCompat> _getPrefs() async {
    return SharedPreferencesCompat.getInstance();
  }

  Future<bool> _shouldUseLocalLlm({required bool isOnline}) async {
    final override = _shouldUseLocalOverride;
    if (override != null) {
      return await override(isOnline: isOnline);
    }

    // Local LLM is opt-in and device-gated. If not enabled or not eligible,
    // keep using cloud (when online).
    try {
      final prefs = await _getPrefs();
      final enabled = prefs.getBool(_prefsKeyOfflineLlmEnabled) ?? false;
      if (!enabled) return false;

      // Require a locally installed/activated model directory.
      final activeDir = prefs.getString(_prefsKeyLocalLlmActiveModelDir);
      if (activeDir == null || activeDir.isEmpty) return false;
      final activeModelId = prefs.getString(_prefsKeyLocalLlmActiveModelId);
      if (activeModelId == null || activeModelId.isEmpty) return false;

      // Enforce device capability gate (mid/high only).
      final caps = await DeviceCapabilityService().getCapabilities();
      final gate = OnDeviceAiCapabilityGate().evaluate(caps);
      if (!gate.eligible) return false;

      // If we're offline, local is the only way to do real chat.
      // If we're online, we still prefer local when enabled (quality + privacy),
      // but will fall back to cloud if local errors.
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LlmBackend> _selectBackend({
    required List<ChatMessage> messages,
    LLMContext? context,
  }) async {
    // Check if query should use BERT-SQuAD (for dataset questions)
    if (_bertSquadBackend != null && messages.isNotEmpty) {
      final lastMessage = messages.lastWhere(
        (m) => m.role == ChatRole.user,
        orElse: () => messages.last,
      );
      
      final queryClassifier = QueryClassifier();
      final isDatasetQuestion = await queryClassifier.isDatasetQuestion(lastMessage.content);
      
      if (isDatasetQuestion) {
        try {
          // Try BERT-SQuAD first for dataset questions
          return _bertSquadBackend!;
        } catch (e) {
          developer.log(
            'BERT-SQuAD not available, falling back to other backend: $e',
            name: _logName,
          );
          // Fall through to normal backend selection
        }
      }
    }
    
    // Normal backend selection (local vs cloud)
    final online = await _isOnline();
    final useLocal = await _shouldUseLocalLlm(isOnline: online);
    if (!online && !useLocal) {
      // Offline and local LLM is not available/enabled.
      // Do not attempt cloud calls when we already know they cannot succeed.
      throw OfflineException(
        'No internet connection. Enable the offline LLM to use AI features offline.',
      );
    }
    return useLocal ? _localBackend : _cloudBackend;
  }

  Future<List<ChatMessage>> _augmentMessagesForLocalIfPossible(
    List<ChatMessage> messages,
    LLMContext? context,
  ) async {
    // Only inject memory for local backends.
    // Cloud already has a dedicated system-context builder in the Edge Function.
    final userId = context?.userId ?? client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return messages;

    try {
      final sl = GetIt.instance;
      final bootstrap = sl.isRegistered<LocalLlmPostInstallBootstrapService>()
          ? sl<LocalLlmPostInstallBootstrapService>()
          : LocalLlmPostInstallBootstrapService();
      final prompt = await bootstrap.getOrBuildSystemPromptForUser(userId);
      if (prompt == null || prompt.trim().isEmpty) return messages;

      // Avoid duplicating system prompts if caller already provided one.
      if (messages.isNotEmpty && messages.first.role == ChatRole.system) {
        return messages;
      }

      return [
        ChatMessage(role: ChatRole.system, content: prompt),
        ...messages,
      ];
    } catch (e, st) {
      developer.log('Failed to augment local messages: $e',
          name: _logName, error: e, stackTrace: st);
      return messages;
    }
  }

  /// Chat with the LLM
  /// 
  /// [messages] - List of chat messages with role and content
  /// [context] - Optional context about user, location, preferences
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  /// [timeout] - Request timeout, default 30 seconds
  /// 
  /// Throws [OfflineException] if device is offline
  /// Throws [TimeoutException] if request times out
  /// Throws [DataCenterFailureException] if data center is unavailable
  Future<String> chat({
    required List<ChatMessage> messages,
    LLMContext? context,
    double temperature = 0.7,
    int maxTokens = 500,
    Duration? timeout,
  }) async {
    final backend = await _selectBackend(messages: messages, context: context);
    // Treat the configured cloud backend as “cloud” even in tests where we
    // inject a recording backend.
    final isCloud = identical(backend, _cloudBackend);
    final messagesToSend = isCloud
        ? messages
        : await _augmentMessagesForLocalIfPossible(messages, context);

    if (isCloud) {
      // Check circuit breaker (cloud-only).
      if (_circuitBreakerOpen) {
        final timeSinceOpen =
            DateTime.now().difference(_circuitBreakerOpenedAt!);
        if (timeSinceOpen < _circuitBreakerOpenDuration) {
          developer.log('Circuit breaker is open, rejecting request',
              name: _logName);
          throw DataCenterFailureException(
            'AI service temporarily unavailable. Please try again later.',
          );
        } else {
          // Try to close circuit breaker (half-open state)
          developer.log('Attempting to close circuit breaker', name: _logName);
          _circuitBreakerOpen = false;
          _consecutiveFailures = 0;
        }
      }
    }

    try {
      final result = await backend.chat(
        service: this,
        messages: messagesToSend,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout ?? _defaultTimeout,
      );
      if (isCloud) _recordSuccess();
      return result;
    } on TimeoutException {
      if (isCloud) _recordFailure();
      rethrow;
    } on DataCenterFailureException {
      if (isCloud) _recordFailure();
      rethrow;
    } on OfflineException {
      rethrow;
    } catch (e) {
      developer.log('LLM service error: $e', name: _logName);
      
      // Record failure for circuit breaker
      if (isCloud) _recordFailure();
      
      // If local failed and we are online, fall back to cloud once.
      if (!isCloud) {
        final online = await _isOnline();
        if (online) {
          developer.log('Local LLM failed; falling back to cloud once',
              name: _logName);
          return await _cloudBackend.chat(
            service: this,
            messages: messages,
            context: context,
            temperature: temperature,
            maxTokens: maxTokens,
            timeout: timeout ?? _defaultTimeout,
          );
        }
      }

      // Ensure we throw an Exception type (some Dart errors are not Exception).
      throw Exception(e.toString());
    }
  }
  
  /// Record a successful request (reset circuit breaker)
  void _recordSuccess() {
    _consecutiveFailures = 0;
    _circuitBreakerOpen = false;
    _circuitBreakerOpenedAt = null;
  }
  
  /// Record a failed request (update circuit breaker)
  void _recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _circuitBreakerFailureThreshold) {
      _circuitBreakerOpen = true;
      _circuitBreakerOpenedAt = DateTime.now();
      developer.log(
        'Circuit breaker opened after $_consecutiveFailures consecutive failures',
        name: _logName,
      );
    }
  }
  
  /// Generate a recommendation or response based on user query
  /// 
  /// [userQuery] - The user's question or request
  /// [userContext] - Context about the user (location, preferences, etc.)
  Future<String> generateRecommendation({
    required String userQuery,
    LLMContext? userContext,
  }) async {
    return chat(
      messages: [
        ChatMessage(
          role: ChatRole.user,
          content: userQuery,
        )
      ],
      context: userContext,
    );
  }
  
  /// Generate a response in a conversation
  /// 
  /// [conversationHistory] - Previous messages in the conversation
  /// [userMessage] - Current user message
  /// [context] - User context
  Future<String> continueConversation({
    required List<ChatMessage> conversationHistory,
    required String userMessage,
    LLMContext? context,
  }) async {
    final messages = [
      ...conversationHistory,
      ChatMessage(role: ChatRole.user, content: userMessage),
    ];
    
    return chat(
      messages: messages,
      context: context,
    );
  }
  
  /// Generate list name suggestions based on user intent
  Future<List<String>> suggestListNames({
    required String userIntent,
    LLMContext? context,
  }) async {
    try {
      final prompt = 'Based on this user request: "$userIntent", suggest 3-5 creative list names for a location discovery app. Return only the list names, one per line, no numbering or bullets.';
      
      final response = await chat(
        messages: [
          ChatMessage(role: ChatRole.user, content: prompt),
        ],
        context: context,
        maxTokens: 200,
      );
      
      // Parse response into list names
      final names = response
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith(RegExp(r'[0-9\-•]')))
          .take(5)
          .toList();
      
      return names.isEmpty ? ['New List'] : names;
    } catch (e) {
      developer.log('Error generating list names: $e', name: _logName);
      return ['New List'];
    }
  }
  
  /// Generate spot recommendations based on query
  Future<String> generateSpotRecommendations({
    required String query,
    LLMContext? context,
  }) async {
    final prompt = 'User is looking for: "$query". Provide helpful, concise recommendations for places to visit. Focus on authentic local spots.';
    
    return chat(
      messages: [
        ChatMessage(role: ChatRole.user, content: prompt),
      ],
      context: context,
      maxTokens: 300,
    );
  }
  
  /// Generate LLM response with structured facts context
  /// 
  /// Phase 11 Section 5: Retrieval + LLM Fusion
  /// Retrieves structured facts from FactsIndex and personality profile,
  /// then prepares distilled context for LLM.
  /// 
  /// [query] - User query
  /// [userId] - Authenticated user ID
  /// [messages] - Optional conversation history (if provided, uses chat() with history)
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  /// 
  /// Returns LLM-generated response with enriched context
  /// 
  /// Note: If [messages] is provided, uses conversation history. Otherwise, uses single query.
  Future<String> generateWithContext({
    required String query,
    required String userId,
    List<ChatMessage>? messages,
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    try {
      developer.log('Generating with structured facts context for user: $userId', name: _logName);
      
      // Get dependencies from GetIt (already imported)
      final factsIndex = GetIt.instance<FactsIndex>();
      final personalityLearning = GetIt.instance<pl.PersonalityLearning>();
      
      // Step 1: Retrieve structured facts
      final facts = await factsIndex.retrieveFacts(userId: userId);
      
      // Step 2: Get dimension scores (from PersonalityProfile)
      final profile = await personalityLearning.getCurrentPersonality(userId);
      final dimensionScores = profile?.dimensions ?? {};
      
      // Step 3: Prepare distilled context for LLM
      final context = LLMContext(
        userId: userId,
        preferences: {
          'traits': facts.traits,
          'places': facts.places,
          'social_graph': facts.socialGraph,
          'dimension_scores': dimensionScores,
        },
        personality: profile,
      );
      
      // Step 4: Call LLM with distilled context
      // Use conversation history if provided, otherwise use single query
      final messagesToSend = messages ?? [
        ChatMessage(role: ChatRole.user, content: query),
      ];
      
      return await chat(
        messages: messagesToSend,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error generating with context: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to basic chat without structured context
      final messagesToSend = messages ?? [
        ChatMessage(role: ChatRole.user, content: query),
      ];
      return await chat(
        messages: messagesToSend,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }
  }
  
  /// Chat with the LLM using streaming for real-time response display
  /// 
  /// [messages] - List of chat messages with role and content
  /// [context] - Optional context about user, location, preferences
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  /// 
  /// Returns a Stream&lt;String&gt; that emits chunks of text as they arrive
  /// Throws [OfflineException] if device is offline
  /// 
  /// Note: Streaming support depends on Edge Function configuration
  /// Falls back to non-streaming if streaming not available
  /// Chat with the LLM using streaming responses
  /// Returns a stream of progressive text chunks for real-time display
  /// 
  /// Optional Enhancement: Real SSE Streaming
  /// Set useRealSSE=true to use actual Server-Sent Events from Gemini API
  /// Set useRealSSE=false to use simulated streaming (faster to implement, still smooth UX)
  /// 
  /// The SSE implementation includes automatic reconnection and fallback to non-streaming
  /// if SSE fails after retries.
  Stream<String> chatStream({
    required List<ChatMessage> messages,
    LLMContext? context,
    double temperature = 0.7,
    int maxTokens = 500,
    bool useRealSSE = true, // Toggle between real and simulated streaming
    bool autoFallback = true, // Automatically fallback to non-streaming if SSE fails
  }) async* {
    final backend = await _selectBackend(messages: messages, context: context);
    final isCloud = identical(backend, _cloudBackend);
    final messagesToSend = isCloud
        ? messages
        : await _augmentMessagesForLocalIfPossible(messages, context);

    if (isCloud) {
      // Check connectivity before making request (cloud-only).
      final isOnline = await _isOnline();
      if (!isOnline) {
        developer.log('Device is offline, cannot use cloud AI', name: _logName);
        throw OfflineException(
            'Cloud AI requires internet connection. Please check your connection and try again.');
      }
    }

    try {
      developer.log('Sending streaming chat request to LLM: ${messages.length} messages (realSSE: $useRealSSE, autoFallback: $autoFallback)', name: _logName);

      yield* backend.chatStream(
        service: this,
        messages: messagesToSend,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        useRealSse: useRealSSE,
        autoFallback: autoFallback,
      );
      
      developer.log('Completed streaming response', name: _logName);
    } catch (e) {
      developer.log('LLM streaming error: $e', name: _logName);
      
      // If autoFallback is enabled and SSE failed, try non-streaming
      if (autoFallback && useRealSSE) {
        developer.log('Auto-fallback: Attempting non-streaming chat', name: _logName);
        try {
          final response = await chat(
            messages: messages,
            context: context,
            temperature: temperature,
            maxTokens: maxTokens,
          );
          yield response;
          return;
        } catch (fallbackError) {
          developer.log('Fallback chat also failed: $fallbackError', name: _logName);
          // If fallback also fails, throw original error
        }
      }
      
      rethrow;
    }
  }
  
  /// Real SSE streaming from Edge Function with reconnection and error handling
  Stream<String> _chatStreamSSE(
    List<ChatMessage> messages,
    LLMContext? context,
    double temperature,
    int maxTokens,
  ) async* {
    const maxReconnectAttempts = 3;
    const reconnectDelay = Duration(seconds: 2);
    const streamTimeout = Duration(minutes: 5);
    
    String accumulatedText = '';
    int reconnectAttempts = 0;
    bool shouldFallback = false;
    
    while (reconnectAttempts <= maxReconnectAttempts) {
      try {
        // Get Supabase URL and key from ConfigService
        // Note: SupabaseClient doesn't expose these directly, so we get from config
        final configService = GetIt.instance<ConfigService>();
        final supabaseUrl = configService.supabaseUrl;
        final supabaseKey = configService.supabaseAnonKey;
        final url = '$supabaseUrl/functions/v1/llm-chat-stream';
        
        final request = http.Request('POST', Uri.parse(url));
        request.headers.addAll({
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        });
        request.body = jsonEncode({
          'messages': messages.map((m) => m.toJson()).toList(),
          if (context != null) 'context': context.toJson(),
          'temperature': temperature,
          'maxTokens': maxTokens,
        });
        
        // Create timeout for the entire stream
        final streamedResponse = await request.send().timeout(
          streamTimeout,
          onTimeout: () {
            throw TimeoutException('SSE stream timeout after ${streamTimeout.inMinutes} minutes');
          },
        );
        
        if (streamedResponse.statusCode != 200) {
          final error = await streamedResponse.stream.bytesToString();
          final errorMessage = 'SSE stream error: ${streamedResponse.statusCode} - $error';
          developer.log(errorMessage, name: _logName);
          
          // For 4xx errors, don't retry - fallback immediately
          if (streamedResponse.statusCode >= 400 && streamedResponse.statusCode < 500) {
            shouldFallback = true;
            break;
          }
          
          // For 5xx errors, retry
          if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            developer.log('Retrying SSE connection (attempt $reconnectAttempts/$maxReconnectAttempts)...', name: _logName);
            await Future.delayed(reconnectDelay);
            continue;
          } else {
            shouldFallback = true;
            break;
          }
        }
        
        // Process SSE stream
        bool streamCompleted = false;
        bool hasError = false;
        String? streamError;
        
        await for (final chunk in streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(streamTimeout, onTimeout: (sink) {
              developer.log('SSE stream chunk timeout', name: _logName);
              sink.close();
            })) {
          // Parse SSE events
          if (chunk.startsWith('data: ')) {
            final data = chunk.substring(6);
            
            try {
              final event = jsonDecode(data) as Map<String, dynamic>;
              
              // Check for completion
              if (event['done'] == true) {
                streamCompleted = true;
                break;
              }
              
              // Check for error
              if (event['error'] != null) {
                streamError = event['error'] as String? ?? 'Unknown SSE error';
                hasError = true;
                developer.log('SSE error event: $streamError', name: _logName);
                
                // For certain errors, don't retry
                if (streamError.contains('timeout') || 
                    streamError.contains('safety') ||
                    streamError.contains('blocked')) {
                  shouldFallback = true;
                  break;
                }
                
                // For connection errors, retry
                if (reconnectAttempts < maxReconnectAttempts) {
                  reconnectAttempts++;
                  developer.log('Retrying after SSE error (attempt $reconnectAttempts/$maxReconnectAttempts)...', name: _logName);
                  await Future.delayed(reconnectDelay);
                  break; // Break out of stream processing to retry
                } else {
                  shouldFallback = true;
                  break;
                }
              }
              
              // Extract text chunk
              if (event['text'] != null) {
                final text = event['text'] as String;
                accumulatedText += text;
                yield accumulatedText; // Yield cumulative text
                
                // Reset reconnect attempts on successful data
                reconnectAttempts = 0;
              }
            } catch (e) {
              developer.log('Error parsing SSE event: $e', name: _logName);
              // Continue processing other events - don't break on parse errors
            }
          }
        }
        
        // If stream completed successfully, we're done
        if (streamCompleted) {
          // Ensure final text is yielded
          if (accumulatedText.isNotEmpty) {
            yield accumulatedText;
          }
          return;
        }
        
        // If we got here and have accumulated text, yield it before retrying/falling back
        if (accumulatedText.isNotEmpty && !hasError) {
          yield accumulatedText;
        }
        
        // If we have an error and exhausted retries, fallback
        if (hasError && reconnectAttempts >= maxReconnectAttempts) {
          shouldFallback = true;
          break;
        }
        
        // If stream ended unexpectedly but we have text, we're done
        if (accumulatedText.isNotEmpty && !hasError) {
          return;
        }
        
      } catch (e) {
        developer.log('SSE connection error: $e', name: _logName);
        
        // Check if it's a timeout
        if (e is TimeoutException) {
          // If we have accumulated text, yield it before falling back
          if (accumulatedText.isNotEmpty) {
            yield accumulatedText;
            return;
          }
          shouldFallback = true;
          break;
        }
        
        // For other errors, retry if we haven't exhausted attempts
        if (reconnectAttempts < maxReconnectAttempts) {
          reconnectAttempts++;
          developer.log('Retrying after connection error (attempt $reconnectAttempts/$maxReconnectAttempts)...', name: _logName);
          await Future.delayed(reconnectDelay);
          continue;
        } else {
          shouldFallback = true;
          break;
        }
      }
    }
    
    // Fallback to non-streaming if SSE failed
    if (shouldFallback) {
      developer.log('Falling back to non-streaming chat due to SSE failures', name: _logName);
      
      // If we have partial text, yield it first
      if (accumulatedText.isNotEmpty) {
        yield accumulatedText;
      }
      
      // Fallback to regular chat
      try {
        final response = await chat(
          messages: messages,
          context: context,
          temperature: temperature,
          maxTokens: maxTokens,
        );
        
        // Yield the complete response
        yield response;
      } catch (e) {
        developer.log('Fallback chat also failed: $e', name: _logName);
        rethrow;
      }
    }
  }
  
  /// Simulated streaming (fallback for offline or testing)
  Stream<String> _chatStreamSimulated(
    List<ChatMessage> messages,
    LLMContext? context,
    double temperature,
    int maxTokens,
  ) async* {
    // Use regular chat and simulate streaming
    final response = await chat(
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    
    // Simulate streaming by yielding chunks
    const chunkSize = 5; // Characters per chunk
    for (int i = 0; i < response.length; i += chunkSize) {
      final end = (i + chunkSize < response.length) ? i + chunkSize : response.length;
      yield response.substring(0, end); // Yield cumulative text
      
      // Small delay to simulate streaming
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }
}

/// Chat message with role and content
class ChatMessage {
  final ChatRole role;
  final String content;
  
  ChatMessage({
    required this.role,
    required this.content,
  });
  
  Map<String, String> toJson() => {
    'role': role.name,
    'content': content,
  };
}

/// Chat message roles
enum ChatRole {
  user,
  assistant,
  system,
}

/// Context for LLM requests with full AI/ML system integration
class LLMContext {
  final String? userId;
  final Position? location;
  final Map<String, dynamic>? preferences;
  final List<Map<String, dynamic>>? recentSpots;
  
  // AI/ML System Integration
  final PersonalityProfile? personality;
  final UserVibe? vibe;
  final List<pl.AI2AILearningInsight>? ai2aiInsights;
  final ConnectionMetrics? connectionMetrics;
  
  // Language Learning Integration (Phase 2.4)
  final String? languageStyle; // Formatted language style summary from LanguageProfile
  
  LLMContext({
    this.userId,
    this.location,
    this.preferences,
    this.recentSpots,
    // AI/ML Integration
    this.personality,
    this.vibe,
    this.ai2aiInsights,
    this.connectionMetrics,
    // Language Learning
    this.languageStyle,
  });
  
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (userId != null) json['userId'] = userId;
    if (location != null) {
      json['location'] = {
        'lat': location!.latitude,
        'lng': location!.longitude,
      };
    }
    if (preferences != null) json['preferences'] = preferences;
    if (recentSpots != null) json['recentSpots'] = recentSpots;
    
    // Personality integration
    if (personality != null) {
      json['personality'] = {
        'archetype': personality!.archetype,
        'dimensions': personality!.dimensions,
        'dimensionConfidence': personality!.dimensionConfidence,
        'authenticity': personality!.authenticity,
        'evolutionGeneration': personality!.evolutionGeneration,
        'dominantTraits': personality!.getDominantTraits(),
      };
    }
    
    // Vibe integration
    if (vibe != null) {
      json['vibe'] = {
        'archetype': vibe!.getVibeArchetype(),
        'overallEnergy': vibe!.overallEnergy,
        'socialPreference': vibe!.socialPreference,
        'explorationTendency': vibe!.explorationTendency,
        'anonymizedDimensions': vibe!.anonymizedDimensions,
        'temporalContext': vibe!.temporalContext,
      };
    }
    
    // AI2AI insights integration
    if (ai2aiInsights != null && ai2aiInsights!.isNotEmpty) {
      json['ai2aiInsights'] = ai2aiInsights!.map((insight) => {
        'type': insight.type.toString(),
        'dimensionInsights': insight.dimensionInsights,
        'learningQuality': insight.learningQuality,
        'timestamp': insight.timestamp.toIso8601String(),
      }).toList();
    }
    
    // Connection metrics integration
    if (connectionMetrics != null) {
      json['connectionMetrics'] = {
        'initialCompatibility': connectionMetrics!.initialCompatibility,
        'currentCompatibility': connectionMetrics!.currentCompatibility,
        'learningEffectiveness': connectionMetrics!.learningEffectiveness,
        'aiPleasureScore': connectionMetrics!.aiPleasureScore,
        'status': connectionMetrics!.status.toString(),
        'learningOutcomes': connectionMetrics!.learningOutcomes,
      };
    }
    
    // Language style integration (Phase 2.4)
    if (languageStyle != null && languageStyle!.isNotEmpty) {
      json['languageStyle'] = languageStyle;
    }
    
    return json;
  }
}

/// Exception thrown when cloud AI is requested but device is offline
class OfflineException implements Exception {
  final String message;
  
  OfflineException(this.message);
  
  @override
  String toString() => 'OfflineException: $message';
}

/// Exception thrown when AI data center is unavailable or experiencing issues
class DataCenterFailureException implements Exception {
  final String message;
  
  DataCenterFailureException(this.message);
  
  @override
  String toString() => 'DataCenterFailureException: $message';
}

// ============================================================================
// Backends (Cloud vs Local)
// ============================================================================

/// Backend abstraction so we can route to cloud (Gemini) or local runtime
/// (Option B: CoreML on iOS, llama.cpp on Android).
abstract class LlmBackend {
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  });

  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  });
}

/// Cloud Gemini backend using Supabase Edge Functions (existing behavior).
class CloudGeminiBackend implements LlmBackend {
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    // Connectivity check before making request.
    final isOnline = await service._isOnline();
    if (!isOnline) {
      developer.log('Device is offline, cannot use cloud AI', name: LLMService._logName);
      throw OfflineException(
        'Cloud AI requires internet connection. Please check your connection and try again.',
      );
    }

    developer.log('Sending cloud chat request: ${messages.length} messages', name: LLMService._logName);

    final response = await service.client.functions.invoke(
      'llm-chat',
      body: jsonEncode({
        // IMPORTANT: role must be JSON-encodable (string), not the enum itself.
        'messages': messages.map((m) => m.toJson()).toList(),
        'context': context?.toJson(),
        'temperature': temperature,
        'maxTokens': maxTokens,
      }),
    ).timeout(
      timeout,
      onTimeout: () {
        developer.log('LLM request timed out after $timeout', name: LLMService._logName);
        throw TimeoutException(
          'LLM request timed out. The AI service may be experiencing issues.',
        );
      },
    );

    if (response.status != 200) {
      final errorData =
          response.data is String ? jsonDecode(response.data as String) : response.data;
      final errorMessage = errorData['error'] ?? 'Unknown error';

      // Check if it's a data center failure (5xx errors)
      if (response.status >= 500) {
        throw DataCenterFailureException(
          'AI data center is experiencing issues (${response.status}). Please try again later.',
        );
      }

      throw Exception('LLM request failed: ${response.status} - $errorMessage');
    }

    final data =
        response.data is String ? jsonDecode(response.data as String) : response.data;

    final responseText = data['response'] as String?;
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Empty response from LLM');
    }

    developer.log('Received cloud LLM response: ${responseText.length} chars', name: LLMService._logName);
    return responseText;
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
    // Preserve existing streaming behavior: use SSE or simulated.
    if (useRealSse) {
      yield* service._chatStreamSSE(messages, context, temperature, maxTokens);
    } else {
      yield* service._chatStreamSimulated(messages, context, temperature, maxTokens);
    }
  }
}

/// Fallback cloud backend using `llm-generation`.
///
/// This is a **provider-routing/failover** path. It intentionally degrades
/// conversation-history fidelity (query-first) in exchange for availability.
class CloudGeminiGenerationBackend implements LlmBackend {
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    final isOnline = await service._isOnline();
    if (!isOnline) {
      throw OfflineException(
        'Cloud AI requires internet connection. Please check your connection and try again.',
      );
    }

    final query = _extractQuery(messages);
    final structuredContext = <String, dynamic>{
      'traits': context?.personality?.getDominantTraits() ?? const <String>[],
      'places': context?.recentSpots ?? const <Map<String, dynamic>>[],
      'social_graph': const <dynamic>[],
      'onboarding_data': <String, dynamic>{
        if (context?.preferences != null) 'preferences': context!.preferences,
      },
      if (context?.userId != null) 'agentId': context!.userId,
    };

    final response = await service.client.functions.invoke(
      'llm-generation',
      body: jsonEncode({
        'query': query,
        'structuredContext': structuredContext,
        'dimensionScores': context?.personality?.dimensions ?? const <String, double>{},
        'personalityProfile': context?.personality?.toJson(),
      }),
    ).timeout(timeout);

    if (response.status != 200) {
      final errorData =
          response.data is String ? jsonDecode(response.data as String) : response.data;
      final errorMessage = errorData['error'] ?? 'Unknown error';
      throw Exception(
        'LLM fallback request failed: ${response.status} - $errorMessage',
      );
    }

    final data =
        response.data is String ? jsonDecode(response.data as String) : response.data;
    final responseText = data['response'] as String?;
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Empty response from fallback LLM');
    }
    return responseText;
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
    // No streaming support for this backend; callers can use simulated streaming.
    yield await chat(
      service: service,
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
      timeout: const Duration(seconds: 30),
    );
  }

  static String _extractQuery(List<ChatMessage> messages) {
    // Prefer the most recent user message.
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == ChatRole.user) return messages[i].content;
    }
    // Fallback: last message or empty.
    return messages.isNotEmpty ? messages.last.content : '';
  }
}

/// Cloud backend wrapper that attempts a fallback backend on transient failures.
class CloudFailoverBackend implements LlmBackend {
  final LlmBackend primary;
  final LlmBackend fallback;

  const CloudFailoverBackend({
    required this.primary,
    required this.fallback,
  });

  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  }) async {
    try {
      return await primary.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    } on OfflineException {
      rethrow;
    } on DataCenterFailureException catch (e) {
      developer.log('Primary cloud backend unavailable, falling back: $e',
          name: LLMService._logName);
      return await fallback.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    } on TimeoutException catch (e) {
      developer.log('Primary cloud backend timed out, falling back: $e',
          name: LLMService._logName);
      return await fallback.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
    } catch (e) {
      // Best-effort: also fail over on obvious rate limiting.
      final msg = e.toString();
      final looksRateLimited = msg.contains('429') || msg.toLowerCase().contains('rate');
      if (!looksRateLimited) rethrow;

      developer.log('Primary cloud backend rate-limited, falling back: $e',
          name: LLMService._logName);
      return await fallback.chat(
        service: service,
        messages: messages,
        context: context,
        temperature: temperature,
        maxTokens: maxTokens,
        timeout: timeout,
      );
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
  }) {
    // Keep streaming behavior stable: use primary stream path.
    // (SSE already has non-streaming fallback higher up.)
    return primary.chatStream(
      service: service,
      messages: messages,
      context: context,
      temperature: temperature,
      maxTokens: maxTokens,
      useRealSse: useRealSse,
      autoFallback: autoFallback,
    );
  }
}

/// Local backend that calls into platform implementations.
///
/// This will be backed by:
/// - iOS CoreML runner
/// - Android llama.cpp runner
class LocalPlatformLlmBackend implements LlmBackend {
  static const MethodChannel _channel = MethodChannel('spots/local_llm');
  static const EventChannel _streamChannel = EventChannel('avra/local_llm_stream');

  String? _loadedModelDir;

  Future<Map<String, String>> _getActiveModelPointers() async {
    final prefs = await SharedPreferencesCompat.getInstance();
    final dir = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
    final id = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelId) ?? '';
    return <String, String>{
      'model_dir': dir,
      'model_id': id,
    };
  }

  Future<void> _ensureLoaded(String modelDir) async {
    if (_loadedModelDir == modelDir) return;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'loadModel',
        <String, dynamic>{'model_dir': modelDir},
      );
      if (ok != true) {
        throw Exception('Local LLM loadModel returned false');
      }
      _loadedModelDir = modelDir;
    } on PlatformException catch (e) {
      throw Exception('Local LLM loadModel platform error: ${e.code} ${e.message}');
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
    // Local is allowed offline; errors should be explicit.
    try {
      final pointers = await _getActiveModelPointers();
      final modelDir = pointers['model_dir'] ?? '';
      if (modelDir.isEmpty) {
        throw Exception('Local model not installed (missing model_dir)');
      }
      await _ensureLoaded(modelDir);

      final payload = <String, dynamic>{
        'model_dir': modelDir,
        'model_id': pointers['model_id'],
        'messages': messages.map((m) => m.toJson()).toList(),
        'context': context?.toJson(),
        'temperature': temperature,
        'maxTokens': maxTokens,
      };

      final res = await _channel
          .invokeMethod<String>('generate', payload)
          .timeout(timeout);

      if (res == null || res.isEmpty) {
        throw Exception('Empty local response');
      }
      return res;
    } on PlatformException catch (e) {
      throw Exception('Local LLM platform error: ${e.code} ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Local LLM timed out');
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
    // Local streaming uses EventChannel token stream.
    // Emit cumulative text chunks for UI compatibility.
    final pointers = await _getActiveModelPointers();
    final modelDir = pointers['model_dir'] ?? '';
    if (modelDir.isEmpty) {
      throw Exception('Local model not installed (missing model_dir)');
    }
    await _ensureLoaded(modelDir);

    final payload = <String, dynamic>{
      'model_dir': modelDir,
      'model_id': pointers['model_id'],
      'messages': messages.map((m) => m.toJson()).toList(),
      'context': context?.toJson(),
      'temperature': temperature,
      'maxTokens': maxTokens,
    };

    String acc = '';

    try {
      // Kick off generation (native side starts emitting stream events).
      await _channel.invokeMethod<void>('startStream', payload);

      final stream = _streamChannel.receiveBroadcastStream();
      await for (final event in stream) {
        if (event is Map) {
          final type = event['type'];
          if (type == 'token') {
            final token = event['text'];
            if (token is String && token.isNotEmpty) {
              acc += token;
              yield acc;
            }
          } else if (type == 'done') {
            return;
          } else if (type == 'error') {
            throw Exception(event['message']?.toString() ?? 'Local stream error');
          }
        } else if (event is String) {
          // Backward-compatible: treat as a token chunk
          acc += event;
          yield acc;
        }
      }
    } on PlatformException catch (e) {
      throw Exception('Local LLM stream platform error: ${e.code} ${e.message}');
    }
  }
}

/// Android implementation using `llama_flutter_android` (GGUF + token streaming).
class AndroidLlamaFlutterAndroidBackend implements LlmBackend {
  static const String _logName = 'AndroidLlamaBackend';

  final llama.LlamaController _controller = llama.LlamaController();
  String? _loadedModelPath;

  Future<String> _findGgufPath(String modelDir) async {
    final dir = Directory(modelDir);
    if (!await dir.exists()) {
      throw Exception('Model dir does not exist: $modelDir');
    }

    final files = dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.gguf'))
        .toList();

    if (files.isEmpty) {
      throw Exception('No .gguf file found under $modelDir');
    }

    // Prefer the largest .gguf in case multiple exist.
    files.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
    return files.first.path;
  }

  Future<void> _ensureLoaded(String modelDir, {int contextSize = 4096}) async {
    final prefs = await SharedPreferencesCompat.getInstance();
    final activeDir = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
    if (activeDir.isEmpty || activeDir != modelDir) {
      // Safety: only load from active dir.
      throw Exception('Local model dir is not active');
    }

    final ggufPath = await _findGgufPath(modelDir);
    if (_loadedModelPath == ggufPath) {
      return;
    }

    final alreadyLoaded = await _controller.isModelLoaded();
    if (alreadyLoaded) {
      // The plugin doesn’t expose unload + reload directly besides dispose.
      await _controller.dispose();
    }

    final threads = (Platform.numberOfProcessors - 1).clamp(2, 8);

    developer.log('Loading GGUF model: $ggufPath', name: _logName);
    await _controller.loadModel(
      modelPath: ggufPath,
      threads: threads,
      contextSize: contextSize,
      // gpuLayers: null // CPU-only default for now.
    );
    _loadedModelPath = ggufPath;
  }

  List<llama.ChatMessage> _toLlamaMessages(List<ChatMessage> messages) {
    return messages
        .map(
          (m) => llama.ChatMessage(
            role: m.role.name,
            content: m.content,
          ),
        )
        .toList();
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
    final prefs = await SharedPreferencesCompat.getInstance();
    final modelDir = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
    if (modelDir.isEmpty) {
      throw Exception('Local model not installed (missing model_dir)');
    }

    await _ensureLoaded(modelDir, contextSize: 4096);

    final llamaMessages = _toLlamaMessages(messages);
    final tokens = <String>[];

    final sub = _controller
        .generateChat(
          messages: llamaMessages,
          template: null, // Let plugin auto-detect from filename when possible.
          temperature: temperature,
          maxTokens: maxTokens,
        )
        .listen(tokens.add);

    try {
      await sub.asFuture<void>().timeout(timeout);
    } finally {
      await sub.cancel();
    }

    return tokens.join();
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
    final prefs = await SharedPreferencesCompat.getInstance();
    final modelDir = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
    if (modelDir.isEmpty) {
      throw Exception('Local model not installed (missing model_dir)');
    }

    await _ensureLoaded(modelDir, contextSize: 4096);

    final llamaMessages = _toLlamaMessages(messages);

    String acc = '';
    await for (final token in _controller.generateChat(
      messages: llamaMessages,
      template: null,
      temperature: temperature,
      maxTokens: maxTokens,
    )) {
      acc += token;
      yield acc;
    }
  }
}

