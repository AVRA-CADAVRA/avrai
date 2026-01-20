import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:avrai_network/network/device_discovery.dart';

/// Best-effort BLE connection pooling for high-throughput operations.
///
/// **Goal:** amortize `connect()` + `discoverServices()` across multiple sends /
/// reads during nearby discovery cycles.
///
/// Notes:
/// - BLE connections are not guaranteed to persist (OS may drop them).
/// - We keep connections warm for a short idle window and then disconnect.
/// - We cache characteristic handles to avoid repeated service discovery.
final class BleConnectionPool {
  static const String _logName = 'BleConnectionPool';

  static final BleConnectionPool instance = BleConnectionPool._();

  // Keep idle connections warm long enough to span periodic discovery.
  static const Duration _idleTimeout = Duration(minutes: 3);

  // Avoid keeping too many GATT connections open (platforms have limits).
  static const int _maxConnections = 3;

  final Map<String, _PooledConnection> _connections = {};
  final Map<String, _AsyncMutex> _mutexByKey = {};

  BleConnectionPool._();

  Future<T> withGatt<T>({
    required DiscoveredDevice device,
    // ignore: library_private_types_in_public_api - Internal helper type for GATT context
    required Future<T> Function(_GattContext gatt) action,
  }) async {
    if (device.type != DeviceType.bluetooth) {
      throw StateError('withGatt called for non-BLE device');
    }
    final handle = device.platformHandle;
    if (handle is! BluetoothDevice) {
      throw StateError('BLE device missing BluetoothDevice handle');
    }

    final key = device.deviceId;
    final entry = _connections[key] ??= _PooledConnection(
      key: key,
      device: handle,
    );

    _enforceMaxConnections();

    final mutex = _mutexByKey.putIfAbsent(key, _AsyncMutex.new);
    return mutex.synchronized(() => entry.withGatt(action));
  }

  /// Acquire an exclusive session for a device.
  ///
  /// While the session is open:
  /// - other pool users for the same device are blocked (no interleaving)
  /// - the GATT connection is kept warm (no idle disconnect)
  Future<BleGattSession> openSession({required DiscoveredDevice device}) async {
    if (device.type != DeviceType.bluetooth) {
      throw StateError('openSession called for non-BLE device');
    }
    final handle = device.platformHandle;
    if (handle is! BluetoothDevice) {
      throw StateError('BLE device missing BluetoothDevice handle');
    }

    final key = device.deviceId;
    final entry = _connections[key] ??= _PooledConnection(
      key: key,
      device: handle,
    );
    _enforceMaxConnections();

    final mutex = _mutexByKey.putIfAbsent(key, _AsyncMutex.new);
    final lease = await mutex.acquire();
    try {
      final gatt = await entry.beginSession();
      return BleGattSession._(
        deviceId: key,
        entry: entry,
        gatt: gatt,
        lease: lease,
      );
    } catch (e) {
      lease.release();
      rethrow;
    }
  }

  Future<void> invalidate(String deviceId) async {
    final entry = _connections[deviceId];
    if (entry == null) return;
    await entry.invalidate();
  }

  void _enforceMaxConnections() {
    if (_connections.length <= _maxConnections) return;

    // Evict least-recently-used idle connections.
    final candidates =
        _connections.values
            .where((c) => c.activeUsers == 0)
            .toList(growable: false)
          ..sort((a, b) => a.lastUsedMs.compareTo(b.lastUsedMs));

    for (final c in candidates) {
      if (_connections.length <= _maxConnections) break;
      _connections.remove(c.key);
      unawaited(c.close());
    }
  }
}

final class _AsyncMutex {
  Future<void> _tail = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final completer = Completer<void>();
    final prev = _tail;
    _tail = completer.future;
    await prev;
    try {
      return await action();
    } finally {
      completer.complete();
    }
  }

  Future<_AsyncLease> acquire() async {
    final completer = Completer<void>();
    final prev = _tail;
    _tail = completer.future;
    await prev;
    return _AsyncLease._(completer);
  }
}

final class _AsyncLease {
  final Completer<void> _completer;
  bool _released = false;

  _AsyncLease._(this._completer);

  void release() {
    if (_released) return;
    _released = true;
    _completer.complete();
  }
}

