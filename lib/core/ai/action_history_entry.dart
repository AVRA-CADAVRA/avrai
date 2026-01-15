/// Action History Entry Model
/// 
/// Part of Feature Matrix Phase 1: Action Execution UI & Integration
/// 
/// Represents a single entry in the action history, storing:
/// - The action intent that was executed
/// - The result of the execution
/// - Timestamp of execution
/// - Whether the action can be undone
/// - Whether the action has been undone
library;

import 'package:avrai/core/ai/action_models.dart';

/// Represents a single action history entry
class ActionHistoryEntry {
  /// Unique identifier for this entry
  final String id;
  
  /// The action intent that was executed
  final ActionIntent intent;
  
  /// The result of the action execution
  final ActionResult result;
  
  /// Timestamp when the action was executed
  final DateTime timestamp;
  
  /// Whether this action can be undone
  final bool canUndo;
  
  /// Whether this action has been undone
  final bool isUndone;
  
  /// User ID who executed the action
  final String userId;

  const ActionHistoryEntry({
    required this.id,
    required this.intent,
    required this.result,
    required this.timestamp,
    required this.canUndo,
    this.isUndone = false,
    required this.userId,
  });

  /// Create a copy with updated fields
  ActionHistoryEntry copyWith({
    String? id,
    ActionIntent? intent,
    ActionResult? result,
    DateTime? timestamp,
    bool? canUndo,
    bool? isUndone,
    String? userId,
  }) {
    return ActionHistoryEntry(
      id: id ?? this.id,
      intent: intent ?? this.intent,
      result: result ?? this.result,
      timestamp: timestamp ?? this.timestamp,
      canUndo: canUndo ?? this.canUndo,
      isUndone: isUndone ?? this.isUndone,
      userId: userId ?? this.userId,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intentType': intent.type,
      'intent': _intentToJson(intent),
      'result': _resultToJson(result),
      'timestamp': timestamp.toIso8601String(),
      'canUndo': canUndo,
      'isUndone': isUndone,
      'userId': userId,
    };
  }

  /// Create from JSON
  factory ActionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ActionHistoryEntry(
      id: json['id'] as String,
      intent: _intentFromJson(json['intentType'] as String, json['intent'] as Map<String, dynamic>),
      result: _resultFromJson(json['result'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      canUndo: json['canUndo'] as bool,
      isUndone: json['isUndone'] as bool? ?? false,
      userId: json['userId'] as String,
    );
  }

  /// Convert intent to JSON
  static Map<String, dynamic> _intentToJson(ActionIntent intent) {
    final base = {
      'type': intent.type,
      'confidence': intent.confidence,
      'metadata': intent.metadata,
    };

    if (intent is CreateSpotIntent) {
      return {
        ...base,
        'name': intent.name,
        'description': intent.description,
        'latitude': intent.latitude,
        'longitude': intent.longitude,
        'category': intent.category,
        'address': intent.address,
        'tags': intent.tags,
        'userId': intent.userId,
      };
    } else if (intent is CreateListIntent) {
      return {
        ...base,
        'title': intent.title,
        'description': intent.description,
        'category': intent.category,
        'isPublic': intent.isPublic,
        'tags': intent.tags,
        'userId': intent.userId,
      };
    } else if (intent is AddSpotToListIntent) {
      return {
        ...base,
        'spotId': intent.spotId,
        'listId': intent.listId,
        'userId': intent.userId,
      };
    } else if (intent is CreateEventIntent) {
      return {
        ...base,
        'userId': intent.userId,
        'templateId': intent.templateId,
        'title': intent.title,
        'description': intent.description,
        'startTime': intent.startTime?.toIso8601String(),
        'maxAttendees': intent.maxAttendees,
        'price': intent.price,
        'category': intent.category,
      };
    }

    return base;
  }

  /// Create intent from JSON
  static ActionIntent _intentFromJson(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'create_spot':
        return CreateSpotIntent(
          name: json['name'] as String,
          description: json['description'] as String,
          latitude: json['latitude'] as double,
          longitude: json['longitude'] as double,
          category: json['category'] as String,
          address: json['address'] as String?,
          tags: List<String>.from(json['tags'] as List? ?? []),
          userId: json['userId'] as String,
          confidence: json['confidence'] as double,
          metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        );
      case 'create_list':
        return CreateListIntent(
          title: json['title'] as String,
          description: json['description'] as String,
          category: json['category'] as String?,
          isPublic: json['isPublic'] as bool? ?? true,
          tags: List<String>.from(json['tags'] as List? ?? []),
          userId: json['userId'] as String,
          confidence: json['confidence'] as double,
          metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        );
      case 'add_spot_to_list':
        return AddSpotToListIntent(
          spotId: json['spotId'] as String,
          listId: json['listId'] as String,
          userId: json['userId'] as String,
          confidence: json['confidence'] as double,
          metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        );
      case 'create_event':
        return CreateEventIntent(
          userId: json['userId'] as String,
          templateId: json['templateId'] as String?,
          title: json['title'] as String?,
          description: json['description'] as String?,
          startTime: json['startTime'] != null
              ? DateTime.parse(json['startTime'] as String)
              : null,
          maxAttendees: json['maxAttendees'] as int?,
          price: (json['price'] as num?)?.toDouble(),
          category: json['category'] as String?,
          confidence: json['confidence'] as double,
          metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        );
      default:
        throw ArgumentError('Unknown intent type: $type');
    }
  }

  /// Convert result to JSON
  static Map<String, dynamic> _resultToJson(ActionResult result) {
    return {
      'success': result.success,
      'errorMessage': result.errorMessage,
      'successMessage': result.successMessage,
      'data': result.data,
    };
  }

  /// Create result from JSON
  static ActionResult _resultFromJson(Map<String, dynamic> json) {
    if (json['success'] as bool) {
      return ActionResult.success(
        message: json['successMessage'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      );
    } else {
      return ActionResult.failure(
        error: json['errorMessage'] as String? ?? 'Unknown error',
      );
    }
  }
}

