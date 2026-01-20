import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:avrai/core/ai2ai/anonymous_communication.dart' as ai2ai;
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai/core/models/business_business_message.dart';
import 'package:avrai/core/services/business_account_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/services/user_anonymization_service.dart';
import 'package:avrai/core/services/location_obfuscation_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sembast/sembast.dart';
import 'package:avrai/data/datasources/local/sembast_database.dart';

/// Business-Business Chat Service (AI2AI Network Routing)
///
/// Routes messages between businesses through ai2ai network while showing real business identities.
/// Messages are encrypted in transit but participants see each other's real business names.
/// All messages stored locally in Sembast for offline access.
class BusinessBusinessChatServiceAI2AI {
  static const String _logName = 'BusinessBusinessChatServiceAI2AI';
  final ai2ai.AnonymousCommunicationProtocol _ai2aiProtocol;
  final MessageEncryptionService _encryptionService;
  final BusinessAccountService? _businessService;
  final AgentIdService _agentIdService;
  final _uuid = const Uuid();

  // Local message storage in Sembast
  static final StoreRef<String, Map<String, dynamic>> _messagesStore =
      stringMapStoreFactory.store('business_business_messages');
  static final StoreRef<String, Map<String, dynamic>> _conversationsStore =
      stringMapStoreFactory.store('business_business_conversations');

