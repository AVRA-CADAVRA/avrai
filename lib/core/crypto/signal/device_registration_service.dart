// Device Registration Service
//
// Phase 2.1: Sesame Multi-Device Support
// Registers and manages devices for Signal Protocol multi-device support
//
// Enables users to access AI2AI connections from multiple devices,
// with personality learning syncing across devices.

import 'dart:developer' as developer;
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';

/// Device Registration Service
///
/// Manages device registration for Signal Protocol multi-device support.
/// Registers devices, manages device list, and handles device lifecycle.
///
/// **Phase 2.1:** Sesame Multi-Device Support (MEDIUM PRIORITY)
///
/// **Features:**
/// - Device registration
/// - Device list management
/// - Device lifecycle (add, remove, update)
/// - Device-specific key management
///
/// **Note:** This is a foundational implementation that can be extended.
/// Full Sesame integration requires state synchronization infrastructure.
class DeviceRegistrationService {
  static const String _logName = 'DeviceRegistrationService';

  // Note: _keyManager reserved for future use (multi-device key distribution)
  // ignore: unused_field
  final SignalKeyManager _keyManager;

  // In-memory device list (deviceId -> DeviceInfo)
  final Map<int, RegisteredDevice> _registeredDevices = {};

  DeviceRegistrationService({
    required SignalKeyManager keyManager,
  }) : _keyManager = keyManager;

  /// Register a new device
  ///
  /// **Parameters:**
  /// - `deviceId`: Device ID (integer, typically starts at 1)
  /// - `deviceName`: Human-readable device name (optional)
  ///
  /// **Returns:**
  /// Registered device info
  Future<RegisteredDevice> registerDevice({
    required int deviceId,
    String? deviceName,
  }) async {
    if (_registeredDevices.containsKey(deviceId)) {
      throw Exception('Device $deviceId is already registered');
    }

    final device = RegisteredDevice(
      deviceId: deviceId,
      deviceName: deviceName ?? 'Device $deviceId',
      registeredAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      isActive: true,
    );

    _registeredDevices[deviceId] = device;

    developer.log(
      'Registered device: id=$deviceId, name=${device.deviceName}',
      name: _logName,
    );

    return device;
  }

  /// Get registered device by ID
  RegisteredDevice? getDevice(int deviceId) {
    return _registeredDevices[deviceId];
  }

  /// Get all registered devices
  List<RegisteredDevice> getAllDevices() {
    return _registeredDevices.values.toList();
  }

  /// Get active devices only
  List<RegisteredDevice> getActiveDevices() {
    return _registeredDevices.values
        .where((device) => device.isActive)
        .toList();
  }

  /// Update device last seen timestamp
  Future<void> updateDeviceLastSeen(int deviceId) async {
    final device = _registeredDevices[deviceId];
    if (device != null) {
      _registeredDevices[deviceId] = device.copyWith(
        lastSeenAt: DateTime.now(),
      );
    }
  }

  /// Remove device (device deregistration)
  Future<void> removeDevice(int deviceId) async {
    final device = _registeredDevices.remove(deviceId);
    if (device != null) {
      developer.log(
        'Removed device: id=$deviceId, name=${device.deviceName}',
        name: _logName,
      );
    }
  }

  /// Deactivate device (keep in list but mark inactive)
  Future<void> deactivateDevice(int deviceId) async {
    final device = _registeredDevices[deviceId];
    if (device != null) {
      _registeredDevices[deviceId] = device.copyWith(isActive: false);
      developer.log(
        'Deactivated device: id=$deviceId',
        name: _logName,
      );
    }
  }
}

/// Registered Device Information
///
/// Represents a device registered for Signal Protocol multi-device support.
class RegisteredDevice {
  final int deviceId;
  final String deviceName;
  final DateTime registeredAt;
  final DateTime lastSeenAt;
  final bool isActive;

  RegisteredDevice({
    required this.deviceId,
    required this.deviceName,
    required this.registeredAt,
    required this.lastSeenAt,
    required this.isActive,
  });

  /// Create copy with updated fields
  RegisteredDevice copyWith({
    int? deviceId,
    String? deviceName,
    DateTime? registeredAt,
    DateTime? lastSeenAt,
    bool? isActive,
  }) {
    return RegisteredDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      registeredAt: registeredAt ?? this.registeredAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'registered_at': registeredAt.toIso8601String(),
      'last_seen_at': lastSeenAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Create from JSON
  factory RegisteredDevice.fromJson(Map<String, dynamic> json) {
    return RegisteredDevice(
      deviceId: json['device_id'] as int,
      deviceName: json['device_name'] as String,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }
}
