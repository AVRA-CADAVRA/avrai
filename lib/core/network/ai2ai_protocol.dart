import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/ai/vibe_analysis_engine.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/services/user_anonymization_service.dart';

/// AI2AI Protocol Handler for Phase 6: Physical Layer
/// Handles message encoding/decoding, encryption, and connection management
/// OUR_GUTS.md: "Privacy-preserving AI2AI communication"
class AI2AIProtocol {
  static const String _logName = 'AI2AIProtocol';
  static const String _protocolVersion = '1.0';
  static const String _spotsIdentifier = 'SPOTS-AI2AI';
  
  // Encryption key (should be derived from shared secret in real implementation)
  final Uint8List? _encryptionKey;
  
  // Anonymization service for converting UnifiedUser to AnonymousUser
  final UserAnonymizationService? _anonymizationService;
  
  AI2AIProtocol({
    Uint8List? encryptionKey,
    UserAnonymizationService? anonymizationService,
  }) : _encryptionKey = encryptionKey,
       _anonymizationService = anonymizationService;
  
  /// Encode a message for transmission
  /// 
  /// **CRITICAL:** This method validates that no UnifiedUser data is in the payload.
  /// All user data must be converted to AnonymousUser before calling this method.
  ProtocolMessage encodeMessage({
    required MessageType type,
    required Map<String, dynamic> payload,
    required String senderNodeId,
    String? recipientNodeId,
  }) {
    try {
      // Validate no UnifiedUser in payload (safety check)
      _validateNoUnifiedUserInPayload(payload);
      
      final message = ProtocolMessage(
        version: _protocolVersion,
        type: type,
        senderId: senderNodeId,
        recipientId: recipientNodeId,
        timestamp: DateTime.now(),
        payload: payload,
      );
      
      // Serialize message
      final json = jsonEncode(message.toJson());
      final bytes = utf8.encode(json);
      
      // Encrypt if key available
      Uint8List encryptedBytes;
      if (_encryptionKey != null) {
        encryptedBytes = _encrypt(bytes);
      } else {
        encryptedBytes = Uint8List.fromList(bytes);
      }
      
      // Create protocol packet (for future transport layer implementation)
      final packet = ProtocolPacket(
        identifier: _spotsIdentifier,
        version: _protocolVersion,
        data: encryptedBytes,
        checksum: _calculateChecksum(encryptedBytes),
      );
      
      // Log packet creation for debugging (packet will be used when transport layer is implemented)
      developer.log('Protocol packet created: ${packet.identifier} v${packet.version}, checksum: ${packet.checksum.substring(0, 8)}...', name: _logName);
      
      return message;
    } catch (e) {
      developer.log('Error encoding message: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Decode a received message
  ProtocolMessage? decodeMessage(Uint8List packetData) {
    try {
      // Parse packet header
      final packet = _parsePacket(packetData);
      
      // Verify checksum
      final calculatedChecksum = _calculateChecksum(packet.data);
      if (calculatedChecksum != packet.checksum) {
        developer.log('Checksum mismatch, packet corrupted', name: _logName);
        return null;
      }
      
      // Verify identifier
      if (packet.identifier != _spotsIdentifier) {
        developer.log('Invalid protocol identifier', name: _logName);
        return null;
      }
      
      // Decrypt if key available
      Uint8List decryptedBytes;
      if (_encryptionKey != null) {
        decryptedBytes = _decrypt(packet.data);
      } else {
        decryptedBytes = packet.data;
      }
      
      // Deserialize message
      final json = utf8.decode(decryptedBytes);
      final data = jsonDecode(json) as Map<String, dynamic>;
      
      return ProtocolMessage.fromJson(data);
    } catch (e) {
      developer.log('Error decoding message: $e', name: _logName);
      return null;
    }
  }
  
  /// Create a connection request message
  ProtocolMessage createConnectionRequest({
    required String senderNodeId,
    required String recipientNodeId,
    required AnonymizedVibeData senderVibe,
  }) {
    return encodeMessage(
      type: MessageType.connectionRequest,
      payload: {
        'senderVibe': _vibeDataToJson(senderVibe),
        'requestId': _generateRequestId(),
      },
      senderNodeId: senderNodeId,
      recipientNodeId: recipientNodeId,
    );
  }
  
  /// Create a connection response message
  ProtocolMessage createConnectionResponse({
    required String senderNodeId,
    required String recipientNodeId,
    required String requestId,
    required bool accepted,
    double? compatibilityScore,
    AnonymizedVibeData? recipientVibe,
  }) {
    return encodeMessage(
      type: MessageType.connectionResponse,
      payload: {
        'requestId': requestId,
        'accepted': accepted,
        if (compatibilityScore != null) 'compatibilityScore': compatibilityScore,
        if (recipientVibe != null) 'recipientVibe': _vibeDataToJson(recipientVibe),
      },
      senderNodeId: senderNodeId,
      recipientNodeId: recipientNodeId,
    );
  }
  
  /// Create a learning exchange message
  ProtocolMessage createLearningExchange({
    required String senderNodeId,
    required String recipientNodeId,
    required Map<String, dynamic> learningData,
  }) {
    // Validate no UnifiedUser in payload
    _validateNoUnifiedUserInPayload(learningData);
    
    // Anonymize learning data before transmission
    final anonymizedData = _anonymizeLearningData(learningData);
    
    return encodeMessage(
      type: MessageType.learningExchange,
      payload: {
        'learningData': anonymizedData,
        'timestamp': DateTime.now().toIso8601String(),
      },
      senderNodeId: senderNodeId,
      recipientNodeId: recipientNodeId,
    );
  }

  /// Create a message with AnonymousUser data
  /// 
  /// **CRITICAL:** This method ensures UnifiedUser is converted to AnonymousUser
  /// before transmission. No personal data is shared in AI2AI network.
  /// 
  /// **Parameters:**
  /// - `senderNodeId`: Sender's node ID (agent ID)
  /// - `recipientNodeId`: Recipient's node ID (optional)
  /// - `type`: Message type
  /// - `user`: UnifiedUser to include (will be anonymized)
  /// - `agentId`: Anonymous agent ID (required, must start with "agent_")
  /// - `personalityProfile`: Optional personality profile
  /// - `isAdmin`: If true, allows exact location (godmode/admin access)
  /// 
  /// **Returns:**
  /// ProtocolMessage with AnonymousUser data (no personal information)
  /// 
  /// **Throws:**
  /// - Exception if anonymizationService is not available
  /// - Exception if conversion fails
  Future<ProtocolMessage> createMessageWithUser({
    required String senderNodeId,
    String? recipientNodeId,
    required MessageType type,
    required UnifiedUser user,
    required String agentId,
    PersonalityProfile? personalityProfile,
    bool isAdmin = false,
  }) async {
    if (_anonymizationService == null) {
      throw Exception(
        'UserAnonymizationService not available. Cannot create message with user data. '
        'Use createMessage() with AnonymousUser instead.'
      );
    }

    developer.log('Creating message with UnifiedUser (will be anonymized): ${user.id}', name: _logName);
    
    try {
      // Convert UnifiedUser to AnonymousUser
      final anonymousUser = await _anonymizationService!.anonymizeUser(
        user,
        agentId,
        personalityProfile,
        isAdmin: isAdmin,
      );
      
      // Create payload with AnonymousUser (no personal data)
      final payload = {
        'anonymousUser': anonymousUser.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return encodeMessage(
        type: type,
        payload: payload,
        senderNodeId: senderNodeId,
        recipientNodeId: recipientNodeId,
      );
    } catch (e) {
      developer.log('Error creating message with user: $e', name: _logName);
      rethrow;
    }
  }

  /// Validate that no UnifiedUser is being sent directly in AI2AI network
  /// 
  /// This is a safety check to prevent accidental personal data leaks.
  /// All user data must be converted to AnonymousUser before transmission.
  void _validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    // Check for common UnifiedUser fields that should never appear in AI2AI payloads
    final forbiddenFields = ['id', 'email', 'displayName', 'photoUrl', 'userId'];
    
    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw Exception(
          'CRITICAL: UnifiedUser field "$field" detected in AI2AI payload. '
          'All user data must be converted to AnonymousUser before transmission. '
          'Use createMessageWithUser() method or pass AnonymousUser directly.'
        );
      }
    }
    
    // Recursively check nested objects
    for (final value in payload.values) {
      if (value is Map<String, dynamic>) {
        _validateNoUnifiedUserInPayload(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            _validateNoUnifiedUserInPayload(item);
          }
        }
      }
    }
  }

