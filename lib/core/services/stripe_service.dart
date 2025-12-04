import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:spots/core/config/stripe_config.dart';
import 'package:spots/core/services/logger.dart';

/// Stripe Service
/// 
/// Wrapper for Stripe API operations.
/// Handles payment intent creation, confirmation, and error handling.
/// 
/// **Usage:**
/// ```dart
/// final stripeService = StripeService(stripeConfig);
/// await stripeService.initializeStripe();
/// final paymentIntent = await stripeService.createPaymentIntent(
///   amount: 2500, // $25.00 in cents
///   currency: 'usd',
/// );
/// ```
class StripeService {
  static const String _logName = 'StripeService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final StripeConfig _config;
  bool _initialized = false;
  
  StripeService(this._config);
  
  /// Initialize Stripe with publishable key
  /// 
  /// **Throws:**
  /// - `Exception` if configuration is invalid
  /// - `Exception` if Stripe initialization fails
  Future<void> initializeStripe() async {
    try {
      if (!_config.isValid) {
        throw Exception('Invalid Stripe configuration: publishable key is required');
      }
      
      _logger.info('Initializing Stripe...', tag: _logName);
      
      // Set publishable key
      Stripe.publishableKey = _config.publishableKey;
      
      // Set merchant identifier for Apple Pay (if provided)
      if (_config.merchantIdentifier != null) {
        Stripe.merchantIdentifier = _config.merchantIdentifier!;
      }
      
      // Initialize Stripe
      await Stripe.instance.applySettings();
      
      _initialized = true;
      _logger.info('Stripe initialized successfully', tag: _logName);
    } catch (e) {
      _logger.error('Failed to initialize Stripe', error: e, tag: _logName);
      _initialized = false;
      rethrow;
    }
  }
  
  /// Check if Stripe is initialized
  bool get isInitialized => _initialized;
  
  /// Create a payment intent
  /// 
  /// **Note:** This creates a payment intent on the client side.
  /// In production, payment intents should be created on your backend
  /// to keep the secret key secure.
  /// 
  /// **Parameters:**
  /// - `amount`: Amount in cents (e.g., 2500 for $25.00)
  /// - `currency`: Currency code (default: 'usd')
  /// - `metadata`: Optional metadata to attach to payment intent
  /// 
  /// **Returns:**
  /// Payment intent client secret
  /// 
  /// **Throws:**
  /// - `Exception` if Stripe is not initialized
  /// - `StripeException` if payment intent creation fails
  Future<String> createPaymentIntent({
    required int amount,
    String currency = 'usd',
    Map<String, String>? metadata,
  }) async {
    if (!_initialized) {
      throw Exception('Stripe is not initialized. Call initializeStripe() first.');
    }
    
    try {
      _logger.info('Creating payment intent: $amount $currency', tag: _logName);
      
      // In production, this should call your backend API
      // which creates the payment intent server-side using the secret key.
      // For now, this is a placeholder that would need backend integration.
      
      // TODO: Replace with backend API call
      // Example:
      // final response = await http.post(
      //   Uri.parse('$backendUrl/api/payment-intents'),
      //   body: jsonEncode({
      //     'amount': amount,
      //     'currency': currency,
      //     'metadata': metadata,
      //   }),
      // );
      // final data = jsonDecode(response.body);
      // return data['clientSecret'];
      
      throw UnimplementedError(
        'Payment intent creation must be implemented via backend API. '
        'Client-side payment intent creation requires secret key which should never be exposed.'
      );
    } catch (e) {
      _logger.error('Failed to create payment intent', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Confirm payment with payment intent client secret
  /// 
  /// **Parameters:**
  /// - `clientSecret`: Payment intent client secret from backend
  /// - `paymentMethodId`: Payment method ID from Stripe payment sheet
  /// 
  /// **Returns:**
  /// Payment intent status
  /// 
  /// **Throws:**
  /// - `Exception` if Stripe is not initialized
  /// - `StripeException` if payment confirmation fails
  Future<PaymentIntent> confirmPayment({
    required String clientSecret,
    String? paymentMethodId,
  }) async {
    if (!_initialized) {
      throw Exception('Stripe is not initialized. Call initializeStripe() first.');
    }
    
    try {
      _logger.info('Confirming payment: $clientSecret', tag: _logName);
      
      // Confirm payment intent
      // Note: Stripe API v11+ requires all named parameters
      // If paymentMethodId is provided, use it; otherwise confirm with clientSecret only
      final paymentIntent = paymentMethodId != null
          ? await Stripe.instance.confirmPayment(
              paymentIntentClientSecret: clientSecret,
              data: PaymentMethodParams.card(
                paymentMethodData: PaymentMethodData(),
              ),
            )
          : await Stripe.instance.confirmPayment(
              paymentIntentClientSecret: clientSecret,
            );
      
      _logger.info('Payment confirmed: ${paymentIntent.id}', tag: _logName);
      return paymentIntent;
    } catch (e) {
      _logger.error('Failed to confirm payment', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Process refund for a payment intent
  /// 
  /// **Note:** In production, refunds should be processed server-side via backend API
  /// to keep the secret key secure. This is a placeholder for client-side integration.
  /// 
  /// **Parameters:**
  /// - `paymentIntentId`: Stripe payment intent ID to refund
  /// - `amount`: Amount to refund in cents (optional, full refund if not provided)
  /// - `reason`: Reason for refund (optional)
  /// 
  /// **Returns:**
  /// Stripe refund ID
  /// 
  /// **Throws:**
  /// - `Exception` if Stripe is not initialized
  /// - `StripeException` if refund processing fails
  Future<String> processRefund({
    required String paymentIntentId,
    int? amount,
    String? reason,
  }) async {
    if (!_initialized) {
      throw Exception('Stripe is not initialized. Call initializeStripe() first.');
    }
    
    try {
      _logger.info('Processing refund: paymentIntent=$paymentIntentId, amount=$amount', tag: _logName);
      
      // In production, this should call your backend API
      // which processes the refund server-side using the secret key.
      // For now, this is a placeholder that would need backend integration.
      
      // TODO: Replace with backend API call
      // Example:
      // final response = await http.post(
      //   Uri.parse('$backendUrl/api/refunds'),
      //   body: jsonEncode({
      //     'paymentIntentId': paymentIntentId,
      //     'amount': amount,
      //     'reason': reason,
      //   }),
      // );
      // final data = jsonDecode(response.body);
      // return data['refundId'];
      
      // For now, generate a mock refund ID
      // In production, this will be the actual Stripe refund ID from backend
      final mockRefundId = 're_${paymentIntentId.substring(3)}_${DateTime.now().millisecondsSinceEpoch}';
      _logger.info('Refund processed (mock): $mockRefundId', tag: _logName);
      return mockRefundId;
    } catch (e) {
      _logger.error('Failed to process refund', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Handle payment errors
  /// 
  /// Converts Stripe exceptions to user-friendly error messages.
  String handlePaymentError(dynamic error) {
    if (error is StripeException) {
      return error.error.message ?? 'Payment failed. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

