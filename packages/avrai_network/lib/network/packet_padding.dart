import 'dart:typed_data';
import 'dart:developer' as developer;

/// PKCS#7 padding implementation for traffic analysis resistance
/// 
/// Pads packets to standard block sizes (256, 512, 1024, 2048 bytes)
/// to obscure true message length from network observers.
/// 
/// **BitChat Pattern:** Same PKCS#7-style padding as BitChat
class PacketPadding {
  static const String _logName = 'PacketPadding';
  
  /// Standard block sizes for padding (in bytes)
  /// Same as BitChat: 256, 512, 1024, 2048 bytes
  static const List<int> standardBlockSizes = [256, 512, 1024, 2048];
  
  /// Pad data to the next standard block size using PKCS#7 padding
  /// 
  /// **Algorithm:**
  /// 1. Determine target block size (smallest standard size >= data.length + 1)
  /// 2. Calculate padding length: targetSize - data.length
  /// 3. Pad with bytes equal to padding length
  /// 
  /// **Example:**
  /// - Data: 100 bytes → Pad to 256 bytes (156 bytes of padding, each byte = 156)
  /// - Data: 256 bytes → Pad to 512 bytes (256 bytes of padding, each byte = 256)
  /// 
  /// **Parameters:**
  /// - `data`: Data to pad
  /// 
  /// **Returns:**
  /// Padded data (always at least one block larger than input)
  static Uint8List pad(Uint8List data) {
    if (data.isEmpty) {
      // Empty data: pad to smallest block size
      return _padToSize(data, standardBlockSizes.first);
    }
    
    // Find smallest standard block size that fits data + at least one padding byte
    int targetSize = standardBlockSizes.first;
    for (final size in standardBlockSizes) {
      if (size > data.length) {
        targetSize = size;
        break;
      }
    }
    
    // If data is already at or larger than largest block size, pad to next multiple
    if (data.length >= standardBlockSizes.last) {
      // Pad to next multiple of largest block size
      final blocks = (data.length / standardBlockSizes.last).ceil();
      targetSize = blocks * standardBlockSizes.last;
      // Always add at least one block
      if (targetSize == data.length) {
        targetSize += standardBlockSizes.last;
      }
    }
    
    return _padToSize(data, targetSize);
  }
  
  /// Pad data to a specific size using PKCS#7 padding
  static Uint8List _padToSize(Uint8List data, int targetSize) {
    if (data.length >= targetSize) {
      throw ArgumentError(
        'Target size ($targetSize) must be larger than data length (${data.length})',
      );
    }
    
    final paddingLength = targetSize - data.length;
    if (paddingLength > 255) {
      throw ArgumentError(
        'Padding length ($paddingLength) exceeds maximum (255) for PKCS#7',
      );
    }
    
    final padded = Uint8List(targetSize);
    padded.setRange(0, data.length, data);
    
    // PKCS#7: pad with bytes equal to padding length
    padded.fillRange(data.length, targetSize, paddingLength);
    
    developer.log(
      'Padded ${data.length} bytes to $targetSize bytes (padding: $paddingLength)',
      name: _logName,
    );
    
    return padded;
  }
  
  /// Remove PKCS#7 padding from data
  /// 
  /// **Algorithm:**
  /// 1. Read last byte (padding length)
  /// 2. Validate padding bytes (all must equal padding length)
  /// 3. Return data without padding
  /// 
  /// **Parameters:**
  /// - `paddedData`: Data with PKCS#7 padding
  /// 
  /// **Returns:**
  /// Data without padding
  /// 
  /// **Throws:**
  /// - `FormatException` if padding is invalid
  static Uint8List unpad(Uint8List paddedData) {
    if (paddedData.isEmpty) {
      throw FormatException('Cannot unpad empty data');
    }
    
    final paddingLength = paddedData[paddedData.length - 1];
    
    if (paddingLength == 0 || paddingLength > paddedData.length) {
      throw FormatException(
        'Invalid padding length: $paddingLength (data length: ${paddedData.length})',
      );
    }
    
    // Validate all padding bytes are equal to padding length
    final paddingStart = paddedData.length - paddingLength;
    for (int i = paddingStart; i < paddedData.length; i++) {
      if (paddedData[i] != paddingLength) {
        throw FormatException(
          'Invalid PKCS#7 padding: byte at index $i is ${paddedData[i]}, expected $paddingLength',
        );
      }
    }
    
    final unpadded = paddedData.sublist(0, paddingStart);
    
    developer.log(
      'Unpadded ${paddedData.length} bytes to ${unpadded.length} bytes (padding: $paddingLength)',
      name: _logName,
    );
    
    return unpadded;
  }
  
  /// Get the target block size for a given data length
  /// 
  /// Returns the smallest standard block size that would be used for padding
  static int getTargetBlockSize(int dataLength) {
    if (dataLength == 0) {
      return standardBlockSizes.first;
    }
    
    for (final size in standardBlockSizes) {
      if (size > dataLength) {
        return size;
      }
    }
    
    // Data is larger than largest block size
    final blocks = (dataLength / standardBlockSizes.last).ceil();
    var targetSize = blocks * standardBlockSizes.last;
    if (targetSize == dataLength) {
      targetSize += standardBlockSizes.last;
    }
    return targetSize;
  }
}