  /// Encode a message with AnonymousUser (already anonymized)
  /// 
  /// Use this method when you already have an AnonymousUser object.
  /// This is more efficient than createMessageWithUser() if you've already anonymized.
  ProtocolMessage createMessageWithAnonymousUser({
    required String senderNodeId,
    String? recipientNodeId,
    required MessageType type,
    required AnonymousUser anonymousUser,
    Map<String, dynamic>? additionalPayload,
  }) {
    // Validate AnonymousUser contains no personal data
    anonymousUser.validateNoPersonalData();
    
    final payload = <String, dynamic>{
      'anonymousUser': anonymousUser.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
      if (additionalPayload != null) ...additionalPayload,
    };
    
    return encodeMessage(
      type: type,
      payload: payload,
      senderNodeId: senderNodeId,
      recipientNodeId: recipientNodeId,
    );
  }
  
  /// Create a heartbeat message
  ProtocolMessage createHeartbeat({
    required String senderNodeId,
    String? recipientNodeId,
  }) {
    return encodeMessage(
      type: MessageType.heartbeat,
      payload: {
        'timestamp': DateTime.now().toIso8601String(),
      },
      senderNodeId: senderNodeId,
      recipientNodeId: recipientNodeId,
    );
  }
  
  // ========================================================================
  // OFFLINE AI2AI METHODS (Philosophy Implementation - Phase 1)
  // OUR_GUTS.md: "Always Learning With You"
  // Philosophy: The key works everywhere, not just when online
  // ========================================================================
  
