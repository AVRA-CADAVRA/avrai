import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/ai/personality_learning.dart' as pl;
import 'package:spots/core/services/config_service.dart';
import 'package:http/http.dart' as http;

/// LLM Service for Google Gemini integration
/// Provides LLM-powered chat and text generation for SPOTS AI features
/// Handles offline scenarios gracefully with connectivity checks
/// 
/// TODO: Standardize error handling to use AppLogger (see week_42_error_handling_standard.md)
class LLMService {
  static const String _logName = 'LLMService';
  
  final SupabaseClient client;
  final Connectivity connectivity;
  
  LLMService(this.client, {Connectivity? connectivity}) 
      : connectivity = connectivity ?? Connectivity();
  
  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
          return result != ConnectivityResult.none;
    } catch (e) {
      developer.log('Connectivity check failed, assuming offline: $e', name: _logName);
      return false;
    }
  }

  /// Chat with the LLM
  /// 
  /// [messages] - List of chat messages with role and content
  /// [context] - Optional context about user, location, preferences
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  /// 
  /// Throws [OfflineException] if device is offline
  Future<String> chat({
    required List<ChatMessage> messages,
    LLMContext? context,
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    // Check connectivity before making request
    final isOnline = await _isOnline();
    if (!isOnline) {
      developer.log('Device is offline, cannot use cloud AI', name: _logName);
      throw OfflineException('Cloud AI requires internet connection. Please check your connection and try again.');
    }

    try {
      developer.log('Sending chat request to LLM: ${messages.length} messages', name: _logName);
      
      final response = await client.functions.invoke(
        'llm-chat',
        body: jsonEncode({
          'messages': messages.map((m) => {
            'role': m.role,
            'content': m.content,
          }).toList(),
          'context': context?.toJson(),
          'temperature': temperature,
          'maxTokens': maxTokens,
        }),
      );
      
      if (response.status != 200) {
        final errorData = response.data is String 
            ? jsonDecode(response.data as String) 
            : response.data;
        throw Exception('LLM request failed: ${response.status} - ${errorData['error'] ?? 'Unknown error'}');
      }
      
      final data = response.data is String 
          ? jsonDecode(response.data as String) 
          : response.data;
      
      final responseText = data['response'] as String?;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from LLM');
      }
      
      developer.log('Received LLM response: ${responseText.length} characters', name: _logName);
      return responseText;
    } catch (e) {
      developer.log('LLM service error: $e', name: _logName);
      rethrow;
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
  
  /// Chat with the LLM using streaming for real-time response display
  /// 
  /// [messages] - List of chat messages with role and content
  /// [context] - Optional context about user, location, preferences
  /// [temperature] - Controls randomness (0.0-1.0), default 0.7
  /// [maxTokens] - Maximum tokens in response, default 500
  /// 
  /// Returns a Stream<String> that emits chunks of text as they arrive
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
    // Check connectivity before making request
    final isOnline = await _isOnline();
    if (!isOnline) {
      developer.log('Device is offline, cannot use cloud AI', name: _logName);
      throw OfflineException('Cloud AI requires internet connection. Please check your connection and try again.');
    }

    try {
      developer.log('Sending streaming chat request to LLM: ${messages.length} messages (realSSE: $useRealSSE, autoFallback: $autoFallback)', name: _logName);
      
      if (useRealSSE) {
        // Use real SSE streaming from Edge Function (includes automatic fallback)
        yield* _chatStreamSSE(messages, context, temperature, maxTokens);
      } else {
        // Use simulated streaming (fallback)
        yield* _chatStreamSimulated(messages, context, temperature, maxTokens);
      }
      
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

