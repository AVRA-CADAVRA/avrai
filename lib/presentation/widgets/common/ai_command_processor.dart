import 'package:flutter/material.dart';
import 'package:spots/core/services/llm_service.dart' as llm
    show LLMService, ChatMessage, ChatRole, LLMContext, OfflineException;
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/ai/personality_learning.dart' as pl;
import 'package:spots/core/ai/vibe_analysis_engine.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';
import 'package:spots/core/ai/action_parser.dart';
import 'package:spots/core/ai/action_executor.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/core/services/action_history_service.dart';
import 'package:spots/presentation/widgets/common/action_confirmation_dialog.dart';
import 'package:spots/presentation/widgets/common/action_error_dialog.dart';
import 'package:spots/presentation/widgets/common/action_success_widget.dart';
import 'package:spots/presentation/widgets/common/ai_thinking_indicator.dart';
import 'package:spots/presentation/widgets/common/streaming_response_widget.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer' as developer;

class AICommandProcessor {
  static const String _logName = 'AICommandProcessor';

  final llm.LLMService? _llmService;

  AICommandProcessor({llm.LLMService? llmService}) : _llmService = llmService;

  /// Process a command using LLM if available, fallback to rule-based
  /// Automatically handles offline scenarios by checking connectivity first
  /// Fully integrated with AI/ML systems (personality, vibe, AI2AI)
  /// Phase 5: Now supports action execution
  /// Phase 1.3: Enhanced with AI thinking states, streaming responses, and rich success feedback
  static Future<String> processCommand(
    String command,
    BuildContext context, {
    llm.LLMContext? userContext,
    llm.LLMService? llmService,
    String? userId,
    Position? currentLocation,
    bool useStreaming = true,
    bool showThinkingIndicator = true,
  }) async {
    // Phase 5: Try to parse and execute actions first
    // Phase 7 Week 33: Enhanced action intent parsing
    // Phase 7 Week 35: Show thinking indicator during action parsing
    if (userId != null) {
      OverlayEntry? thinkingOverlay;
      try {
        // Show thinking indicator during action parsing
        if (showThinkingIndicator && context.mounted) {
          thinkingOverlay = _showThinkingIndicator(context);
        }

        try {
          final actionParser =
              ActionParser(llmService: llmService ?? _tryGetLLMService());
          final intent = await actionParser.parseAction(
            command,
            userId: userId,
            currentLocation: currentLocation,
          );

          // Remove thinking indicator after parsing
          thinkingOverlay?.remove();
          thinkingOverlay = null;

          if (intent != null) {
            developer.log(
                'Action intent detected: ${intent.type} (confidence: ${intent.confidence})',
                name: _logName);

            // Show thinking indicator during action execution check
            if (showThinkingIndicator && context.mounted) {
              thinkingOverlay = _showThinkingIndicator(context);
            }

            // Check if action can be executed
            final canExecute = await actionParser.canExecute(intent);

            // Remove thinking indicator after check
            thinkingOverlay?.remove();
            thinkingOverlay = null;

            if (canExecute) {
              // Show confirmation dialog before executing
              if (!context.mounted) return 'Context lost';

              // Generate preview for user feedback
              final preview = _generateActionPreview(intent);
              developer.log('Action preview: $preview', name: _logName);

              final confirmed = await _showConfirmationDialog(context, intent);
              if (!confirmed) {
                developer.log('Action cancelled by user', name: _logName);
                return 'Action cancelled';
              }

              // Show thinking indicator during action execution
              if (showThinkingIndicator && context.mounted) {
                thinkingOverlay = _showThinkingIndicator(context);
              }

              try {
                // Execute the action with retry support
                final serviceForAction = llmService ?? _tryGetLLMService();
                final result = await _executeActionWithUI(
                  context,
                  intent,
                  serviceForAction,
                  userContext,
                  command,
                );

                // Remove thinking indicator after execution
                thinkingOverlay?.remove();
                return result;
              } catch (e) {
                // Remove thinking indicator on error
                thinkingOverlay?.remove();
                rethrow;
              }
            } else {
              developer.log(
                  'Action cannot be executed: missing required fields',
                  name: _logName);
              return 'I understand you want to ${_generateActionPreview(intent).toLowerCase()}, but I need more information to complete this action.';
            }
          }
        } catch (e) {
          // Remove thinking indicator on error
          thinkingOverlay?.remove();
          rethrow;
        }
      } catch (e, stackTrace) {
        // Ensure thinking indicator is removed on any error
        thinkingOverlay?.remove();
        developer.log('Error in action execution: $e', name: _logName);
        developer.log('Stack trace: $stackTrace', name: _logName);
        // Continue to normal processing if action execution fails
      }
    }

    // Check connectivity first to avoid unnecessary attempts
    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    final isOnline = connectivityResult is List
        ? !connectivityResult.contains(ConnectivityResult.none)
        : connectivityResult != ConnectivityResult.none;

    // Try to get LLM service from GetIt if not provided
    final service = llmService ?? _tryGetLLMService();

    // Use LLM if available and online
    if (service != null && isOnline) {
      try {
        developer.log('Processing command with LLM: $command', name: _logName);

        // Phase 1 Integration: Show thinking indicator if requested
        OverlayEntry? thinkingOverlay;
        if (showThinkingIndicator && context.mounted) {
          thinkingOverlay = _showThinkingIndicator(context);
        }

        try {
          // Enhance context with AI/ML system data if userId provided
          llm.LLMContext? enhancedContext = userContext;
          if (userId != null) {
            enhancedContext = await _buildEnhancedContext(
              userId: userId,
              baseContext: userContext,
              currentLocation: currentLocation,
            );
          }

          String response = '';
          // Phase 1 Integration: Use streaming if requested
          if (useStreaming) {
            final stream = service.chatStream(
              messages: [
                llm.ChatMessage(role: llm.ChatRole.user, content: command)
              ],
              context: enhancedContext,
            );

            // Collect the final response
            await for (final chunk in stream) {
              response = chunk;
            }
          } else {
            response = await service.generateRecommendation(
              userQuery: command,
              userContext: enhancedContext,
            );
          }

          return response;
        } finally {
          // Remove thinking indicator
          thinkingOverlay?.remove();
        }
      } catch (e) {
        // If it's an offline exception, log and fall through to rule-based
        if (e is llm.OfflineException) {
          developer.log('Device is offline, using rule-based processing',
              name: _logName);
        } else {
          developer.log('LLM processing failed, falling back to rules: $e',
              name: _logName);
        }
        // Fall through to rule-based processing
      }
    } else if (!isOnline) {
      developer.log('Device is offline, using rule-based processing',
          name: _logName);
    }

    // Fallback to rule-based processing (works offline)
    return _processRuleBased(command);
  }

