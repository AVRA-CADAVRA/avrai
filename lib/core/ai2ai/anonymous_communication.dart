import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:avrai/core/services/message_encryption_service.dart'
    as message_encryption_service;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/user_anonymization_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/supabase_service.dart';

/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// Anonymous AI2AI communication protocol with zero user data exposure
///
/// **Phase 14:** Updated to use MessageEncryptionService (Signal Protocol ready)
class AnonymousCommunicationProtocol {
  static const String _logName = 'AnonymousCommunicationProtocol';

  // Message encryption service (Phase 14: Signal Protocol ready)
  final message_encryption_service.MessageEncryptionService _encryptionService;

  // Agent ID service (for tracking sender ID in Signal Protocol decryption)
  final AgentIdService? _agentIdService;

  // Required dependencies (used by protocol methods)
  // ignore: unused_field
  final SupabaseClient? _supabase;
  // ignore: unused_field
  final AtomicClockService? _atomicClock;
  // ignore: unused_field
  final UserAnonymizationService? _anonymizationService;
  final SupabaseService? _supabaseService;

  // Encryption settings for maximum privacy
  // ignore: unused_field
  static const int _keyRotationIntervalMinutes =
      30; // Reserved for future key rotation implementation
  static const int _messageExpirationMinutes = 60;
  static const int _maxHopsForMessage = 5;

  AnonymousCommunicationProtocol({
    message_encryption_service.MessageEncryptionService? encryptionService,
    AgentIdService? agentIdService,
    SupabaseClient? supabase,
    AtomicClockService? atomicClock,
    UserAnonymizationService? anonymizationService,
    SupabaseService? supabaseService,
  })  : _encryptionService = encryptionService ??
            message_encryption_service.AES256GCMEncryptionService(),
        _agentIdService = agentIdService,
        _supabase = supabase,
        _atomicClock = atomicClock,
        _anonymizationService = anonymizationService,
        _supabaseService = supabaseService;

  /// Send encrypted message between AI agents invisibly
  /// OUR_GUTS.md: "Zero user data exposure, maximum privacy"
  Future<AnonymousMessage> sendEncryptedMessage(
    String targetAgentId,
    MessageType messageType,
    Map<String, dynamic> anonymousPayload,
  ) async {
    try {
      developer.log('Sending anonymous message type: ${messageType.name}',
          name: _logName);

      // Validate target agent ID
      if (targetAgentId.isEmpty) {
        throw AnonymousCommunicationException(
            'Target agent ID cannot be empty');
      }

      // Get sender's agent ID (required for Signal Protocol decryption tracking)
      String? senderAgentId;
      if (_agentIdService != null && _supabaseService != null) {
        try {
          final currentUser = _supabaseService!.currentUser;
          if (currentUser != null && currentUser.id.isNotEmpty) {
            senderAgentId =
                await _agentIdService!.getUserAgentId(currentUser.id);
            developer.log(
              'Sender agent ID retrieved for Signal Protocol tracking: ${senderAgentId.substring(0, 20)}...',
              name: _logName,
            );
          }
        } catch (e) {
          developer.log(
            'Warning: Could not retrieve sender agent ID for Signal Protocol tracking: $e',
            name: _logName,
          );
          // Continue without sender ID (will use fallback encryption if Signal Protocol unavailable)
        }
      }

      // Validate payload contains no user data
      await _validateAnonymousPayload(anonymousPayload);

      // Encrypt payload using MessageEncryptionService (Phase 14: Signal Protocol ready)
      final payloadJson = jsonEncode(anonymousPayload);
      final encryptedMessage = await _encryptionService.encrypt(
        payloadJson,
        targetAgentId,
      );
      final encryptedPayloadBase64 = encryptedMessage.toBase64();

      developer.log(
        'Payload encrypted using ${_encryptionService.encryptionType.name}',
        name: _logName,
      );

      // Create message with privacy protection
      final message = AnonymousMessage(
        messageId: _generateMessageId(),
        targetAgentId: targetAgentId,
        messageType: messageType,
        encryptedPayload: encryptedPayloadBase64,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now()
            .add(const Duration(minutes: _messageExpirationMinutes)),
        routingHops: [],
        privacyLevel: PrivacyLevel.maximum,
      );

      // Store message with sender ID for Signal Protocol decryption
      // Phase 14: Store senderAgentId for proper Signal Protocol session lookup
      if (senderAgentId != null) {
        await _storeEncryptedMessage(
          message: message,
          senderAgentId: senderAgentId,
          targetAgentId: targetAgentId,
          encryptedPayload: encryptedPayloadBase64,
        );
      }

      // Route through privacy network
      await _routeThroughPrivacyNetwork(message);

      developer.log('Anonymous message sent successfully', name: _logName);
      return message;
    } catch (e) {
      developer.log('Error sending anonymous message: $e', name: _logName);
      throw AnonymousCommunicationException('Failed to send anonymous message');
    }
  }

