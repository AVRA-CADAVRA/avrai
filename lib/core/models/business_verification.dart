import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';

/// Business Verification Model
/// Tracks verification status and documents for business accounts
class BusinessVerification extends Equatable {
  // Sentinel value to distinguish "parameter not provided" from "explicit null".
  static const Object _unset = Object();
  final String id;
  final String businessAccountId;
  final VerificationStatus status;
  final VerificationMethod method;
  
  // Verification Documents
  final String? businessLicenseUrl; // Business license document
  final String? taxIdDocumentUrl; // Tax ID/EIN document
  final String? proofOfAddressUrl; // Utility bill, lease, etc.
  final String? websiteVerificationUrl; // Website screenshot or verification
  final String? socialMediaVerificationUrl; // Social media account verification
  
  // Business Details for Verification
  final String? legalBusinessName;
  final String? taxId; // EIN, SSN, or business tax ID
  final String? businessAddress;
  final String? phoneNumber;
  final String? websiteUrl;
  
  // Verification Metadata
  final String? verifiedBy; // Admin/verifier user ID
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String? notes; // Internal notes
  
  // Submission metadata
  final DateTime submittedAt;
  final DateTime updatedAt;
  
  const BusinessVerification({
    required this.id,
    required this.businessAccountId,
    this.status = VerificationStatus.pending,
    this.method = VerificationMethod.automatic,
    this.businessLicenseUrl,
    this.taxIdDocumentUrl,
    this.proofOfAddressUrl,
    this.websiteVerificationUrl,
    this.socialMediaVerificationUrl,
    this.legalBusinessName,
    this.taxId,
    this.businessAddress,
    this.phoneNumber,
    this.websiteUrl,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.rejectedAt,
    this.notes,
    required this.submittedAt,
    required this.updatedAt,
  });

