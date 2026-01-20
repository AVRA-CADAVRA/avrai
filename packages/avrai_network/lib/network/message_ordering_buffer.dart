import 'dart:developer' as developer;
import 'package:avrai_network/network/ai2ai_protocol.dart' show ProtocolMessage;

/// Message ordering buffer for out-of-order message processing (AI2AI-specific)
///
/// **Purpose:** Ensures learning insights and other messages are processed in correct order
///
/// **Features:**
/// - Buffers out-of-order messages
/// - Processes messages in sequence order
/// - Detects sequence gaps
/// - Handles sequence number wraparound
class MessageOrderingBuffer {
  static const String _logName = 'MessageOrderingBuffer';

  /// Maximum buffer size (prevent memory exhaustion)
  static const int maxBufferSize = 1000;

  /// Maximum gap to wait for (if gap > this, process what we have)
  static const int maxGap = 100;

  /// Per-peer buffers (keyed by AI agent ID)
  final Map<String, _PeerBuffer> _buffers = {};

  /// Add message to buffer
  ///
  /// **Parameters:**
  /// - `peerAgentId`: AI agent ID of the peer
  /// - `sequenceNumber`: Sequence number of the message
  /// - `message`: Message to buffer
  ///
  /// **Returns:**
  /// List of messages ready to process (in order)
  List<ProtocolMessage> addMessage({
    required String peerAgentId,
    required int sequenceNumber,
    required ProtocolMessage message,
  }) {
    final buffer = _getOrCreateBuffer(peerAgentId);
    buffer.add(sequenceNumber, message);

    // Get ready messages (in order)
    final ready = buffer.getReadyMessages();

    if (ready.isNotEmpty) {
      developer.log(
        'Processed $ready messages from buffer (peer: $peerAgentId, nextSeq: ${buffer.nextExpectedSequence})',
        name: _logName,
      );
    }

    return ready;
  }

  /// Get or create buffer for peer
  _PeerBuffer _getOrCreateBuffer(String peerAgentId) {
    return _buffers.putIfAbsent(peerAgentId, () => _PeerBuffer());
  }

  /// Clear buffer for peer (e.g., on disconnect)
  void clearBuffer(String peerAgentId) {
    _buffers.remove(peerAgentId);
    developer.log(
      'Cleared message ordering buffer for peer: $peerAgentId',
      name: _logName,
    );
  }

  /// Get statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'activeBuffers': _buffers.length,
      'totalBuffered': _buffers.values.fold(
        0,
        (sum, buffer) => sum + buffer.bufferedCount,
      ),
    };
  }
}

/// Per-peer message ordering buffer
class _PeerBuffer {
  /// Next expected sequence number
  int nextExpectedSequence = 0;

  /// Buffered messages (sequence number -> message)
  final Map<int, ProtocolMessage> _buffer = {};

  /// Add message to buffer
  void add(int sequenceNumber, ProtocolMessage message) {
    // Handle sequence number wraparound (32-bit max)
    final normalizedSeq = sequenceNumber % (1 << 32);

    if (normalizedSeq < nextExpectedSequence) {
      // Sequence number is in the past (wraparound or duplicate)
      // Check if it's within reasonable range (wraparound)
      final diff = nextExpectedSequence - normalizedSeq;
      if (diff > (1 << 31)) {
        // Likely wraparound, adjust nextExpectedSequence
        nextExpectedSequence = normalizedSeq;
      } else {
        // Duplicate or very old message, ignore
        return;
      }
    }

    // Add to buffer
    _buffer[normalizedSeq] = message;

    // Prevent buffer overflow
    if (_buffer.length > MessageOrderingBuffer.maxBufferSize) {
      // Remove oldest messages
      final sorted = _buffer.keys.toList()..sort();
      final toRemove = sorted.take(
        _buffer.length - MessageOrderingBuffer.maxBufferSize,
      );
      for (final seq in toRemove) {
        _buffer.remove(seq);
      }
    }
  }

  /// Get ready messages (in order, up to first gap)
  List<ProtocolMessage> getReadyMessages() {
    final ready = <ProtocolMessage>[];

    // Process messages in order
    while (_buffer.containsKey(nextExpectedSequence)) {
      final message = _buffer.remove(nextExpectedSequence);
      if (message != null) {
        ready.add(message);
      }
      nextExpectedSequence++;

      // Handle wraparound
      if (nextExpectedSequence >= (1 << 32)) {
        nextExpectedSequence = 0;
      }
    }

    // Check for large gaps (process what we have if gap is too large)
    if (_buffer.isNotEmpty && ready.isEmpty) {
      final sorted = _buffer.keys.toList()..sort();
      final firstBuffered = sorted.first;
      final gap = firstBuffered - nextExpectedSequence;

      if (gap > MessageOrderingBuffer.maxGap) {
        // Gap is too large, process from first buffered message
        developer.log(
          'Large sequence gap detected: $gap, processing from sequence $firstBuffered',
          name: MessageOrderingBuffer._logName,
        );
        nextExpectedSequence = firstBuffered;
        return getReadyMessages(); // Recursive call to process
      }
    }

    return ready;
  }

  /// Get count of buffered messages
  int get bufferedCount => _buffer.length;
}
