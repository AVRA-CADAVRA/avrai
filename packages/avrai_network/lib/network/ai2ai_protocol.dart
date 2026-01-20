import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:avrai_core/models/personality_profile.dart';

import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_network/network/binary_packet_codec.dart';
import 'package:avrai_network/network/packet_padding.dart';
import 'package:avrai_network/network/replay_protection.dart';
import 'package:avrai_network/network/rate_limiter.dart';
import 'package:avrai_network/network/message_ordering_buffer.dart';
import 'package:avrai_network/network/delivery_ack_service.dart';
import 'package:avrai_network/network/message_fragmentation.dart'
    show MessageFragmentation, Fragment;

/// AI2AI Protocol Handler for Phase 6: Physical Layer
/// Handles message encoding/decoding, encryption, and connection management
/// OUR_GUTS.md: "Privacy-preserving AI2AI communication"
///
/// **NEW:** Uses binary packet format (BitChat-inspired, AI2AI-optimized)
/// - Binary serialization for efficiency (30-50% smaller packets)
/// - TTL integration with geographic scope
/// - PKCS#7 padding for traffic analysis resistance
/// - Backward compatible with JSON format during transition
class AI2AIProtocol {
  static const String _logName = 'AI2AIProtocol';
  static const String _protocolVersion = '1.0';
  static const String _protocolVersionBinary = '2.0'; // Binary format version
  static const String _spotsIdentifier = 'SPOTS-AI2AI';

  // Message encryption service (Phase 14: Signal Protocol ready)
  final MessageEncryptionService _encryptionService;

  // Legacy encryption key (deprecated - kept for backward compatibility)
  // TODO: Remove once all code uses MessageEncryptionService
  final Uint8List? _encryptionKey;

  // Binary format flag (for gradual rollout)
  final bool _useBinaryFormat;

  // Replay protection (BitChat-inspired)
  final ReplayProtection _replayProtection;

  // Rate limiter (BitChat-inspired, AI2AI-enhanced)
  final RateLimiter _rateLimiter;

  // Message ordering buffer (AI2AI-specific)
  final MessageOrderingBuffer _orderingBuffer;

  // Delivery ACK service (BitChat-inspired, AI2AI-optimized)
  final DeliveryAckService _ackService;

  // Per-peer sequence numbers (AI2AI-specific: for message ordering)
  final Map<String, int> _sequenceNumbers = {};

  // Fragment reassembly buffers (messageId -> fragments) - AI2AI-specific
  final Map<String, List<Fragment>> _fragmentBuffers = {};

  // Cleanup timer for fragment buffers
  Timer? _fragmentCleanupTimer;