final class _GattContext {
  final BluetoothDevice device;
  final BluetoothCharacteristic readChar;
  final BluetoothCharacteristic writeChar;

  const _GattContext({
    required this.device,
    required this.readChar,
    required this.writeChar,
  });
}

final class _PooledConnection {
  static const String _spotsServiceUuid =
      '0000ff00-0000-1000-8000-00805f9b34fb';
  static const String _spotsReadCharacteristicUuid =
      '0000ff01-0000-1000-8000-00805f9b34fb';
  static const String _spotsWriteCharacteristicUuid =
      '0000ff02-0000-1000-8000-00805f9b34fb';

  final String key;
  final BluetoothDevice device;

  int activeUsers = 0;
  int lastUsedMs = DateTime.now().millisecondsSinceEpoch;

  Timer? _idleTimer;
  Future<void>? _connectFuture;
  BluetoothCharacteristic? _cachedRead;
  BluetoothCharacteristic? _cachedWrite;

  _PooledConnection({required this.key, required this.device});

  Future<_GattContext> beginSession() async {
    activeUsers++;
    _idleTimer?.cancel();
    await _ensureConnected();
    return _ensureGatt();
  }

  void endSession() {
    activeUsers--;
    lastUsedMs = DateTime.now().millisecondsSinceEpoch;
    if (activeUsers <= 0) {
      _scheduleIdleDisconnect();
    }
  }

  Future<T> withGatt<T>(Future<T> Function(_GattContext gatt) action) async {
    activeUsers++;
    _idleTimer?.cancel();
    try {
      await _ensureConnected();
      final gatt = await _ensureGatt();
      final out = await action(gatt);
      return out;
    } finally {
      activeUsers--;
      lastUsedMs = DateTime.now().millisecondsSinceEpoch;
      if (activeUsers <= 0) {
        _scheduleIdleDisconnect();
      }
    }
  }

  void _scheduleIdleDisconnect() {
    _idleTimer?.cancel();
    _idleTimer = Timer(BleConnectionPool._idleTimeout, () {
      // Best-effort: if someone grabbed it again, do nothing.
      if (activeUsers > 0) return;
      unawaited(close());
    });
  }

  Future<void> _ensureConnected() async {
    _connectFuture ??= () async {
      try {
        await device
            .connect(
              license: License.free, // Use free license for development/testing
            )
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        // Some platforms throw when already connected; treat as non-fatal.
        developer.log(
          'connect() error (best-effort): $e',
          name: BleConnectionPool._logName,
        );
      }
    }();

    try {
      await _connectFuture;
    } finally {
      // Allow future reconnect attempts if the caller invalidates/close()s.
      // We keep it set on success for "already connected" fast-path.
    }
  }

  Future<_GattContext> _ensureGatt() async {
    if (_cachedRead != null && _cachedWrite != null) {
      return _GattContext(
        device: device,
        readChar: _cachedRead!,
        writeChar: _cachedWrite!,
      );
    }

    final services = await device.discoverServices();
    BluetoothService? service;
    for (final s in services) {
      if (s.uuid.str.toLowerCase() == _spotsServiceUuid) {
        service = s;
        break;
      }
    }
    if (service == null) {
      throw StateError('SPOTS BLE service not found');
    }

    BluetoothCharacteristic? readChar;
    BluetoothCharacteristic? writeChar;
    for (final c in service.characteristics) {
      final uuid = c.uuid.str.toLowerCase();
      if (uuid == _spotsReadCharacteristicUuid) readChar = c;
      if (uuid == _spotsWriteCharacteristicUuid) writeChar = c;
    }
    if (readChar == null || writeChar == null) {
      throw StateError('SPOTS BLE characteristics not found');
    }

    _cachedRead = readChar;
    _cachedWrite = writeChar;
    return _GattContext(
      device: device,
      readChar: readChar,
      writeChar: writeChar,
    );
  }

  Future<void> invalidate() async {
    _cachedRead = null;
    _cachedWrite = null;
    _connectFuture = null;
    try {
      await device.disconnect();
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> close() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    _cachedRead = null;
    _cachedWrite = null;
    _connectFuture = null;
    try {
      await device.disconnect();
    } catch (_) {
      // Ignore.
    }
  }
}

/// Exclusive, multi-operation session on a pooled BLE connection.
///
/// This is the "lease" API: callers can do multiple operations (read stream 0,
/// read stream 1, send batch) without other callers interleaving.
class BleGattSession {
  final String deviceId;
  final _PooledConnection _entry;
  final _GattContext _gatt;
  final _AsyncLease _lease;
  bool _closed = false;

