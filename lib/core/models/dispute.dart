import 'package:equatable/equatable.dart';
import 'package:spots/core/models/dispute_type.dart';
import 'package:spots/core/models/dispute_status.dart';

/// Dispute Model
/// 
/// Represents a dispute between parties regarding an event or transaction.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to fair dispute resolution
/// - Enables trust through transparent processes
/// - Supports user protection and conflict resolution
/// 
/// **Usage:**
/// ```dart
/// final dispute = Dispute(
///   id: 'dispute-123',
///   eventId: 'event-456',
///   reporterId: 'user-789',
///   reportedId: 'user-012',
///   type: DisputeType.refundDisagreement,
///   description: 'Refund amount incorrect',
///   status: DisputeStatus.submitted,
///   createdAt: DateTime.now(),
/// );
/// ```
class Dispute extends Equatable {
  /// Unique dispute identifier
  final String id;
  
  /// Event ID this dispute is about
  final String eventId;
  
  /// User ID who reported the dispute
  final String reporterId;
  
  /// User ID being reported
  final String reportedId;
  
  /// Type of dispute
  final DisputeType type;
  
  /// Description of the dispute
  final String description;
  
  /// Evidence URLs (photos, screenshots, etc.)
  final List<String> evidenceUrls;
  
  /// When dispute was created
  final DateTime createdAt;
  
  /// Current status
  final DisputeStatus status;
  
  /// Admin ID assigned to review
  final String? assignedAdminId;
  
  /// When dispute was assigned
  final DateTime? assignedAt;
  
  /// When dispute was resolved
  final DateTime? resolvedAt;
  
  /// Resolution description
  final String? resolution;
  
  /// Admin notes (internal)
  final String? adminNotes;
  
  /// Refund amount (if resolution includes refund)
  final double? refundAmount;
  
  /// Resolution details (JSON)
  final Map<String, dynamic>? resolutionDetails;
  
  /// Dispute messages (communication thread)
  final List<DisputeMessage> messages;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const Dispute({
    required this.id,
    required this.eventId,
    required this.reporterId,
    required this.reportedId,
    required this.type,
    required this.description,
    this.evidenceUrls = const [],
    required this.createdAt,
    this.status = DisputeStatus.pending,
    this.assignedAdminId,
    this.assignedAt,
    this.resolvedAt,
    this.resolution,
    this.adminNotes,
    this.refundAmount,
    this.resolutionDetails,
    this.messages = const [],
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  Dispute copyWith({
    String? id,
    String? eventId,
    String? reporterId,
    String? reportedId,
    DisputeType? type,
    String? description,
    List<String>? evidenceUrls,
    DateTime? createdAt,
    DisputeStatus? status,
    String? assignedAdminId,
    DateTime? assignedAt,
    DateTime? resolvedAt,
    String? resolution,
    String? adminNotes,
    double? refundAmount,
    Map<String, dynamic>? resolutionDetails,
    List<DisputeMessage>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return Dispute(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      reporterId: reporterId ?? this.reporterId,
      reportedId: reportedId ?? this.reportedId,
      type: type ?? this.type,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      assignedAt: assignedAt ?? this.assignedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      adminNotes: adminNotes ?? this.adminNotes,
      refundAmount: refundAmount ?? this.refundAmount,
      resolutionDetails: resolutionDetails ?? this.resolutionDetails,
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'reporterId': reporterId,
      'reportedId': reportedId,
      'type': type.name,
      'description': description,
      'evidenceUrls': evidenceUrls,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'assignedAdminId': assignedAdminId,
      'assignedAt': assignedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
      'adminNotes': adminNotes,
      'refundAmount': refundAmount,
      'resolutionDetails': resolutionDetails,
      'messages': messages.map((m) => m.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      reporterId: json['reporterId'] as String,
      reportedId: json['reportedId'] as String,
      type: DisputeType.fromJson(json['type'] as String),
      description: json['description'] as String,
      evidenceUrls: List<String>.from(json['evidenceUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: DisputeStatus.fromJson(json['status'] as String),
      assignedAdminId: json['assignedAdminId'] as String?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolution: json['resolution'] as String?,
      adminNotes: json['adminNotes'] as String?,
      refundAmount: json['refundAmount'] != null
          ? (json['refundAmount'] as num).toDouble()
          : null,
      resolutionDetails: json['resolutionDetails'] != null
          ? Map<String, dynamic>.from(json['resolutionDetails'] as Map)
          : null,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => DisputeMessage.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Check if dispute is resolved
  bool get isResolved => status.isResolved || status.isClosed;

  /// Check if dispute is in progress
  bool get isInProgress => status.isActive;

  @override
  List<Object?> get props => [
        id,
        eventId,
        reporterId,
        reportedId,
        type,
        description,
        evidenceUrls,
        createdAt,
        status,
        assignedAdminId,
        assignedAt,
        resolvedAt,
        resolution,
        adminNotes,
        refundAmount,
        resolutionDetails,
        messages,
        metadata,
      ];
}

/// Dispute Message Model
/// 
/// Represents a message in the dispute communication thread.
class DisputeMessage extends Equatable {
  /// Sender user ID
  final String senderId;
  
  /// Message content
  final String message;
  
  /// When message was sent
  final DateTime timestamp;
  
  /// Whether this is an admin message
  final bool isAdminMessage;
  
  /// Attachments (URLs)
  final List<String>? attachments;

  const DisputeMessage({
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isAdminMessage = false,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isAdminMessage': isAdminMessage,
      'attachments': attachments,
    };
  }

  factory DisputeMessage.fromJson(Map<String, dynamic> json) {
    return DisputeMessage(
      senderId: json['senderId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isAdminMessage: json['isAdminMessage'] as bool? ?? false,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
    );
  }

  @override
  List<Object?> get props => [senderId, message, timestamp, isAdminMessage, attachments];
}
