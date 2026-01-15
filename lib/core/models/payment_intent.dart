import 'package:equatable/equatable.dart';
import 'package:avrai/core/models/payment_status.dart';

/// Payment Intent Model
///
/// Represents a Stripe payment intent for event ticket purchases.
/// Stores payment intent data from Stripe API.
///
/// **Usage:**
/// ```dart
/// final paymentIntent = PaymentIntent(
///   id: 'pi_1234567890',
///   clientSecret: 'pi_1234567890_secret_abc',
///   amount: 2500, // $25.00 in cents
///   currency: 'usd',
///   status: PaymentStatus.pending,
///   createdAt: DateTime.now(),
/// );
/// ```
class PaymentIntent extends Equatable {
  /// Stripe payment intent ID
  final String id;

  /// Client secret for confirming payment
  final String clientSecret;

  /// Amount in cents (e.g., 2500 for $25.00)
  final int amount;

  /// Currency code (e.g., 'usd', 'eur')
  final String currency;

  /// Current payment intent status
  final PaymentStatus status;

  /// When payment intent was created
  final DateTime createdAt;

  /// When payment intent was last updated
  final DateTime? updatedAt;

  /// Payment method ID (if payment method attached)
  final String? paymentMethodId;

  /// Event ID this payment intent is for
  final String? eventId;

  /// User ID who initiated the payment
  final String? userId;

  /// Optional metadata
  final Map<String, dynamic> metadata;

  /// Capture method for payment intent (Phase 4: Payment holds)
  /// - 'automatic': Charge immediately (default)
  /// - 'manual': Hold payment, capture later (for limited seats/tickets)
  final String? captureMethod;

  const PaymentIntent({
    required this.id,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethodId,
    this.eventId,
    this.userId,
    this.metadata = const {},
    this.captureMethod, // Phase 4: Payment holds
  });

  /// Create a copy with updated fields
  PaymentIntent copyWith({
    String? id,
    String? clientSecret,
    int? amount,
    String? currency,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethodId,
    String? eventId,
    String? userId,
    Map<String, dynamic>? metadata,
    String? captureMethod, // Phase 4: Payment holds
  }) {
    return PaymentIntent(
      id: id ?? this.id,
      clientSecret: clientSecret ?? this.clientSecret,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
      captureMethod: captureMethod ?? this.captureMethod,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientSecret': clientSecret,
      'amount': amount,
      'currency': currency,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paymentMethodId': paymentMethodId,
      'eventId': eventId,
      'userId': userId,
      'metadata': metadata,
      'captureMethod': captureMethod, // Phase 4: Payment holds
    };
  }

  /// Create from JSON
  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] as String,
      clientSecret: json['clientSecret'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      status: PaymentStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      paymentMethodId: json['paymentMethodId'] as String?,
      eventId: json['eventId'] as String?,
      userId: json['userId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      captureMethod: json['captureMethod'] as String?, // Phase 4: Payment holds
    );
  }

  /// Get amount in dollars
  double get amountInDollars => amount / 100.0;

  /// Check if payment intent is in terminal state
  bool get isTerminal => status.isTerminal;

  /// Check if payment intent is successful
  bool get isSuccessful => status.isSuccessful;

  @override
  List<Object?> get props => [
        id,
        clientSecret,
        amount,
        currency,
        status,
        createdAt,
        updatedAt,
        paymentMethodId,
        eventId,
        userId,
        captureMethod, // Phase 4: Payment holds
        metadata,
      ];
}
