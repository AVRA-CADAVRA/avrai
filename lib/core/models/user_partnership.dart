import 'package:equatable/equatable.dart';
import 'package:spots/core/models/event_partnership.dart';

/// Profile Partnership Type
/// 
/// Represents the type of partnership for profile display purposes.
enum ProfilePartnershipType {
  business,  // EventPartnership with BusinessAccount
  brand,     // Brand sponsorship partnerships
  company,   // Corporate partnerships
}

extension ProfilePartnershipTypeExtension on ProfilePartnershipType {
  String get displayName {
    switch (this) {
      case ProfilePartnershipType.business:
        return 'Business Partnership';
      case ProfilePartnershipType.brand:
        return 'Brand Partnership';
      case ProfilePartnershipType.company:
        return 'Company Partnership';
    }
  }

  static ProfilePartnershipType fromString(String? value) {
    if (value == null) return ProfilePartnershipType.business;
    switch (value.toLowerCase()) {
      case 'business':
        return ProfilePartnershipType.business;
      case 'brand':
        return ProfilePartnershipType.brand;
      case 'company':
        return ProfilePartnershipType.company;
      default:
        return ProfilePartnershipType.business;
    }
  }
}

/// User Partnership Model
/// 
/// Represents a partnership for display on user profiles.
/// Aggregates partnerships from EventPartnership, Brand Sponsorship, and Company partnerships.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to showcasing professional collaborations
/// - Enables visibility of authentic partnerships
/// - Supports expertise recognition through partnerships
class UserPartnership extends Equatable {
  /// Partnership ID
  final String id;
  
  /// Partnership type (business, brand, company)
  final ProfilePartnershipType type;
  
  /// Partner ID (Business ID, Brand ID, or Company ID)
  final String partnerId;
  
  /// Partner name
  final String partnerName;
  
  /// Partner logo URL (optional)
  final String? partnerLogoUrl;
  
  /// Partnership status
  final PartnershipStatus status;
  
  /// Partnership start date
  final DateTime? startDate;
  
  /// Partnership end date (for term-limited partnerships)
  final DateTime? endDate;
  
  /// Category (if applicable)
  final String? category;
  
  /// Vibe compatibility score (0.0 to 1.0)
  final double? vibeCompatibility;
  
  /// Number of events in this partnership
  final int eventCount;
  
  /// Visibility setting (user controls whether to display on profile)
  final bool isPublic;

  const UserPartnership({
    required this.id,
    required this.type,
    required this.partnerId,
    required this.partnerName,
    this.partnerLogoUrl,
    required this.status,
    this.startDate,
    this.endDate,
    this.category,
    this.vibeCompatibility,
    this.eventCount = 0,
    this.isPublic = true,
  });

  /// Check if partnership is active
  bool get isActive => status == PartnershipStatus.active;

  /// Check if partnership is completed
  bool get isCompleted => status == PartnershipStatus.completed;

  /// Check if partnership is ongoing
  /// Ongoing partnerships have a startDate but no endDate (term-limited)
  bool get isOngoing => startDate != null && endDate == null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerLogoUrl': partnerLogoUrl,
      'status': status.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'category': category,
      'vibeCompatibility': vibeCompatibility,
      'eventCount': eventCount,
      'isPublic': isPublic,
    };
  }

  /// Create from JSON
  factory UserPartnership.fromJson(Map<String, dynamic> json) {
    return UserPartnership(
      id: json['id'] as String,
      type: ProfilePartnershipTypeExtension.fromString(json['type'] as String?),
      partnerId: json['partnerId'] as String,
      partnerName: json['partnerName'] as String,
      partnerLogoUrl: json['partnerLogoUrl'] as String?,
      status: PartnershipStatusExtension.fromString(json['status'] as String?),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      category: json['category'] as String?,
      vibeCompatibility: json['vibeCompatibility'] != null
          ? (json['vibeCompatibility'] as num).toDouble()
          : null,
      eventCount: json['eventCount'] as int? ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  /// Create a copy with updated fields
  UserPartnership copyWith({
    String? id,
    ProfilePartnershipType? type,
    String? partnerId,
    String? partnerName,
    String? partnerLogoUrl,
    PartnershipStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    double? vibeCompatibility,
    int? eventCount,
    bool? isPublic,
  }) {
    return UserPartnership(
      id: id ?? this.id,
      type: type ?? this.type,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerLogoUrl: partnerLogoUrl ?? this.partnerLogoUrl,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      vibeCompatibility: vibeCompatibility ?? this.vibeCompatibility,
      eventCount: eventCount ?? this.eventCount,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        partnerId,
        partnerName,
        partnerLogoUrl,
        status,
        startDate,
        endDate,
        category,
        vibeCompatibility,
        eventCount,
        isPublic,
      ];
}