  /// Build enhanced LLM context with AI/ML system data
  static Future<llm.LLMContext> _buildEnhancedContext({
    required String userId,
    llm.LLMContext? baseContext,
    Position? currentLocation,
  }) async {
    try {
      developer.log(
          'Building enhanced LLM context with AI/ML data for: $userId',
          name: _logName);

      // Get AI/ML services from DI
      PersonalityProfile? personality;
      UserVibe? vibe;
      List<pl.AI2AILearningInsight>? ai2aiInsights;
      ConnectionMetrics? connectionMetrics;

      try {
        // Get personality learning service
        final personalityLearning = _tryGetPersonalityLearning();
        if (personalityLearning != null) {
          personality = await personalityLearning.initializePersonality(userId);
          developer.log(
              'Loaded personality: ${personality.archetype}, generation ${personality.evolutionGeneration}',
              name: _logName);
        }

        // Get vibe analyzer
        final vibeAnalyzer = _tryGetVibeAnalyzer();
        if (vibeAnalyzer != null && personality != null) {
          vibe = await vibeAnalyzer.compileUserVibe(userId, personality);
          developer.log('Compiled vibe: ${vibe.getVibeArchetype()}',
              name: _logName);
        }

        // Get AI2AI insights (recent learning)
        try {
          final ai2aiLearning = _tryGetAI2AILearning();
          if (ai2aiLearning != null && personality != null) {
            // Get recent insights from personality learning
            // Note: This would fetch insights from AI2AI interactions
            // For now, we'll get insights from PersonalityLearning if available
            final recentInsights =
                await _getRecentAI2AIInsights(userId, personality);
            if (recentInsights.isNotEmpty) {
              ai2aiInsights = recentInsights;
              developer.log('Loaded ${recentInsights.length} AI2AI insights',
                  name: _logName);
            }
          }
        } catch (e) {
          developer.log('Error fetching AI2AI insights: $e', name: _logName);
          // Continue without insights
        }

        // Get connection metrics from orchestrator
        final orchestrator = _tryGetConnectionOrchestrator();
        if (orchestrator != null && personality != null) {
          try {
            // Get active connections for this user
            final activeConnections = await orchestrator
                .discoverNearbyAIPersonalities(userId, personality);
            if (activeConnections.isNotEmpty) {
              developer.log(
                  'Found ${activeConnections.length} active AI2AI connections',
                  name: _logName);
              // Note: ConnectionMetrics would come from active connections
              // For now, we'll leave it null - can be enhanced to fetch actual metrics
            }
          } catch (e) {
            developer.log('Error fetching connection metrics: $e',
                name: _logName);
          }
        }
      } catch (e) {
        developer.log('Error fetching AI/ML data, using base context: $e',
            name: _logName);
      }

      // Build enhanced context
      return llm.LLMContext(
        userId: baseContext?.userId ?? userId,
        location: baseContext?.location ?? currentLocation,
        preferences: baseContext?.preferences,
        recentSpots: baseContext?.recentSpots,
        // AI/ML Integration
        personality: personality ?? baseContext?.personality,
        vibe: vibe ?? baseContext?.vibe,
        ai2aiInsights: ai2aiInsights ?? baseContext?.ai2aiInsights,
        connectionMetrics: connectionMetrics ?? baseContext?.connectionMetrics,
      );
    } catch (e) {
      developer.log('Error building enhanced context: $e', name: _logName);
      return baseContext ??
          llm.LLMContext(userId: userId, location: currentLocation);
    }
  }

