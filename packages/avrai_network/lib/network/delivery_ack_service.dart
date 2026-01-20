import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai_network/network/ai2ai_protocol.dart' show MessageType;

/// Delivery acknowledgment service (BitChat-inspired, AI2AI-optimized)
///
/// **BitChat Pattern:** DeliveryAck/ReadReceipt pattern
/// **AI2AI-Specific:** ONLY for critical messages (personalityExchange, connectionRequest/Response, chat)
/// NO ACKs for learning insights (redundancy handles it)
///
/// **ACK Strategy:**
/// - Critical messages require delivery ACK (personalityExchange, connectionRequest/Response)
/// - Learning insights are best-effort (no ACK, redundancy handles delivery)
/// - Read receipts optional (future enhancement)
///
/// **ACK Types:**
/// - DeliveryAck: Message was delivered to recipient
/// - ReadReceipt: Message was read by recipient (future)
class DeliveryAckService {
  static const String _logName = 'DeliveryAckService';

  /// ACK timeout (5 seconds)
  static const Duration ackTimeout = Duration(seconds: 5);

  /// Pending ACKs (messageId -> Completer)
  final Map<String, Completer<bool>> _pendingAcks = {};

  /// ACK timers (messageId -> Timer)
  final Map<String, Timer> _ackTimers = {};

  /// Check if message type requires ACK (AI2AI-specific)
  ///
  /// **ACK Strategy:**
  /// - Critical messages require ACK: personalityExchange, connectionRequest/Response, userChat
  /// - Best-effort messages: learningInsight, heartbeat, disconnect, learningExchange, fragments
  static bool requiresAck(MessageType messageType) {
    switch (messageType) {
      case MessageType.personalityExchange:
      case MessageType.connectionRequest:
      case MessageType.connectionResponse:
      case MessageType.userChat: // User-to-user chat requires ACK (critical)
        return true; // Critical messages require ACK
      case MessageType.learningInsight:
      case MessageType.heartbeat:
      case MessageType.disconnect:
      case MessageType.learningExchange:
      case MessageType.fragmentStart:
      case MessageType.fragmentContinue:
      case MessageType.fragmentEnd:
      case MessageType.deliveryAck:
      case MessageType.readReceipt:
        return false; // Best-effort messages and ACK messages, no ACK
    }
  }

  /// Wait for delivery ACK
  ///
  /// **Parameters:**
  /// - `messageId`: Message ID to wait for ACK
  ///
  /// **Returns:**
  /// `true` if ACK received, `false` if timeout
  Future<bool> waitForAck(String messageId) async {
    final completer = Completer<bool>();
    _pendingAcks[messageId] = completer;

    // Set timeout
    final timer = Timer(ackTimeout, () {
      if (_pendingAcks.containsKey(messageId)) {
        _pendingAcks.remove(messageId);
        _ackTimers.remove(messageId);
        if (!completer.isCompleted) {
          completer.complete(false); // Timeout
          developer.log('ACK timeout for message: $messageId', name: _logName);
        }
      }
    });
    _ackTimers[messageId] = timer;

    return completer.future;
  }

  /// Receive delivery ACK
  ///
  /// **Parameters:**
  /// - `messageId`: Message ID that was acknowledged
  ///
  /// **Returns:**
  /// `true` if ACK was expected and processed, `false` if not expected
  bool receiveAck(String messageId) {
    final completer = _pendingAcks.remove(messageId);
    final timer = _ackTimers.remove(messageId);

    if (completer == null) {
      developer.log(
        'Received unexpected ACK for message: $messageId',
        name: _logName,
      );
      return false; // Not expected
    }

    // Cancel timeout
    timer?.cancel();

    // Complete ACK
    if (!completer.isCompleted) {
      completer.complete(true);
      developer.log('Received ACK for message: $messageId', name: _logName);
    }

    return true; // ACK processed
  }

  /// Cancel pending ACK (e.g., if message failed to send)
  void cancelAck(String messageId) {
    final completer = _pendingAcks.remove(messageId);
    final timer = _ackTimers.remove(messageId);

    timer?.cancel();

    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
      developer.log('Cancelled ACK for message: $messageId', name: _logName);
    }
  }

  /// Clear all pending ACKs
  void clear() {
    for (final timer in _ackTimers.values) {
      timer.cancel();
    }
    _pendingAcks.clear();
    _ackTimers.clear();
    developer.log('Cleared all pending ACKs', name: _logName);
  }

  /// Get statistics for debugging
  Map<String, dynamic> getStats() {
    return {'pendingAcks': _pendingAcks.length};
  }
}
