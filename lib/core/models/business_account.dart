import 'package:equatable/equatable.dart';
import 'package:spots/core/models/business_expert_preferences.dart';
import 'package:spots/core/models/business_patron_preferences.dart';
import 'package:spots/core/models/business_verification.dart';

/// Business Account Model
/// Represents a business account that can connect with experts
class BusinessAccount extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? description;
  final String? website;
  final String? location;
  final String? phone;
  final String? logoUrl;
  
  // Business type/category
  final String businessType; // e.g., "Restaurant", "Retail", "Service"
  final List<String> categories; // e.g., ["Coffee", "Food", "Dining"]
  
  // Expertise needs - what expertise the business is looking for
  final List<String> requiredExpertise; // Categories of expertise needed
  final List<String> preferredCommunities; // Community IDs the business wants to connect with
  
  // Expert matching preferences (detailed preferences for AI/ML matching)
  final BusinessExpertPreferences? expertPreferences;
  
  // Patron preferences (what types of customers/patrons the business wants)
  final BusinessPatronPreferences? patronPreferences;
  
  // Legacy connection preferences (kept for backwards compatibility)
  final String? preferredLocation; // Geographic preference for experts
  final int? minExpertLevel; // Minimum expertise level (0-5, maps to ExpertiseLevel)
  
  // Status and metadata
  final bool isActive;
  final bool isVerified; // Legacy field - use verification.status instead
  final BusinessVerification? verification; // Verification details
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // User ID who created this business account
  
  // Payment integration
  final String? stripeConnectAccountId; // Stripe Connect account ID for payouts
  
  // Connected experts
  final List<String> connectedExpertIds;
  final List<String> pendingConnectionIds;
  
  const BusinessAccount({
    required this.id,
    required this.name,
    required this.email,
    this.description,
    this.website,
    this.location,
    this.phone,
    this.logoUrl,
    required this.businessType,
    this.categories = const [],
    this.requiredExpertise = const [],
    this.preferredCommunities = const [],
    this.expertPreferences,
    this.patronPreferences,
    this.preferredLocation,
    this.minExpertLevel,
    this.isActive = true,
    this.isVerified = false,
    this.verification,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.connectedExpertIds = const [],
    this.pendingConnectionIds = const [],
    this.stripeConnectAccountId,
  });

  factory BusinessAccount.fromJson(Map<String, dynamic> json) {
    return BusinessAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      description: json['description'] as String?,
      website: json['website'] as String?,
      location: json['location'] as String?,
      phone: json['phone'] as String?,
      logoUrl: json['logoUrl'] as String?,
      businessType: json['businessType'] as String,
      categories: List<String>.from(json['categories'] ?? []),
      requiredExpertise: List<String>.from(json['requiredExpertise'] ?? []),
      preferredCommunities: List<String>.from(json['preferredCommunities'] ?? []),
      expertPreferences: json['expertPreferences'] != null
          ? BusinessExpertPreferences.fromJson(json['expertPreferences'] as Map<String, dynamic>)
          : null,
      patronPreferences: json['patronPreferences'] != null
          ? BusinessPatronPreferences.fromJson(json['patronPreferences'] as Map<String, dynamic>)
          : null,
      preferredLocation: json['preferredLocation'] as String?,
      minExpertLevel: json['minExpertLevel'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      verification: json['verification'] != null
          ? BusinessVerification.fromJson(json['verification'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String,
      connectedExpertIds: List<String>.from(json['connectedExpertIds'] ?? []),
      pendingConnectionIds: List<String>.from(json['pendingConnectionIds'] ?? []),
      stripeConnectAccountId: json['stripeConnectAccountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'description': description,
      'website': website,
      'location': location,
      'phone': phone,
      'logoUrl': logoUrl,
      'businessType': businessType,
      'categories': categories,
      'requiredExpertise': requiredExpertise,
      'preferredCommunities': preferredCommunities,
      'expertPreferences': expertPreferences?.toJson(),
      'patronPreferences': patronPreferences?.toJson(),
      'preferredLocation': preferredLocation,
      'minExpertLevel': minExpertLevel,
      'isActive': isActive,
      'isVerified': isVerified,
      'verification': verification?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'connectedExpertIds': connectedExpertIds,
      'pendingConnectionIds': pendingConnectionIds,
      'stripeConnectAccountId': stripeConnectAccountId,
    };
  }

  BusinessAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? description,
    String? website,
    String? location,
    String? phone,
    String? logoUrl,
    String? businessType,
    List<String>? categories,
    List<String>? requiredExpertise,
    List<String>? preferredCommunities,
    BusinessExpertPreferences? expertPreferences,
    BusinessPatronPreferences? patronPreferences,
    String? preferredLocation,
    int? minExpertLevel,
    bool? isActive,
    bool? isVerified,
    BusinessVerification? verification,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? connectedExpertIds,
    List<String>? pendingConnectionIds,
    String? stripeConnectAccountId,
  }) {
    return BusinessAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      description: description ?? this.description,
      website: website ?? this.website,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      businessType: businessType ?? this.businessType,
      categories: categories ?? this.categories,
      requiredExpertise: requiredExpertise ?? this.requiredExpertise,
      preferredCommunities: preferredCommunities ?? this.preferredCommunities,
      expertPreferences: expertPreferences ?? this.expertPreferences,
      patronPreferences: patronPreferences ?? this.patronPreferences,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      minExpertLevel: minExpertLevel ?? this.minExpertLevel,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      verification: verification ?? this.verification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      connectedExpertIds: connectedExpertIds ?? this.connectedExpertIds,
      pendingConnectionIds: pendingConnectionIds ?? this.pendingConnectionIds,
      stripeConnectAccountId: stripeConnectAccountId ?? this.stripeConnectAccountId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        description,
        website,
        location,
        phone,
        logoUrl,
        businessType,
        categories,
        requiredExpertise,
        preferredCommunities,
        expertPreferences,
        patronPreferences,
        preferredLocation,
        minExpertLevel,
        isActive,
        isVerified,
        verification,
        createdAt,
        updatedAt,
        createdBy,
        connectedExpertIds,
        pendingConnectionIds,
        stripeConnectAccountId,
      ];
}