  BleGattSession._({
    required this.deviceId,
    required _PooledConnection entry,
    required _GattContext gatt,
    required _AsyncLease lease,
  }) : _entry = entry,
       _gatt = gatt,
       _lease = lease;

  // --- Read/control protocol ("SPTS") ---
  static const int _spts0 = 0x53; // S
  static const int _spts1 = 0x50; // P
  static const int _spts2 = 0x54; // T
  static const int _spts3 = 0x53; // S
  static const int _sptsVersion = 1;
  static const int _readHeaderLen = 16;
  static const int _controlFrameLen = 10;

  // --- Message write protocol ("SPTM") ---
  static const int _sptm0 = 0x53; // S
  static const int _sptm1 = 0x50; // P
  static const int _sptm2 = 0x54; // T
  static const int _sptm3 = 0x4D; // M
  static const int _sptmVersion = 2;
  static const int _senderIdLen = 36;
  static const int _headerLen = 20 + _senderIdLen;
  static const int _maxChunk = 120;

  // ACK stream id (served by peripheral as SPTS stream 2).
  static const int _streamAck = 2;

  Future<Uint8List?> readStreamPayload({required int streamId}) async {
    _ensureOpen();
    int offset = 0;
    int totalLen = -1;
    final out = BytesBuilder(copy: false);

    for (int i = 0; i < 2048; i++) {
      final control = _buildControlFrame(streamId: streamId, offset: offset);
      await _gatt.writeChar.write(control);

      final chunk = Uint8List.fromList(await _gatt.readChar.read());
      if (chunk.length < _readHeaderLen) return null;

      if (chunk[0] != _spts0 ||
          chunk[1] != _spts1 ||
          chunk[2] != _spts2 ||
          chunk[3] != _spts3) {
        return null;
      }
      if (chunk[4] != _sptsVersion) return null;
      if (chunk[5] != streamId) return null;

      final header = ByteData.sublistView(chunk, 0, _readHeaderLen);
      final rxTotalLen = header.getUint32(6, Endian.little);
      final rxOffset = header.getUint32(10, Endian.little);
      final rxChunkLen = header.getUint16(14, Endian.little);

      if (totalLen < 0) {
        totalLen = rxTotalLen;
      } else if (rxTotalLen != totalLen) {
        return null;
      }
      if (rxOffset != offset) return null;
      if (rxChunkLen == 0) break;

      final actualDataLen = chunk.length - _readHeaderLen;
      if (actualDataLen <= 0) return null;
      final usableDataLen = actualDataLen < rxChunkLen
          ? actualDataLen
          : rxChunkLen;
      out.add(chunk.sublist(_readHeaderLen, _readHeaderLen + usableDataLen));
      offset += usableDataLen;
      if (offset >= totalLen) break;
    }

    if (totalLen < 0) return null;
    final bytes = out.toBytes();
    if (bytes.length != totalLen) return null;
    return bytes;
  }

  Future<List<bool>> sendPacketsBatch({
    required String senderId,
    required List<Uint8List> packetBytesList,
  }) async {
    _ensureOpen();
    if (packetBytesList.isEmpty) return const [];

    final cappedList = packetBytesList.length > 20
        ? packetBytesList.sublist(0, 20)
        : packetBytesList;
    final results = List<bool>.filled(cappedList.length, false);

    final baseMsgId = _randomMsgId();
    final msgIds = List<int>.generate(
      cappedList.length,
      (i) => (baseMsgId + i) & 0x7FFFFFFF,
      growable: false,
    );

    var ackedIds = await _readAckedMsgIds(senderId: senderId);
    for (var i = 0; i < msgIds.length; i++) {
      if (ackedIds.contains(msgIds[i])) results[i] = true;
    }

    for (var i = 0; i < cappedList.length; i++) {
      if (results[i]) continue;
      final ok = await _writeMessageFrames(
        senderId: senderId,
        msgId: msgIds[i],
        packetBytes: cappedList[i],
      );
      if (!ok) return results;
    }

    var didResend = false;
    for (var poll = 0; poll < 6; poll++) {
      await Future.delayed(
        Duration(milliseconds: poll == 0 ? 120 : 120 * (1 << (poll - 1))),
      );
      ackedIds = await _readAckedMsgIds(senderId: senderId);
      for (var i = 0; i < msgIds.length; i++) {
        if (results[i]) continue;
        if (ackedIds.contains(msgIds[i])) results[i] = true;
      }

      final remaining = <int>[];
      for (var i = 0; i < results.length; i++) {
        if (!results[i]) remaining.add(i);
      }
      if (remaining.isEmpty) return results;

      if (!didResend && poll >= 2) {
        didResend = true;
        for (final idx in remaining) {
          await _writeMessageFrames(
            senderId: senderId,
            msgId: msgIds[idx],
            packetBytes: cappedList[idx],
          );
        }
      }
    }

    return results;
  }

