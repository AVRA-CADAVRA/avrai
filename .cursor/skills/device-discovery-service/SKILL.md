---
name: device-discovery-service
description: Guides device discovery implementation patterns for AI2AI connections. Use when implementing device discovery, BLE scanning, or WiFi-based device detection.
---

# Device Discovery Service

## Core Purpose

Discover nearby SPOTS-enabled devices for AI2AI connections.

## Platform Support

- **Android:** BLE + WiFi Direct
- **iOS:** Multipeer Connectivity + mDNS
- **Web:** WebRTC + WebSocket

## Discovery Pattern

```dart
/// Device Discovery Service
/// 
/// Discovers nearby SPOTS-enabled devices
class DeviceDiscoveryService {
  final BLEScanner _bleScanner;
  final WiFiDirectScanner? _wifiScanner;
  
  /// Start continuous device discovery
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration scanWindow = const Duration(seconds: 4),
    Duration deviceTimeout = const Duration(minutes: 2),
  }) async {
    // Start continuous scanning
    await _bleScanner.startScan(
      serviceUuid: spotsServiceUuid,
      scanInterval: scanInterval,
      scanWindow: scanWindow,
    );
    
    // Optional: WiFi Direct for Android
    if (_wifiScanner != null) {
      await _wifiScanner.startScan();
    }
  }
  
  /// Stop device discovery
  Future<void> stopDiscovery() async {
    await _bleScanner.stopScan();
    await _wifiScanner?.stopScan();
  }
  
  /// Get discovered devices
  Stream<List<DiscoveredDevice>> get discoveredDevices => _deviceStream;
}
```

## Service UUID Filtering

```dart
/// SPOTS Service UUID for hardware-level filtering
static const String spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';

/// Start scanning with service UUID filter (power efficient)
await ble.scan(
  withServices: [Guid(spotsServiceUuid)],
  scanMode: ScanMode.lowPower,
);
```

## Personality Data Extraction

```dart
/// Extract personality data from device advertisement
Future<AnonymizedPersonalityData?> extractPersonalityData(
  DiscoveredDevice device,
) async {
  // Extract anonymized personality data from advertisement
  // No personal identifiers, only anonymized personality dimensions
  final advertisementData = device.advertisementData;
  return AnonymizedPersonalityData.fromAdvertisement(advertisementData);
}
```

## Platform-Specific Implementations

### Android
```dart
/// Android BLE Device Discovery
class BLEDeviceDiscoveryAndroid implements DeviceDiscovery {
  @override
  Future<void> startDiscovery() async {
    // Use Android BLE APIs
    // Foreground service for background scanning
  }
}
```

### iOS
```dart
/// iOS Multipeer Connectivity Discovery
class DeviceDiscoveryIOS implements DeviceDiscovery {
  @override
  Future<void> startDiscovery() async {
    // Use Multipeer Connectivity framework
    // Background modes for continuous operation
  }
}
```

## Reference

- `docs/ai2ai/06_network_connectivity/DEVICE_DISCOVERY.md`
- `lib/core/network/device_discovery_android.dart`
- `lib/core/network/device_discovery_ios.dart`