  /// Exchange full personality profiles peer-to-peer (offline)
  /// Returns remote device's personality profile
  /// 
  /// Philosophy: "AI2AI = Doors to People"
  /// When your AI connects with someone else's AI, it learns about doors
  /// they've opened. This works completely offline via Bluetooth/NSD.
  Future<PersonalityProfile?> exchangePersonalityProfile(
    String deviceId,
    PersonalityProfile localProfile,
  ) async {
    try {
      // Create personality exchange message
      final message = encodeMessage(
        type: MessageType.personalityExchange,
        payload: {
          'profile': localProfile.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
          'vibeSignature': await _generateVibeSignature(localProfile),
        },
        senderNodeId: deviceId,
      );
      
      // In production, this would send via existing transport layer
      // and wait for response with timeout
      developer.log(
        'Exchanging personality profile with device: $deviceId (message type: ${message.type.name}, payload size: ${message.payload.toString().length} chars)',
        name: _logName,
      );
      
      // Timeout after 5 seconds
      // For now, return null - full transport implementation needed
      // TODO: Implement actual send/receive via Bluetooth/NSD
      // Message is prepared but not sent until transport layer is implemented
      return null;
      
    } catch (e) {
      developer.log(
        'Error exchanging personality profile: $e',
        name: _logName,
      );
      return null;
    }
  }
  
  /// Calculate compatibility between two profiles locally (no cloud)
  /// 
  /// Philosophy: "Always Learning With You"
  /// The AI learns alongside you which doors resonate. This calculation
  /// happens entirely on-device - no network required.
  Future<VibeCompatibilityResult> calculateLocalCompatibility(
    PersonalityProfile local,
    PersonalityProfile remote,
    UserVibeAnalyzer analyzer,
  ) async {
    try {
      // Compile UserVibe for both profiles
      final localVibe = await analyzer.compileUserVibe(local.userId, local);
      final remoteVibe = await analyzer.compileUserVibe(remote.userId, remote);
      
      // Calculate compatibility using existing algorithm
      final compatibility = await analyzer.analyzeVibeCompatibility(
        localVibe,
        remoteVibe,
      );
      
      developer.log(
        'Local compatibility calculated: ${compatibility.basicCompatibility}',
        name: _logName,
      );
      
      return compatibility;
    } catch (e) {
      developer.log(
        'Error calculating local compatibility: $e',
        name: _logName,
      );
      rethrow;
    }
  }
  
