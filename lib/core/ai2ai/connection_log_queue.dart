import 'dart:developer' as developer;
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'dart:convert';
import 'package:spots/core/models/connection_metrics.dart';

/// OUR_GUTS.md: "Cloud is optional enhancement"
/// Philosophy: Key works offline, cloud adds network wisdom
/// Queues AI2AI connection logs for sync when online
class ConnectionLogQueue {
  static const String _logName = 'ConnectionLogQueue';
  static const String _queueKey = 'connection_log_queue';
  static const int _maxQueueSize = 100;
  
  final SharedPreferencesCompat _prefs;
  
  ConnectionLogQueue(this._prefs);
  
  /// Add connection log to queue
  Future<void> enqueue(ConnectionMetrics connection) async {
    try {
      final queue = await _getQueue();
      
      // Add to queue
      queue.add(connection.toJson());
      
      // Enforce max size (FIFO)
      if (queue.length > _maxQueueSize) {
        queue.removeAt(0);
        developer.log('Queue full, removed oldest', name: _logName);
      }
      
      // Save
      await _saveQueue(queue);
      
      developer.log(
        'Connection log queued: ${connection.connectionId} (${queue.length} in queue)',
        name: _logName,
      );
    } catch (e) {
      developer.log('Error enqueueing connection: $e', name: _logName);
    }
  }
  
  /// Get all queued connections
  Future<List<ConnectionMetrics>> getQueue() async {
    final queue = await _getQueue();
    return queue
        .map((json) => ConnectionMetrics.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Remove connection from queue (after successful sync)
  Future<void> dequeue(String connectionId) async {
    try {
      final queue = await _getQueue();
      queue.removeWhere((json) => 
        (json as Map<String, dynamic>)['connectionId'] == connectionId
      );
      await _saveQueue(queue);
      
      developer.log('Connection dequeued: $connectionId', name: _logName);
    } catch (e) {
      developer.log('Error dequeuing connection: $e', name: _logName);
    }
  }
  
  /// Clear queue (after bulk sync)
  Future<void> clearQueue() async {
    try {
      await _prefs.remove(_queueKey);
      developer.log('Queue cleared', name: _logName);
    } catch (e) {
      developer.log('Error clearing queue: $e', name: _logName);
    }
  }
  
  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await _getQueue();
    return queue.length;
  }
  
  /// Check if queue is empty
  Future<bool> isEmpty() async {
    return await getQueueSize() == 0;
  }
  
  /// Internal: Get queue from storage
  Future<List<dynamic>> _getQueue() async {
    try {
      final jsonString = _prefs.getString(_queueKey);
      if (jsonString == null) return [];
      
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      developer.log('Error loading queue: $e', name: _logName);
      return [];
    }
  }
  
  /// Internal: Save queue to storage
  Future<void> _saveQueue(List<dynamic> queue) async {
    try {
      final jsonString = jsonEncode(queue);
      await _prefs.setString(_queueKey, jsonString);
    } catch (e) {
      developer.log('Error saving queue: $e', name: _logName);
    }
  }
}

