---
name: ble-implementation-patterns
description: Guides BLE implementation: device discovery, background scanning, power optimization, platform-specific implementations (Android/iOS). Use when implementing Bluetooth Low Energy features or device discovery.
---

# BLE Implementation Patterns

## Core Purpose

Bluetooth Low Energy (BLE) enables device discovery and personality data advertising in AI2AI system.

## Platform Support

- **Android:** BLE APIs with foreground service for background
- **iOS:** Core Bluetooth framework with background modes
- **Web:** Web Bluetooth API (when available)

## Device Discovery Pattern

```dart
/// BLE Device Discovery Service
/// 
/// Discovers nearby SPOTS-enabled devices using BLE
class BLEDeviceDiscoveryService {
  final BLEScanner _scanner;
  
  /// Start BLE scanning
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration scanWindow = const Duration(seconds: 4),
  }) async {
    // Start continuous scanning
    await _scanner.startScan(
      serviceUuid: spotsServiceUuid, // Filter by service UUID
      scanInterval: scanInterval,
      scanWindow: scanWindow,
    );
  }
  
  /// Stop BLE scanning
  Future<void> stopDiscovery() async {
    await _scanner.stopScan();
  }
}
```

## Service UUID Filtering

Use hardware-level filtering for power efficiency:

```dart
/// SPOTS Service UUID for hardware-level filtering
static const String spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';

/// Start scanning with service UUID filter
await ble.scan(
  withServices: [Guid(spotsServiceUuid)],
  scanMode: ScanMode.lowPower,
);
```

## Background Scanning (Android)

Use foreground service for background BLE:

```dart
/// BLE Foreground Service (Android)
/// 
/// Enables continuous BLE scanning in background
class BLEForegroundService extends Service {
  @override
  void onCreate() {
    super.onCreate();
    startForeground(
      NOTIFICATION_ID,
      createNotification(),
    );
    startBLEScanning();
  }
  
  void startBLEScanning() {
    // Start BLE scanning
    // Runs continuously in background
  }
}
```

## Background Scanning (iOS)

Configure background modes for iOS:

```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
  <string>bluetooth-peripheral</string>
</array>
```

## Power Optimization

### Intermittent Scanning
Scan for short periods, sleep in between:

```dart
/// Adaptive BLE Scanning
/// 
/// Adjusts scan frequency based on battery level and usage patterns
class AdaptiveBLEScanner {
  Future<void> startAdaptiveScanning() async {
    final batteryLevel = await getBatteryLevel();
    
    if (batteryLevel > 50) {
      // High battery: Scan more frequently
      await scan(interval: Duration(seconds: 3));
    } else if (batteryLevel > 20) {
      // Medium battery: Normal scanning
      await scan(interval: Duration(seconds: 5));
    } else {
      // Low battery: Reduced scanning
      await scan(interval: Duration(seconds: 10));
    }
  }
}
```

### Scan Window Pattern
```dart
/// Scan for 1 second, sleep for 4 seconds (intermittent)
await scanner.startScan(
  scanInterval: Duration(seconds: 5),
  scanWindow: Duration(seconds: 1), // Scan for 1 second
);
```

## Personality Data Advertising

Advertise anonymized personality data:

```dart
/// Personality Advertising Service
/// 
/// Advertises anonymized personality data via BLE
class PersonalityAdvertisingService {
  final BLEAdvertiser _advertiser;
  
  /// Start advertising personality data
  Future<void> startAdvertising() async {
    final personalityData = extractAnonymizedPersonality();
    
    await _advertiser.startAdvertising(
      serviceUuid: spotsServiceUuid,
      manufacturerData: personalityData.toBytes(),
    );
  }
}
```

## Platform-Specific Implementations

### Android
```dart
// lib/core/network/device_discovery_android.dart
class BLEDeviceDiscoveryAndroid implements BLEDeviceDiscovery {
  // Android-specific BLE implementation
  // Uses Android BLE APIs
  // Supports foreground service for background
}
```

### iOS
```dart
// lib/core/network/device_discovery_ios.dart
class BLEDeviceDiscoveryIOS implements BLEDeviceDiscovery {
  // iOS-specific BLE implementation
  // Uses Core Bluetooth framework
  // Supports background modes
}
```

## Reference

- `docs/ai2ai/06_network_connectivity/BLE_IMPLEMENTATION.md`
- `docs/ai2ai/06_network_connectivity/BLE_BACKGROUND.md`
- `lib/core/network/device_discovery_android.dart`
- `lib/core/network/device_discovery_ios.dart`