  BusinessBusinessChatServiceAI2AI({
    ai2ai.AnonymousCommunicationProtocol? ai2aiProtocol,
    MessageEncryptionService? encryptionService,
    BusinessAccountService? businessService,
    AgentIdService? agentIdService,
  })  : _ai2aiProtocol = ai2aiProtocol ?? _createDefaultProtocol(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _businessService = businessService,
        _agentIdService = agentIdService ?? di.sl<AgentIdService>();

  static ai2ai.AnonymousCommunicationProtocol _createDefaultProtocol() {
    try {
      // Try to get from DI first
      if (di.sl.isRegistered<ai2ai.AnonymousCommunicationProtocol>()) {
        return di.sl<ai2ai.AnonymousCommunicationProtocol>();
      }
    } catch (_) {
      // Fallback to creating with defaults
    }

    // Fallback: create with default dependencies
    try {
      return ai2ai.AnonymousCommunicationProtocol(
        encryptionService: di.sl.isRegistered<MessageEncryptionService>()
            ? di.sl<MessageEncryptionService>()
            : AES256GCMEncryptionService(),
        supabase: di.sl.isRegistered<SupabaseClient>()
            ? di.sl<SupabaseClient>()
            : Supabase.instance.client,
        atomicClock: di.sl.isRegistered<AtomicClockService>()
            ? di.sl<AtomicClockService>()
            : AtomicClockService(),
        anonymizationService: di.sl.isRegistered<UserAnonymizationService>()
            ? di.sl<UserAnonymizationService>()
            : UserAnonymizationService(
                locationObfuscationService: LocationObfuscationService(),
              ),
      );
    } catch (_) {
      // Last resort: create with minimal defaults
      return ai2ai.AnonymousCommunicationProtocol(
        encryptionService: AES256GCMEncryptionService(),
        supabase: Supabase.instance.client,
        atomicClock: AtomicClockService(),
        anonymizationService: UserAnonymizationService(
          locationObfuscationService: LocationObfuscationService(),
        ),
      );
    }
  }

  /// Send a message from one business to another
  ///
  /// Messages are:
  /// 1. Encrypted with MessageEncryptionService
  /// 2. Routed through ai2ai network (encrypted in transit)
  /// 3. Stored locally in Sembast (for offline access)
  /// 4. Include participant identities (visible to participants)
  ///
  /// Agent IDs are automatically looked up if not provided.
  Future<BusinessBusinessMessage> sendMessage({
    required String senderBusinessId,
    required String recipientBusinessId,
    required String content,
    String? senderAgentId, // Optional: will be looked up if not provided
    String? recipientAgentId, // Optional: will be looked up if not provided
    BusinessBusinessMessageType messageType = BusinessBusinessMessageType.text,
    bool encrypt = true,
  }) async {
    try {
      // Get agent IDs if not provided
      final actualSenderAgentId = senderAgentId ??
          await _agentIdService.getBusinessAgentId(senderBusinessId);

      final actualRecipientAgentId = recipientAgentId ??
          await _agentIdService.getBusinessAgentId(recipientBusinessId);

      developer.log(
        'Sending business-business message via ai2ai: senderAgent=$actualSenderAgentId, recipientAgent=$actualRecipientAgentId',
        name: _logName,
      );

      // Get or create conversation
      final conversation =
          await _getOrCreateConversation(senderBusinessId, recipientBusinessId);

      // Encrypt message content if requested
      Uint8List? encryptedContent;
      EncryptionType encryptionType = EncryptionType.aes256gcm;
      if (encrypt) {
        final encrypted =
            await _encryptionService.encrypt(content, actualRecipientAgentId);
        encryptedContent = encrypted.encryptedContent;
        encryptionType = encrypted.encryptionType;
      }

      // Create message with participant identities
      final message = BusinessBusinessMessage(
        id: _uuid.v4(),
        conversationId: conversation['id'] as String,
        senderBusinessId: senderBusinessId,
        recipientBusinessId: recipientBusinessId,
        content: content,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store message locally in Sembast
      await _saveMessageLocally(message);

      // Route message through ai2ai network
      // Payload includes participant identities (visible to participants, encrypted in transit)
      final ai2aiPayload = {
        'message_id': message.id,
        'conversation_id': message.conversationId,
        'sender_business_id': senderBusinessId,
        'recipient_business_id': recipientBusinessId,
        'content': content, // Will be encrypted by ai2ai protocol
        'encrypted_content':
            encryptedContent != null ? base64Encode(encryptedContent) : null,
        'encryption_type': encryptionType.name,
        'message_type': messageType.name,
        'created_at': message.createdAt.toIso8601String(),
      };

      // Route through ai2ai network
      // MessageType.userChat allows routing before decryption (unencrypted header)
      final payloadWithCategory = {
        ...ai2aiPayload,
        'message_category':
            'user_chat', // Optional: post-decryption validation/clarity
      };
      await _ai2aiProtocol.sendEncryptedMessage(
        actualRecipientAgentId,
        ai2ai.MessageType
            .userChat, // Protocol-level routing via unencrypted header (AnonymousCommunicationProtocol enum)
        payloadWithCategory,
      );

      // Update conversation last_message_at
      await _updateConversationLastMessage(conversation['id'] as String);

      developer.log(
        'Business-business message sent via ai2ai: ${message.id}',
        name: _logName,
      );

      return message;
    } catch (e) {
      developer.log('Error sending message: $e', name: _logName);
      rethrow;
    }
  }

  /// Get conversation between two businesses
  Future<Map<String, dynamic>?> getConversation(
    String business1Id,
    String business2Id,
  ) async {
    try {
      final db = await SembastDatabase.database;
      final conversationId = _generateConversationId(business1Id, business2Id);
      final record = await _conversationsStore.record(conversationId).get(db);
      return record;
    } catch (e) {
      developer.log('Error getting conversation: $e', name: _logName);
      return null;
    }
  }

  /// Get all conversations for a business (business-business)
  Future<List<Map<String, dynamic>>> getBusinessConversations(
      String businessId) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(
        filter: Filter.or([
          Filter.equals('business_1_id', businessId),
          Filter.equals('business_2_id', businessId),
        ]),
        sortOrders: [SortOrder('last_message_at', true)], // Most recent first
      );

      final records = await _conversationsStore.find(db, finder: finder);
      return records.map((record) {
        final data = record.value;
        // Normalize: always put the other business as the "partner"
        if (data['business_1_id'] == businessId) {
          return {
            ...data,
            'partner_id': data['business_2_id'],
            'partner_name': data['business_2_name'],
          };
        } else {
          return {
            ...data,
            'partner_id': data['business_1_id'],
            'partner_name': data['business_1_name'],
          };
        }
      }).toList();
    } catch (e) {
      developer.log('Error getting business conversations: $e', name: _logName);
      return [];
    }
  }

