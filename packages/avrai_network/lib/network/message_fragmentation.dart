import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:avrai_network/network/ai2ai_protocol.dart' show MessageType;

/// Message fragmentation for large messages (BitChat-inspired, AI2AI-optimized)
///
/// **BitChat Pattern:** fragmentStart/Continue/End pattern
/// **AI2AI-Specific:** ONLY for personalityExchange messages (>BLE MTU), skip for learning insights
///
/// **Fragmentation Strategy:**
/// - BLE MTU: 20-512 bytes (typically 23 bytes for notifications, 512 bytes for write)
/// - Fragment size: MTU - header overhead (typically 20 bytes per fragment)
/// - Only fragment personalityExchange messages (5-20KB)
/// - Learning insights (<1KB) are never fragmented
///
/// **Fragment Structure:**
/// - fragmentStart: Contains fragment index (0), total fragments, message ID, first chunk
/// - fragmentContinue: Contains fragment index, message ID, chunk data
/// - fragmentEnd: Contains fragment index (last), message ID, last chunk
class MessageFragmentation {
  static const String _logName = 'MessageFragmentation';

  /// BLE MTU (Maximum Transmission Unit)
  /// Typical values: 23 bytes (notifications), 512 bytes (write)
  /// We use conservative 20 bytes per fragment to account for headers
  static const int bleMtu = 512; // Conservative: use write MTU
  static const int fragmentSize = bleMtu - 20; // Reserve 20 bytes for headers

  /// Minimum size to trigger fragmentation (only for personalityExchange)
  static const int minFragmentationSize = 500; // 500 bytes

  /// Fragment a large message into smaller chunks
  ///
  /// **AI2AI-Specific:** Only fragments personalityExchange messages
  ///
  /// **Parameters:**
  /// - `messageData`: Full message data to fragment
  /// - `messageType`: Type of message (only personalityExchange is fragmented)
  /// - `messageId`: Unique message ID for reassembly
  ///
  /// **Returns:**
  /// List of fragments (or single fragment if message is small)
  static List<Fragment> fragment({
    required Uint8List messageData,
    required MessageType messageType,
    required String messageId,
  }) {
    // AI2AI-specific: Only fragment personalityExchange messages
    if (messageType != MessageType.personalityExchange) {
      developer.log(
        'Skipping fragmentation for message type: ${messageType.name} (only personalityExchange is fragmented)',
        name: _logName,
      );
      return [
        Fragment(
          index: 0,
          totalFragments: 1,
          messageId: messageId,
          data: messageData,
          isStart: true,
          isEnd: true,
        ),
      ];
    }

    // Check if message needs fragmentation
    if (messageData.length < minFragmentationSize) {
      developer.log(
        'Message too small to fragment: ${messageData.length} bytes < $minFragmentationSize bytes',
        name: _logName,
      );
      return [
        Fragment(
          index: 0,
          totalFragments: 1,
          messageId: messageId,
          data: messageData,
          isStart: true,
          isEnd: true,
        ),
      ];
    }

    // Calculate number of fragments
    final totalFragments = (messageData.length / fragmentSize).ceil();

    developer.log(
      'Fragmenting message: ${messageData.length} bytes into $totalFragments fragments (fragment size: $fragmentSize)',
      name: _logName,
    );

    final fragments = <Fragment>[];

    for (int i = 0; i < totalFragments; i++) {
      final start = i * fragmentSize;
      final end = (start + fragmentSize).clamp(0, messageData.length);
      final chunk = messageData.sublist(start, end);

      fragments.add(
        Fragment(
          index: i,
          totalFragments: totalFragments,
          messageId: messageId,
          data: chunk,
          isStart: i == 0,
          isEnd: i == totalFragments - 1,
        ),
      );
    }

    return fragments;
  }

  /// Reassemble fragments into complete message
  ///
  /// **Parameters:**
  /// - `fragments`: List of fragments to reassemble (must be sorted by index)
  ///
  /// **Returns:**
  /// Reassembled message data
  ///
  /// **Throws:**
  /// - `FormatException` if fragments are invalid or incomplete
  static Uint8List reassemble(List<Fragment> fragments) {
    if (fragments.isEmpty) {
      throw FormatException('No fragments provided for reassembly');
    }

    // Validate fragments
    final messageId = fragments.first.messageId;
    final totalFragments = fragments.first.totalFragments;

    // Check all fragments have same message ID and total count
    for (final fragment in fragments) {
      if (fragment.messageId != messageId) {
        throw FormatException(
          'Fragment message ID mismatch: expected $messageId, got ${fragment.messageId}',
        );
      }
      if (fragment.totalFragments != totalFragments) {
        throw FormatException(
          'Fragment total count mismatch: expected $totalFragments, got ${fragment.totalFragments}',
        );
      }
    }

    // Check we have all fragments
    if (fragments.length != totalFragments) {
      throw FormatException(
        'Incomplete fragments: expected $totalFragments, got ${fragments.length}',
      );
    }

    // Sort by index
    fragments.sort((a, b) => a.index.compareTo(b.index));

    // Validate indices are sequential
    for (int i = 0; i < fragments.length; i++) {
      if (fragments[i].index != i) {
        throw FormatException(
          'Fragment index mismatch: expected $i, got ${fragments[i].index}',
        );
      }
    }

    // Reassemble
    final buffer = BytesBuilder();
    for (final fragment in fragments) {
      buffer.add(fragment.data);
    }

    developer.log(
      'Reassembled message from $totalFragments fragments: ${buffer.length} bytes',
      name: _logName,
    );

    return buffer.toBytes();
  }

  /// Get MessageType for fragment
  static MessageType getFragmentType(Fragment fragment) {
    if (fragment.isStart && fragment.isEnd) {
      // Single fragment (not actually fragmented)
      return MessageType.personalityExchange;
    } else if (fragment.isStart) {
      return MessageType.fragmentStart;
    } else if (fragment.isEnd) {
      return MessageType.fragmentEnd;
    } else {
      return MessageType.fragmentContinue;
    }
  }
}

/// Fragment of a fragmented message
class Fragment {
  final int index;
  final int totalFragments;
  final String messageId;
  final Uint8List data;
  final bool isStart;
  final bool isEnd;

  const Fragment({
    required this.index,
    required this.totalFragments,
    required this.messageId,
    required this.data,
    required this.isStart,
    required this.isEnd,
  });

  /// Check if fragment is valid
  bool get isValid {
    return index >= 0 &&
        index < totalFragments &&
        totalFragments > 0 &&
        messageId.isNotEmpty &&
        data.isNotEmpty &&
        (isStart == (index == 0)) &&
        (isEnd == (index == totalFragments - 1));
  }
}
