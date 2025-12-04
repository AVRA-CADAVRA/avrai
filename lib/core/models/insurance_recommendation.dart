import 'package:equatable/equatable.dart';

/// Insurance Recommendation Model
/// 
/// Represents insurance recommendations for event hosts and attendees.
/// Generated based on event type, risk level, and location.
/// 
/// **Philosophy Alignment:**
/// - Supports responsible event hosting
/// - Provides risk protection guidance
/// - Enables informed decision-making
/// 
/// **Usage:**
/// ```dart
/// final insuranceRec = InsuranceRecommendation(
///   eventId: 'event-123',
///   recommendedInsuranceTypes: ['liability', 'accident'],
///   isRecommended: true,
///   reason: 'Outdoor event with physical activity',
///   estimatedCost: 50.00,
/// );
/// ```
class InsuranceRecommendation extends Equatable {
  /// Unique recommendation identifier
  final String id;
  
  /// Event ID this recommendation is for
  final String eventId;
  
  /// Recommended insurance types
  final List<String> recommendedInsuranceTypes;
  
  /// Whether insurance is recommended (vs. optional)
  final bool isRecommended;
  
  /// Reason for recommendation
  final String? reason;
  
  /// Estimated cost range (optional)
  final double? estimatedCostMin;
  
  /// Estimated cost range (optional)
  final double? estimatedCostMax;
  
  /// Insurance provider suggestions (optional)
  final List<String> providerSuggestions;
  
  /// Additional notes
  final String? additionalNotes;
  
  /// When recommendation was created
  final DateTime createdAt;
  
  /// When recommendation was last updated
  final DateTime updatedAt;

  const InsuranceRecommendation({
    required this.id,
    required this.eventId,
    this.recommendedInsuranceTypes = const [],
    this.isRecommended = false,
    this.reason,
    this.estimatedCostMin,
    this.estimatedCostMax,
    this.providerSuggestions = const [],
    this.additionalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  InsuranceRecommendation copyWith({
    String? id,
    String? eventId,
    List<String>? recommendedInsuranceTypes,
    bool? isRecommended,
    String? reason,
    double? estimatedCostMin,
    double? estimatedCostMax,
    List<String>? providerSuggestions,
    String? additionalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InsuranceRecommendation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      recommendedInsuranceTypes:
          recommendedInsuranceTypes ?? this.recommendedInsuranceTypes,
      isRecommended: isRecommended ?? this.isRecommended,
      reason: reason ?? this.reason,
      estimatedCostMin: estimatedCostMin ?? this.estimatedCostMin,
      estimatedCostMax: estimatedCostMax ?? this.estimatedCostMax,
      providerSuggestions:
          providerSuggestions ?? this.providerSuggestions,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'recommendedInsuranceTypes': recommendedInsuranceTypes,
      'isRecommended': isRecommended,
      'reason': reason,
      'estimatedCostMin': estimatedCostMin,
      'estimatedCostMax': estimatedCostMax,
      'providerSuggestions': providerSuggestions,
      'additionalNotes': additionalNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory InsuranceRecommendation.fromJson(Map<String, dynamic> json) {
    return InsuranceRecommendation(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      recommendedInsuranceTypes:
          List<String>.from(json['recommendedInsuranceTypes'] ?? []),
      isRecommended: json['isRecommended'] as bool? ?? false,
      reason: json['reason'] as String?,
      estimatedCostMin: json['estimatedCostMin'] != null
          ? (json['estimatedCostMin'] as num).toDouble()
          : null,
      estimatedCostMax: json['estimatedCostMax'] != null
          ? (json['estimatedCostMax'] as num).toDouble()
          : null,
      providerSuggestions:
          List<String>.from(json['providerSuggestions'] ?? []),
      additionalNotes: json['additionalNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get estimated cost range string
  String? get estimatedCostRange {
    if (estimatedCostMin == null && estimatedCostMax == null) {
      return null;
    }
    if (estimatedCostMin != null && estimatedCostMax != null) {
      return '\$${estimatedCostMin!.toStringAsFixed(2)} - \$${estimatedCostMax!.toStringAsFixed(2)}';
    }
    if (estimatedCostMin != null) {
      return 'From \$${estimatedCostMin!.toStringAsFixed(2)}';
    }
    if (estimatedCostMax != null) {
      return 'Up to \$${estimatedCostMax!.toStringAsFixed(2)}';
    }
    return null;
  }

  /// Check if has cost estimate
  bool get hasCostEstimate =>
      estimatedCostMin != null || estimatedCostMax != null;

  @override
  List<Object?> get props => [
        id,
        eventId,
        recommendedInsuranceTypes,
        isRecommended,
        reason,
        estimatedCostMin,
        estimatedCostMax,
        providerSuggestions,
        additionalNotes,
        createdAt,
        updatedAt,
      ];
}