  /// Get or create conversation
  Future<Map<String, dynamic>> _getOrCreateConversation(
    String business1Id,
    String business2Id,
  ) async {
    final existing = await getConversation(business1Id, business2Id);
    if (existing != null) {
      return existing;
    }

    // Get business names for display
    String? business1Name;
    String? business2Name;

    if (_businessService != null) {
      try {
        final business1 =
            await _businessService!.getBusinessAccount(business1Id);
        business1Name = business1?.name;
        final business2 =
            await _businessService!.getBusinessAccount(business2Id);
        business2Name = business2?.name;
      } catch (e) {
        developer.log('Error getting business names: $e', name: _logName);
      }
    }

    // Create new conversation
    final conversationId = _generateConversationId(business1Id, business2Id);
    final conversationData = {
      'id': conversationId,
      'business_1_id': business1Id,
      'business_2_id': business2Id,
      'business_1_name': business1Name,
      'business_2_name': business2Name,
      'connection_status': 'pending',
      'last_message_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final db = await SembastDatabase.database;
    await _conversationsStore.record(conversationId).put(db, conversationData);

    return conversationData;
  }

  /// Get message history for a conversation (from local Sembast storage)
  Future<List<BusinessBusinessMessage>> getMessageHistory(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await SembastDatabase.database;

      // Query messages for this conversation, ordered by created_at
      final finder = Finder(
        filter: Filter.equals('conversation_id', conversationId),
        sortOrders: [SortOrder('created_at', false)], // Newest first
      );

      final records = await _messagesStore.find(db, finder: finder);

      // Apply pagination
      final paginatedRecords = records.skip(offset).take(limit);

      final messages = paginatedRecords
          .map((record) => BusinessBusinessMessage.fromJson(record.value))
          .toList();

      // Decrypt messages if needed
      final decryptedMessages = <BusinessBusinessMessage>[];
      for (final message in messages) {
        if (message.encryptedContent != null) {
          try {
            final encrypted = EncryptedMessage(
              encryptedContent: message.encryptedContent!,
              encryptionType: message.encryptionType,
            );
            // Signal sessions are keyed by the remote business *agentId* (not businessId).
            // For legacy AES (local-only), keep the existing senderBusinessId behavior.
            final decryptKeyId =
                message.encryptionType == EncryptionType.signalProtocol
                    ? await _agentIdService
                        .getBusinessAgentId(message.senderBusinessId)
                    : message.senderBusinessId;
            final decrypted = await _encryptionService.decrypt(
              encrypted,
              decryptKeyId,
            );
            decryptedMessages.add(message.copyWith(content: decrypted));
          } catch (e) {
            developer.log('Error decrypting message: $e', name: _logName);
            decryptedMessages.add(message);
          }
        } else {
          decryptedMessages.add(message);
        }
      }

      return decryptedMessages.reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      developer.log('Error getting message history: $e', name: _logName);
      return [];
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final db = await SembastDatabase.database;
      final record = await _messagesStore.record(messageId).get(db);
      if (record != null) {
        final updated = Map<String, dynamic>.from(record)
          ..['is_read'] = true
          ..['read_at'] = DateTime.now().toIso8601String()
          ..['updated_at'] = DateTime.now().toIso8601String();
        await _messagesStore.record(messageId).put(db, updated);
      }
    } catch (e) {
      developer.log('Error marking message as read: $e', name: _logName);
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String businessId) async {
    try {
      final db = await SembastDatabase.database;

      final finder = Finder(
        filter: Filter.and([
          Filter.equals('is_read', false),
          Filter.equals('recipient_business_id', businessId),
        ]),
      );

      final records = await _messagesStore.find(db, finder: finder);
      return records.length;
    } catch (e) {
      developer.log('Error getting unread count: $e', name: _logName);
      return 0;
    }
  }

  /// Subscribe to real-time messages from ai2ai network
  Stream<BusinessBusinessMessage> subscribeToMessages(String conversationId) {
    final controller = StreamController<BusinessBusinessMessage>.broadcast();

    // Poll for new messages from ai2ai network
    // In a real implementation, this would use ai2ai realtime subscriptions
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Check for new messages via ai2ai protocol
        final newMessages = await _checkForNewMessages(conversationId);
        for (final message in newMessages) {
          controller.add(message);
        }
      } catch (e) {
        developer.log('Error checking for new messages: $e', name: _logName);
      }
    });

    return controller.stream;
  }

  /// Check for new messages from ai2ai network
  Future<List<BusinessBusinessMessage>> _checkForNewMessages(
      String conversationId) async {
    // This would integrate with ai2ai network to receive messages
    // For now, return empty list - real implementation would:
    // 1. Listen to ai2ai network for messages
    // 2. Decrypt and validate messages
    // 3. Store locally in Sembast
    // 4. Return new messages
    return [];
  }

  /// Save message locally in Sembast
  Future<void> _saveMessageLocally(BusinessBusinessMessage message) async {
    try {
      final db = await SembastDatabase.database;
      await _messagesStore.record(message.id).put(db, message.toJson());
    } catch (e) {
      developer.log('Error saving message locally: $e', name: _logName);
      rethrow;
    }
  }

  /// Update conversation last message timestamp
  Future<void> _updateConversationLastMessage(String conversationId) async {
    try {
      final db = await SembastDatabase.database;
      final record = await _conversationsStore.record(conversationId).get(db);
      if (record != null) {
        final updated = Map<String, dynamic>.from(record)
          ..['last_message_at'] = DateTime.now().toIso8601String()
          ..['updated_at'] = DateTime.now().toIso8601String();
        await _conversationsStore.record(conversationId).put(db, updated);
      }
    } catch (e) {
      developer.log('Error updating conversation: $e', name: _logName);
    }
  }

  /// Generate conversation ID from two business IDs
  String _generateConversationId(String business1Id, String business2Id) {
    // Deterministic ID generation (same conversation always gets same ID)
    final ids = [business1Id, business2Id]..sort();
    return 'conv_bb_${ids.join('_')}';
  }
}
