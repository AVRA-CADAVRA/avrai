import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/widgets/common/ai_chat_bar.dart';
import 'package:spots/presentation/widgets/common/ai_command_processor.dart';
import 'package:spots/presentation/widgets/common/ai_thinking_indicator.dart';
import 'package:spots/presentation/widgets/common/streaming_response_widget.dart';
import 'package:spots/presentation/widgets/common/action_success_widget.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/core/services/action_history_service.dart';
import 'package:geolocator/geolocator.dart';

/// Phase 1 Integration: Enhanced AI chat interface with all new Phase 1.3 widgets
/// 
/// This widget demonstrates the complete integration of:
/// - AIThinkingIndicator (shows AI processing stages)
/// - StreamingResponseWidget (displays responses with typing animation)
/// - ActionSuccessWidget (rich feedback after actions)
/// - Offline handling
class EnhancedAIChatInterface extends StatefulWidget {
  final String userId;
  final Position? currentLocation;
  final bool enableStreaming;
  final bool showThinkingStages;
  
  const EnhancedAIChatInterface({
    super.key,
    required this.userId,
    this.currentLocation,
    this.enableStreaming = true,
    this.showThinkingStages = true,
  });

  @override
  State<EnhancedAIChatInterface> createState() => _EnhancedAIChatInterfaceState();
}

class _EnhancedAIChatInterfaceState extends State<EnhancedAIChatInterface> {
  final List<ChatBubble> _messages = [];
  bool _isProcessing = false;
  AIThinkingStage _currentStage = AIThinkingStage.loadingContext;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _messages[index],
          ),
        ),
        
        // Thinking indicator (shown during processing)
        if (_isProcessing && widget.showThinkingStages)
          Container(
            padding: const EdgeInsets.all(16),
            child: AIThinkingIndicator(
              stage: _currentStage,
              showDetails: true,
            ),
          ),
        
        // Input bar
        AIChatBar(
          enabled: !_isProcessing,
          isLoading: _isProcessing,
          onSendMessage: _handleUserMessage,
        ),
      ],
    );
  }
  
  Future<void> _handleUserMessage(String message) async {
    if (message.isEmpty) return;
    
    // Add user message to chat
    setState(() {
      _messages.add(ChatBubble(
        message: message,
        isUser: true,
      ));
      _isProcessing = true;
      _currentStage = AIThinkingStage.loadingContext;
    });
    
    try {
      // Simulate stage progression
      if (widget.showThinkingStages) {
        await _progressThroughStages();
      }
      
      // Process with AI Command Processor
      final response = await AICommandProcessor.processCommand(
        message,
        context,
        userId: widget.userId,
        currentLocation: widget.currentLocation,
        useStreaming: widget.enableStreaming,
        showThinkingIndicator: false, // We're managing it ourselves
      );
      
      // Show streaming response if enabled
      if (widget.enableStreaming && mounted) {
        await _showStreamingResponse(response);
      } else {
        // Add regular response
        setState(() {
          _messages.add(ChatBubble(
            message: response,
            isUser: false,
          ));
        });
      }
      
      // Check if action was executed and show success feedback
      await _checkForActionSuccess(message, response);
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatBubble(
            message: 'Sorry, I encountered an error: $e',
            isUser: false,
            isError: true,
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  /// Progress through AI thinking stages
  Future<void> _progressThroughStages() async {
    final stages = [
      AIThinkingStage.loadingContext,
      AIThinkingStage.analyzingPersonality,
      AIThinkingStage.consultingNetwork,
      AIThinkingStage.generatingResponse,
    ];
    
    for (final stage in stages) {
      if (!mounted) break;
      setState(() => _currentStage = stage);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
  
  /// Show streaming response in a message bubble
  Future<void> _showStreamingResponse(String fullResponse) async {
    // Create a stream that simulates typing
    final stream = _simulateTypingStream(fullResponse);
    
    // Add streaming message bubble
    final streamingBubble = StreamingChatBubble(
      textStream: stream,
      onComplete: () {
        // Message complete
      },
    );
    
    if (mounted) {
      setState(() {
        _messages.add(streamingBubble);
      });
    }
  }
  
  /// Simulate typing stream for demonstration
  Stream<String> _simulateTypingStream(String text) async* {
    final words = text.split(' ');
    String current = '';
    
    for (final word in words) {
      current += '$word ';
      await Future.delayed(const Duration(milliseconds: 50));
      yield current;
    }
  }
  
  /// Check if an action was executed and show success dialog
  Future<void> _checkForActionSuccess(String command, String response) async {
    // Simple heuristic: if response contains success keywords, it was likely an action
    final successKeywords = ['created', 'added', 'saved', 'updated'];
    final isAction = successKeywords.any((keyword) => 
      response.toLowerCase().contains(keyword));
    
    if (isAction && mounted) {
      // Create a mock action result for demonstration
      final mockResult = ActionResult(
        success: true,
        intent: CreateListIntent(listName: 'Example List'), // Mock intent
        message: response,
        data: {'id': 'mock-id'},
      );
      
      // Record action in history
      try {
        final historyService = GetIt.instance<ActionHistoryService>();
        await historyService.recordAction(mockResult);
      } catch (e) {
        // Service not registered, skip
      }
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ActionSuccessWidget(
          result: mockResult,
          onUndo: () async {
            // Optional Enhancement: Wire to ActionHistoryService
            try {
              final historyService = GetIt.instance<ActionHistoryService>();
              final undoResult = await historyService.undoLastAction();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(undoResult.success 
                        ? 'Action undone successfully!' 
                        : undoResult.message),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Undo failed: $e')),
                );
              }
            }
          },
          onViewResult: () {
            // TODO: Navigate to created item
            Navigator.of(context).pop();
          },
          undoTimeout: const Duration(seconds: 5),
        ),
      );
    }
  }
}

/// Regular chat bubble
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isError;
  
  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isError ? AppColors.error.withValues(alpha: 0.1) : AppColors.grey100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? AppColors.white : AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Streaming chat bubble with typing animation
class StreamingChatBubble extends StatelessWidget {
  final Stream<String> textStream;
  final VoidCallback? onComplete;
  
  const StreamingChatBubble({
    super.key,
    required this.textStream,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StreamingResponseWidget(
          textStream: textStream,
          onComplete: onComplete,
          onStop: () {
            // User stopped streaming
          },
        ),
      ),
    );
  }
}