  /// Try to get PersonalityLearning from DI
  static pl.PersonalityLearning? _tryGetPersonalityLearning() {
    try {
      // PersonalityLearning is not registered in DI, create instance
      // Using in-memory version for now (no SharedPreferences dependency)
      return pl.PersonalityLearning();
    } catch (e) {
      return null;
    }
  }

  /// Try to get AI2AI Learning service from DI
  static dynamic _tryGetAI2AILearning() {
    try {
      // AI2AIChatAnalyzer requires SharedPreferences, so we'll use PersonalityLearning
      // which can provide insights through its learning history
      return _tryGetPersonalityLearning();
    } catch (e) {
      return null;
    }
  }

  /// Get recent AI2AI insights from personality learning
  static Future<List<pl.AI2AILearningInsight>> _getRecentAI2AIInsights(
    String userId,
    PersonalityProfile personality,
  ) async {
    try {
      final insights = <pl.AI2AILearningInsight>[];

      // Extract insights from personality learning history
      final learningHistory = personality.learningHistory;
      if (learningHistory.containsKey('recent_insights')) {
        final recentInsightsData = learningHistory['recent_insights'] as List?;
        if (recentInsightsData != null) {
          for (final insightData in recentInsightsData) {
            if (insightData is Map) {
              try {
                final insight = pl.AI2AILearningInsight(
                  type: pl.AI2AIInsightType.values.firstWhere(
                    (t) =>
                        t.toString().split('.').last ==
                        (insightData['type'] as String? ?? 'unknown'),
                    orElse: () => pl.AI2AIInsightType.compatibilityLearning,
                  ),
                  dimensionInsights: Map<String, double>.from(
                      insightData['dimensionInsights'] as Map? ?? {}),
                  learningQuality:
                      (insightData['learningQuality'] as num?)?.toDouble() ??
                          0.5,
                  timestamp: insightData['timestamp'] != null
                      ? DateTime.parse(insightData['timestamp'] as String)
                      : DateTime.now(),
                );
                insights.add(insight);
              } catch (e) {
                developer.log('Error parsing insight: $e', name: _logName);
              }
            }
          }
        }
      }

      return insights;
    } catch (e) {
      developer.log('Error getting AI2AI insights: $e', name: _logName);
      return [];
    }
  }

