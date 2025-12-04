import 'dart:developer' as developer;
import 'package:spots/core/ai2ai/anonymous_communication.dart';

/// Error handler for anonymization and privacy-related errors
/// 
/// Phase 7, Section 43-44 (7.3.5-6): Data Anonymization & Database Security
/// 
/// Provides user-friendly error messages for AnonymousCommunicationException
/// and other privacy-related errors.
class AnonymizationErrorHandler {
  static const String _logName = 'AnonymizationErrorHandler';
  
  /// Convert AnonymousCommunicationException to user-friendly message
  /// 
  /// Maps technical error messages to clear, actionable user messages
  /// that explain privacy protection without exposing technical details.
  static String getUserFriendlyMessage(AnonymousCommunicationException error) {
    final message = error.message.toLowerCase();
    
    // Check for specific validation failures
    if (message.contains('forbidden user data')) {
      return _handleForbiddenDataError(error.message);
    }
    
    if (message.contains('suspicious patterns')) {
      return _handleSuspiciousPatternError(error.message);
    }
    
    if (message.contains('target agent id cannot be empty')) {
      return 'Connection error: Please select a valid AI connection.';
    }
    
    if (message.contains('failed to send anonymous message')) {
      return 'Privacy protection: Unable to send message. Please check your connection and try again.';
    }
    
    if (message.contains('failed to receive anonymous messages')) {
      return 'Privacy protection: Unable to receive messages. Please check your connection and try again.';
    }
    
    if (message.contains('failed to establish secure channel')) {
      return 'Privacy protection: Unable to establish secure connection. Please try again.';
    }
    
    if (message.contains('insufficient trust level')) {
      return 'Privacy protection: Connection requires higher trust level. Continue building compatibility with this AI.';
    }
    
    // Generic fallback
    return 'Privacy protection: Personal information cannot be shared in AI2AI network. Please check your privacy settings.';
  }
  
  /// Handle forbidden data errors with specific field identification
  static String _handleForbiddenDataError(String technicalMessage) {
    // Extract which fields were detected
    final violations = <String>[];
    
    if (technicalMessage.contains('email') || technicalMessage.contains('email_address')) {
      violations.add('email address');
    }
    if (technicalMessage.contains('phone') || technicalMessage.contains('phone_number')) {
      violations.add('phone number');
    }
    if (technicalMessage.contains('name') || technicalMessage.contains('display_name')) {
      violations.add('name');
    }
    if (technicalMessage.contains('address') || technicalMessage.contains('street_address')) {
      violations.add('address');
    }
    if (technicalMessage.contains('userid') || technicalMessage.contains('user_id')) {
      violations.add('user ID');
    }
    if (technicalMessage.contains('ssn') || technicalMessage.contains('social_security')) {
      violations.add('social security number');
    }
    if (technicalMessage.contains('credit_card') || technicalMessage.contains('card_number')) {
      violations.add('credit card number');
    }
    
    if (violations.isNotEmpty) {
      final fields = violations.join(', ');
      return 'Privacy protection: $fields cannot be shared in AI2AI network. Please remove personal information and try again.';
    }
    
    return 'Privacy protection: Personal information cannot be shared in AI2AI network. Please check your privacy settings.';
  }
  
  /// Handle suspicious pattern detection errors
  static String _handleSuspiciousPatternError(String technicalMessage) {
    final patterns = <String>[];
    
    if (technicalMessage.contains('email_address_detected')) {
      patterns.add('email address');
    }
    if (technicalMessage.contains('phone_number_detected')) {
      patterns.add('phone number');
    }
    if (technicalMessage.contains('address_detected')) {
      patterns.add('address');
    }
    if (technicalMessage.contains('ssn_detected')) {
      patterns.add('social security number');
    }
    if (technicalMessage.contains('credit_card_detected')) {
      patterns.add('credit card number');
    }
    
    if (patterns.isNotEmpty) {
      final detected = patterns.join(', ');
      return 'Privacy protection: Detected $detected in your message. Personal information cannot be shared in AI2AI network.';
    }
    
    return 'Privacy protection: Personal information detected in your message. Please remove personal details and try again.';
  }
  
  /// Get actionable guidance for the error
  /// 
  /// Returns suggestions for how the user can resolve the issue
  static List<String> getActionableGuidance(AnonymousCommunicationException error) {
    final message = error.message.toLowerCase();
    final guidance = <String>[];
    
    if (message.contains('forbidden') || message.contains('suspicious')) {
      guidance.add('Remove any personal information (name, email, phone, address) from your message');
      guidance.add('Use only anonymous identifiers and non-personal data');
      guidance.add('Check your privacy settings to ensure proper anonymization');
    }
    
    if (message.contains('trust level')) {
      guidance.add('Continue building compatibility with this AI connection');
      guidance.add('Higher trust levels are required for certain operations');
      guidance.add('Your AI will automatically establish trust over time');
    }
    
    if (message.contains('connection') || message.contains('channel')) {
      guidance.add('Check your internet connection');
      guidance.add('Ensure device discovery is enabled');
      guidance.add('Try again in a moment');
    }
    
    if (guidance.isEmpty) {
      guidance.add('Check your privacy settings');
      guidance.add('Ensure no personal information is included');
      guidance.add('Try again with anonymous data only');
    }
    
    return guidance;
  }
  
  /// Log error with context
  static void logError(AnonymousCommunicationException error, {String? context}) {
    developer.log(
      'Anonymization error: ${error.message}',
      name: _logName,
      error: error,
    );
    
    if (context != null) {
      developer.log('Context: $context', name: _logName);
    }
  }
  
  /// Check if error is a validation error (user can fix)
  static bool isValidationError(AnonymousCommunicationException error) {
    final message = error.message.toLowerCase();
    return message.contains('forbidden') ||
           message.contains('suspicious') ||
           message.contains('cannot be empty');
  }
  
  /// Check if error is a connection error (may be transient)
  static bool isConnectionError(AnonymousCommunicationException error) {
    final message = error.message.toLowerCase();
    return message.contains('failed to send') ||
           message.contains('failed to receive') ||
           message.contains('failed to establish') ||
           message.contains('connection');
  }
  
  /// Check if error is a trust/security error (requires time/action)
  static bool isTrustError(AnonymousCommunicationException error) {
    final message = error.message.toLowerCase();
    return message.contains('trust level') ||
           message.contains('insufficient');
  }
}

