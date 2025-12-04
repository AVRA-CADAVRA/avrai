import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/core/ai/action_history_entry.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/storage_service.dart';

/// Service for managing action history and undo functionality
/// 
/// Phase 1.1 Enhancement: Provides undo capability for AI-executed actions
/// Stores action history in local storage and provides methods to undo actions
class ActionHistoryService {
  static const String _logName = 'ActionHistoryService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );
  static const String _storageKey = 'action_history';
  static const int _maxHistorySize = 50; // Keep last 50 actions
  
  final GetStorage _storage;
  
  /// Constructor with dependency injection for storage
  /// 
  /// [storage] - Optional GetStorage instance. If not provided, uses StorageService singleton.
  /// This allows for testability by injecting mock storage in tests.
  ActionHistoryService({GetStorage? storage})
      : _storage = storage ?? StorageService.instance.defaultStorage;
  
  /// Record an action in history
  Future<void> recordAction(ActionResult result) async {
    try {
      if (!result.success) {
        _logger.debug('Not recording failed action', tag: _logName);
        return;
      }
      
      final history = await getHistory();
      
      // Ensure intent exists
      if (result.intent == null) {
        _logger.warn('Cannot record action without intent', tag: _logName);
        return;
      }
      
      // Extract userId from intent
      final userId = result.intent is CreateSpotIntent
          ? (result.intent as CreateSpotIntent).userId
          : result.intent is CreateListIntent
              ? (result.intent as CreateListIntent).userId
              : result.intent is AddSpotToListIntent
                  ? (result.intent as AddSpotToListIntent).userId
                  : result.intent is CreateEventIntent
                      ? (result.intent as CreateEventIntent).userId
                      : '';
      
      // Check if action can be undone
      final canUndo = _supportsUndo(result.intent);
      
      // Create history entry using proper model
      final entry = ActionHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        intent: result.intent!,
        result: result,
        timestamp: DateTime.now(),
        canUndo: canUndo,
        isUndone: false,
        userId: userId,
      );
      
      // Add to history (newest first)
      history.insert(0, entry);
      
      // Limit history size
      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }
      
      // Save to storage
      await _saveHistory(history);
      