  Future<void> invalidateConnection() async {
    _ensureOpen();
    await _entry.invalidate();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _entry.endSession();
    _lease.release();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('BleGattSession is closed');
    }
  }

  Future<bool> _writeMessageFrames({
    required String senderId,
    required int msgId,
    required Uint8List packetBytes,
  }) async {
    if (packetBytes.isEmpty) return false;
    final totalLen = packetBytes.length;
    int offset = 0;
    while (offset < totalLen) {
      final remaining = totalLen - offset;
      final chunkLen = remaining < _maxChunk ? remaining : _maxChunk;
      final frame = _buildMessageFrame(
        msgId: msgId,
        totalLen: totalLen,
        offset: offset,
        senderId: senderId,
        chunk: packetBytes.sublist(offset, offset + chunkLen),
      );
      await _gatt.writeChar.write(frame, withoutResponse: true);
      offset += chunkLen;
    }
    return true;
  }

  Future<Set<int>> _readAckedMsgIds({required String senderId}) async {
    final payload = await readStreamPayload(streamId: _streamAck);
    if (payload == null || payload.isEmpty) return <int>{};

    try {
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is! Map) return <int>{};
      final acks = decoded['acks'];
      if (acks is! List) return <int>{};
      final out = <int>{};
      for (final item in acks) {
        if (item is! Map) continue;
        final s = item['sender_id'];
        final m = item['msg_id'];
        if (s == senderId && m is num) out.add(m.toInt());
      }
      return out;
    } catch (_) {
      return <int>{};
    }
  }

  Uint8List _buildControlFrame({required int streamId, required int offset}) {
    final buf = Uint8List(_controlFrameLen);
    buf[0] = _spts0;
    buf[1] = _spts1;
    buf[2] = _spts2;
    buf[3] = _spts3;
    buf[4] = _sptsVersion;
    buf[5] = streamId;
    final bd = ByteData.sublistView(buf);
    bd.setUint32(6, offset, Endian.little);
    return buf;
  }

  Uint8List _buildMessageFrame({
    required int msgId,
    required int totalLen,
    required int offset,
    required String senderId,
    required List<int> chunk,
  }) {
    final buf = Uint8List(_headerLen + chunk.length);
    buf[0] = _sptm0;
    buf[1] = _sptm1;
    buf[2] = _sptm2;
    buf[3] = _sptm3;
    buf[4] = _sptmVersion;
    buf[5] = 0; // reserved

    final bd = ByteData.sublistView(buf);
    bd.setUint32(6, msgId, Endian.little);
    bd.setUint32(10, totalLen, Endian.little);
    bd.setUint32(14, offset, Endian.little);
    bd.setUint16(18, chunk.length, Endian.little);

    final idBytes = Uint8List.fromList(senderId.codeUnits);
    final idField = Uint8List(_senderIdLen);
    final copyLen = idBytes.length < _senderIdLen
        ? idBytes.length
        : _senderIdLen;
    idField.setRange(0, copyLen, idBytes);
    for (int i = copyLen; i < _senderIdLen; i++) {
      idField[i] = 0x20; // space pad
    }
    buf.setRange(20, 20 + _senderIdLen, idField);

    buf.setRange(_headerLen, _headerLen + chunk.length, chunk);
    return buf;
  }

  int _randomMsgId() {
    final r = Random.secure();
    return r.nextInt(0x7FFFFFFF);
  }
}
