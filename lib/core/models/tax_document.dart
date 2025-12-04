import 'package:equatable/equatable.dart';

/// Tax Form Type Enum
enum TaxFormType {
  form1099K,   // Payment card and third party network transactions
  form1099NEC, // Nonemployee compensation
  formW9,      // Request for taxpayer identification
}

/// Tax Status Enum
enum TaxStatus {
  notRequired,     // Earnings < $600
  pending,         // Needs generation
  generated,       // Document created
  sent,            // Sent to user
  filed,           // Filed with IRS
}

/// Tax Document Model
/// 
/// Represents tax documents generated for users (1099 forms, W-9 requests).
/// 
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables tax reporting accuracy
/// - Supports user trust through transparency
/// 
/// **Usage:**
/// ```dart
/// final taxDoc = TaxDocument(
///   id: 'tax-doc-123',
///   userId: 'user-456',
///   taxYear: 2025,
///   formType: TaxFormType.form1099K,
///   totalEarnings: 1250.00,
///   status: TaxStatus.generated,
///   generatedAt: DateTime.now(),
/// );
/// ```
class TaxDocument extends Equatable {
  /// Unique document identifier
  final String id;
  
  /// User ID this document is for
  final String userId;
  
  /// Tax year (e.g., 2025)
  final int taxYear;
  
  /// Type of tax form
  final TaxFormType formType;
  
  /// Total earnings for this tax year
  final double totalEarnings;
  
  /// Current status of the document
  final TaxStatus status;
  
  /// When document was generated
  final DateTime generatedAt;
  
  /// URL to download document (encrypted, secure storage)
  final String? documentUrl;
  
  /// When document was filed with IRS
  final DateTime? filedWithIRSAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const TaxDocument({
    required this.id,
    required this.userId,
    required this.taxYear,
    required this.formType,
    required this.totalEarnings,
    required this.status,
    required this.generatedAt,
    this.documentUrl,
    this.filedWithIRSAt,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  TaxDocument copyWith({
    String? id,
    String? userId,
    int? taxYear,
    TaxFormType? formType,
    double? totalEarnings,
    TaxStatus? status,
    DateTime? generatedAt,
    String? documentUrl,
    DateTime? filedWithIRSAt,
    Map<String, dynamic>? metadata,
  }) {
    return TaxDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taxYear: taxYear ?? this.taxYear,
      formType: formType ?? this.formType,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      documentUrl: documentUrl ?? this.documentUrl,
      filedWithIRSAt: filedWithIRSAt ?? this.filedWithIRSAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        taxYear,
        formType,
        totalEarnings,
        status,
        generatedAt,
        documentUrl,
        filedWithIRSAt,
        metadata,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taxYear': taxYear,
      'formType': formType.name,
      'totalEarnings': totalEarnings,
      'status': status.name,
      'generatedAt': generatedAt.toIso8601String(),
      'documentUrl': documentUrl,
      'filedWithIRSAt': filedWithIRSAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory TaxDocument.fromJson(Map<String, dynamic> json) {
    return TaxDocument(
      id: json['id'] as String,
      userId: json['userId'] as String,
      taxYear: json['taxYear'] as int,
      formType: TaxFormType.values.firstWhere(
        (e) => e.name == json['formType'],
        orElse: () => TaxFormType.form1099K,
      ),
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      status: TaxStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaxStatus.pending,
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      documentUrl: json['documentUrl'] as String?,
      filedWithIRSAt: json['filedWithIRSAt'] != null
          ? DateTime.parse(json['filedWithIRSAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
