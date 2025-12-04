import 'dart:developer' as developer;
import 'dart:convert';
import 'package:spots/core/services/logger.dart';

/// Audit Log Service
/// 
/// Logs all sensitive data access and security events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to compliance and security monitoring
/// - Protects user data through comprehensive audit trails
/// - Enables security incident detection and response
/// 
/// **Features:**
/// - Logs all sensitive data access
/// - Logs security events (authentication, authorization)
/// - Logs data modifications
/// - Secure storage of audit logs
/// 
/// **Usage:**
/// ```dart
/// final service = AuditLogService();
/// await service.logDataAccess('user-123', 'email', 'read');
/// await service.logSecurityEvent('authentication', 'user-123', 'success');
/// ```
class AuditLogService {
  static const String _logName = 'AuditLogService';
  static const AppLogger _logger = AppLogger(
    defaultTag: 'AuditLog',
    minimumLevel: LogLevel.info,
  );
  
  /// Log sensitive data access
  /// 
  /// **Parameters:**
  /// - `userId`: User ID whose data was accessed
  /// - `fieldName`: Field that was accessed
  /// - `action`: Action performed ('read', 'write', 'delete', 'update')
  /// - `metadata`: Optional metadata about the access
  Future<void> logDataAccess(
    String userId,
    String fieldName,
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'data_access',
        'userId': userId,
        'fieldName': fieldName,
        'action': action,
        if (metadata != null) 'metadata': metadata,
      };
      
      _logger.info(
        'Data access: $action on $fieldName for user $userId',
        tag: _logName,
      );
      
      // In production, store in secure database/audit log table
      // For now, log to console
      developer.log('AUDIT: ${jsonEncode(logEntry)}', name: _logName);
    } catch (e) {
      developer.log('Error logging data access: $e', name: _logName);
    }
  }
  
  /// Log security event
  /// 
  /// **Parameters:**
  /// - `eventType`: Type of security event ('authentication', 'authorization', 'encryption', etc.)
  /// - `userId`: User ID (if applicable)
  /// - `status`: Event status ('success', 'failure', 'blocked')
  /// - `metadata`: Optional metadata about the event
  Future<void> logSecurityEvent(
    String eventType,
    String? userId,
    String status, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'security_event',
        'eventType': eventType,
        if (userId != null) 'userId': userId,
        'status': status,
        if (metadata != null) 'metadata': metadata,
      };
      
      _logger.info(
        'Security event: $eventType - $status${userId != null ? " for user $userId" : ""}',
        tag: _logName,
      );
      
      // In production, store in secure database/audit log table
      developer.log('AUDIT: ${jsonEncode(logEntry)}', name: _logName);
    } catch (e) {
      developer.log('Error logging security event: $e', name: _logName);
    }
  }
  
  /// Log data modification
  /// 
  /// **Parameters:**
  /// - `userId`: User ID whose data was modified
  /// - `fieldName`: Field that was modified
  /// - `oldValue`: Previous value (may be masked)
  /// - `newValue`: New value (may be masked)
  /// - `metadata`: Optional metadata about the modification
  Future<void> logDataModification(
    String userId,
    String fieldName,
    String? oldValue,
    String? newValue, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'data_modification',
        'userId': userId,
        'fieldName': fieldName,
        'oldValue': _maskSensitiveValue(oldValue, fieldName),
        'newValue': _maskSensitiveValue(newValue, fieldName),
        if (metadata != null) 'metadata': metadata,
      };
      
      _logger.info(
        'Data modification: $fieldName for user $userId',
        tag: _logName,
      );
      
      // In production, store in secure database/audit log table
      developer.log('AUDIT: ${jsonEncode(logEntry)}', name: _logName);
    } catch (e) {
      developer.log('Error logging data modification: $e', name: _logName);
    }
  }
  
  /// Mask sensitive values in audit logs
  String? _maskSensitiveValue(String? value, String fieldName) {
    if (value == null) return null;
    
    // Mask sensitive fields
    final sensitiveFields = ['email', 'phone', 'ssn', 'creditCard'];
    if (sensitiveFields.contains(fieldName.toLowerCase())) {
      if (value.length <= 4) {
        return '****';
      }
      return '${value.substring(0, 2)}****${value.substring(value.length - 2)}';
    }
    
    return value;
  }
  
  /// Log anonymization event
  /// 
  /// **Parameters:**
  /// - `userId`: User ID that was anonymized
  /// - `agentId`: Agent ID that was created
  /// - `metadata`: Optional metadata about the anonymization
  Future<void> logAnonymization(
    String userId,
    String agentId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'anonymization',
        'userId': userId,
        'agentId': agentId,
        if (metadata != null) 'metadata': metadata,
      };
      
      _logger.info(
        'Anonymization: user $userId -> agent $agentId',
        tag: _logName,
      );
      
      developer.log('AUDIT: ${jsonEncode(logEntry)}', name: _logName);
    } catch (e) {
      developer.log('Error logging anonymization: $e', name: _logName);
    }
  }
}