  AI2AIProtocol({
    required MessageEncryptionService encryptionService,
    Uint8List? encryptionKey, // Deprecated - use encryptionService instead
    bool useBinaryFormat = true, // Feature flag for binary format
    ReplayProtection? replayProtection,
    RateLimiter? rateLimiter,
    MessageOrderingBuffer? orderingBuffer,
    DeliveryAckService? ackService,
  }) : _encryptionService = encryptionService,
       _encryptionKey = encryptionKey,
       _useBinaryFormat = useBinaryFormat,
       _replayProtection = replayProtection ?? ReplayProtection(),
       _rateLimiter = rateLimiter ?? RateLimiter(),
       _orderingBuffer = orderingBuffer ?? MessageOrderingBuffer(),
       _ackService = ackService ?? DeliveryAckService() {
    // Start fragment buffer cleanup timer
    _fragmentCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupFragmentBuffers(),
    );
  }

  /// Dispose resources
  void dispose() {
    _fragmentCleanupTimer?.cancel();
    _fragmentCleanupTimer = null;
    _replayProtection.dispose();
    _rateLimiter.dispose();
    _fragmentBuffers.clear();
    _sequenceNumbers.clear();
  }

  /// Encode a message for transmission
  ///
  /// **CRITICAL:** This method validates that no UnifiedUser data is in the payload.
  /// All user data must be converted to AnonymousUser before calling this method.
  ///
  /// **Phase 14:** Now uses MessageEncryptionService (Signal Protocol ready)
  Future<ProtocolMessage> encodeMessage({
    required MessageType type,
    required Map<String, dynamic> payload,
    required String senderNodeId,
    String? recipientNodeId,
  }) async {
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

      // Encrypt using MessageEncryptionService (Phase 14: Signal Protocol ready)
      Uint8List encryptedBytes;
      try {
        final encryptedMessage = await _encryptionService.encrypt(
          json,
          recipientNodeId ?? senderNodeId,
        );
        encryptedBytes = encryptedMessage.encryptedContent;

        developer.log(
          'Message encrypted using ${_encryptionService.encryptionType.name}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          'Encryption failed, falling back to unencrypted: $e',
          name: _logName,
        );
        // Fallback to unencrypted if encryption fails
        encryptedBytes = Uint8List.fromList(utf8.encode(json));
      }

      // Create protocol packet (for future transport layer implementation)
      final packet = ProtocolPacket(
        identifier: _spotsIdentifier,
        version: _protocolVersion,
        data: encryptedBytes,
        checksum: _calculateChecksum(encryptedBytes),
      );

      // Log packet creation for debugging (packet will be used when transport layer is implemented)
      developer.log(
        'Protocol packet created: ${packet.identifier} v${packet.version}, checksum: ${packet.checksum.substring(0, 8)}...',
        name: _logName,
      );

      return message;
    } catch (e) {
      developer.log('Error encoding message: $e', name: _logName);
      rethrow;
    }
  }

  /// Encode and return the full protocol packet bytes (for BLE transport).
  ///
  /// **NEW:** Uses binary packet format (BitChat-inspired, AI2AI-optimized)
  /// - Binary serialization for efficiency
  /// - TTL integration with geographic scope
  /// - PKCS#7 padding for traffic analysis resistance
  /// - Falls back to JSON format for backward compatibility
  ///
  /// Packet format: Binary (preferred) or JSON (legacy)
  Future<Uint8List> encodePacketBytes({
    required MessageType type,
    required Map<String, dynamic> payload,
    required String senderNodeId,
    String? recipientNodeId,
    String? geographicScope, // AI2AI-specific: for TTL calculation
    bool requiresAck = false, // AI2AI-specific: only for critical messages
  }) async {
    // Validate no UnifiedUser in payload (safety check)
    _validateNoUnifiedUserInPayload(payload);

    final message = ProtocolMessage(
      version: _useBinaryFormat ? _protocolVersionBinary : _protocolVersion,
      type: type,
      senderId: senderNodeId,
      recipientId: recipientNodeId,
      timestamp: DateTime.now(),
      payload: payload,
    );

    // Encrypt payload (JSON for encryption, binary for packet structure)
    // For binary format, we still encrypt the JSON payload, but use binary packet structure
    final json = jsonEncode(payload); // Only payload, not full message

    Uint8List encryptedBytes;
    try {
      final encryptedMessage = await _encryptionService.encrypt(
        json,
        recipientNodeId ?? senderNodeId,
      );
      encryptedBytes = encryptedMessage.encryptedContent;
    } catch (e) {
      // Last resort: plaintext (not ideal, but keeps transport functional).
      encryptedBytes = Uint8List.fromList(utf8.encode(json));
    }

    if (_useBinaryFormat) {
      // Check if message needs fragmentation (AI2AI-specific: only personalityExchange)
      final needsFragmentation =
          type == MessageType.personalityExchange &&
          encryptedBytes.length > MessageFragmentation.minFragmentationSize;

      if (needsFragmentation) {
        // Fragment large personality exchange messages
        final messageId = _generateMessageId();
        final fragments = MessageFragmentation.fragment(
          messageData: encryptedBytes,
          messageType: type,
          messageId: messageId,
        );

        // Encode each fragment
        final fragmentPackets = <Uint8List>[];
        for (final fragment in fragments) {
          final fragmentType = MessageFragmentation.getFragmentType(fragment);

          // Generate sequence number for ordering (AI2AI-specific)
          final peerId = recipientNodeId ?? senderNodeId;
          final seqNum = _getNextSequenceNumber(peerId);

          // Generate nonce for replay protection
          final nonce = _replayProtection.generateNonce(peerId);

          // Create fragment message
          final fragmentMessage = ProtocolMessage(
            version: _protocolVersionBinary,
            type: fragmentType,
            senderId: senderNodeId,
            recipientId: recipientNodeId,
            timestamp: message.timestamp,
            payload: {
              'fragment_index': fragment.index,
              'total_fragments': fragment.totalFragments,
              'message_id': fragment.messageId,
              'fragment_data': base64Encode(fragment.data),
            },
          );

          // Encode fragment payload
          final fragmentPayloadJson = jsonEncode(fragmentMessage.payload);
          final fragmentEncryptedBytes = Uint8List.fromList(
            utf8.encode(fragmentPayloadJson),
          );

          // Phase 4.2: Deniability features - fragments inherit deniability from original message
          final fragmentIsDeniable = type == MessageType.learningInsight || 
                                     type == MessageType.learningExchange;

          final binaryPacket = BinaryPacketCodec.encode(
            message: fragmentMessage,
            encryptedPayload: fragmentEncryptedBytes,
            geographicScope: geographicScope,
            nonce: nonce,
            sequenceNumber: seqNum,
            requiresAck: requiresAck,
            isDeniable: fragmentIsDeniable, // Phase 4.2: Deniability flag
          );

          // Apply padding
          final paddedPacket = PacketPadding.pad(binaryPacket);
          fragmentPackets.add(paddedPacket);
        }

        // Return first fragment
        // Note: In production, caller should send all fragments sequentially
        // For now, return first fragment - caller can iterate through fragments
        final checksum = _calculateChecksum(fragmentPackets.first);
        final firstPacket = _buildPacketBytes(
          identifier: _spotsIdentifier,
          version: _protocolVersionBinary,
          checksum: checksum,
          data: fragmentPackets.first,
        );

        developer.log(
          'Fragmented message into ${fragments.length} fragments: $messageId',
          name: _logName,
        );

        // TODO: Return all fragments or handle multi-packet sending
        // For now, return first fragment - remaining fragments should be sent separately
        return firstPacket;
      } else {
        // Non-fragmented message (normal flow)
        // Generate sequence number for ordering (AI2AI-specific)
        final peerId = recipientNodeId ?? senderNodeId;
        final seqNum = _getNextSequenceNumber(peerId);

        // Generate nonce for replay protection
        final nonce = _replayProtection.generateNonce(peerId);

        // Phase 4.2: Deniability features - mark learning insights as deniable
        // Learning insights cannot be cryptographically proven (Signal Protocol provides deniability)
        final isDeniable = type == MessageType.learningInsight || 
                          type == MessageType.learningExchange;

        final binaryPacket = BinaryPacketCodec.encode(
          message: message,
          encryptedPayload: encryptedBytes,
          geographicScope: geographicScope,
          nonce: nonce, // AI2AI-specific: nonce for replay protection
          sequenceNumber:
              seqNum, // AI2AI-specific: sequence number for ordering
          requiresAck: requiresAck,
          isDeniable: isDeniable, // Phase 4.2: Deniability flag
        );

        // Apply padding for traffic analysis resistance (BitChat pattern)
        final paddedPacket = PacketPadding.pad(binaryPacket);

        // Build legacy packet wrapper for backward compatibility
        // TODO: Remove wrapper after transition period
        final checksum = _calculateChecksum(paddedPacket);
        return _buildPacketBytes(
          identifier: _spotsIdentifier,
          version: _protocolVersionBinary, // Mark as binary format
          checksum: checksum,
          data: paddedPacket,
        );
      }
    } else {
      // Legacy JSON format (for backward compatibility)
      final checksum = _calculateChecksum(encryptedBytes);
      return _buildPacketBytes(
        identifier: _spotsIdentifier,
        version: _protocolVersion,
        checksum: checksum,
        data: encryptedBytes,
      );
    }
  }

  Uint8List _buildPacketBytes({
    required String identifier,
    required String version,
    required String checksum,
    required Uint8List data,
  }) {
    final idBytes = Uint8List.fromList(utf8.encode(identifier));
    final verBytes = Uint8List.fromList(utf8.encode(version));
    final chkBytes = Uint8List.fromList(utf8.encode(checksum));

    // Fixed-width fields required by _parsePacket().
    final idField = Uint8List(12);
    final verField = Uint8List(4);
    final chkField = Uint8List(64);

    idField.setRange(0, idBytes.length.clamp(0, 12), idBytes);
    verField.setRange(0, verBytes.length.clamp(0, 4), verBytes);
    chkField.setRange(0, chkBytes.length.clamp(0, 64), chkBytes);

    final out = BytesBuilder(copy: false);
    out.add(idField);
    out.add(verField);
    out.add(chkField);
    out.add(data);
    return out.toBytes();
  }

  /// Decode a received message
  ///
  /// **NEW:** Supports both binary and JSON formats (backward compatibility)
  /// **Phase 14:** Uses MessageEncryptionService (Signal Protocol ready)
  /// **AI2AI-Enhanced:** Includes replay protection and rate limiting checks
  Future<ProtocolMessage?> decodeMessage(
    Uint8List packetData,
    String senderId, // AI agent ID (not device ID) - AI2AI-specific
  ) async {
    try {
      // Rate limiting check (AI2AI-specific: check before processing)
      // Note: Message type and geographic scope would need to be extracted from packet
      // For now, use default limits - can be enhanced later with packet parsing
      final isAllowed = await _rateLimiter.checkRateLimit(
        peerAgentId: senderId,
        limitType: RateLimitType.message,
      );
      if (!isAllowed) {
        developer.log(
          'Rate limit exceeded for peer: $senderId, dropping message',
          name: _logName,
        );
        return null; // Drop message due to rate limit
      }

      // Parse packet header
      final packet = _parsePacket(packetData);

      // Verify identifier
      if (packet.identifier != _spotsIdentifier) {
        developer.log('Invalid protocol identifier', name: _logName);
        return null;
      }

      // Detect format: binary (version 2.0) or JSON (version 1.0)
      final isBinaryFormat = packet.version == _protocolVersionBinary;

      Uint8List dataToDecrypt = packet.data;

      // Verify checksum first (on padded data for binary format)
      // Checksum is calculated on padded data to match encoding
      final calculatedChecksum = _calculateChecksum(packet.data);
      if (calculatedChecksum != packet.checksum) {
        developer.log('Checksum mismatch, packet corrupted', name: _logName);
        return null;
      }

      // If binary format, remove padding after checksum verification
      if (isBinaryFormat) {
        try {
          dataToDecrypt = PacketPadding.unpad(packet.data);
        } catch (e) {
          developer.log(
            'Failed to unpad binary packet: $e',
            name: _logName,
            error: e,
          );
          // Cannot continue without valid padding - reject packet
          return null;
        }
      }

      if (isBinaryFormat) {
        // Decode binary packet
        try {
          final decodeResult = BinaryPacketCodec.decode(dataToDecrypt);

          // Replay protection: check nonce if present (AI2AI-specific)
          if (decodeResult.nonce != null) {
            final isValid = _replayProtection.checkNonce(
              decodeResult.nonce!,
              senderId,
            );
            if (!isValid) {
              developer.log(
                'Replay detected: nonce check failed (sender: $senderId)',
                name: _logName,
              );
              return null; // Reject replayed message
            }
          }

          // Decrypt payload
          String jsonPayload;
          try {
            final decryptedJson = await _encryptionService.decrypt(
              EncryptedMessage(
                encryptedContent: decodeResult.encryptedPayload,
                encryptionType: _encryptionService.encryptionType,
              ),
              senderId,
            );
            jsonPayload = decryptedJson;
          } catch (e) {
            // Fallback: Try legacy decryption
            if (_encryptionKey != null) {
              try {
                final decryptedBytes = _decrypt(decodeResult.encryptedPayload);
                jsonPayload = utf8.decode(decryptedBytes);
              } catch (legacyError) {
                developer.log(
                  'Both encryption methods failed: $e, $legacyError',
                  name: _logName,
                );
                jsonPayload = utf8.decode(decodeResult.encryptedPayload);
              }
            } else {
              jsonPayload = utf8.decode(decodeResult.encryptedPayload);
            }
          }

          // Check if this is a fragment (AI2AI-specific: fragment reassembly)
          final payloadData = jsonDecode(jsonPayload) as Map<String, dynamic>;
          final isFragment =
              payloadData.containsKey('fragment_index') &&
              payloadData.containsKey('total_fragments') &&
              payloadData.containsKey('message_id');

          if (isFragment) {
            // Handle fragment reassembly
            final fragment = Fragment(
              index: payloadData['fragment_index'] as int,
              totalFragments: payloadData['total_fragments'] as int,
              messageId: payloadData['message_id'] as String,
              data: base64Decode(payloadData['fragment_data'] as String),
              isStart: payloadData['fragment_index'] == 0,
              isEnd:
                  payloadData['fragment_index'] ==
                  payloadData['total_fragments'] - 1,
            );

            // Add fragment to buffer
            final fragments = _fragmentBuffers.putIfAbsent(
              fragment.messageId,
              () => <Fragment>[],
            );
            fragments.add(fragment);

            // Check if we have all fragments
            if (fragments.length == fragment.totalFragments) {
              try {
                // Reassemble fragments
                final reassembledData = MessageFragmentation.reassemble(
                  fragments,
                );
                _fragmentBuffers.remove(fragment.messageId);

                // Decrypt reassembled payload
                String reassembledJson;
                try {
                  final decryptedJson = await _encryptionService.decrypt(
                    EncryptedMessage(
                      encryptedContent: reassembledData,
                      encryptionType: _encryptionService.encryptionType,
                    ),
                    senderId,
                  );
                  reassembledJson = decryptedJson;
                } catch (e) {
                  // Fallback: Try legacy decryption
                  if (_encryptionKey != null) {
                    try {
                      final decryptedBytes = _decrypt(reassembledData);
                      reassembledJson = utf8.decode(decryptedBytes);
                    } catch (legacyError) {
                      developer.log(
                        'Both encryption methods failed for reassembled fragments: $e, $legacyError',
                        name: _logName,
                      );
                      reassembledJson = utf8.decode(reassembledData);
                    }
                  } else {
                    reassembledJson = utf8.decode(reassembledData);
                  }
                }

                // Parse reassembled payload
                final reassembledPayload =
                    jsonDecode(reassembledJson) as Map<String, dynamic>;

                // Create message from reassembled data
                final reassembledMessage = ProtocolMessage(
                  version: decodeResult.message.version,
                  type: MessageType.personalityExchange, // Original type
                  senderId: decodeResult.message.senderId,
                  recipientId: decodeResult.message.recipientId,
                  timestamp: decodeResult.message.timestamp,
                  payload: reassembledPayload,
                );

                developer.log(
                  'Reassembled fragmented message: ${fragment.messageId}, ${fragment.totalFragments} fragments',
                  name: _logName,
                );

                // Process reassembled message through ordering and ACK flow
                return await _processOrderedMessage(
                  message: reassembledMessage,
                  senderId: senderId,
                  sequenceNumber: decodeResult.sequenceNumber,
                  requiresAck: decodeResult.requiresAck,
                  ttl: decodeResult.ttl,
                );
              } catch (e) {
                developer.log(
                  'Failed to reassemble fragments: $e',
                  name: _logName,
                  error: e,
                );
                _fragmentBuffers.remove(fragment.messageId);
                return null;
              }
            } else {
              // Waiting for more fragments
              developer.log(
                'Fragment received: ${fragments.length}/${fragment.totalFragments} for message ${fragment.messageId}',
                name: _logName,
              );
              return null; // Will be returned when all fragments received
            }
          } else {
            // Normal (non-fragmented) message
            final message = ProtocolMessage(
              version: decodeResult.message.version,
              type: decodeResult.message.type,
              senderId: decodeResult.message.senderId,
              recipientId: decodeResult.message.recipientId,
              timestamp: decodeResult.message.timestamp,
              payload: payloadData,
            );

            // Handle delivery ACK messages immediately (AI2AI-specific)
            if (message.type == MessageType.deliveryAck) {
              final handled = handleDeliveryAck(message.payload);
              if (handled) {
                developer.log(
                  'Processed delivery ACK message from $senderId',
                  name: _logName,
                );
              }
              // ACK messages don't need ordering or further processing
              // Return null to indicate message was handled but not returned
              return null;
            }

            // Process through ordering and ACK flow
            return await _processOrderedMessage(
              message: message,
              senderId: senderId,
              sequenceNumber: decodeResult.sequenceNumber,
              requiresAck: decodeResult.requiresAck,
              ttl: decodeResult.ttl,
            );
          }
        } catch (e) {
          developer.log(
            'Failed to decode binary packet, falling back to JSON: $e',
            name: _logName,
          );
          // Fall through to JSON decoding
        }
      }

      // JSON format (legacy or fallback)
      String json;
      try {
        final decryptedJson = await _encryptionService.decrypt(
          EncryptedMessage(
            encryptedContent: dataToDecrypt,
            encryptionType: _encryptionService.encryptionType,
          ),
          senderId,
        );
        json = decryptedJson;
      } catch (e) {
        // Fallback: Try legacy decryption
        if (_encryptionKey != null) {
          try {
            final decryptedBytes = _decrypt(dataToDecrypt);
            json = utf8.decode(decryptedBytes);
          } catch (legacyError) {
            developer.log(
              'Both encryption methods failed: $e, $legacyError',
              name: _logName,
            );
            json = utf8.decode(dataToDecrypt);
          }
        } else {
          json = utf8.decode(dataToDecrypt);
        }
      }

      // Deserialize JSON message
      final data = jsonDecode(json) as Map<String, dynamic>;
      return ProtocolMessage.fromJson(data);
    } catch (e) {
      developer.log('Error decoding message: $e', name: _logName);
      return null;
    }
  }

  /// Validate that no UnifiedUser is being sent directly in AI2AI network
  ///
  /// This is a safety check to prevent accidental personal data leaks.
  /// All user data must be pre-anonymized before transmission.
  void _validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    // Check for common UnifiedUser fields that should never appear in AI2AI payloads
    final forbiddenFields = [
      'id',
      'email',
      'displayName',
      'photoUrl',
      'userId',
    ];

    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw Exception(
          'CRITICAL: UnifiedUser field "$field" detected in AI2AI payload. '
          'All user data must be anonymized before transmission.',
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

  /// Create a heartbeat message
  Future<ProtocolMessage> createHeartbeat({
    required String senderNodeId,
    String? recipientNodeId,
  }) async {
    return await encodeMessage(
      type: MessageType.heartbeat,
      payload: {'timestamp': DateTime.now().toIso8601String()},
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
      final message = await encodeMessage(
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
      developer.log('Error exchanging personality profile: $e', name: _logName);
      return null;
    }
  }

  /// Encrypt data using AES-256-GCM authenticated encryption
  ///
  /// **Deprecated:** Legacy method kept for backward compatibility.
  /// New code should use MessageEncryptionService instead.
  /// Returns encrypted data with format: IV (12 bytes) + ciphertext + tag (16 bytes)
  // ignore: unused_element
  Uint8List _encrypt(Uint8List data) {
    final encryptionKey = _encryptionKey;
    if (encryptionKey == null) {
      developer.log(
        'Warning: No encryption key set, returning unencrypted data',
        name: _logName,
      );
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
            KeyParameter(encryptionKey),
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
      encrypted.setRange(iv.length + ciphertext.length, encrypted.length, tag);

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
    final encryptionKey = _encryptionKey;
    if (encryptionKey == null) {
      developer.log(
        'Warning: No encryption key set, returning data as-is',
        name: _logName,
      );
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
        KeyParameter(encryptionKey),
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
        throw Exception(
          'Authentication tag mismatch - message may be tampered',
        );
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

  /// Process message through ordering buffer and ACK handling (AI2AI-specific)
  Future<ProtocolMessage?> _processOrderedMessage({
    required ProtocolMessage message,
    required String senderId,
    int? sequenceNumber,
    required bool requiresAck,
    required int ttl,
  }) async {
    // Message ordering: buffer and process in order (AI2AI-specific)
    if (sequenceNumber != null) {
      final readyMessages = _orderingBuffer.addMessage(
        peerAgentId: senderId,
        sequenceNumber: sequenceNumber,
        message: message,
      );

      // Process ready messages in order (return first ready message)
      // Note: In production, this should return all ready messages or use a callback
      if (readyMessages.isNotEmpty) {
        final readyMessage = readyMessages.first;

        // Note: ACK sending should be handled by caller after processing message
        // Log that ACK is required for critical messages
        if (requiresAck && DeliveryAckService.requiresAck(readyMessage.type)) {
          developer.log(
            'Message requires ACK: type=${readyMessage.type.name}, sender=$senderId',
            name: _logName,
          );
        }

        developer.log(
          'Decoded and ordered binary packet: type=${readyMessage.type.name}, seq=$sequenceNumber, ttl=$ttl',
          name: _logName,
        );

        return readyMessage;
      } else {
        // Message buffered, waiting for earlier messages
        developer.log(
          'Message buffered (out of order): type=${message.type.name}, seq=$sequenceNumber',
          name: _logName,
        );
        return null; // Will be returned when in order
      }
    } else {
      // No sequence number, process immediately
      developer.log(
        'Decoded binary packet (no ordering): type=${message.type.name}, ttl=$ttl, requiresAck=$requiresAck',
        name: _logName,
      );

      // Note: ACK sending should be handled by caller after processing message
      // We just log that ACK is required here
      if (requiresAck && DeliveryAckService.requiresAck(message.type)) {
        developer.log(
          'Message requires ACK: type=${message.type.name}, sender=$senderId',
          name: _logName,
        );
      }

      return message;
    }
  }

  /// Generate unique message ID for fragmentation
  String _generateMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return 'msg_${sha256.convert(bytes).toString().substring(0, 12)}';
  }

  /// Get next sequence number for peer (AI2AI-specific: for message ordering)
  int _getNextSequenceNumber(String peerId) {
    final current = _sequenceNumbers[peerId] ?? 0;
    final next = (current + 1) % (1 << 32); // Wrap around at 32-bit max
    _sequenceNumbers[peerId] = next;
    return next;
  }

  /// Send delivery ACK for a received message (AI2AI-specific)
  ///
  /// **Note:** This should be called by the caller after processing a message
  /// that requires an ACK. The ACK is sent as a separate message.
  ///
  /// **Parameters:**
  /// - `messageId`: ID of the message being acknowledged
  /// - `messageType`: Type of the message (to check if ACK required)
  /// - `senderId`: Our ID (sender of ACK)
  /// - `recipientId`: ID of the peer who sent the original message
  ///
  /// **Returns:**
  /// ACK packet bytes ready for transmission, or null if ACK not required
  Future<Uint8List?> sendDeliveryAck({
    required String messageId,
    required MessageType messageType,
    required String senderId,
    required String recipientId,
  }) async {
    // Check if ACK is required for this message type
    if (!DeliveryAckService.requiresAck(messageType)) {
      return null; // ACK not required
    }

    try {
      // Create ACK message payload
      final ackPayload = {
        'ack_type': 'delivery',
        'message_id': messageId,
        'original_type': messageType.name,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Create ACK message
      final ackMessage = ProtocolMessage(
        version: _protocolVersionBinary,
        type: MessageType.deliveryAck, // Use dedicated delivery ACK type
        senderId: senderId,
        recipientId: recipientId,
        timestamp: DateTime.now(),
        payload: ackPayload,
      );

      // Encode ACK message payload
      final ackJson = jsonEncode(ackPayload);
      Uint8List ackEncryptedBytes;
      try {
        final encryptedAck = await _encryptionService.encrypt(
          ackJson,
          recipientId,
        );
        ackEncryptedBytes = encryptedAck.encryptedContent;
      } catch (e) {
        // Fallback: plaintext (not ideal, but keeps transport functional)
        ackEncryptedBytes = Uint8List.fromList(utf8.encode(ackJson));
      }

      // Generate sequence number and nonce
      final seqNum = _getNextSequenceNumber(recipientId);
      final nonce = _replayProtection.generateNonce(recipientId);

      // Encode binary packet
      // Phase 4.2: Delivery ACKs are not deniable (they are explicit acknowledgments)
      final binaryPacket = BinaryPacketCodec.encode(
        message: ackMessage,
        encryptedPayload: ackEncryptedBytes,
        nonce: nonce,
        sequenceNumber: seqNum,
        requiresAck: false, // ACKs don't require ACKs
        isDeniable: false, // ACKs are explicit, not deniable
      );

      // Apply padding
      final paddedPacket = PacketPadding.pad(binaryPacket);

      // Build packet
      final checksum = _calculateChecksum(paddedPacket);

      developer.log(
        'Generated delivery ACK for message: $messageId, type=${messageType.name}',
        name: _logName,
      );

      return _buildPacketBytes(
        identifier: _spotsIdentifier,
        version: _protocolVersionBinary,
        checksum: checksum,
        data: paddedPacket,
      );
    } catch (e) {
      developer.log(
        'Failed to send delivery ACK: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Handle incoming ACK message (AI2AI-specific)
  ///
  /// **Parameters:**
  /// - `ackPayload`: Payload from ACK message
  ///
  /// **Returns:**
  /// `true` if ACK was processed, `false` if invalid
  bool handleDeliveryAck(Map<String, dynamic> ackPayload) {
    try {
      final messageId = ackPayload['message_id'] as String?;
      if (messageId == null) {
        return false;
      }

      // Mark ACK as received
      final received = _ackService.receiveAck(messageId);

      if (received) {
        developer.log(
          'Processed delivery ACK for message: $messageId',
          name: _logName,
        );
      }

      return received;
    } catch (e) {
      developer.log(
        'Failed to handle delivery ACK: $e',
        name: _logName,
        error: e,
      );
      return false;
    }
  }

  /// Clean up expired fragment buffers (call periodically)
  void _cleanupFragmentBuffers() {
    final expired = <String>[];

    // Remove empty fragment buffers
    for (final entry in _fragmentBuffers.entries) {
      // Simple cleanup: remove if buffer is empty
      // TODO: Add timestamp tracking for more sophisticated cleanup
      if (entry.value.isEmpty) {
        expired.add(entry.key);
      }
    }

    for (final messageId in expired) {
      _fragmentBuffers.remove(messageId);
    }

    if (expired.isNotEmpty) {
      developer.log(
        'Cleaned up ${expired.length} expired fragment buffers',
        name: _logName,
      );
    }
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
    final identifier = utf8.decode(data.sublist(0, 12)).trim();
    final version = utf8.decode(data.sublist(12, 16)).trim();
    final checksum = utf8.decode(data.sublist(16, 80)).trim();
    final payload = data.sublist(80);

    return ProtocolPacket(
      identifier: identifier,
      version: version,
      data: payload,
      checksum: checksum,
    );
  }

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
}

/// Protocol message types
enum MessageType {
  connectionRequest,
  connectionResponse,
  learningExchange,
  learningInsight, // NEW: Encrypted AI2AI learning insight exchange (v1)
  heartbeat,
  disconnect,
  personalityExchange, // NEW: For offline AI2AI personality exchange
  // Fragment types (BitChat-inspired, AI2AI-optimized)
  fragmentStart, // First fragment of fragmented message
  fragmentContinue, // Middle fragment of fragmented message
  fragmentEnd, // Last fragment of fragmented message
  userChat, // NEW: User-to-user chat messages routed through AI2AI mesh
  // Delivery acknowledgment types (BitChat-inspired, AI2AI-optimized)
  deliveryAck, // NEW: Delivery acknowledgment for critical messages
  readReceipt, // NEW: Read receipt (future enhancement)
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

  /// Convert to JSON (deprecated - kept for debugging and backward compatibility)
  ///
  /// **Note:** Binary format is preferred for production. JSON format is kept
  /// for debugging and backward compatibility during transition period.
  @Deprecated('Use binary format for production. JSON kept for debugging only.')
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

  /// Create from JSON (deprecated - kept for debugging and backward compatibility)
  ///
  /// **Note:** Binary format is preferred for production. JSON format is kept
  /// for debugging and backward compatibility during transition period.
  @Deprecated('Use binary format for production. JSON kept for debugging only.')
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