  factory BusinessVerification.fromJson(Map<String, dynamic> json) {
    return BusinessVerification(
      id: json['id'] as String,
      businessAccountId: json['businessAccountId'] as String,
      status: VerificationStatusExtension.fromString(json['status'] as String? ?? 'pending'),
      method: VerificationMethodExtension.fromString(json['method'] as String? ?? 'automatic'),
      businessLicenseUrl: json['businessLicenseUrl'] as String?,
      taxIdDocumentUrl: json['taxIdDocumentUrl'] as String?,
      proofOfAddressUrl: json['proofOfAddressUrl'] as String?,
      websiteVerificationUrl: json['websiteVerificationUrl'] as String?,
      socialMediaVerificationUrl: json['socialMediaVerificationUrl'] as String?,
      legalBusinessName: json['legalBusinessName'] as String?,
      taxId: json['taxId'] as String?,
      businessAddress: json['businessAddress'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessAccountId': businessAccountId,
      'status': status.name,
      'method': method.name,
      'businessLicenseUrl': businessLicenseUrl,
      'taxIdDocumentUrl': taxIdDocumentUrl,
      'proofOfAddressUrl': proofOfAddressUrl,
      'websiteVerificationUrl': websiteVerificationUrl,
      'socialMediaVerificationUrl': socialMediaVerificationUrl,
      'legalBusinessName': legalBusinessName,
      'taxId': taxId,
      'businessAddress': businessAddress,
      'phoneNumber': phoneNumber,
      'websiteUrl': websiteUrl,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'notes': notes,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BusinessVerification copyWith({
    String? id,
    String? businessAccountId,
    VerificationStatus? status,
    VerificationMethod? method,
    Object? businessLicenseUrl = _unset,
    Object? taxIdDocumentUrl = _unset,
    Object? proofOfAddressUrl = _unset,
    Object? websiteVerificationUrl = _unset,
    Object? socialMediaVerificationUrl = _unset,
    Object? legalBusinessName = _unset,
    Object? taxId = _unset,
    Object? businessAddress = _unset,
    Object? phoneNumber = _unset,
    Object? websiteUrl = _unset,
    Object? verifiedBy = _unset,
    Object? verifiedAt = _unset,
    Object? rejectionReason = _unset,
    Object? rejectedAt = _unset,
    Object? notes = _unset,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    // #region agent log
    // Debug mode: prove whether legalBusinessName (and other nullable fields) were explicitly cleared vs omitted.
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H7',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-business-verification',
        'hypothesisId': 'H7',
        'location': 'lib/core/models/business_verification.dart:BusinessVerification.copyWith',
        'message': 'copyWith nullable field handling',
        'data': {
          'legalBusinessName_param_is_unset': identical(legalBusinessName, _unset),
          'legalBusinessName_param_is_null': legalBusinessName == null,
          'prev_legalBusinessName_is_null': this.legalBusinessName == null,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    return BusinessVerification(
      id: id ?? this.id,
      businessAccountId: businessAccountId ?? this.businessAccountId,
      status: status ?? this.status,
      method: method ?? this.method,
      businessLicenseUrl: identical(businessLicenseUrl, _unset)
          ? this.businessLicenseUrl
          : businessLicenseUrl as String?,
      taxIdDocumentUrl: identical(taxIdDocumentUrl, _unset)
          ? this.taxIdDocumentUrl
          : taxIdDocumentUrl as String?,
      proofOfAddressUrl: identical(proofOfAddressUrl, _unset)
          ? this.proofOfAddressUrl
          : proofOfAddressUrl as String?,
      websiteVerificationUrl: identical(websiteVerificationUrl, _unset)
          ? this.websiteVerificationUrl
          : websiteVerificationUrl as String?,
      socialMediaVerificationUrl: identical(socialMediaVerificationUrl, _unset)
          ? this.socialMediaVerificationUrl
          : socialMediaVerificationUrl as String?,
      legalBusinessName: identical(legalBusinessName, _unset)
          ? this.legalBusinessName
          : legalBusinessName as String?,
      taxId: identical(taxId, _unset) ? this.taxId : taxId as String?,
      businessAddress: identical(businessAddress, _unset)
          ? this.businessAddress
          : businessAddress as String?,
      phoneNumber: identical(phoneNumber, _unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      websiteUrl: identical(websiteUrl, _unset)
          ? this.websiteUrl
          : websiteUrl as String?,
      verifiedBy: identical(verifiedBy, _unset)
          ? this.verifiedBy
          : verifiedBy as String?,
      verifiedAt: identical(verifiedAt, _unset)
          ? this.verifiedAt
          : verifiedAt as DateTime?,
      rejectionReason: identical(rejectionReason, _unset)
          ? this.rejectionReason
          : rejectionReason as String?,
      rejectedAt: identical(rejectedAt, _unset)
          ? this.rejectedAt
          : rejectedAt as DateTime?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if verification is complete
  bool get isComplete {
    return status == VerificationStatus.verified;
  }

  /// Check if verification is pending
  bool get isPending {
    return status == VerificationStatus.pending;
  }

  /// Check if verification was rejected
  bool get isRejected {
    return status == VerificationStatus.rejected;
  }

  /// Get verification progress (0.0 to 1.0)
  double get progress {
    int completed = 0;
    int total = 4;

    if (legalBusinessName != null && legalBusinessName!.isNotEmpty) completed++;
    if (businessAddress != null && businessAddress!.isNotEmpty) completed++;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) completed++;
    if (businessLicenseUrl != null || taxIdDocumentUrl != null || proofOfAddressUrl != null) {
      completed++;
    }

    return completed / total;
  }

  @override
  List<Object?> get props => [
        id,
        businessAccountId,
        status,
        method,
        businessLicenseUrl,
        taxIdDocumentUrl,
        proofOfAddressUrl,
        websiteVerificationUrl,
        socialMediaVerificationUrl,
        legalBusinessName,
        taxId,
        businessAddress,
        phoneNumber,
        websiteUrl,
        verifiedBy,
        verifiedAt,
        rejectionReason,
        rejectedAt,
        notes,
        submittedAt,
        updatedAt,
      ];
}

/// Verification Status
enum VerificationStatus {
  pending,      // Awaiting review
  inReview,    // Under review by admin
  verified,    // Verified and approved
  rejected,    // Rejected (can resubmit)
  expired,     // Verification expired (needs renewal)
}

extension VerificationStatusExtension on VerificationStatus {
  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.inReview:
        return 'In Review';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.expired:
        return 'Expired';
    }
  }

  static VerificationStatus fromString(String? value) {
    if (value == null) return VerificationStatus.pending;
    switch (value.toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'inreview':
      case 'in_review':
        return VerificationStatus.inReview;
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'expired':
        return VerificationStatus.expired;
      default:
        return VerificationStatus.pending;
    }
  }
}

/// Verification Method
enum VerificationMethod {
  automatic,   // Automatic verification (website, social media)
  manual,      // Manual review by admin
  document,    // Document-based verification
  hybrid,      // Combination of methods
}

extension VerificationMethodExtension on VerificationMethod {
  String get displayName {
    switch (this) {
      case VerificationMethod.automatic:
        return 'Automatic';
      case VerificationMethod.manual:
        return 'Manual Review';
      case VerificationMethod.document:
        return 'Document Verification';
      case VerificationMethod.hybrid:
        return 'Hybrid';
    }
  }

  static VerificationMethod fromString(String? value) {
    if (value == null) return VerificationMethod.automatic;
    switch (value.toLowerCase()) {
      case 'automatic':
        return VerificationMethod.automatic;
      case 'manual':
        return VerificationMethod.manual;
      case 'document':
        return VerificationMethod.document;
      case 'hybrid':
        return VerificationMethod.hybrid;
      default:
        return VerificationMethod.automatic;
    }
  }
}

