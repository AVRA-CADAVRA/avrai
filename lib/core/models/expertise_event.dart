import 'package:equatable/equatable.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';

/// Expertise Event Model
/// OUR_GUTS.md: "Pins unlock new features, like event hosting"
/// Represents events hosted by experts (tours, workshops, tastings, etc.)
class ExpertiseEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., "Coffee", "Bookstores"
  final ExpertiseEventType eventType;
  final UnifiedUser host; // Expert hosting the event
  final List<String> attendeeIds;
  final int attendeeCount;
  final int maxAttendees;
  final DateTime startTime;
  final DateTime endTime;
  final List<Spot> spots; // Spots visited during event
  final String? location; // Meeting point or location
  final double? latitude;
  final double? longitude;
  final double? price; // Event price (if paid)
  final bool isPaid;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EventStatus status;

  const ExpertiseEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.host,
    this.attendeeIds = const [],
    this.attendeeCount = 0,
    this.maxAttendees = 20,
    required this.startTime,
    required this.endTime,
    this.spots = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.price,
    this.isPaid = false,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
    this.status = EventStatus.upcoming,
  });

  /// Check if event is full
  bool get isFull => attendeeCount >= maxAttendees;

  /// Check if event has started
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Check if event has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Check if user can attend
  bool canUserAttend(String userId) {
    if (hasEnded) return false;
    if (isFull) return false;
    if (attendeeIds.contains(userId)) return false;
    return true;
  }

  /// Get display name for event type
  String getEventTypeDisplayName() {
    switch (eventType) {
      case ExpertiseEventType.tour:
        return 'Expert Tour';
      case ExpertiseEventType.workshop:
        return 'Workshop';
      case ExpertiseEventType.tasting:
        return 'Tasting';
      case ExpertiseEventType.meetup:
        return 'Meetup';
      case ExpertiseEventType.walk:
        return 'Curated Walk';
      case ExpertiseEventType.lecture:
        return 'Lecture';
    }
  }

  /// Get emoji for event type
  String getEventTypeEmoji() {
    switch (eventType) {
      case ExpertiseEventType.tour:
        return '🚶';
      case ExpertiseEventType.workshop:
        return '🎓';
      case ExpertiseEventType.tasting:
        return '🍽️';
      case ExpertiseEventType.meetup:
        return '👥';
      case ExpertiseEventType.walk:
        return '🚶‍♂️';
      case ExpertiseEventType.lecture:
        return '📚';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'eventType': eventType.name,
      'hostId': host.id,
      'attendeeIds': attendeeIds,
      'attendeeCount': attendeeCount,
      'maxAttendees': maxAttendees,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'spotIds': spots.map((s) => s.id).toList(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'isPaid': isPaid,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
    };
  }

  /// Create from JSON
  factory ExpertiseEvent.fromJson(Map<String, dynamic> json, UnifiedUser host) {
    return ExpertiseEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      eventType: ExpertiseEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => ExpertiseEventType.meetup,
      ),
      host: host,
      attendeeIds: List<String>.from(json['attendeeIds'] as List? ?? []),
      attendeeCount: json['attendeeCount'] as int? ?? 0,
      maxAttendees: json['maxAttendees'] as int? ?? 20,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      spots: const [], // Would need to fetch separately
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: EventStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EventStatus.upcoming,
      ),
    );
  }

  /// Copy with method
  ExpertiseEvent copyWith({
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
  }) {
    return ExpertiseEvent(
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
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        eventType,
        host,
        attendeeIds,
        attendeeCount,
        maxAttendees,
        startTime,
        endTime,
        spots,
        location,
        latitude,
        longitude,
        price,
        isPaid,
        isPublic,
        createdAt,
        updatedAt,
        status,
      ];
}

/// Expertise Event Type
enum ExpertiseEventType {
  tour,      // Expert-led tour
  workshop,  // Educational workshop
  tasting,   // Food/drink tasting
  meetup,    // Casual meetup
  walk,      // Curated walk
  lecture,   // Educational lecture
}

/// Event Status
enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}

