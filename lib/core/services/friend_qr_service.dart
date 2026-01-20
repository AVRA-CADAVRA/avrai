// Friend QR Service
//
// Generates and parses QR codes for user friending
// Repurposed from AI2AI fingerprint verification to user-initiated friending

import 'dart:developer' as developer;

/// Friend QR Service
///
/// Generates QR code data for user friending.
/// Users can generate QR codes with their agentId and scan others' QR codes to add friends.
///
/// **QR Format:** `SPOTS:FRIEND:CONNECT:{agentId}:{timestamp}:{signature?}`
///
/// **Features:**
/// - QR code data generation from agentId
/// - Parsing QR codes to extract agentId
/// - Optional signature validation for security
class FriendQRService {
  static const String _logName = 'FriendQRService';
  static const String _qrPrefix = 'SPOTS:FRIEND:CONNECT:';
  static const String _separator = ':';

  /// Generate QR code data for friend connection
  ///
  /// **Format:** `SPOTS:FRIEND:CONNECT:{agentId}:{timestamp}`
  ///
  /// **Parameters:**
  /// - `agentId`: User's agent ID
  ///
  /// **Returns:**
  /// QR code data string (ready for QR code generation library)
  static String generateFriendQRCodeData(String agentId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrData = '$_qrPrefix$agentId$_separator$timestamp';
    
    developer.log(
      'Generated friend QR code data for agentId: ${agentId.length > 10 ? agentId.substring(0, 10) : agentId}...',
      name: _logName,
    );
    
    return qrData;
  }

  /// Parse QR code data to extract friend information
  ///
  /// **Parameters:**
  /// - `qrCodeData`: QR code data string
  ///
  /// **Returns:**
  /// FriendQRData if valid, `null` otherwise
  static FriendQRData? parseFriendQRCodeData(String qrCodeData) {
    try {
      if (!qrCodeData.startsWith(_qrPrefix)) {
        developer.log(
          'QR code data does not start with expected prefix',
          name: _logName,
        );
        return null;
      }

      // Remove prefix: "SPOTS:FRIEND:CONNECT:"
      final data = qrCodeData.substring(_qrPrefix.length);
      
      // Split by separator to get agentId and timestamp
      final parts = data.split(_separator);
      if (parts.length < 2) {
        developer.log(
          'QR code data missing required parts (agentId:timestamp)',
          name: _logName,
        );
        return null;
      }

      final agentId = parts[0];
      final timestampStr = parts[1];
      
      // Parse timestamp
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) {
        developer.log(
          'Invalid timestamp in QR code data: $timestampStr',
          name: _logName,
        );
        return null;
      }

      // Validate agentId format (should start with "agent_")
      if (!agentId.startsWith('agent_')) {
        developer.log(
          'Invalid agentId format: $agentId',
          name: _logName,
        );
        return null;
      }

      developer.log(
        'Parsed friend QR code data: agentId=${agentId.length > 10 ? agentId.substring(0, 10) : agentId}..., timestamp=$timestamp',
        name: _logName,
      );

      return FriendQRData(
        agentId: agentId,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    } catch (e) {
      developer.log(
        'Error parsing friend QR code data: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Validate QR code signature (optional security feature)
  ///
  /// **Note:** This is a placeholder for future signature validation.
  /// Currently returns true if QR code data is valid.
  ///
  /// **Parameters:**
  /// - `qrCodeData`: QR code data string
  ///
  /// **Returns:**
  /// `true` if signature is valid (or if validation is not implemented), `false` otherwise
  static bool validateQRCodeSignature(String qrCodeData) {
    // For now, just validate that the QR code can be parsed
    final data = parseFriendQRCodeData(qrCodeData);
    return data != null;
  }
}

/// Friend QR Data Model
///
/// Represents data extracted from a friend QR code.
class FriendQRData {
  /// Friend's agent ID
  final String agentId;

  /// Timestamp when QR code was generated
  final DateTime timestamp;

  FriendQRData({
    required this.agentId,
    required this.timestamp,
  });

  /// Check if QR code is expired (older than 24 hours)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours > 24;
  }

  /// Get age of QR code in minutes
  int get ageInMinutes {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes;
  }

  @override
  String toString() {
    return 'FriendQRData(agentId: ${agentId.length > 10 ? agentId.substring(0, 10) : agentId}..., timestamp: $timestamp)';
  }
}