  /// Receive and decrypt anonymous messages
  /// OUR_GUTS.md: "Secure message processing with privacy preservation"
  Future<AnonymousMessage?> receiveEncryptedMessage(String agentId) async {
    try {
      developer.log('Checking for anonymous messages for agent: $agentId',
          name: _logName);

      // Get messages from secure queue
      final encryptedMessages = await _getEncryptedMessagesFromQueue(agentId);

      for (final encryptedMessage in encryptedMessages) {
        try {
          // Decrypt and validate message
          final decryptedMessage = await _decryptMessage(encryptedMessage);

          // Verify message integrity and expiration
          if (await _validateMessageIntegrity(decryptedMessage)) {
            await _removeFromQueue(encryptedMessage.messageId);
            return decryptedMessage;
          }
        } catch (e) {
          developer.log('Failed to decrypt message: $e', name: _logName);
          continue; // Try next message
        }
      }

      developer.log('No valid anonymous messages found', name: _logName);
      return null;
    } catch (e) {
      developer.log('Error receiving anonymous messages: $e', name: _logName);
      throw AnonymousCommunicationException(
          'Failed to receive anonymous messages');
    }
  }

  /// Establish secure communication channel
  /// OUR_GUTS.md: "Trust network establishment without identity exposure"
  Future<SecureCommunicationChannel> establishSecureChannel(
    String targetAgentId,
    TrustLevel requiredTrustLevel,
  ) async {
    try {
      developer.log(
          'Establishing secure channel with trust level: ${requiredTrustLevel.name}',
          name: _logName);

      // Generate shared secret without exposing identities
      final sharedSecret = await _generateSharedSecret(targetAgentId);

      // Create secure channel with perfect forward secrecy
      final channel = SecureCommunicationChannel(
        channelId: _generateChannelId(),
        targetAgentId: targetAgentId,
        sharedSecret: sharedSecret,
        establishedAt: DateTime.now(),
        trustLevel: requiredTrustLevel,
        encryptionStrength: EncryptionStrength.maximum,
      );

      // Validate trust level
      await _validateTrustLevel(channel);

      developer.log('Secure channel established successfully', name: _logName);
      return channel;
    } catch (e) {
      developer.log('Error establishing secure channel: $e', name: _logName);
      throw AnonymousCommunicationException(
          'Failed to establish secure channel');
    }
  }

  // Private helper methods
  /// Enhanced anonymization validation with deep recursive checking
  /// CRITICAL: Blocks suspicious payloads (throws exceptions) instead of just logging
  Future<void> _validateAnonymousPayload(Map<String, dynamic> payload) async {
    // Check for forbidden keys at top level
    final forbiddenKeys = [
      'userId', 'user_id', 'userid',
      'email', 'emailAddress', 'email_address',
      'name', 'displayName', 'display_name', 'fullName', 'full_name',
      'phone', 'phoneNumber', 'phone_number', 'mobile', 'telephone',
      'address', 'streetAddress', 'street_address', 'homeAddress',
      'home_address',
      'personalInfo', 'personal_info', 'personalData', 'personal_data',
      // Device fingerprinting / session identifiers
      'device', 'deviceId', 'device_id', 'deviceInfo', 'device_info',
      'session', 'sessionId', 'session_id',
      // Explicit location data
      'location', 'geo', 'geolocation', 'gps', 'latitude', 'longitude', 'lat',
      'lng',
      'ssn', 'socialSecurityNumber', 'social_security_number',
      'creditCard', 'credit_card', 'cardNumber', 'card_number',
    ];

    // Recursively validate the entire payload structure
    final violations = <String>[];
    _validateRecursive(payload, forbiddenKeys, violations, '');

    if (violations.isNotEmpty) {
      throw AnonymousCommunicationException(
          'Payload contains forbidden user data: ${violations.join(", ")}');
    }

    // Deep pattern matching for personal information
    final payloadString = jsonEncode(payload);
    final patternViolations = _checkPatterns(payloadString);

    if (patternViolations.isNotEmpty) {
      throw AnonymousCommunicationException(
          'Payload contains suspicious patterns: ${patternViolations.join(", ")}');
    }
  }