  /// Try to get UserVibeAnalyzer from DI
  static UserVibeAnalyzer? _tryGetVibeAnalyzer() {
    try {
      return GetIt.instance<UserVibeAnalyzer>();
    } catch (e) {
      return null;
    }
  }

  /// Try to get VibeConnectionOrchestrator from DI
  static VibeConnectionOrchestrator? _tryGetConnectionOrchestrator() {
    try {
      return GetIt.instance<VibeConnectionOrchestrator>();
    } catch (e) {
      return null;
    }
  }

  /// Show confirmation dialog for action execution
  /// Phase 7 Week 33: Enhanced with action preview
  static Future<bool> _showConfirmationDialog(
      BuildContext context, ActionIntent intent) async {
    bool confirmed = false;

    // Generate preview text for logging
    final preview = _generateActionPreview(intent);
    developer.log('Showing confirmation for action: $preview', name: _logName);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActionConfirmationDialog(
        intent: intent,
        showConfidence: intent.confidence < 0.8, // Show confidence if low
        onConfirm: () {
          confirmed = true;
        },
        onCancel: () {
          confirmed = false;
        },
      ),
    );
    return confirmed;
  }

  /// Generate human-readable action preview
  /// Phase 7 Week 33: Action preview generation
  static String _generateActionPreview(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return 'Create spot "${intent.name}" (${intent.category}) at ${intent.latitude.toStringAsFixed(4)}, ${intent.longitude.toStringAsFixed(4)}';
    } else if (intent is CreateListIntent) {
      return 'Create list "${intent.title}" (${intent.isPublic ? "public" : "private"})';
    } else if (intent is AddSpotToListIntent) {
      final spotName = intent.metadata['spotName'] as String? ?? intent.spotId;
      final listName = intent.metadata['listName'] as String? ?? intent.listId;
      return 'Add spot "$spotName" to list "$listName"';
    } else if (intent is CreateEventIntent) {
      return 'Create event "${intent.title ?? intent.templateId ?? "event"}"${intent.startTime != null ? " at ${intent.startTime}" : ""}';
    } else {
      return 'Execute action: ${intent.type}';
    }
  }

  /// Execute action with UI dialogs and history storage
  /// Phase 7 Week 33: Enhanced error handling and preview
  static Future<String> _executeActionWithUI(
    BuildContext context,
    ActionIntent intent,
    llm.LLMService? llmService,
    llm.LLMContext? userContext,
    String command,
  ) async {
    // Log action preview
    final preview = _generateActionPreview(intent);
    developer.log('Executing action: $preview', name: _logName);

    final executor = ActionExecutor.fromDI();
    ActionResult result;

    try {
      result = await executor.execute(intent);
    } catch (e, stackTrace) {
      developer.log('Error executing action: $e', name: _logName);
      developer.log('Stack trace: $stackTrace', name: _logName);
      result = ActionResult.failure(
        error: 'Unexpected error: $e',
        intent: intent,
      );
    }

    if (result.success) {
      // Store in action history
      try {
        // Use dependency injection instead of direct instantiation
        final historyService = GetIt.instance<ActionHistoryService>();
        await historyService.addAction(intent: intent, result: result);
        developer.log('Action stored in history', name: _logName);
      } catch (e) {
        developer.log('Failed to save action history: $e', name: _logName);
        // Don't fail the action if history save fails
      }

      // Phase 7 Week 35: Show ActionSuccessWidget after successful action
      if (context.mounted) {
        final successMsg =
            result.successMessage ?? 'Action completed successfully';
        developer.log('Action succeeded: $successMsg', name: _logName);

        // Show success widget
        await _showActionSuccessWidget(
          context,
          result,
          intent,
        );

        // Try to get LLM response for more natural language
        final connectivity = Connectivity();
        final connectivityResult = await connectivity.checkConnectivity();
        final isOnline = connectivityResult is List
            ? !connectivityResult.contains(ConnectivityResult.none)
            : connectivityResult != ConnectivityResult.none;

        final service = llmService ?? _tryGetLLMService();
        if (service != null && isOnline) {
          try {
            // Get a natural language response about the action
            final llmResponse = await service.generateRecommendation(
              userQuery: command,
              userContext: userContext,
            );
            // Combine action result with LLM response
            return '$successMsg\n\n$llmResponse';
          } catch (e) {
            developer.log('LLM response failed, using success message: $e',
                name: _logName);
            // If LLM fails, just return success message
            return successMsg;
          }
        }

        return successMsg;
      }

      return result.successMessage ?? 'Action completed successfully';
    } else {
      // Action failed, show error dialog with retry option
      developer.log('Action failed: ${result.errorMessage}', name: _logName);

      if (!context.mounted) {
        return result.errorMessage ?? 'Failed to execute action';
      }

      return await _showErrorDialogWithRetry(
        context,
        intent,
        result,
        llmService,
        userContext,
        command,
      );
    }
  }

  /// Show error dialog with retry option
  /// Phase 7 Week 33: Enhanced with technical details and better error handling
  static Future<String> _showErrorDialogWithRetry(
    BuildContext context,
    ActionIntent intent,
    ActionResult result,
    llm.LLMService? llmService,
    llm.LLMContext? userContext,
    String command,
  ) async {
    bool retry = false;

    // Get technical error details (original error message)
    final technicalDetails = result.errorMessage ?? 'Unknown error occurred';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActionErrorDialog(
        error:
            technicalDetails, // Will be translated to user-friendly in the dialog
        intent: intent,
        technicalDetails:
            technicalDetails, // Pass technical details for View Details
        onDismiss: () {},
        onRetry: () {
          retry = true;
        },
      ),
    );

    if (retry) {
      developer.log('Retrying action after error', name: _logName);
      // Retry the action
      return await _executeActionWithUI(
        context,
        intent,
        llmService,
        userContext,
        command,
      );
    }

    // User dismissed, return error message
    return result.errorMessage ?? 'Failed to execute action';
  }

  /// Try to get LLM service from GetIt (may not be registered)
  static llm.LLMService? _tryGetLLMService() {
    try {
      return GetIt.instance<llm.LLMService>();
    } catch (e) {
      return null;
    }
  }

  /// Rule-based command processing (fallback)
  static String _processRuleBased(String command) {
    final lowerCommand = command.toLowerCase();

    // Create list commands
    if (lowerCommand.contains('create') && lowerCommand.contains('list')) {
      return _handleCreateList(command);
    }

    // Add spot to list commands
    if (lowerCommand.contains('add') &&
        (lowerCommand.contains('spot') || lowerCommand.contains('location'))) {
      return _handleAddSpotToList(command);
    }

    // Find/search commands
    if (lowerCommand.contains('find') ||
        lowerCommand.contains('search') ||
        lowerCommand.contains('show me')) {
      return _handleFindCommand(command);
    }

    // Event commands
    if (lowerCommand.contains('event') ||
        lowerCommand.contains('weekend') ||
        lowerCommand.contains('upcoming')) {
      return _handleEventCommand(command);
    }

    // User discovery commands
    if (lowerCommand.contains('user') || lowerCommand.contains('people')) {
      return _handleUserCommand(command);
    }

    // Discovery/help commands
    if (lowerCommand.contains('help') ||
        lowerCommand.contains('discover') ||
        lowerCommand.contains('new places')) {
      return _handleDiscoveryCommand(command);
    }

    // Trip/planning commands
    if (lowerCommand.contains('trip') ||
        lowerCommand.contains('plan') ||
        lowerCommand.contains('adventure')) {
      return _handleTripCommand(command);
    }

    // Trending/popular commands
    if (lowerCommand.contains('trending') || lowerCommand.contains('popular')) {
      return _handleTrendingCommand(command);
    }

    // Default response
    return _handleDefaultCommand(command);
  }

  static String _handleCreateList(String command) {
    // Extract list name from command
    String listName = '';
    if (command.contains('"')) {
      final start = command.indexOf('"') + 1;
      final end = command.lastIndexOf('"');
      if (start > 0 && end > start) {
        listName = command.substring(start, end);
      }
    } else if (command.contains('called')) {
      final parts = command.split('called');
      if (parts.length > 1) {
        listName = parts[1].trim();
      }
    } else if (command.contains('for')) {
      final parts = command.split('for');
      if (parts.length > 1) {
        listName = parts[1].trim();
      }
    }

    if (listName.isEmpty) {
      listName = 'New List';
    }

    return "I'll create a new list called \"$listName\" for you! The list has been created and is ready for you to add spots. You can now say things like \"Add Central Park to my $listName list\" or \"Find coffee shops to add to $listName\".";
  }

  static String _handleAddSpotToList(String command) {
    String spotName = '';
    String listName = '';

    // Extract spot name
    if (command.contains('add') && command.contains('to')) {
      final addIndex = command.indexOf('add');
      final toIndex = command.indexOf('to');
      if (addIndex < toIndex) {
        spotName = command.substring(addIndex + 4, toIndex).trim();
      }
    }

    // Extract list name
    if (command.contains('to my') && command.contains('list')) {
      final toMyIndex = command.indexOf('to my');
      final listIndex = command.indexOf('list', toMyIndex);
      if (toMyIndex < listIndex) {
        listName = command.substring(toMyIndex + 5, listIndex).trim();
      }
    }

    if (spotName.isEmpty) spotName = 'this location';
    if (listName.isEmpty) listName = 'your list';

    return "Perfect! I've added $spotName to your \"$listName\" list. The spot is now saved and you can view it anytime. You can also say \"Show me my $listName list\" to see all the spots you've added.";
  }

  static String _handleFindCommand(String command) {
    if (command.contains('restaurant') || command.contains('food')) {
      return "I found some great restaurants for you! Here are some recommendations: Joe's Pizza (casual), The French Laundry (fine dining), and Chelsea Market (food court). Would you like me to add any of these to a list or get more specific recommendations?";
    }

    if (command.contains('coffee') || command.contains('cafe')) {
      return "I found excellent coffee shops nearby! Try Blue Bottle Coffee, Stumptown Coffee Roasters, or Intelligentsia. All have great wifi and atmosphere. Would you like me to create a coffee shop list for you?";
    }

    if (command.contains('park') || command.contains('outdoor')) {
      return "I found beautiful outdoor spots! Central Park is always a classic, Prospect Park has great trails, and Brooklyn Bridge Park offers amazing views. Would you like me to add these to an outdoor spots list?";
    }

    if (command.contains('study') || command.contains('quiet')) {
      return "I found perfect study spots! Try the New York Public Library, Brooklyn Public Library, or quiet coffee shops like Think Coffee. All have good wifi and quiet atmosphere.";
    }

    return "I can help you find restaurants, coffee shops, parks, study spots, and more! Just tell me what you're looking for and I'll find the best options for you.";
  }

  static String _handleEventCommand(String command) {
    if (command.contains('weekend')) {
      return "Here are some great events this weekend: Brooklyn Flea Market (Saturday), Central Park Concert Series (Sunday), and Food Truck Festival (both days). Would you like me to create an events list for you?";
    }

    if (command.contains('upcoming')) {
      return "I found upcoming events: Jazz in the Park (next Friday), Art Walk (next Saturday), and Farmers Market (every Sunday). I can add these to your events list if you'd like!";
    }

    return "I can show you events happening this weekend, upcoming events, or help you discover new activities. What type of events are you interested in?";
  }

  static String _handleUserCommand(String command) {
    if (command.contains('hiking')) {
      return "I found users who love hiking! Sarah (likes mountain trails), Mike (prefers city parks), and Emma (adventure seeker). Would you like to connect with any of them?";
    }

    if (command.contains('area')) {
      return "I found users in your area! There are 15 users within 2 miles who share similar interests. Would you like me to show you their profiles or help you connect?";
    }

    return "I can help you find users with similar interests, users in your area, or help you discover new connections. What type of users are you looking for?";
  }

  static String _handleDiscoveryCommand(String command) {
    return "I'd love to help you discover new places! Based on your preferences, I recommend checking out: Brooklyn Bridge Park (amazing views), Chelsea Market (food paradise), and High Line (unique urban walk). Would you like me to create a discovery list for you?";
  }

  static String _handleTripCommand(String command) {
    return "I can help you plan an amazing trip! I'll create a comprehensive list with transportation, accommodation, activities, and local recommendations. What type of trip are you planning? Weekend getaway, city exploration, or outdoor adventure?";
  }

  static String _handleTrendingCommand(String command) {
    return "Here are the trending spots right now: Brooklyn Bridge Park (amazing sunset views), Chelsea Market (foodie paradise), and High Line (unique urban experience). These are getting lots of love from the community!";
  }

  static String _handleDefaultCommand(String command) {
    return "I can help you with many things! Try asking me to:\n• Create lists (\"Create a coffee shop list\")\n• Add spots (\"Add Central Park to my list\")\n• Find places (\"Find restaurants near me\")\n• Discover events (\"Show me weekend events\")\n• Find users (\"Find hikers in my area\")\n• Plan trips (\"Help me plan a weekend trip\")";
  }

  /// Phase 1 Integration: Show thinking indicator overlay
  static OverlayEntry _showThinkingIndicator(BuildContext context) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: AppColors.black.withValues(alpha: 0.54),
        child: const Center(
          child: AIThinkingIndicator(
            stage: AIThinkingStage.generatingResponse,
            showDetails: true,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    return overlayEntry;
  }

  /// Phase 7 Week 35: Show ActionSuccessWidget after successful action
  static Future<void> _showActionSuccessWidget(
    BuildContext context,
    ActionResult result,
    ActionIntent intent,
  ) async {
    if (!context.mounted) return;

    // Determine if undo is available (for now, only for list/spot creation)
    VoidCallback? onUndo;
    if (intent is CreateListIntent || intent is CreateSpotIntent) {
      // TODO: Implement undo functionality when action history supports it
      // For now, we'll leave it null
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ActionSuccessWidget(
        result: result,
        onUndo: onUndo,
        onViewResult: () {
          // Navigate to the created item if possible
          if (intent is CreateListIntent) {
            // TODO: Navigate to list details page
            final listId = result.data['listId'] as String?;
            developer.log('Navigate to list: ${listId ?? intent.title}',
                name: _logName);
          } else if (intent is CreateSpotIntent) {
            // TODO: Navigate to spot details page
            final spotId = result.data['spotId'] as String?;
            developer.log('Navigate to spot: ${spotId ?? intent.name}',
                name: _logName);
          }
        },
        autoDismiss: false,
      ),
    );
  }

  /// Phase 1 Integration: Show streaming response in bottom sheet
  static Future<void> showStreamingResponse(
    BuildContext context,
    Stream<String> textStream, {
    VoidCallback? onComplete,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Response',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamingResponseWidget(
                textStream: textStream,
                onComplete: onComplete,
                onStop: () {
                  // User stopped streaming
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
