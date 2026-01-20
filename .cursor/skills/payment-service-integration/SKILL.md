---
name: payment-service-integration
description: Guides payment service integration: Stripe integration, event ticketing, revenue splits, refund handling. Use when implementing payment processing, ticketing, or financial transactions.
---

# Payment Service Integration

## Core Components

### Payment Service
Handles payment processing, Stripe integration, and transaction management.

### Event Ticketing
Manages event tickets, pricing, and ticket sales.

### Revenue Splits
Handles multi-party revenue sharing for partnerships.

## Stripe Integration Pattern

```dart
/// Payment Service with Stripe
class PaymentService {
  final StripeService _stripeService;
  
  /// Process payment for reservation
  Future<PaymentResult> processPayment({
    required Reservation reservation,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Create Stripe payment intent
      final paymentIntent = await _stripeService.createPaymentIntent(
        amount: reservation.totalAmount,
        currency: 'usd',
        paymentMethodId: paymentMethod.id,
      );
      
      // Confirm payment
      final confirmed = await _stripeService.confirmPayment(paymentIntent.id);
      
      if (confirmed.status == 'succeeded') {
        return PaymentResult.success(
          transactionId: confirmed.id,
          amount: reservation.totalAmount,
        );
      } else {
        return PaymentResult.failure('Payment failed: ${confirmed.status}');
      }
    } catch (e, st) {
      developer.log('Payment processing failed', error: e, stackTrace: st);
      return PaymentResult.failure('Payment processing error');
    }
  }
}
```

## Event Ticketing Pattern

```dart
/// Create event ticket payment
Future<TicketPurchaseResult> purchaseEventTickets({
  required String eventId,
  required int ticketCount,
  required PaymentMethod paymentMethod,
}) async {
  final event = await _eventService.getEvent(eventId);
  
  // Calculate total amount (includes platform fee)
  final ticketPrice = event.ticketPrice;
  final subtotal = ticketPrice * ticketCount;
  final platformFee = subtotal * 0.10; // 10% platform fee
  final total = subtotal + platformFee;
  
  // Process payment
  final paymentResult = await _paymentService.processPayment(
    amount: total,
    paymentMethod: paymentMethod,
  );
  
  if (paymentResult.isSuccess) {
    // Create tickets
    final tickets = await _ticketService.createTickets(
      eventId: eventId,
      ticketCount: ticketCount,
      transactionId: paymentResult.transactionId,
    );
    
    return TicketPurchaseResult.success(tickets);
  } else {
    return TicketPurchaseResult.failure(paymentResult.error);
  }
}
```

## Revenue Split Pattern

```dart
/// Calculate revenue split for multi-party event
Future<RevenueSplit> calculateRevenueSplit({
  required Event event,
  required double totalRevenue,
}) async {
  // Get event partners
  final partners = await _partnershipService.getEventPartners(event.id);
  
  // Calculate splits based on pre-event agreements
  final splits = <RevenueShare>[];
  
  for (final partner in partners) {
    final shareAmount = totalRevenue * partner.revenuePercentage;
    splits.add(RevenueShare(
      partnerId: partner.id,
      amount: shareAmount,
      percentage: partner.revenuePercentage,
    ));
  }
  
  // Platform fee (10%)
  final platformFee = totalRevenue * 0.10;
  splits.add(RevenueShare(
    partnerId: 'platform',
    amount: platformFee,
    percentage: 0.10,
  ));
  
  return RevenueSplit(
    totalRevenue: totalRevenue,
    platformFee: platformFee,
    partnerSplits: splits,
  );
}
```

## Refund Handling

```dart
/// Process refund for cancellation
Future<RefundResult> processRefund({
  required Reservation reservation,
  required CancellationReason reason,
}) async {
  // Check cancellation policy
  final policy = reservation.cancellationPolicy;
  final refundAmount = policy.calculateRefund(
    originalAmount: reservation.totalAmount,
    cancellationTime: DateTime.now(),
    reason: reason,
  );
  
  if (refundAmount > 0) {
    // Process Stripe refund
    final refund = await _stripeService.createRefund(
      paymentIntentId: reservation.paymentIntentId,
      amount: refundAmount,
      reason: reason.toString(),
    );
    
    return RefundResult.success(
      refundId: refund.id,
      amount: refundAmount,
    );
  } else {
    return RefundResult.noRefund('Outside refund window');
  }
}
```

## Reference

- `lib/core/services/payment_service.dart`
- `lib/injection_container_payment.dart`
- `docs/plans/monetization_business_expertise/`
