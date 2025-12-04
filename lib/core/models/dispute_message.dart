import 'package:equatable/equatable.dart';

/// Dispute Message Model
/// 
/// Represents a single message in a dispute conversation thread.
/// 
/// **Philosophy Alignment:**
/// - Enables transparent communication
/// - Supports dispute resolution process
/// - Maintains conversation history
/// 
/// **Usage:**
/// ```dart
/// final message = DisputeMessage(
///   id: 'message-123',
///   disputeId: 'dispute-456',
///   userId: 'user-789',
///   content: 'I did not receive my refund',
///   attachments: ['receipt.pdf'],
/// );
/// ```
class DisputeMessage extends Equatable {
  /// Unique message identifier
  final String id;
  
  /// Dispute ID this message belongs to
  final String disputeId;
  
  /// User ID who sent the message
  final String userId;
  
  /// Message content
  final String content;
  
  /// File attachments (URLs or file IDs)
  final List<String> attachments;
  
  /// Whether message is from admin
  final bool isAdminMessage;
  
  /// Whether message is internal (not visible to other party)
  final bool isInternal;
  
  /// When message was created
  final DateTime createdAt;
  
  /// When message was last updated
  final DateTime updatedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const DisputeMessage({
    required this.id,
    required this.disputeId,
    required this.userId,
    required this.content,
    this.attachments = const [],
    this.isAdminMessage = false,
    this.isInternal = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  DisputeMessage copyWith({
    String? id,
    String? disputeId,
    String? userId,
    String? content,
    List<String>? attachments,
    bool? isAdminMessage,
    bool? isInternal,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DisputeMessage(
      id: id ?? this.id,
      disputeId: disputeId ?? this.disputeId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      isAdminMessage: isAdminMessage ?? this.isAdminMessage,
      isInternal: isInternal ?? this.isInternal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disputeId': disputeId,
      'userId': userId,
      'content': content,
      'attachments': attachments,
      'isAdminMessage': isAdminMessage,
      'isInternal': isInternal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory DisputeMessage.fromJson(Map<String, dynamic> json) {
    return DisputeMessage(
      id: json['id'] as String,
      disputeId: json['disputeId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      attachments: List<String>.from(json['attachments'] ?? []),
      isAdminMessage: json['isAdminMessage'] as bool? ?? false,
      isInternal: json['isInternal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Check if message has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        disputeId,
        userId,
        content,
        attachments,
        isAdminMessage,
        isInternal,
        createdAt,
        updatedAt,
        metadata,
      ];
}

