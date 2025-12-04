import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/revenue_split.dart';

/// Partnership Event Model
/// 
/// Extends existing ExpertiseEvent model to support partnerships.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to business partnerships
/// - Enables multi-party event hosting
/// - Supports revenue sharing agreements
/// - Creates pathways for business collaboration
/// 
/// **Key Features:**
/// - Extends ExpertiseEvent with partnership support
/// - References partnership and revenue split
/// - Partnership-specific fields
class PartnershipEvent extends ExpertiseEvent {
  /// Partnership reference
  final String? partnershipId;
  final EventPartnership? partnership;
  
  /// Revenue split reference
  final String? revenueSplitId;
  final RevenueSplit? revenueSplit;
  
  /// Partnership-specific fields
  final bool isPartnershipEvent;
  final List<String> partnerIds; // All partner IDs (user + business + sponsors)
  final int partnerCount; // Number of partners

  const PartnershipEvent({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.eventType,
    required super.host,
    super.attendeeIds,
    super.attendeeCount,
    super.maxAttendees,
    required super.startTime,
    required super.endTime,
    super.spots,
    super.location,
    super.latitude,
    super.longitude,
    super.price,
    super.isPaid,
    super.isPublic,
    required super.createdAt,
    required super.updatedAt,
    super.status,
    this.partnershipId,
    this.partnership,
    this.revenueSplitId,
    this.revenueSplit,
    this.isPartnershipEvent = false,
    this.partnerIds = const [],
    this.partnerCount = 0,
  });

  /// Create PartnershipEvent from ExpertiseEvent
  factory PartnershipEvent.fromExpertiseEvent({
    required ExpertiseEvent event,
    String? partnershipId,
    EventPartnership? partnership,
    String? revenueSplitId,
    RevenueSplit? revenueSplit,
    List<String>? partnerIds,
    int? partnerCount,
  }) {
    return PartnershipEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      category: event.category,
      eventType: event.eventType,
      host: event.host,
      attendeeIds: event.attendeeIds,
      attendeeCount: event.attendeeCount,
      maxAttendees: event.maxAttendees,
      startTime: event.startTime,
      endTime: event.endTime,
      spots: event.spots,
      location: event.location,
      latitude: event.latitude,
      longitude: event.longitude,
      price: event.price,
      isPaid: event.isPaid,
      isPublic: event.isPublic,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      status: event.status,
      partnershipId: partnershipId,
      partnership: partnership,
      revenueSplitId: revenueSplitId,
      revenueSplit: revenueSplit,
      isPartnershipEvent: partnershipId != null,
      partnerIds: partnerIds ?? [],
      partnerCount: partnerCount ?? (partnerIds?.length ?? 0),
    );
  }

  /// Check if event has partnership
  bool get hasPartnership => partnershipId != null || partnership != null;

  /// Check if event has revenue split
  bool get hasRevenueSplit => revenueSplitId != null || revenueSplit != null;

  /// Check if revenue split is locked
  bool get isRevenueSplitLocked => revenueSplit?.isLocked ?? false;

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'partnershipId': partnershipId,
      'revenueSplitId': revenueSplitId,
      'isPartnershipEvent': isPartnershipEvent,
      'partnerIds': partnerIds,
      'partnerCount': partnerCount,
    });
    return baseJson;
  }

  /// Create from JSON
  factory PartnershipEvent.fromJson(
    Map<String, dynamic> json,
    UnifiedUser host,
  ) {
    final baseEvent = ExpertiseEvent.fromJson(json, host);
    return PartnershipEvent.fromExpertiseEvent(
      event: baseEvent,
      partnershipId: json['partnershipId'] as String?,
      revenueSplitId: json['revenueSplitId'] as String?,
      partnerIds: List<String>.from(json['partnerIds'] ?? []),
      partnerCount: json['partnerCount'] as int? ?? 0,
    );
  }

  /// Copy with method
  @override
  PartnershipEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    ExpertiseEventType? eventType,
    UnifiedUser? host,
    List<String>? attendeeIds,
    int? attendeeCount,
    int? maxAttendees,
    DateTime? startTime,
    DateTime? endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    double? price,
    bool? isPaid,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventStatus? status,
    String? partnershipId,
    EventPartnership? partnership,
    String? revenueSplitId,
    RevenueSplit? revenueSplit,
    bool? isPartnershipEvent,
    List<String>? partnerIds,
    int? partnerCount,
  }) {
    return PartnershipEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      eventType: eventType ?? this.eventType,
      host: host ?? this.host,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      spots: spots ?? this.spots,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      price: price ?? this.price,
      isPaid: isPaid ?? this.isPaid,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      partnershipId: partnershipId ?? this.partnershipId,
      partnership: partnership ?? this.partnership,
      revenueSplitId: revenueSplitId ?? this.revenueSplitId,
      revenueSplit: revenueSplit ?? this.revenueSplit,
      isPartnershipEvent: isPartnershipEvent ?? this.isPartnershipEvent,
      partnerIds: partnerIds ?? this.partnerIds,
      partnerCount: partnerCount ?? this.partnerCount,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        partnershipId,
        partnership,
        revenueSplitId,
        revenueSplit,
        isPartnershipEvent,
        partnerIds,
        partnerCount,
      ];
}

