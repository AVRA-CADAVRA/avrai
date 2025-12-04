import 'package:equatable/equatable.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_intent.dart';
import 'package:spots/core/models/revenue_split.dart';

/// Payment Result Model
/// 
/// Represents the result of a payment transaction attempt.
/// 
/// **Usage:**
/// ```dart
/// final result = await paymentService.purchaseEventTicket(...);
/// if (result.isSuccess) {
///   // Payment successful
///   final payment = result.payment!;
/// } else {
///   // Payment failed
///   final error = result.errorMessage;
/// }
/// ```
class PaymentResult extends Equatable {
  /// Whether payment was successful
  final bool isSuccess;
  
  /// Payment record (if successful)
  final Payment? payment;
  
  /// Payment intent (if created)
  final PaymentIntent? paymentIntent;
  
  /// Revenue split calculation
  final RevenueSplit? revenueSplit;
  
  /// Error message (if failed)
  final String? errorMessage;
  
  /// Error code for programmatic error handling
  final String? errorCode;
  
  /// When result was created
  final DateTime timestamp;

  const PaymentResult({
    required this.isSuccess,
    this.payment,
    this.paymentIntent,
    this.revenueSplit,
    this.errorMessage,
    this.errorCode,
    required this.timestamp,
  });

  /// Create successful payment result
  factory PaymentResult.success({
    required Payment payment,
    PaymentIntent? paymentIntent,
    RevenueSplit? revenueSplit,
  }) {
    return PaymentResult(
      isSuccess: true,
      payment: payment,
      paymentIntent: paymentIntent,
      revenueSplit: revenueSplit,
      timestamp: DateTime.now(),
    );
  }

  /// Create failed payment result
  factory PaymentResult.failure({
    required String errorMessage,
    String? errorCode,
    PaymentIntent? paymentIntent,
  }) {
    return PaymentResult(
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      paymentIntent: paymentIntent,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'payment': payment?.toJson(),
      'paymentIntent': paymentIntent?.toJson(),
      'revenueSplit': revenueSplit?.toJson(),
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      isSuccess: json['isSuccess'] as bool,
      payment: json['payment'] != null
          ? Payment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      paymentIntent: json['paymentIntent'] != null
          ? PaymentIntent.fromJson(json['paymentIntent'] as Map<String, dynamic>)
          : null,
      revenueSplit: json['revenueSplit'] != null
          ? RevenueSplit.fromJson(json['revenueSplit'] as Map<String, dynamic>)
          : null,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [
        isSuccess,
        payment,
        paymentIntent,
        revenueSplit,
        errorMessage,
        errorCode,
        timestamp,
      ];
}