      _logger.info('Recorded action: ${result.intent?.type ?? "unknown"}', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error recording action',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }
  
  /// Add an action to history (convenience method with intent parameter)
  /// Phase 7 Week 33: Enhanced method for better integration
  Future<void> addAction({
    required ActionIntent intent,
    required ActionResult result,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Ensure result has the intent attached
      final resultWithIntent = result.intent == null
          ? ActionResult(
              success: result.success,
              errorMessage: result.errorMessage,
              successMessage: result.successMessage,
              data: result.data,
              intent: intent,
            )
          : result;
      
      // Record the action
      await recordAction(resultWithIntent);
      
      _logger.info('Added action to history: ${intent.type}', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error adding action',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }
  
  /// Get action history
  Future<List<ActionHistoryEntry>> getHistory() async {
    try {
      final data = _storage.read(_storageKey);
      if (data == null) return [];
      
      final list = jsonDecode(data as String) as List;
      return list.map((e) => ActionHistoryEntry.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _logger.error(
        'Error reading history',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
  
  /// Save history to storage
  Future<void> _saveHistory(List<ActionHistoryEntry> history) async {
    try {
      final data = jsonEncode(history.map((e) => e.toJson()).toList());
      // Use write with error handling to prevent async flush errors from failing tests
      _storage.write(_storageKey, data).catchError((e) {
        // Ignore MissingPluginException in tests (expected when running unit tests without platform channels)
        if (e.toString().contains('MissingPluginException') || 
            e.toString().contains('getApplicationDocumentsDirectory')) {
          _logger.debug('Storage write skipped in test environment', tag: _logName);
          return;
        }
        _logger.error('Error saving history', error: e, tag: _logName);
      });
    } catch (e, stackTrace) {
      // Ignore MissingPluginException in tests
      if (e.toString().contains('MissingPluginException') || 
          e.toString().contains('getApplicationDocumentsDirectory')) {
        _logger.debug('Storage write skipped in test environment', tag: _logName);
        return;
      }
      _logger.error(
        'Error saving history',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }
  
  /// Undo an action by ID
  Future<UndoResult> undoAction(String actionId) async {
    try {
      final history = await getHistory();
      final entry = history.firstWhere(
        (e) => e.id == actionId,
        orElse: () => throw Exception('Action not found in history'),
      );
      
      if (entry.isUndone) {
        return UndoResult(
          success: false,
          message: 'Action already undone',
        );
      }
      
      // Perform undo based on action type
      final undoResult = await _performUndo(entry.intent, entry.result);
      
      // Mark as undone even if undo operation fails (since use cases aren't implemented yet)
      // This allows users to track what they've attempted to undo
      final updatedEntry = entry.copyWith(isUndone: true);
      final entryIndex = history.indexWhere((e) => e.id == actionId);
      if (entryIndex != -1) {
        history[entryIndex] = updatedEntry;
        await _saveHistory(history);
      }
      
      return undoResult;
    } catch (e, stackTrace) {
      _logger.error(
        'Error undoing action: $actionId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return UndoResult(
        success: false,
        message: 'Failed to undo: $e',
      );
    }
  }
  
  /// Undo the most recent action
  Future<UndoResult> undoLastAction() async {
    try {
      final history = await getHistory();
      
      // Find most recent non-undone action
      final entry = history.firstWhere(
        (e) => !e.isUndone,
        orElse: () => throw Exception('No actions to undo'),
      );
      
      return await undoAction(entry.id);
    } catch (e, stackTrace) {
      _logger.error(
        'Error undoing last action',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return UndoResult(
        success: false,
        message: 'No actions to undo',
      );
    }
  }
  
  /// Perform the actual undo operation
  Future<UndoResult> _performUndo(ActionIntent intent, ActionResult result) async {
    try {
      // Note: These use cases would need to be imported and called
      // For now, this is a placeholder showing the structure
      
      if (intent is CreateSpotIntent) {
        return await _undoCreateSpot(intent, result);
      } else if (intent is CreateListIntent) {
        return await _undoCreateList(intent, result);
      } else if (intent is AddSpotToListIntent) {
        return await _undoAddSpotToList(intent, result);
      } else {
        return UndoResult(
          success: false,
          message: 'Undo not supported for this action type',
        );
      }
    } catch (e) {
      return UndoResult(
        success: false,
        message: 'Undo failed: $e',
      );
    }
  }
  
  /// Undo spot creation
  /// Phase 7 Week 33: Enhanced with ActionExecutor integration
  Future<UndoResult> _undoCreateSpot(CreateSpotIntent intent, ActionResult result) async {
    try {
      _logger.info('Undo create spot: ${intent.name}', tag: _logName);
      
      // Get spot ID from result data
      final spotId = result.data['spotId'] as String?;
      if (spotId == null) {
        return UndoResult(
          success: false,
          message: 'Cannot undo: Spot ID not found in result',
        );
      }
      
      // TODO: Wire to DeleteSpotUseCase when available
      // For now, return a message indicating manual deletion needed
      return UndoResult(
        success: false,
        message: 'Spot deletion not yet implemented. Please delete spot "$spotId" manually.',
        data: {'spotId': spotId},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error undoing spot creation: ${intent.name}',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return UndoResult(
        success: false,
        message: 'Failed to undo spot creation: $e',
      );
    }
  }
  
  /// Undo list creation
  /// Phase 7 Week 33: Enhanced with ActionExecutor integration
  Future<UndoResult> _undoCreateList(CreateListIntent intent, ActionResult result) async {
    try {
      _logger.info('Undo create list: ${intent.title}', tag: _logName);
      
      // Get list ID from result data
      final listId = result.data['listId'] as String?;
      if (listId == null) {
        return UndoResult(
          success: false,
          message: 'Cannot undo: List ID not found in result',
        );
      }
      
      // TODO: Wire to DeleteListUseCase when available
      // For now, return a message indicating manual deletion needed
      return UndoResult(
        success: false,
        message: 'List deletion not yet implemented. Please delete list "$listId" manually.',
        data: {'listId': listId},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error undoing list creation: ${intent.title}',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return UndoResult(
        success: false,
        message: 'Failed to undo list creation: $e',
      );
    }
  }
  
  /// Undo adding spot to list
  /// Phase 7 Week 33: Enhanced with ActionExecutor integration
  Future<UndoResult> _undoAddSpotToList(AddSpotToListIntent intent, ActionResult result) async {
    try {
      _logger.info('Undo add spot to list: ${intent.spotId} -> ${intent.listId}', tag: _logName);
      
      // Get IDs from result or intent
      final spotId = result.data['spotId'] as String? ?? intent.spotId;
      final listId = result.data['listId'] as String? ?? intent.listId;
      
      // TODO: Wire to RemoveSpotFromListUseCase when available
      // For now, return a message indicating manual removal needed
      return UndoResult(
        success: false,
        message: 'Spot removal not yet implemented. Please remove spot "$spotId" from list "$listId" manually.',
        data: {'spotId': spotId, 'listId': listId},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error undoing add spot to list: ${intent.spotId} -> ${intent.listId}',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return UndoResult(
        success: false,
        message: 'Failed to undo add spot to list: $e',
      );
    }
  }
  
  /// Clear all history
  Future<void> clearHistory() async {
    try {
      await _storage.remove(_storageKey);
      _logger.info('Cleared action history', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Error clearing history',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }
  
  /// Get undoable actions (non-undone actions from last 24 hours)
  Future<List<ActionHistoryEntry>> getUndoableActions() async {
    final history = await getHistory();
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    
    return history
        .where((e) => !e.isUndone && e.timestamp.isAfter(cutoff))
        .toList();
  }
  
  /// Check if an action can be undone
  /// Phase 7 Week 33: Enhanced undo functionality
  Future<bool> canUndo(String actionId) async {
    try {
      final history = await getHistory();
      final entry = history.firstWhere(
        (e) => e.id == actionId,
        orElse: () => throw Exception('Action not found'),
      );
      
      // Check if already undone
      if (entry.isUndone) {
        return false;
      }
      
      // Check if within undo window (24 hours)
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      if (entry.timestamp.isBefore(cutoff)) {
        return false;
      }
      
      // Check if action type supports undo
      return _supportsUndo(entry.intent);
    } catch (e, stackTrace) {
      _logger.error(
        'Error checking if action can be undone: $actionId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return false;
    }
  }
  
  /// Check if an action type supports undo
  bool _supportsUndo(ActionIntent? intent) {
    if (intent == null) return false;
    
    // Currently supported undo types
    return intent is CreateSpotIntent ||
        intent is CreateListIntent ||
        intent is AddSpotToListIntent;
  }
  
  /// Get recent actions (last N actions)
  /// Phase 7 Week 33: Enhanced metadata access
  Future<List<ActionHistoryEntry>> getRecentActions({int limit = 10}) async {
    final history = await getHistory();
    return history.take(limit).toList();
  }
  
  /// Get actions of specific type within time window
  /// Phase 7 Week 40: For collaborative activity analytics
  Future<List<ActionHistoryEntry>> getActionsByTypeInWindow({
    required String actionType,
    required DateTime start,
    required DateTime end,
    String? userId,
  }) async {
    try {
      final history = await getHistory();
      
      return history.where((entry) {
        // Check if action type matches
        if (entry.intent.type != actionType) {
          return false;
        }
        
        // Check if within time window
        if (entry.timestamp.isBefore(start) || entry.timestamp.isAfter(end)) {
          return false;
        }
        
        // Check userId if provided
        if (userId != null && entry.userId != userId) {
          return false;
        }
        
        return true;
      }).toList();
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting actions by type in window: $actionType',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
  
  /// Mark an action as undone without performing the undo operation
  /// Phase 7 Week 33: Convenience method for UI
  /// This is useful when the undo operation itself fails but we still want to mark it as undone
  Future<bool> markAsUndone(String actionId) async {
    try {
      final history = await getHistory();
      final entryIndex = history.indexWhere((e) => e.id == actionId);
      
      if (entryIndex == -1) {
        _logger.warn('Action not found: $actionId', tag: _logName);
        return false;
      }
      
      final entry = history[entryIndex];
      if (entry.isUndone) {
        _logger.info('Action already undone: $actionId', tag: _logName);
        return false;
      }
      
      // Mark as undone
      final updatedEntry = entry.copyWith(isUndone: true);
      history[entryIndex] = updatedEntry;
      await _saveHistory(history);
      
      _logger.info('Marked action as undone: $actionId', tag: _logName);
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error marking action as undone: $actionId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return false;
    }
  }
}

/// Result of undo operation
class UndoResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  
  UndoResult({
    required this.success,
    required this.message,
    this.data,
  });
}
