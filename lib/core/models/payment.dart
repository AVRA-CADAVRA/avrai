import 'package:equatable/equatable.dart';
import 'package:spots/core/models/payment_status.dart';

/// Payment Model
/// 
/// Represents a payment transaction for an event ticket purchase.
/// 
/// **Usage:**
/// ```dart
/// final payment = Payment(
///   id: 'payment-123',
///   eventId: 'event-456',
///   userId: 'user-789',
///   amount: 25.00,
///   status: PaymentStatus.completed,
///   createdAt: DateTime.now(),
///   stripePaymentIntentId: 'pi_1234567890',
/// );
/// ```
class Payment extends Equatable {
  /// Unique payment identifier
  final String id;
  
  /// Event ID this payment is for
  final String eventId;
  
  /// User ID who made the payment
  final String userId;
  
  /// Payment amount in dollars
  final double amount;
  
  /// Current payment status
  final PaymentStatus status;
  
  /// When payment was created
  final DateTime createdAt;
  
  /// When payment was last updated
  final DateTime updatedAt;
  
  /// Stripe payment intent ID (if using Stripe)
  final String? stripePaymentIntentId;
  
  /// Number of tickets purchased
  final int quantity;
  
  /// Optional metadata for additional payment information
  final Map<String, dynamic> metadata;

  const Payment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.stripePaymentIntentId,
    this.quantity = 1,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? eventId,
    String? userId,
    double? amount,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? stripePaymentIntentId,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      quantity: quantity ?? this.quantity,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'amount': amount,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'stripePaymentIntentId': stripePaymentIntentId,
      'quantity': quantity,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Get total amount (amount * quantity)
  double get totalAmount => amount * quantity;

  /// Check if payment is successful
  bool get isSuccessful => status.isSuccessful;

  /// Check if payment is in terminal state
  bool get isTerminal => status.isTerminal;

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        amount,
        status,
        createdAt,
        updatedAt,
        stripePaymentIntentId,
        quantity,
        metadata,
      ];
}