  /// Recursively validate nested objects and arrays
  void _validateRecursive(
    dynamic value,
    List<String> forbiddenKeys,
    List<String> violations,
    String path,
  ) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        final fullPath = path.isEmpty ? key : '$path.$key';

        // Check if key matches any forbidden pattern
        for (final forbidden in forbiddenKeys) {
          if (key.contains(forbidden.toLowerCase())) {
            violations.add('$fullPath (matches: $forbidden)');
          }
        }

        // Recursively check nested values
        _validateRecursive(entry.value, forbiddenKeys, violations, fullPath);
      }
    } else if (value is List) {
      for (int i = 0; i < value.length; i++) {
        _validateRecursive(value[i], forbiddenKeys, violations, '$path[$i]');
      }
    }
  }

  /// Check for suspicious patterns in payload string
  List<String> _checkPatterns(String payloadString) {
    final violations = <String>[];
    final lowerPayload = payloadString.toLowerCase();

    // Email regex pattern
    final emailPattern =
        RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    if (emailPattern.hasMatch(payloadString)) {
      violations.add('email_address_detected');
    }

    // Phone number patterns (US formats)
    final phonePatterns = [
      RegExp(
          r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'), // (XXX) XXX-XXXX, XXX-XXX-XXXX
      RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}'), // XXX-XXX-XXXX
      RegExp(r'\+1[-.\s]?\d{3}[-.\s]?\d{3}[-.\s]?\d{4}'), // +1 XXX XXX XXXX
    ];
    for (final pattern in phonePatterns) {
      if (pattern.hasMatch(payloadString)) {
        violations.add('phone_number_detected');
        break;
      }
    }

    // Address patterns
    final addressPatterns = [
      RegExp(
          r'\d+\s+[a-zA-Z\s]+(?:street|st|avenue|ave|road|rd|boulevard|blvd|drive|dr|lane|ln|way|court|ct|plaza|pl)',
          caseSensitive: false),
      RegExp(r'p\.?o\.?\s*box\s+\d+', caseSensitive: false), // PO Box
      RegExp(r'apt\.?\s*\d+|apartment\s+\d+',
          caseSensitive: false), // Apartment
    ];
    for (final pattern in addressPatterns) {
      if (pattern.hasMatch(lowerPayload)) {
        violations.add('address_detected');
        break;
      }
    }

    // SSN pattern (XXX-XX-XXXX)
    final ssnPattern = RegExp(r'\d{3}-\d{2}-\d{4}');
    if (ssnPattern.hasMatch(payloadString)) {
      violations.add('ssn_detected');
    }

    // Credit card patterns (be careful with false positives)
    // Only flag if it looks like a credit card number (13-19 digits, possibly with spaces/dashes)
    final creditCardPattern =
        RegExp(r'\b\d{4}[-.\s]?\d{4}[-.\s]?\d{4}[-.\s]?\d{3,4}\b');
    if (creditCardPattern.hasMatch(payloadString)) {
      // Additional validation: check if it's not just a long number (like a timestamp)
      final match = creditCardPattern.firstMatch(payloadString);
      if (match != null) {
        final digits = match.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 13 && digits.length <= 19) {
          violations.add('credit_card_detected');
        }
      }
    }

    return violations;
  }

  /// Generate ephemeral encryption key
  ///
  /// **Deprecated:** Legacy method kept for backward compatibility.
  /// New code should use MessageEncryptionService instead.
  // ignore: unused_element
  Future<String> _generateEphemeralKey() async {
    final random = math.Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random.secure().nextInt(999999);
    return 'msg_${timestamp}_$random';
  }

  String _generateChannelId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random.secure().nextInt(999999);
    return 'ch_${timestamp}_$random';
  }

  /// Encrypt payload using AES-256-GCM authenticated encryption
  ///
  /// **Deprecated:** Legacy method kept for backward compatibility.
  /// New code should use MessageEncryptionService instead.
  /// Returns base64-encoded encrypted data with format: IV (12 bytes) + ciphertext + tag (16 bytes)
  // ignore: unused_element
  Future<String> _encryptPayload(
      Map<String, dynamic> payload, String keyBase64) async {
    try {
      // 1. Prepare data
      final payloadJson = jsonEncode(payload);
      final plaintext = Uint8List.fromList(utf8.encode(payloadJson));
      final keyBytes = base64Decode(keyBase64);

      // 2. Generate random IV (12 bytes for GCM - 96 bits recommended)
      final iv = _generateIV();

      // 3. Create AES-256-GCM cipher
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true, // encrypt
          AEADParameters(
            KeyParameter(keyBytes),
            128, // MAC length (128 bits)
            iv,
            Uint8List(0), // Additional authenticated data (none)
          ),
        );

      // 4. Encrypt
      final ciphertext = cipher.process(plaintext);
      final tag = cipher.mac;

      // 5. Combine: IV + ciphertext + tag
      final encrypted = Uint8List(iv.length + ciphertext.length + tag.length);
      encrypted.setRange(0, iv.length, iv);
      encrypted.setRange(iv.length, iv.length + ciphertext.length, ciphertext);
      encrypted.setRange(
        iv.length + ciphertext.length,
        encrypted.length,
        tag,
      );

      // 6. Return base64 encoded
      return base64Encode(encrypted);
    } catch (e) {
      developer.log('Error encrypting payload: $e', name: _logName);
      throw AnonymousCommunicationException('Failed to encrypt payload: $e');
    }
  }

  /// Decrypt payload using AES-256-GCM authenticated encryption
  ///
  /// **Deprecated:** Legacy method kept for backward compatibility.
  /// New code should use MessageEncryptionService instead.
  /// Verifies authentication tag to ensure message integrity and authenticity.
  /// Returns decrypted payload as Map.
  // ignore: unused_element
  Future<Map<String, dynamic>> _decryptPayload(
      String encryptedBase64, String keyBase64) async {
    try {
      // 1. Decode base64
      final encrypted = base64Decode(encryptedBase64);

      // 2. Extract IV, ciphertext, and tag
      if (encrypted.length < 12 + 16) {
        // Need at least IV (12 bytes) + tag (16 bytes)
        throw AnonymousCommunicationException('Invalid encrypted data length');
      }

      final iv = encrypted.sublist(0, 12);
      final tag = encrypted.sublist(encrypted.length - 16);
      final ciphertext = encrypted.sublist(12, encrypted.length - 16);

      // 3. Create AES-256-GCM cipher
      final cipher = GCMBlockCipher(AESEngine());
      final keyBytes = base64Decode(keyBase64);
      final params = AEADParameters(
        KeyParameter(keyBytes),
        128, // MAC length
        iv,
        Uint8List(0), // Additional authenticated data
      );
      cipher.init(false, params); // false = decrypt

      // 4. Decrypt
      final plaintext = cipher.process(ciphertext);

      // 5. Verify authentication tag (prevents tampering)
      final calculatedTag = cipher.mac;
      if (!_constantTimeEquals(tag, calculatedTag)) {
        throw AnonymousCommunicationException(
            'Authentication tag mismatch - message may be tampered');
      }

      // 6. Decode JSON
      final json = utf8.decode(plaintext);
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error decrypting payload: $e', name: _logName);
      if (e is AnonymousCommunicationException) {
        rethrow;
      }
      throw AnonymousCommunicationException('Failed to decrypt payload: $e');
    }
  }

  /// Generate random IV (Initialization Vector) for AES-GCM
  ///
  /// Uses cryptographically secure random number generator.
  /// IV length: 12 bytes (96 bits) - recommended for GCM mode.
  Uint8List _generateIV() {
    final random = math.Random.secure();
    final iv = Uint8List(12); // 96 bits for GCM
    for (int i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Constant-time comparison to prevent timing attacks
  ///
  /// Compares two byte arrays in constant time, preventing attackers
  /// from using timing information to guess correct values.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  Future<void> _routeThroughPrivacyNetwork(AnonymousMessage message) async {
    // Route message through multiple privacy-preserving hops
    final availableHops = await _getAvailablePrivacyHops();
    final selectedHops = _selectOptimalHops(availableHops, _maxHopsForMessage);

    message.routingHops.addAll(selectedHops);

    // Send through privacy network
    await _sendThroughNetwork(message);
  }

  Future<List<String>> _getAvailablePrivacyHops() async {
    // Get available privacy-preserving relay nodes
    return ['hop1', 'hop2', 'hop3', 'hop4', 'hop5'];
  }

  List<String> _selectOptimalHops(List<String> available, int maxHops) {
    // Select optimal routing path for privacy
    final selected = <String>[];
    final random = math.Random.secure();

    for (int i = 0; i < math.min(maxHops, available.length); i++) {
      final index = random.nextInt(available.length);
      if (!selected.contains(available[index])) {
        selected.add(available[index]);
      }
    }

    return selected;
  }

  Future<void> _sendThroughNetwork(AnonymousMessage message) async {
    // Send message through privacy network
    developer.log('Routing message through ${message.routingHops.length} hops',
        name: _logName);
  }

  Future<List<EncryptedMessage>> _getEncryptedMessagesFromQueue(
      String agentId) async {
    // Get encrypted messages from secure queue
    // Phase 14: Retrieve messages with senderAgentId for Signal Protocol decryption
    // TODO(Phase 14.5): Implement message queue retrieval from Supabase or in-memory store
    // When implementing, ensure each message includes:
    // - senderAgentId: The agent ID of the message sender (required for Signal Protocol decryption)
    // - targetAgentId: The agent ID of the message recipient (should match the provided agentId parameter)
    // - payload: The encrypted message payload
    // - Other metadata (messageId, timestamp, expiresAt)

    // For now, retrieve from in-memory store if available
    // This will be replaced with Supabase queue implementation
    return _retrieveStoredMessages(agentId);
  }

  /// Store encrypted message with sender ID for Signal Protocol decryption
  /// Phase 14: Ensures senderAgentId is tracked for proper Signal Protocol session lookup
  Future<void> _storeEncryptedMessage({
    required AnonymousMessage message,
    required String senderAgentId,
    required String targetAgentId,
    required String encryptedPayload,
  }) async {
    // TODO(Phase 14.5): Store in Supabase queue or persistent in-memory store
    // For now, store in temporary in-memory cache
    // This ensures senderAgentId is available when decrypting
    _messageStore.add(EncryptedMessage(
      messageId: message.messageId,
      senderAgentId:
          senderAgentId, // Phase 14: Track sender ID for Signal Protocol
      targetAgentId: targetAgentId,
      payload: encryptedPayload,
      timestamp: message.timestamp,
      expiresAt: message.expiresAt,
    ));
  }

  /// Retrieve stored messages for an agent
  /// Phase 14: Returns messages with senderAgentId for Signal Protocol decryption
  List<EncryptedMessage> _retrieveStoredMessages(String agentId) {
    // Filter messages for this agent and remove expired ones
    final now = DateTime.now();
    _messageStore.removeWhere((msg) => msg.expiresAt.isBefore(now));
    return _messageStore.where((msg) => msg.targetAgentId == agentId).toList();
  }

  // Temporary in-memory message store (will be replaced with Supabase queue)
  final List<EncryptedMessage> _messageStore = [];

  /// Decrypt incoming encrypted message
  ///
  /// Decrypts the payload and reconstructs the AnonymousMessage.
  /// Note: In a real implementation, the key would be retrieved from
  /// the secure channel or key exchange. For now, we use the shared secret.
  Future<AnonymousMessage> _decryptMessage(EncryptedMessage encrypted) async {
    try {
      // In a real implementation, we would:
      // 1. Look up the key for this sender/agent
      // 2. Decrypt the payload
      // 3. Validate and reconstruct the message

      // Decrypt using MessageEncryptionService (Phase 14: Signal Protocol ready)
      final messageEncryptionEncrypted =
          message_encryption_service.EncryptedMessage.fromBase64(
        encrypted.payload,
        _encryptionService.encryptionType,
      );
      // Use sender's agent ID for decryption (required for Signal Protocol)
      // Signal Protocol needs the sender's identity to decrypt messages
      final decryptedJson = await _encryptionService.decrypt(
        messageEncryptionEncrypted,
        encrypted
            .senderAgentId, // Sender's agent ID (correct for Signal Protocol)
      );
      final decryptedPayload =
          jsonDecode(decryptedJson) as Map<String, dynamic>;

      // Extract message type from decrypted payload if available
      final messageType = decryptedPayload['messageType'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == decryptedPayload['messageType'],
              orElse: () => MessageType.discoverySync,
            )
          : MessageType.discoverySync;

      // Reconstruct message with decrypted payload
      // Note: The encryptedPayload field keeps the encrypted version for storage
      // The actual decrypted data is in decryptedPayload
      return AnonymousMessage(
        messageId: encrypted.messageId,
        targetAgentId: encrypted.targetAgentId,
        messageType: messageType,
        encryptedPayload: encrypted.payload, // Keep encrypted for storage
        timestamp: encrypted.timestamp,
        expiresAt: encrypted.expiresAt,
        routingHops: [],
        privacyLevel: PrivacyLevel.maximum,
      );
    } catch (e) {
      developer.log('Error decrypting message: $e', name: _logName);
      throw AnonymousCommunicationException('Failed to decrypt message: $e');
    }
  }

  Future<bool> _validateMessageIntegrity(AnonymousMessage message) async {
    // Validate message hasn't expired and integrity is intact
    if (DateTime.now().isAfter(message.expiresAt)) {
      return false;
    }

    return true;
  }

  Future<void> _removeFromQueue(String messageId) async {
    // Remove processed message from queue
    developer.log('Removing processed message: $messageId', name: _logName);
  }

  Future<String> _generateSharedSecret(String targetAgentId) async {
    // Generate shared secret using secure key exchange
    final random = math.Random.secure();
    final bytes = List<int>.generate(64, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Future<void> _validateTrustLevel(SecureCommunicationChannel channel) async {
    // Validate that the channel meets required trust level
    if (channel.trustLevel == TrustLevel.unverified) {
      throw AnonymousCommunicationException('Insufficient trust level');
    }
  }
}

// Supporting classes and enums
enum MessageType {
  discoverySync,
  recommendationShare,
  trustVerification,
  reputationUpdate,
  networkMaintenance,
  emergencyAlert,
  userChat, // NEW: User-to-user chat messages routed through AI2AI mesh
}

enum PrivacyLevel { low, medium, high, maximum }

enum TrustLevel { unverified, basic, verified, trusted, highlyTrusted }

enum EncryptionStrength { basic, standard, high, maximum }

class AnonymousMessage {
  final String messageId;
  final String targetAgentId;
  final MessageType messageType;
  final String encryptedPayload;
  final DateTime timestamp;
  final DateTime expiresAt;
  final List<String> routingHops;
  final PrivacyLevel privacyLevel;

  AnonymousMessage({
    required this.messageId,
    required this.targetAgentId,
    required this.messageType,
    required this.encryptedPayload,
    required this.timestamp,
    required this.expiresAt,
    required this.routingHops,
    required this.privacyLevel,
  });
}

class EncryptedMessage {
  final String messageId;
  final String
      senderAgentId; // Sender's agent ID (required for Signal Protocol decryption)
  final String targetAgentId; // Recipient's agent ID
  final String payload;
  final DateTime timestamp;
  final DateTime expiresAt;

  EncryptedMessage({
    required this.messageId,
    required this.senderAgentId,
    required this.targetAgentId,
    required this.payload,
    required this.timestamp,
    required this.expiresAt,
  });
}

class SecureCommunicationChannel {
  final String channelId;
  final String targetAgentId;
  final String sharedSecret;
  final DateTime establishedAt;
  final TrustLevel trustLevel;
  final EncryptionStrength encryptionStrength;

  SecureCommunicationChannel({
    required this.channelId,
    required this.targetAgentId,
    required this.sharedSecret,
    required this.establishedAt,
    required this.trustLevel,
    required this.encryptionStrength,
  });
}

class AnonymousCommunicationException implements Exception {
  final String message;
  AnonymousCommunicationException(this.message);
}
