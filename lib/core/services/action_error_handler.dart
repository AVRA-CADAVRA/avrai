import 'dart:developer' as developer;
import 'package:spots/core/ai/action_models.dart';

/// Error handling utilities for action execution
/// Phase 7 Week 33: Action Execution UI & Integration
/// 
/// Provides:
/// - Error categorization
/// - Retry logic
/// - User-friendly error messages
/// - Error recovery strategies

/// Categories of action errors
enum ActionErrorCategory {
  /// Network/connectivity errors (can retry)
  network,
  
  /// Validation errors (cannot retry without fixing input)
  validation,
  
  /// Permission errors (user needs to grant permissions)
  permission,
  
  /// Not found errors (resource doesn't exist)
  notFound,
  
  /// Conflict errors (resource already exists, etc.)
  conflict,
  
  /// Server/backend errors (may be transient)
  server,
  
  /// Unknown errors
  unknown,
}

/// Error handler for action execution
class ActionErrorHandler {
  static const String _logName = 'ActionErrorHandler';
  
  /// Categorize an error from action execution
  static ActionErrorCategory categorizeError(dynamic error, ActionResult? result) {
    if (error == null && result != null) {
      // Categorize based on error message
      final errorMsg = result.errorMessage?.toLowerCase() ?? '';
      
      if (errorMsg.contains('network') || 
          errorMsg.contains('connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('offline')) {
        return ActionErrorCategory.network;
      }
      
      if (errorMsg.contains('permission') ||
          errorMsg.contains('denied') ||
          errorMsg.contains('unauthorized')) {
        return ActionErrorCategory.permission;
      }
      
      if (errorMsg.contains('not found') ||
          errorMsg.contains('does not exist') ||
          errorMsg.contains('missing')) {
        return ActionErrorCategory.notFound;
      }
      
      if (errorMsg.contains('already exists') ||
          errorMsg.contains('duplicate') ||
          errorMsg.contains('conflict')) {
        return ActionErrorCategory.conflict;
      }
      
      if (errorMsg.contains('invalid') ||
          errorMsg.contains('validation') ||
          errorMsg.contains('required')) {
        return ActionErrorCategory.validation;
      }
      
      if (errorMsg.contains('server') ||
          errorMsg.contains('500') ||
          errorMsg.contains('503')) {
        return ActionErrorCategory.server;
      }
    }
    
    // Categorize based on exception type
    if (error is Exception) {
      final errorStr = error.toString().toLowerCase();
      
      if (errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('timeout') ||
          errorStr.contains('socket')) {
        return ActionErrorCategory.network;
      }
      
      if (errorStr.contains('permission') ||
          errorStr.contains('denied') ||
          errorStr.contains('unauthorized')) {
        return ActionErrorCategory.permission;
      }
    }
    
    return ActionErrorCategory.unknown;
  }
  
  /// Check if an error is retryable
  static bool isRetryable(ActionErrorCategory category) {
    return category == ActionErrorCategory.network ||
        category == ActionErrorCategory.server;
  }
  
  /// Check if an error is retryable based on error and result
  static bool canRetry(dynamic error, ActionResult? result) {
    final category = categorizeError(error, result);
    return isRetryable(category);
  }
  
  /// Generate user-friendly error message
  static String getUserFriendlyMessage(
    dynamic error,
    ActionResult? result,
    ActionIntent? intent,
  ) {
    final category = categorizeError(error, result);
    final errorMsg = result?.errorMessage ?? error?.toString() ?? 'Unknown error';
    
    switch (category) {
      case ActionErrorCategory.network:
        return 'Connection error. Please check your internet connection and try again.';
      
      case ActionErrorCategory.validation:
        return 'Invalid input. ${_extractValidationDetails(errorMsg)}';
      
      case ActionErrorCategory.permission:
        return 'Permission denied. Please grant the required permissions and try again.';
      
      case ActionErrorCategory.notFound:
        if (intent is AddSpotToListIntent) {
          return 'Could not find the spot or list. Please check that they exist and try again.';
        }
        return 'Resource not found. Please check your input and try again.';
      
      case ActionErrorCategory.conflict:
        if (intent is CreateSpotIntent) {
          return 'A spot with this name already exists. Please use a different name.';
        } else if (intent is CreateListIntent) {
          return 'A list with this name already exists. Please use a different name.';
        }
        return 'This action conflicts with existing data. Please check and try again.';
      
      case ActionErrorCategory.server:
        return 'Server error. Please try again in a moment.';
      
      case ActionErrorCategory.unknown:
      default:
        // Try to extract meaningful message from error
        if (errorMsg.length < 100) {
          return errorMsg;
        }
        return 'An error occurred: ${errorMsg.substring(0, 50)}...';
    }
  }
  
  /// Extract validation details from error message
  static String _extractValidationDetails(String errorMsg) {
    // Try to extract specific validation errors
    if (errorMsg.contains('required')) {
      final match = RegExp(r'required[:\s]+([^,\.]+)', caseSensitive: false).firstMatch(errorMsg);
      if (match != null) {
        return 'Missing required field: ${match.group(1)?.trim()}';
      }
    }
    
    if (errorMsg.contains('invalid')) {
      final match = RegExp(r'invalid[:\s]+([^,\.]+)', caseSensitive: false).firstMatch(errorMsg);
      if (match != null) {
        return 'Invalid value: ${match.group(1)?.trim()}';
      }
    }
    
    return 'Please check your input and try again.';
  }
  
  /// Get retry delay based on attempt number
  /// Uses exponential backoff: 1s, 2s, 4s, 8s, max 30s
  static Duration getRetryDelay(int attemptNumber) {
    final seconds = (1 << (attemptNumber - 1)).clamp(1, 30);
    return Duration(seconds: seconds);
  }
  
  /// Get maximum retry attempts for error category
  static int getMaxRetries(ActionErrorCategory category) {
    switch (category) {
      case ActionErrorCategory.network:
        return 3;
      case ActionErrorCategory.server:
        return 2;
      default:
        return 0; // Don't retry other categories
    }
  }
  
  /// Log error with context
  static void logError(
    dynamic error,
    ActionResult? result,
    ActionIntent? intent, {
    String? context,
  }) {
    final category = categorizeError(error, result);
    final preview = intent != null ? _getIntentPreview(intent) : 'unknown';
    
    developer.log(
      'Action error [${category.name}]: $preview',
      name: _logName,
      error: error,
    );
    
    if (result != null) {
      developer.log(
        'Error message: ${result.errorMessage}',
        name: _logName,
      );
    }
    
    if (context != null) {
      developer.log('Context: $context', name: _logName);
    }
  }
  
  /// Get preview of intent for logging
  static String _getIntentPreview(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return 'CreateSpot: ${intent.name}';
    } else if (intent is CreateListIntent) {
      return 'CreateList: ${intent.title}';
    } else if (intent is AddSpotToListIntent) {
      return 'AddSpotToList: ${intent.spotId} -> ${intent.listId}';
    } else if (intent is CreateEventIntent) {
      return 'CreateEvent: ${intent.title ?? intent.templateId}';
    }
    return intent.type;
  }
}