  /// Generate learning insights from AI2AI interaction locally
  /// 
  /// Philosophy: "Your doors stay yours"
  /// Learning happens, but with resistance to surface drift. Only significant
  /// differences with high confidence influence your personality.
  Future<AI2AILearningInsight> generateLocalLearningInsights(
    PersonalityProfile local,
    PersonalityProfile remote,
    VibeCompatibilityResult compatibility,
  ) async {
    try {
      final dimensionInsights = <String, double>{};
      final significantDimensions = <String>[];
      
      // Learning algorithm: Compare dimensions
      for (final dimension in remote.dimensions.keys) {
        final localValue = local.dimensions[dimension] ?? 0.0;
        final remoteValue = remote.dimensions[dimension] ?? 0.0;
        final difference = remoteValue - localValue;
        
        // Only learn if difference is significant and confidence high
        final remoteConfidence = remote.dimensionConfidence[dimension] ?? 0.0;
        
        if (difference.abs() > 0.15 && remoteConfidence > 0.7) {
          // Gradual learning - 30% influence
          dimensionInsights[dimension] = difference * 0.3;
          significantDimensions.add(dimension);
        }
      }
      
      // Create learning insight using existing model
      final insight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: dimensionInsights,
        learningQuality: _calculateInsightConfidence(
          dimensionInsights,
          compatibility,
        ),
        timestamp: DateTime.now(),
      );
      
      developer.log(
        'Generated ${dimensionInsights.length} learning insights from offline AI2AI',
        name: _logName,
      );
      
      return insight;
    } catch (e) {
      developer.log(
        'Error generating learning insights: $e',
        name: _logName,
      );
      rethrow;
    }
  }
  
  /// Encrypt data using AES-256-GCM authenticated encryption
  ///
  /// Replaces insecure XOR encryption with proper cryptographic encryption.
  /// Returns encrypted data with format: IV (12 bytes) + ciphertext + tag (16 bytes)
  Uint8List _encrypt(Uint8List data) {
    if (_encryptionKey == null) {
      developer.log('Warning: No encryption key set, returning unencrypted data', name: _logName);
      return data;
    }
    
    try {
      // Generate random IV (12 bytes for GCM - 96 bits recommended)
      final iv = _generateIV();
      
      // Create AES-256-GCM cipher
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true, // encrypt
          AEADParameters(
            KeyParameter(_encryptionKey!),
            128, // MAC length (128 bits)
            iv,
            Uint8List(0), // Additional authenticated data (none)
          ),
        );
      
      // Encrypt
      final ciphertext = cipher.process(data);
      final tag = cipher.mac;
      
      // Combine: IV + ciphertext + tag
      final encrypted = Uint8List(iv.length + ciphertext.length + tag.length);
      encrypted.setRange(0, iv.length, iv);
      encrypted.setRange(iv.length, iv.length + ciphertext.length, ciphertext);
      encrypted.setRange(
        iv.length + ciphertext.length,
        encrypted.length,
        tag,
      );
      
      return encrypted;
    } catch (e) {
      developer.log('Error encrypting data: $e', name: _logName);
      throw Exception('Encryption failed: $e');
    }
  }
  
  /// Decrypt data using AES-256-GCM authenticated encryption
  ///
  /// Verifies authentication tag to ensure message integrity and authenticity.
  Uint8List _decrypt(Uint8List encrypted) {
    if (_encryptionKey == null) {
      developer.log('Warning: No encryption key set, returning data as-is', name: _logName);
      return encrypted;
    }
    
    try {
      // Extract IV, ciphertext, and tag
      if (encrypted.length < 12 + 16) {
        // Need at least IV (12 bytes) + tag (16 bytes)
        throw Exception('Invalid encrypted data length: ${encrypted.length}');
      }
      
      final iv = encrypted.sublist(0, 12);
      final tag = encrypted.sublist(encrypted.length - 16);
      final ciphertext = encrypted.sublist(12, encrypted.length - 16);
      
      // Create AES-256-GCM cipher
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(_encryptionKey!),
        128, // MAC length
        iv,
        Uint8List(0), // Additional authenticated data
      );
      cipher.init(false, params); // false = decrypt
      
      // Decrypt
      final plaintext = cipher.process(ciphertext);
      
      // Verify authentication tag (prevents tampering)
      final calculatedTag = cipher.mac;
      if (!_constantTimeEquals(tag, calculatedTag)) {
        throw Exception('Authentication tag mismatch - message may be tampered');
      }
      
      return plaintext;
    } catch (e) {
      developer.log('Error decrypting data: $e', name: _logName);
      throw Exception('Decryption failed: $e');
    }
  }
  
  /// Generate random IV (Initialization Vector) for AES-GCM
  ///
  /// Uses cryptographically secure random number generator.
  /// IV length: 12 bytes (96 bits) - recommended for GCM mode.
  Uint8List _generateIV() {
    final random = Random.secure();
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
  
  /// Calculate checksum for data integrity
  String _calculateChecksum(Uint8List data) {
    final hash = sha256.convert(data);
    return hash.toString();
  }
  
  /// Parse protocol packet from raw data
  ProtocolPacket _parsePacket(Uint8List data) {
    // Simple packet format: [identifier(12 bytes)][version(4 bytes)][checksum(64 bytes)][data]
    // In production, use a proper binary protocol
    final identifier = utf8.decode(data.sublist(0, 12));
    final version = utf8.decode(data.sublist(12, 16));
    final checksum = utf8.decode(data.sublist(16, 80));
    final payload = data.sublist(80);
    
    return ProtocolPacket(
      identifier: identifier,
      version: version,
      data: payload,
      checksum: checksum,
    );
  }
  
  /// Generate unique request ID
  String _generateRequestId() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(random));
    return hash.toString().substring(0, 16);
  }
  
  /// Anonymize learning data before transmission
  Map<String, dynamic> _anonymizeLearningData(Map<String, dynamic> data) {
    // Remove any identifying information
    final anonymized = Map<String, dynamic>.from(data);
    anonymized.remove('userId');
    anonymized.remove('deviceId');
    anonymized.remove('personalInfo');
    
    // Add differential privacy noise if needed
    // (Simplified for now)
    
    return anonymized;
  }
  
  /// Convert AnonymizedVibeData to JSON
  Map<String, dynamic> _vibeDataToJson(AnonymizedVibeData vibeData) {
    return vibeData.toJson();
  }
  
  // ========================================================================
  // HELPER METHODS FOR OFFLINE AI2AI
  // ========================================================================
  
  /// Generate unique vibe signature for personality profile
  Future<String> _generateVibeSignature(PersonalityProfile profile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dimensions = profile.dimensions.entries
        .map((e) => '${e.key}:${e.value.toStringAsFixed(2)}')
        .join('|');
    final data = '$timestamp|$dimensions|${profile.userId}';
    final hash = sha256.convert(utf8.encode(data));
    return hash.toString().substring(0, 16);
  }
  
  /// Calculate learning quality score for insight
  double _calculateInsightConfidence(
    Map<String, double> dimensionInsights,
    VibeCompatibilityResult compatibility,
  ) {
    if (dimensionInsights.isEmpty) return 0.0;
    
    // Base confidence on compatibility and number of insights
    final compatibilityFactor = compatibility.basicCompatibility;
    final insightFactor = (dimensionInsights.length / 12.0).clamp(0.0, 1.0);
    
    return (compatibilityFactor * 0.7 + insightFactor * 0.3).clamp(0.0, 1.0);
  }
}

/// Protocol message types
enum MessageType {
  connectionRequest,
  connectionResponse,
  learningExchange,
  heartbeat,
  disconnect,
  personalityExchange, // NEW: For offline AI2AI personality exchange
}

/// Protocol message structure
class ProtocolMessage {
  final String version;
  final MessageType type;
  final String senderId;
  final String? recipientId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  
  const ProtocolMessage({
    required this.version,
    required this.type,
    required this.senderId,
    this.recipientId,
    required this.timestamp,
    required this.payload,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'type': type.name,
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }
  
  factory ProtocolMessage.fromJson(Map<String, dynamic> json) {
    return ProtocolMessage(
      version: json['version'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.heartbeat,
      ),
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

/// Protocol packet structure
class ProtocolPacket {
  final String identifier;
  final String version;
  final Uint8List data;
  final String checksum;
  
  const ProtocolPacket({
    required this.identifier,
    required this.version,
    required this.data,
    required this.checksum,
  });
}

